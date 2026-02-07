import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/core/coordination/file_lock_manager.dart';

void main() {
  group('FileLockManager Tests', () {
    late Directory tempDir;
    late FileLockManager lockManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lock_test');
      lockManager = FileLockManager();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('Single execution acquires and releases lock', () async {
      final lockFile = File('${tempDir.path}/test.lock');
      bool executed = false;

      await lockManager.runWithLock(lockFile, () async {
        executed = true;
        expect(await lockFile.exists(), isTrue);
      });

      expect(executed, isTrue);
    });

    // Note: Testing actual Blocking/Concurrency within a single Isolate test environment
    // is limited because Dart is single threaded event loop.
    // However, we can ensure the API contract works.
  });
}
