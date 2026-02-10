import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AIService {
  static const _apiKeyStorageKey = 'gemini_api_key';
  GenerativeModel? _model;
  final FlutterSecureStorage _storage;

  AIService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  bool get isReady => _model != null;

  Future<void> initialize() async {
    String? apiKey = await _storage.read(key: _apiKeyStorageKey);

    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2, // Low temperature for code
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 64, // Short completion
        ),
      );
    }
  }

  Future<void> setApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyStorageKey, value: apiKey);
    await initialize();
  }

  /// Generates code completion based on current context
  Future<String?> completeCode(String fullCode, int cursorOffset) async {
    if (_model == null) return null;

    try {
      // Create a prompt that asks for completion
      // We can split code into prefix and suffix
      final prefix = fullCode.substring(0, cursorOffset);
      final suffix = fullCode.substring(cursorOffset);

      final content = [
        Content.text('''
You are a Dart/Flutter coding assistant. Complete the code at the cursor position.
Output ONLY the missing code bytes. Do not wrap in markdown. Do not repeat the prefix.
Stop at the end of the logical line or block.

Code Prefix:
$prefix

Code Suffix:
$suffix

Completion:
'''),
      ];

      final response = await _model!.generateContent(content);
      return response.text; // Clean up if needed
    } catch (e) {
      // Silent error or log
      return null;
    }
  }
}
