import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/ai/application/ai_service.dart';
import 'package:script_automator/features/ai/data/datasources/vector_store.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:script_automator/features/ai/domain/abstractions/generative_ai_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Mock Client
class MockGenerativeAIClient implements GenerativeAIClient {
  @override
  Stream<String> generateContentStream(Iterable<Content> prompt) async* {
    yield "Response";
  }

  @override
  Future<List<double>> embedContent(String text) async {
    // Return a determinisic vector
    return List.filled(384, 0.5);
  }
}

// Subclass AIService to inject mock client (since initialize creates real one)
// Or better: Modify AIService to allow injecting client factory?
// For now, let's use a "TestableAIService" pattern or refactor AIService slightly.
// Since AIService.initialize HARDCODES GenerativeModel, we can't easily mock it without refactoring.
// REFRACTOR REQUIRED: AIService should accept a Client Factory or allow overriding.

// Let's modify AIService test to use a partial mock or refactor AIService slightly to be more testable.
// Actually, I can just mock the VectorStore and manually set the client via reflection or just trust the logic?
// No, the user wants PROD QUALITY. Prod Code is Testable Code.
// I will refactor AIService to accept a `clientFactory` in constructor or `initialize`

void main() {
  late VectorStore vectorStore;
  late AIService aiService;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbPath = join(
      Directory.systemTemp.path,
      'ai_service_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    vectorStore = VectorStore();
    await vectorStore.initialize(dbPathOverride: dbPath);

    aiService = AIService(vectorStore: vectorStore);
  });

  tearDown(() async {
    await vectorStore.close();
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  test('AIService learns code and persists it', () async {
    // 1. Initialize with Mock Client
    await aiService.initialize(
      "fake_key",
      clientFactory: (_) => MockGenerativeAIClient(),
    );

    // 2. Teach it something new
    await aiService.learnCode('lib/new_feature.dart', 'void newFeature() {}');

    // 3. Verify it's in the Vector Store (Mock Embed returns 0.5s)
    // We search with the same vector
    final results = await vectorStore.search(List.filled(384, 0.5));

    expect(results.isNotEmpty, true);
    expect(results.first.$1, 'void newFeature() {}');
  });
}
