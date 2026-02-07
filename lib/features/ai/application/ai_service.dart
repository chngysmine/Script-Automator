import '../data/datasources/vector_store.dart';
import '../domain/rag_engine.dart';
import '../domain/abstractions/generative_ai_client.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Application Service that exposes AI capabilities to the UI.
/// Manages lifecycle and dependencies of the AI stack.
class AIService {
  final VectorStore _vectorStore;
  GenerativeAIClient? _client;
  RAGEngine? _ragEngine;

  bool _isInitialized = false;

  AIService({VectorStore? vectorStore})
    : _vectorStore = vectorStore ?? VectorStore();

  /// Initialize the AI System (Vector DB, Models).
  /// [clientFactory] can be injected for testing.
  Future<void> initialize(
    String apiKey, {
    GenerativeAIClient Function(GenerativeModel)? clientFactory,
  }) async {
    if (_isInitialized) return;

    // 1. Init Memory
    await _vectorStore.initialize();

    // 2. Init Model (Gemini Flash for speed on mobile)
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
    );

    // 3. Init Engine
    final client = clientFactory != null
        ? clientFactory(model)
        : GenerativeAIClientImpl(model);

    _client = client;

    _ragEngine = RAGEngine(vectorStore: _vectorStore, client: client);

    _isInitialized = true;
  }

  /// Send a message to the AI and get a streaming response.
  Stream<String> sendMessage(String message) {
    if (!_isInitialized || _ragEngine == null) {
      throw StateError("AIService not initialized. Call initialize() first.");
    }
    return _ragEngine!.processQuery(message);
  }

  /// Ingest a new code snippet dynamically (e.g. user just wrote code).
  Future<void> learnCode(String path, String content) async {
    if (!_isInitialized || _client == null) {
      throw StateError("AIService not initialized. Call initialize() first.");
    }

    // Generate embedding for the new code
    final vector = await _client!.embedContent(content);

    // Store in knowledge base
    await _vectorStore.addDocument(path, content, vector);
  }
}
