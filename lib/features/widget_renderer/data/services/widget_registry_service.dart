import 'dart:io';
import 'package:app_group_directory/app_group_directory.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:script_automator/features/script_management/data/models/script_model.dart';

/// Service to manage the Shared SQLite Registry for Widgets.
///
/// This "Sidecar Database" allows the iOS Widget Extension to query
/// script metadata efficiently without loading the full Flutter runtime
/// or parsing large JSON files.
class WidgetRegistryService {
  static const String _dbName = 'widget_registry.db';
  static const String _tableName = 'scripts';
  static const String _appGroupId = 'group.com.antigravity.script_automator';

  Database? _db;

  /// Initializes the SQLite database in the App Group container.
  Future<void> init() async {
    if (_db != null && _db!.isOpen) return;

    try {
      final directory = await _getSharedDirectory();
      // _getSharedDirectory now handles fallback internally
      if (directory == null) {
        // Should not happen with fallback, but safe check
        return;
      }

      final dbPath = p.join(directory.path, _dbName);

      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      );
      debugPrint("WidgetRegistryDB initialized at: $dbPath");
    } catch (e) {
      debugPrint("Failed to init WidgetRegistryDB: $e");
      // Fail silently in production, but log for debug
    }
  }

  /// Syncs a script to the registry (Upsert).
  Future<void> syncScript(ScriptModel script) async {
    try {
      await init();
      await _db?.insert(_tableName, {
        'id': script.id,
        'name': script.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint("Failed to sync script to registry: $e");
    }
  }

  /// Removes a script from the registry.
  Future<void> removeScript(String id) async {
    try {
      await init();
      await _db?.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint("Failed to remove script from registry: $e");
    }
  }

  Future<Directory?> _getSharedDirectory() async {
    if (Platform.isIOS) {
      try {
        final dir = await AppGroupDirectory.getAppGroupDirectory(_appGroupId);
        if (dir != null) return dir;
      } catch (e) {
        debugPrint(
          "WidgetRegistryDB: App Group failed ($e). Using local fallback.",
        );
      }
    }
    // Fallback for Android OR failed iOS App Group
    return await getApplicationDocumentsDirectory();
  }
}
