import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:script_automator/features/ai/data/datasources/vector_store.dart';

void main() {
  group('VectorStore Tests', () {
    late VectorStore store;

    setUpAll(() {
      // Initialize FFI loader
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      store = VectorStore();
      await store.initialize(dbPathOverride: inMemoryDatabasePath);
    });

    tearDown(() async {
      await store.close();
    });

    test('Math: Cosine Similarity Logic', () async {
      // We can't access private _cosineSimilarity directly easily without reflection or @visibleForTesting
      // So we test via search().

      // Orthogonal vectors: dot product 0
      await store.addDocument(
        'doc1',
        'orthogonal',
        [1.0, 0.0] + List.filled(382, 0.0),
      );
      await store.addDocument(
        'doc2',
        'parallel',
        [0.0, 1.0] + List.filled(382, 0.0),
      );

      final results = await store.search([1.0, 0.0] + List.filled(382, 0.0));

      expect(results[0].$1, 'orthogonal');
      expect(results[0].$2, closeTo(1.0, 0.0001)); // Identical

      expect(results[1].$1, 'parallel');
      expect(results[1].$2, closeTo(0.0, 0.0001)); // Orthogonal
    });

    test('Persistence: Store and Retrieve', () async {
      final vec = List.generate(384, (i) => i * 0.001);
      await store.addDocument('path/to/file.dart', 'class Foo {}', vec);

      final results = await store.search(vec);
      expect(results.first.$1, 'class Foo {}');
      expect(results.first.$2, closeTo(1.0, 0.0001));
    });

    test('Update: Overwrite existing path', () async {
      final vec = List.filled(384, 0.1);
      await store.addDocument('file1', 'Old Content', vec);
      await store.addDocument('file1', 'New Content', vec); // Should overwrite

      final results = await store.search(vec);
      // Should only have 1 result for file1, not 2
      // But wait, search returns ALL matches.
      // We need to ensure logic deletes old one.

      // Verify count by hacking logic? No, trust query result count.
      // Add dummy doc to ensure >1 total exists
      await store.addDocument('file2', 'Other', vec);

      // If overwrite worked, we see "New Content" and "Other". Not "Old Content".
      final matching = results.where((r) => r.$1 == 'New Content').length;
      final old = results.where((r) => r.$1 == 'Old Content').length;

      expect(matching, 1);
      expect(old, 0);
    });
  });
}
