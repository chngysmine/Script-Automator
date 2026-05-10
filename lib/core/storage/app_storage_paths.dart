import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves shared / durable storage locations for the host app.
///
/// On iOS, Hive boxes live under the App Group container (same volume as the
/// widget extension) when the platform channel returns a valid group path.
///
/// Encrypted Hive uses a DEK from [AppSecureStorage] (shared keychain access
/// group on iOS). The widget extension still consumes **SQLite + JSON** only;
/// opening Hive from native Swift would require the same access group + Hive
/// native support (not implemented).
class AppStoragePaths {
  AppStoragePaths._();

  static const String _appGroupId = 'group.com.js.scriptAutomator';
  static const MethodChannel _channel = MethodChannel(
    'com.js.scriptAutomator/widget',
  );

  /// Subdirectory inside the App Group for Hive files (keeps them separate
  /// from `widget_registry.db` and widget JSON payloads).
  static const String _hiveSubdir = 'hive_storage';

  /// Hive box filenames used for migration detection.
  static const List<String> _hiveMarkerFiles = [
    'scripts_metadata_v2.hive',
    'scripts_content_v2.hive',
  ];

  /// Directory for [Hive.init] — App Group on iOS when available, otherwise
  /// the same default as [Hive.initFlutter] (application documents).
  static Future<Directory> hiveRootDirectory() async {
    if (Platform.isIOS) {
      try {
        final String? groupPath = await _channel.invokeMethod<String>(
          'getAppGroupPath',
          _appGroupId,
        );
        if (groupPath != null && groupPath.isNotEmpty) {
          final hiveDir = Directory(p.join(groupPath, _hiveSubdir));
          if (!await hiveDir.exists()) {
            await hiveDir.create(recursive: true);
          }
          final legacy = await getApplicationDocumentsDirectory();
          await _migrateHiveFromLegacyIfNeeded(legacy, hiveDir);
          return hiveDir;
        }
      } catch (_) {
        // Fall through to documents directory.
      }
    }
    return getApplicationDocumentsDirectory();
  }

  static Future<void> _migrateHiveFromLegacyIfNeeded(
    Directory legacy,
    Directory target,
  ) async {
    Future<bool> hasHiveData(Directory d) async {
      for (final name in _hiveMarkerFiles) {
        if (await File(p.join(d.path, name)).exists()) return true;
      }
      return false;
    }

    if (await hasHiveData(target)) return;
    if (!await hasHiveData(legacy)) return;

    await for (final entity in legacy.list(followLinks: false)) {
      if (entity is! File) continue;
      final base = p.basename(entity.path);
      if (base.endsWith('.hive') ||
          base.endsWith('.hivec') ||
          base.endsWith('.lock')) {
        final dest = File(p.join(target.path, base));
        if (!await dest.exists()) {
          await entity.copy(dest.path);
        }
      }
    }
  }
}
