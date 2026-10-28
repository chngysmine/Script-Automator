import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:script_automator/features/script_management/data/models/script_model.dart';
import 'package:script_automator/features/widget_renderer/data/services/widget_registry_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late WidgetRegistryService service;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('widget_registry_test');
    service = WidgetRegistryService(
      databaseFactory: databaseFactoryFfi,
      directoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await service.close();
    await tempDir.delete(recursive: true);
  });

  test('opens in WAL mode with the schema the widget extension reads', () async {
    final now = DateTime.now();
    await service.syncScript(
      ScriptModel(id: 'script_1', name: 'Weather', createdAt: now, updatedAt: now),
    );

    expect(await service.getActiveWidgetIds(), ['script_1']);

    final db = await databaseFactoryFfi.openDatabase(
      p.join(tempDir.path, 'widget_registry.db'),
    );
    try {
      final mode = await db.rawQuery('PRAGMA journal_mode');
      expect(mode.first.values.first.toString().toLowerCase(), 'wal');

      // Same query as ios/ScriptAutomatorWidget/ScriptDatabase.swift.
      final rows = await db.rawQuery(
        'SELECT id, name, updated_at FROM scripts ORDER BY updated_at DESC;',
      );
      expect(rows.single['id'], 'script_1');
      expect(rows.single['name'], 'Weather');
    } finally {
      await db.close();
    }
  });
}
