import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  bool _notificationsInitialized = false;

  /// The ID of the currently executing script, used for Keychain namespacing.
  String? activeScriptId;

  /// Blocked URL patterns for SSRF protection.
  static final List<RegExp> _blockedPatterns = [
    RegExp(r'^https?://(localhost|127\.0\.0\.1|0\.0\.0\.0)', caseSensitive: false),
    RegExp(r'^https?://\[::1\]'),
    RegExp(r'^https?://10\.'),
    RegExp(r'^https?://172\.(1[6-9]|2\d|3[01])\.'),
    RegExp(r'^https?://192\.168\.'),
    RegExp(r'^https?://169\.254\.'),
    RegExp(r'^https?://metadata\.google'),
  ];

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
    await _notificationsPlugin.initialize(settings: initializationSettings);
    _notificationsInitialized = true;
  }

  /// Returns `true` if the [url] targets a private or loopback address.
  bool _isBlockedUrl(String url) {
    return _blockedPatterns.any((pattern) => pattern.hasMatch(url));
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

      if (_isBlockedUrl(url)) {
        return jsonEncode({
          'error': 'Request blocked: private/loopback addresses are not allowed',
          'status': 403,
        });
      }

      final uri = Uri.parse(url);
      http.Response response;

      switch (method) {
        case 'POST':
          response = await _client.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers, body: body);
          break;
        case 'GET':
        default:
          response = await _client.get(uri, headers: headers);
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
      const storage = FlutterSecureStorage();

      switch (action) {
        case 'set':
          if (value == null) return jsonEncode({'error': 'Value is null'});
          await storage.write(key: namespacedKey, value: value);
          return jsonEncode({'success': true});
        case 'delete':
          await storage.delete(key: namespacedKey);
          return jsonEncode({'success': true});
        case 'get':
        default:
          final readValue = await storage.read(key: namespacedKey);
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
          'script_channel_id', 'Script Automator',
          channelDescription: 'Notifications generated by JS scripts',
          importance: Importance.max,
          priority: Priority.high);
      const iosDetails = DarwinNotificationDetails();
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

  /// Releases HTTP client resources. Call when the handler is no longer needed.
  void dispose() {
    _client.close();
  }
}
