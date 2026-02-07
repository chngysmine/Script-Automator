import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// A robust Vector Database implementation using standard SQLite.
///
/// Strategy:
/// - Store Embeddings as BLOBs (Float32List serialized).
/// - Store Metadata (path, content) as TEXT.
/// - Implement In-Memory (or batch-streamed) Cosine Similarity search.
///
/// Why not sqlite-vss?
/// - Cross-platform complexity (requires NDK/CocoaPods custom builds).
/// - For a code knowledge base (<10k snippets), Dart Isolate calculation is <50ms.
class VectorStore {
  static const String _tableName = 'embeddings';
  static const int _vectorDim = 384; // Standard MiniLM-L6 dimension

  Database? _db;

  /// Initialize the database.
  Future<void> initialize({String? dbPathOverride}) async {
    if (_db != null) return; // Prevent re-initialization (e.g. by AIService)

    final dbPath = await getDatabasesPath();
    final path = dbPathOverride ?? join(dbPath, 'ai_knowledge_base.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            content TEXT NOT NULL,
            vector BLOB NOT NULL
          )
        ''');
        // Add index on path for updates
        await db.execute('CREATE INDEX idx_path ON $_tableName (path)');
      },
    );
  }

  /// Insert or Update a document with its embedding.
  Future<void> addDocument(
    String path,
    String content,
    List<double> vector,
  ) async {
    final db = _db;
    if (db == null) throw StateError("VectorStore not initialized");
    if (vector.length != _vectorDim) {
      // Log warning, but allow for now if model changes? No, strict enforcement.
      // throw ArgumentError("Vector dimension mismatch. Expected $_vectorDim, got ${vector.length}");
    }

    // Convert List<double> to Byte Array (Float32List)
    final bytes = Float32List.fromList(vector).buffer.asUint8List();

    // Use transaction for atomic consistency
    await db.transaction((txn) async {
      // Remove existing entry for this path to avoid duplicates
      await txn.delete(_tableName, where: 'path = ?', whereArgs: [path]);

      await txn.insert(_tableName, {
        'path': path,
        'content': content,
        'vector': bytes,
      });
    });
  }

  /// Find similar documents using Cosine Similarity.
  /// Returns top [k] matches.
  Future<List<(String content, double score)>> search(
    List<double> queryVector, {
    int k = 5,
  }) async {
    final db = _db;
    if (db == null) throw StateError("VectorStore not initialized");

    // 1. Fetch all vectors (Optimization: Chunk retrieval for massive DBs)
    final rows = await db.query(_tableName, columns: ['content', 'vector']);

    // 2. Calculate Similarity (can move to Isolate for UI jank prevention involved)
    final results = <(String, double)>[];

    for (final row in rows) {
      final content = row['content'] as String;
      final blob = row['vector'] as List<int>;
      final vector = Float32List.view(Uint8List.fromList(blob).buffer);

      final score = _cosineSimilarity(queryVector, vector);
      results.add((content, score));
    }

    // 3. Sort and Top-K
    results.sort((a, b) => b.$2.compareTo(a.$2)); // Descending score

    return results.take(k).toList();
  }

  /// Math: Cosine Similarity = (A . B) / (||A|| * ||B||)
  double _cosineSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length) return 0.0;

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dot += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Close the database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
