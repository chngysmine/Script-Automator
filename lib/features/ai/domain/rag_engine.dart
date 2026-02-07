import 'package:google_generative_ai/google_generative_ai.dart';
import '../data/datasources/vector_store.dart';
import 'abstractions/generative_ai_client.dart';

/// The sovereign brain of the Script Automator.
/// Orchestrates the Retrieval-Augmented Generation pipeline.
class RAGEngine {
  final VectorStore _vectorStore;
  final GenerativeAIClient _client;

  // Cache context to enable multi-turn conversation
  final List<Content> _chatHistory = [];

  RAGEngine({
    required VectorStore vectorStore,
    required GenerativeAIClient client,
  }) : _vectorStore = vectorStore,
       _client = client;

  /// Process a user query with context awareness.
  Stream<String> processQuery(String userQuery) async* {
    // 1. Embedding
    List<double> queryVector;
    try {
      queryVector = await _client.embedContent(userQuery);
    } catch (e) {
      // Fallback if embedding fails (e.g. offline) or mock it
      queryVector = List.filled(384, 0.0);
    }

    // 2. Retrieval
    final relevantDocs = await _vectorStore.search(queryVector);

    // Context Construction
    final contextBuffer = StringBuffer();
    if (relevantDocs.isNotEmpty) {
      contextBuffer.writeln("Context from Codebase (Knowledge Base):");
      for (final doc in relevantDocs) {
        // Doc tuple: (content, score)
        contextBuffer.writeln(
          "--- Extracted Knowledge (Confidence: ${doc.$2.toStringAsFixed(2)}) ---",
        );
        contextBuffer.writeln(doc.$1);
        contextBuffer.writeln(
          "------------------------------------------------",
        );
      }
    }

    // 3. Augmentation
    final prompt = [
      Content.text('''
System: You are ScriptAutomator AI, an expert mobile automation coding assistant.
Use the provided Context to answer the User Request. If the context is empty, rely on your general knowledge but mention that you checked the codebase.
Strictly follow Dart/Flutter best practices. 

$contextBuffer

User Request: $userQuery
'''),
    ];

    // 4. Generation
    final stream = _client.generateContentStream([..._chatHistory, ...prompt]);

    await for (final text in stream) {
      yield text;
    }

    // Update history (simplified)
    // _chatHistory.add(Content.user(userQuery));
    // _chatHistory.add(Content.model(fullResponse));
  }
}
