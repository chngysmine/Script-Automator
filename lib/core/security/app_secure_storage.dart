import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain access group aligned with `Runner.entitlements` /
/// `ScriptAutomatorWidgetExtension.entitlements` so the main app and widget
/// extension can read the same items when both declare
/// `keychain-access-groups`.
///
/// **Widget extension** does not run Dart; it still uses SQLite sidecar today.
/// Shared keychain matters for Hive DEK and any future native readers of
/// encrypted data in the App Group container.
class AppSecureStorage {
  AppSecureStorage._();

  /// Same identifier as the App Group (`group.com.js.scriptAutomator`).
  static const String iosKeychainAccessGroup =
      'group.com.js.scriptAutomator';

  /// Default [FlutterSecureStorage] for this app (shared keychain on iOS).
  static FlutterSecureStorage create() {
    if (kIsWeb) return const FlutterSecureStorage();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FlutterSecureStorage(
        iOptions: IOSOptions(
          groupId: iosKeychainAccessGroup,
        ),
      );
    }
    return const FlutterSecureStorage();
  }

  /// Legacy default keychain (no access group). Used only to migrate existing
  /// keys after enabling [iosKeychainAccessGroup].
  static const FlutterSecureStorage iosLegacy = FlutterSecureStorage();

  /// Reads [key] from [primary], or once copies from [iosLegacy] on iOS if missing.
  static Future<String?> readMigratingLegacy(
    FlutterSecureStorage primary,
    String key,
  ) async {
    var v = await primary.read(key: key);
    if (v != null && v.isNotEmpty) return v;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    final old = await iosLegacy.read(key: key);
    if (old != null && old.isNotEmpty) {
      await primary.write(key: key, value: old);
      return old;
    }
    return null;
  }
}
