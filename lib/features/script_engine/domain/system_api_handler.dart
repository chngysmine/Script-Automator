import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  bool _isPrivateIp(String ip) {
    if (ip.startsWith('10.') ||
        ip.startsWith('192.168.') ||
        ip.startsWith('169.254.')) {
      return true;
    }
    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length >= 2) {
        final secondPart = int.tryParse(parts[1]);
        if (secondPart != null && secondPart >= 16 && secondPart <= 31) {
          return true;
        }
      }
    }
    if (ip == '::1' || ip == '0:0:0:0:0:0:0:1') return true;
    final lowerIp = ip.toLowerCase();
    if (lowerIp.startsWith('fc00:') ||
        lowerIp.startsWith('fd00:') ||
        lowerIp.startsWith('fe80:')) {
      return true;
    }
    return false;
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

      final uri = Uri.parse(url);
      final String scheme = uri.scheme.toLowerCase();

      if (scheme != 'http' && scheme != 'https') {
        return jsonEncode({
          'error': 'Request blocked: unsupported scheme. Only http and https are allowed',
          'status': 400,
        });
      }

      if (_isBlockedUrl(url)) {
        return jsonEncode({
          'error': 'Request blocked: private/loopback addresses are not allowed',
          'status': 403,
        });
      }

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
          if (resolvedHosts.isEmpty) {
            return jsonEncode({
              'error': 'Request blocked: unable to resolve host securely',
              'status': 403,
            });
          }
          final address = resolvedHosts.first;
          resolvedIp = address.address;

          if (address.isLoopback || address.isLinkLocal || _isPrivateIp(resolvedIp)) {
            return jsonEncode({
              'error': 'Request blocked: resolved address is private or loopback',
              'status': 403,
            });
          }
        } catch (_) {
          return jsonEncode({
            'error': 'Request blocked: unable to resolve host securely or DNS lookup timed out',
            'status': 403,
          });
        }
      } else {
        if (_isPrivateIp(resolvedIp) || resolvedIp == '127.0.0.1' || resolvedIp == '::1') {
          return jsonEncode({
            'error': 'Request blocked: target IP is private or loopback',
            'status': 403,
          });
        }
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
