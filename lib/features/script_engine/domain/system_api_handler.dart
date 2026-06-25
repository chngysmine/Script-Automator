import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:script_automator/core/security/network_policy.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Handles System API requests dispatched from the JS Engine Isolate.
///
/// Runs on the Main Isolate where full platform access (HTTP, Channels)
/// is available. Each handler returns a JSON-encoded [String] response.
///
/// Security measures:
/// - Keychain keys are namespaced per [scriptId] to prevent cross-script access.
/// - Fetch requests are blocked to private/loopback IP ranges (SSRF protection).
/// - The HTTP client is properly closed via [dispose].
class SystemAPIHandler {
  final http.Client _client = http.Client();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late final FlutterSecureStorage _secureStorage;
  bool _notificationsInitialized = false;

  /// The ID of the currently executing script, used for Keychain namespacing.
  String? activeScriptId;

  SystemAPIHandler() {
    _secureStorage = AppSecureStorage.create();
  }

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
    await _notificationsPlugin.initialize(settings: initializationSettings);
    
    // Explicitly request notification permission on Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
    
    _notificationsInitialized = true;
  }

  /// Executes an HTTP fetch request.
  ///
  /// [payload] must be a JSON string:
  /// ```json
  /// { "url": "...", "method": "GET", "headers": {...}, "body": "..." }
  /// ```
  ///
  /// Returns a JSON string with `status`, `headers`, and `body` fields.
  /// Returns `{ "error": "...", "status": 0 }` on failure.
  Future<String> handleFetch(String payload) async {
    try {
      final Map<String, dynamic> requestData = jsonDecode(payload);
      final String url = requestData['url'] ?? '';
      final String method = (requestData['method'] ?? 'GET').toUpperCase();
      final Map<String, String> headers =
          Map<String, String>.from(requestData['headers'] ?? {});
      final String? body = requestData['body'];

      final validationError = await NetworkPolicy.validateUrl(url);
      if (validationError != null) {
        return jsonEncode({
          'error': validationError,
          'status': validationError.contains('unsupported scheme') ? 400 : 403,
        });
      }

      final uri = Uri.parse(url);
      final String scheme = uri.scheme.toLowerCase();

      String resolvedIp = uri.host;
      bool isHostIp = false;
      try {
        InternetAddress(uri.host);
        isHostIp = true;
      } catch (_) {}

      if (!isHostIp) {
        try {
          final resolvedHosts = await InternetAddress.lookup(uri.host)
              .timeout(const Duration(seconds: 5));
          if (resolvedHosts.isNotEmpty) {
            resolvedIp = resolvedHosts.first.address;
          }
        } catch (_) {}
      }

      // Pin the target host to IP for HTTP requests to prevent DNS Rebinding.
      // Rely on TLS/SSL Handshake hostname validation for HTTPS requests.
      Uri targetUri;
      if (scheme == 'http') {
        targetUri = uri.replace(host: resolvedIp);
        headers['Host'] = uri.host;
      } else {
        targetUri = uri;
      }

      http.Response response;

      switch (method) {
        case 'POST':
          response = await _client
              .post(targetUri, headers: headers, body: body)
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await _client
              .put(targetUri, headers: headers, body: body)
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await _client
              .delete(targetUri, headers: headers, body: body)
              .timeout(const Duration(seconds: 15));
          break;
        case 'GET':
        default:
          response = await _client
              .get(targetUri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
      }

      return jsonEncode({
        'status': response.statusCode,
        'headers': response.headers,
        'body': response.body,
      });
    } catch (e) {
      return jsonEncode({
        'error': e.toString(),
        'status': 0,
      });
    }
  }

  /// Queries basic device information.
  ///
  /// [property] must be one of: `os`, `osVersion`, `locale`, `model`.
  /// Returns a JSON string: `{ "value": "..." }`.
  Future<String> handleDeviceInfo(String property) async {
    try {
      String result;
      switch (property) {
        case 'os':
          result = Platform.operatingSystem;
        case 'osVersion':
          result = Platform.operatingSystemVersion;
        case 'locale':
          result = Platform.localeName;
        case 'model':
          if (Platform.isIOS) {
            result = 'iPhone/iPad';
          } else if (Platform.isAndroid) {
            result = 'Android Device';
          } else {
            result = 'Desktop';
          }
        default:
          result = 'unknown';
      }
      return jsonEncode({'value': result});
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// Handles Keychain (Secure Storage) read/write/delete operations.
  ///
  /// Keys are automatically namespaced with the [activeScriptId] prefix
  /// to prevent cross-script access to sensitive data.
  ///
  /// [payload] must be a JSON string:
  /// ```json
  /// { "action": "get"|"set"|"delete", "key": "...", "value": "..." }
  /// ```
  Future<String> handleKeychain(String payload) async {
    try {
      final data = jsonDecode(payload);
      final String action = data['action'] ?? 'get';
      final String rawKey = data['key'] ?? '';
      final String? value = data['value'];

      if (rawKey.isEmpty) {
        return jsonEncode({'error': 'Key must not be empty'});
      }

      final namespacedKey = 'script_${activeScriptId ?? 'unknown'}.$rawKey';

      switch (action) {
        case 'set':
          if (value == null) return jsonEncode({'error': 'Value is null'});
          await _secureStorage.write(key: namespacedKey, value: value);
          return jsonEncode({'success': true});
        case 'delete':
          await _secureStorage.delete(key: namespacedKey);
          return jsonEncode({'success': true});
        case 'get':
        default:
          final readValue = await _secureStorage.read(key: namespacedKey);
          return jsonEncode({'value': readValue});
      }
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// Schedules a local notification.
  ///
  /// [payload] must be a JSON string:
  /// ```json
  /// { "title": "...", "body": "...", "id": 1 }
  /// ```
  Future<String> handleNotification(String payload) async {
    try {
      await _initNotifications();
      final data = jsonDecode(payload);
      final String title = data['title'] ?? 'Script Notification';
      final String body = data['body'] ?? '';
      final int id =
          data['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const androidDetails = AndroidNotificationDetails(
        'script_channel_id',
        'Script Automator',
        channelDescription: 'Notifications generated by JS scripts',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public, // Ensures lock screen content visibility
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true, // Show banner when app is in foreground
        presentBadge: true,
        presentSound: true,
      );
      const notificationDetails =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
      return jsonEncode({'success': true});
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// Handles Clipboard read/write operations.
  Future<String> handleClipboard(String payload) async {
    try {
      final data = jsonDecode(payload);
      final String action = data['action'] ?? 'read';
      final String? text = data['text'];

      if (action == 'write') {
        if (text == null) return jsonEncode({'error': 'Text is null'});
        await Clipboard.setData(ClipboardData(text: text));
        return jsonEncode({'success': true});
      } else {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        return jsonEncode({'value': clipboardData?.text});
      }
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// Handles Share operations.
  Future<String> handleShare(String payload) async {
    try {
      final data = jsonDecode(payload);
      final String text = data['text'] ?? '';
      final String? title = data['title'];

      if (text.isEmpty) {
        return jsonEncode({'error': 'Text must not be empty'});
      }

      // ignore: deprecated_member_use
      await Share.share(text, subject: title);
      return jsonEncode({'success': true});
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// Releases HTTP client resources. Call when the handler is no longer needed.
  void dispose() {
    _client.close();
  }
}
