import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/script_management/data/services/virtual_file_system_service.dart';

void main() {
  late Directory tempDir;
  late VirtualFileSystemService vfs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vfs_test');
    vfs = VirtualFileSystemService(tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('VFS Security Tests', () {
    test('Should allow writing and reading within root', () async {
      await vfs.writeString('test.txt', 'Hello VFS');
      final content = await vfs.readString('test.txt');
      expect(content, 'Hello VFS');
    });

    test('Should BLOCK Path Traversal (../)', () async {
      // Attempt to access a hypothetical secret file outside root
      // Strategy: ../secret.txt
      expect(
        () async => await vfs.writeString('../secret.txt', 'Hacked'),
        throwsA(isA<SecurityException>()),
      );

      expect(
        () async => await vfs.readString('../secret.txt'),
        throwsA(isA<SecurityException>()),
      );
    });

    test('Should BLOCK deep Path Traversal (../../)', () async {
      expect(
        () async => await vfs.readString('../../etc/passwd'),
        throwsA(isA<SecurityException>()),
      );
    });

    test('Should Allow valid subdirectories', () async {
      await vfs.writeString('subdir/file.txt', 'Sub content');
      final content = await vfs.readString('subdir/file.txt');
      expect(content, 'Sub content');
    });
  });
}
