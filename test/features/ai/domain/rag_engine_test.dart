import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/ai/data/datasources/vector_store.dart';
import 'package:script_automator/features/ai/domain/rag_engine.dart';
import 'package:script_automator/features/ai/domain/abstractions/generative_ai_client.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// 1. Mock the Interface, NOT the final class
class MockGenerativeAIClient implements GenerativeAIClient {
  String? lastPromptReceived;

  @override
  Stream<String> generateContentStream(Iterable<Content> prompt) async* {
    // Capture the prompt text for verification
    lastPromptReceived = (prompt.first.parts.first as TextPart).text;
    yield "I found the answer in the context.";
  }

  @override
  Future<List<double>> embedContent(String text) async {
    return List.filled(384, 0.1);
  }
}

class MockVectorStore extends VectorStore {
  @override
  Future<List<(String, double)>> search(
    List<double> queryVector, {
    int k = 5,
  }) async {
    return [("SECRET_KNOWLEDGE: The password is 123456", 0.99)];
  }
}

void main() {
  test('RAGEngine connects Embedding -> Search -> Prompt', () async {
    final mockStore = MockVectorStore();
    final mockClient = MockGenerativeAIClient();

    final rag = RAGEngine(vectorStore: mockStore, client: mockClient);

    final stream = rag.processQuery("What is the password?");
    final output = await stream.join();

    expect(output, "I found the answer in the context.");

    // CRITICAL: Verify the "Secret Knowledge" from VectorStore was injected into the prompt
    expect(mockClient.lastPromptReceived, contains("SECRET_KNOWLEDGE"));
    expect(mockClient.lastPromptReceived, contains("The password is 123456"));
  });
}
