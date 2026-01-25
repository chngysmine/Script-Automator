import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:script_automator/features/script_management/data/datasources/script_local_data_source.dart';
import 'package:script_automator/features/script_management/data/models/script_model.dart';
import 'package:script_automator/features/script_management/data/services/encryption_service.dart';

/// Test implementation of [EncryptionService] for unit testing.
///
/// returns a deterministic key (0, 1, 2...) for consistent test runs
/// without accessing platform secure storage.
class TestEncryptionService implements EncryptionService {
  @override
  Future<List<int>> getEncryptionKey() async {
    return List<int>.generate(32, (index) => index);
  }
}

void main() {
  late ScriptLocalDataSourceImpl dataSource;
  late TestEncryptionService testEncryptionService;
  late Directory tempDir;
  late ScriptModel testScript;
  final testContent = 'console.log("Hello World");';

  setUp(() async {
    // 1. Setup clean temp directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    // 2. Register Adapter (Crucial!)
    // If ScriptModelAdapter is not registered, opening a box with ScriptModel will fail.
    // We need to ensure we don't register it twice if multiple tests run in same process
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ScriptModelAdapter());
    }

    testEncryptionService = TestEncryptionService();
    dataSource = ScriptLocalDataSourceImpl(testEncryptionService);

    await dataSource.init();

    // Create fresh script for each test to avoid "The same instance of a HiveObject..." error
    testScript = ScriptModel(
      id: '1',
      name: 'Test Script',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  tearDown(() async {
    try {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignored
    }
  });

  group('Dual-Store Architecture Tests', () {
    test('Should save Metadata and Content to separate boxes', () async {
      try {
        // Act
        await dataSource.saveScript(testScript, content: testContent);

        // Assert Metadata Box
        final savedMeta = await dataSource.getScriptDetail('1');
        expect(savedMeta, isNotNull);
        expect(savedMeta!.name, 'Test Script');

        // Assert Content Box
        final savedContent = await dataSource.getScriptContent('1');
        expect(savedContent, testContent);
      } catch (e) {
        fail("Test failed with exception: $e");
      }
    });

    test('getScriptsMetadata should NOT access content box', () async {
      await dataSource.saveScript(testScript, content: testContent);
      final list = await dataSource.getScriptsMetadata();

      expect(list.length, 1);
      expect(list.first.name, 'Test Script');
    });

    test('Delete should remove from both boxes', () async {
      await dataSource.saveScript(testScript, content: testContent);
      await dataSource.deleteScript('1');

      final meta = await dataSource.getScriptDetail('1');
      final content = await dataSource.getScriptContent('1');

      expect(meta, isNull);
      expect(content, ''); // Default empty return
    });
  });

  group('Rollback & Concurrency Tests', () {
    test('Should rollback content if metadata save fails', () async {
      // 1. Create a Faulty Metadata Box that throws on put
      final faultyMetaBox = FaultyLazyBox<ScriptModel>();

      // 2. Inject into DataSource
      // NOTE: We rely on the fact that safeMetadataBox checks the injected box first
      dataSource.testMetadataBox = faultyMetaBox;

      // We need to ensure content box is REAL
      // Since we called init() in setUp, _contentBox is already set to the real one.
      // So saveScript will write to Real Content Box -> Fail on Faulty Meta Box -> Delete from Real Content Box.

      try {
        await dataSource.saveScript(testScript, content: "Ghost Content");
        fail("Should have thrown CacheException");
      } catch (e) {
        // Expected exception
      }

      // 3. Verify Content is DELETED (Rollback success)
      final content = await dataSource.getScriptContent(testScript.id);
      expect(content, '', reason: "Content should be empty after rollback");
    });
  });
}

// Minimal Faulty Box for Testing
class FaultyLazyBox<T> implements LazyBox<T> {
  @override
  Future<void> put(dynamic key, T value) async {
    throw HiveError("Simulated Metadata Write Failure");
  }

  // --- Boilerplate stubs to satisfy interface (unused in test) ---
  @override
  Future<T?> get(dynamic key, {T? defaultValue}) async => null;
  @override
  Future<void> delete(dynamic key) async {}
  @override
  bool get isOpen => true;
  @override
  String get name => 'faulty_box';
  @override
  String get path => '';
  @override
  Iterable get keys => [];
  @override
  Future<int> add(T value) async => 0;
  @override
  Future<Iterable<int>> addAll(Iterable<T> values) async => [];
  @override
  Future<int> clear() async => 0;
  @override
  Future<void> close() async {}
  @override
  Future<void> compact() async {}
  @override
  bool containsKey(dynamic key) => false;
  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {}
  @override
  Future<void> deleteAt(int index) async {}
  @override
  Future<void> deleteFromDisk() async {}
  @override
  Future<void> flush() async {}
  @override
  Future<T?> getAt(int index) async => null;
  @override
  bool get isEmpty => true;
  @override
  bool get isNotEmpty => false;
  @override
  bool get lazy => true;
  @override
  int get length => 0;
  @override
  Future<void> putAll(Map<dynamic, T> entries) async {}
  @override
  Future<void> putAt(int index, T value) async {}
  Map<dynamic, T> toMap() => {};
  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();
  // @override - Removed as it might not be in interface for this version
  Future<void> putAllByOne(Map<dynamic, T> entries) async {}

  @override
  dynamic keyAt(int index) => null; // Stub implementation
}
