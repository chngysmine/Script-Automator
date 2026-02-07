import 'package:google_generative_ai/google_generative_ai.dart';

/// Abstraction for the Generative AI Provider.
/// Decouples the domain logic from the specific SDK implementation (Gemini).
abstract class GenerativeAIClient {
  Stream<String> generateContentStream(Iterable<Content> prompt);
  Future<List<double>> embedContent(String text);
}

/// Real implementation using Google Generative AI SDK
class GenerativeAIClientImpl implements GenerativeAIClient {
  final GenerativeModel _model;

  GenerativeAIClientImpl(this._model);

  @override
  Stream<String> generateContentStream(Iterable<Content> prompt) async* {
    final response = _model.generateContentStream(prompt);
    await for (final chunk in response) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }

  @override
  Future<List<double>> embedContent(String text) async {
    final content = Content.text(text);
    final response = await _model.embedContent(content);
    return response.embedding.values;
  }
}
