import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';

class GeminiService {
  final FlutterSecureStorage _secureStorage;
  GenerativeModel? _model;

  static const String _kApiKeyKey = 'gemini_api_key';

  GeminiService(this._secureStorage);

  Future<void> initialize() async {
    final apiKey = await AppSecureStorage.readMigratingLegacy(
      _secureStorage,
      _kApiKeyKey,
    );
    if (apiKey != null && apiKey.isNotEmpty) {
      _initModel(apiKey);
    }
    // No fallback - user must provide their own key via setApiKey()
  }

  void _initModel(String apiKey) {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _kApiKeyKey, value: apiKey);
    _initModel(apiKey);
  }

  Future<bool> hasApiKey() async {
    return _model != null;
  }

  Future<bool> hasCustomApiKey() async {
    return (await AppSecureStorage.readMigratingLegacy(
          _secureStorage,
          _kApiKeyKey,
        )) !=
        null;
  }

  /// Generates a full script based on a natural language prompt
  Future<String> generateScript(String prompt) async {
    if (_model == null) {
      throw Exception("AI Model not initialized. Please set API Key.");
    }

    final content = [Context.scriptGenerationPrompt(prompt)];
    final response = await _model!.generateContent([
      Content.text(content.first),
    ]);

    return _cleanCodeBlock(response.text ?? "");
  }

  /// Completes code based on current context (Ghost Text)
  Future<String?> completeCode(String codeContext) async {
    if (_model == null) return null;

    final prompt =
        "Complete the following JavaScript/QuickJS code. Return ONLY the completion text, no markdown. Context:\n$codeContext";
    final response = await _model!.generateContent([Content.text(prompt)]);

    return response.text;
  }

  String _cleanCodeBlock(String text) {
    // Remove markdown code blocks if present
    final regex = RegExp(r'```(javascript|js)?\n([\s\S]*?)\n```');
    final match = regex.firstMatch(text);
    if (match != null) {
      return match.group(2) ?? text;
    }
    return text;
  }
}

class Context {
  static String scriptGenerationPrompt(String userRequest) {
    return """
You are an expert JavaScript developer for a mobile widget automation app (similar to Scriptable).
The environment supports standard ES6 and has a global object `console` for logging.
It does NOT have DOM, window, or document.

Generate a self-contained JavaScript script for the following request:
"$userRequest"

Return ONLY the code. Do not include explanations. Use comments in the code if needed.
""";
  }
}
