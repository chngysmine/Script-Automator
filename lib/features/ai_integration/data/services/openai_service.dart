import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';

/// Service responsible for communicating with OpenAI's API.
///
/// Key resolution order:
///   1. Secure storage (user's custom key from Settings) -> uses `dart_openai` directly.
///   2. Fallback -> uses Firebase Cloud Functions proxy (`openAiProxy`).
class OpenAIService {
  static const String _storageKey = 'openai_api_key';
  
  final FlutterSecureStorage _secureStorage;
  bool _isConfigured = false;
  bool _isUsingCustomKey = false;
  String _currentModel = 'gpt-3.5-turbo';

  /// Constructor requiring secure storage injection.
  OpenAIService(this._secureStorage);

  /// Checks if the service is fully configured and ready to use.
  /// @return bool True if API key is loaded into OpenAI.instance
  bool get isReady => _isConfigured;

  /// Whether the user has overridden the built-in key with their own.
  bool get isUsingCustomKey => _isUsingCustomKey;
  
  /// Gets the currently active model.
  /// @return String model ID
  String get currentModel => _currentModel;

  /// Sets the GPT model to use.
  /// @param modelId The OpenAI model ID (e.g. gpt-4o, gpt-3.5-turbo)
  void setModel(String modelId) {
    _currentModel = modelId;
  }

  /// Initializes the service by attempting to load the custom API key from secure storage.
  /// If no custom key is found, it defaults to using the Cloud Functions proxy.
  /// @return `Future<void>`
  Future<void> initialize() async {
    try {
      final stored = await AppSecureStorage.readMigratingLegacy(
        _secureStorage,
        _storageKey,
      );
      if (stored != null && stored.isNotEmpty) {
        OpenAI.apiKey = stored;
        _isUsingCustomKey = true;
        debugPrint("[OpenAIService] Initialized using user's custom key.");
      } else {
        _isUsingCustomKey = false;
        debugPrint("[OpenAIService] No custom key found. Defaulting to Cloud Functions proxy.");
      }
      _isConfigured = true; // Always ready, either via custom key or proxy
    } catch (e) {
      _isConfigured = false;
      debugPrint("[OpenAIService] Error initializing: $e");
    }
  }

  /// Checks if a custom API key exists in storage.
  /// @return `Future<bool>` True if key exists
  Future<bool> hasCustomApiKey() async {
    try {
      final key = await AppSecureStorage.readMigratingLegacy(
        _secureStorage,
        _storageKey,
      );
      return key != null && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Safely saves the API key to secure storage and configures the SDK.
  /// @param apiKey The raw OpenAI API Key
  /// @return `Future<void>`
  Future<void> setApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _storageKey, value: apiKey);
      OpenAI.apiKey = apiKey;
      _isConfigured = true;
      debugPrint("[OpenAIService] Custom API Key saved and applied.");
    } catch (e) {
      debugPrint("[OpenAIService] Failed to save key: $e");
      rethrow;
    }
  }

  /// Removes the custom API Key from storage and invalidates the session.
  /// @return `Future<void>`
  Future<void> clearApiKey() async {
    try {
      await _secureStorage.delete(key: _storageKey);
      OpenAI.apiKey = "invalid_key"; // Dart_openai requires a non-null string
      _isConfigured = false;
      debugPrint("[OpenAIService] API Key cleared.");
    } catch (e) {
      debugPrint("[OpenAIService] Failed to clear key: $e");
    }
  }

  /// Completes code at the cursor position based on context (Prefix).
  /// Uses a system prompt to enforce clean, parseable Dart/JS code returns.
  /// 
  /// @param codeContext The string containing code up to the current cursor position
  /// @return `Future<String?>` The suggested code completion, or null if failed
  Future<String?> completeCode(String codeContext) async {
    if (!_isConfigured) return null;

    try {
      final systemContent = "You are an expert JavaScript coding assistant inside a mobile App editor. "
          "Your task is to COMPLETE the code given by the user context. "
          "Output ONLY the raw code required to complete the snippet. "
          "DO NOT wrap your response in markdown code blocks (e.g. ```javascript). "
          "DO NOT provide explanations. Just output the exact characters to append.";
      final userContent = "Context up to cursor:\n\n$codeContext";

      String? text;

      if (_isUsingCustomKey) {
        final systemMessage = OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemContent)],
        );
        final userMessage = OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userContent)],
        );
        final completion = await OpenAI.instance.chat.create(
          model: _currentModel,
          messages: [systemMessage, userMessage],
          temperature: 0.1,
          maxTokens: 128,
        );
        text = completion.choices.first.message.content?.first.text;
      } else {
        final callable = FirebaseFunctions.instance.httpsCallable('openAiProxy');
        final response = await callable.call({
          'model': _currentModel,
          'messages': [
            {'role': 'system', 'content': systemContent},
            {'role': 'user', 'content': userContent}
          ],
          'temperature': 0.1,
          'max_tokens': 128
        });
        text = response.data['result'] as String?;
      }
      
      if (text != null) {
        String cleanText = text;
        if (cleanText.startsWith('```')) {
           cleanText = cleanText.replaceFirst(RegExp(r'```[a-zA-Z]*\n?'), '');
           if (cleanText.endsWith('```')) {
              cleanText = cleanText.substring(0, cleanText.length - 3);
           }
        }
        return cleanText.trim();
      }
      return null;
    } catch (e) {
      debugPrint("[OpenAIService] Completion failed: $e");
      return null;
    }
  }
  /// Generates, fixes, or modifies JavaScript code based on a user prompt.
  ///
  /// Modes:
  ///   - **Generate:** When [existingCode] is null/empty, creates new code
  ///   - **Fix/Debug:** When [existingCode] has code and prompt describes a bug
  ///   - **Modify:** When [existingCode] has code and prompt describes changes
  ///
  /// @param prompt The user's instruction or idea
  /// @param existingCode Optional current editor content for context
  /// @return `Future<String?>` Generated/fixed JS code, or an error message
  Future<String?> generateCode(String prompt, {String? existingCode}) async {
    if (!_isConfigured) return '// Error: AI Service not ready.';

    try {
      final hasExistingCode = existingCode != null &&
          existingCode.trim().isNotEmpty &&
          !existingCode.trim().startsWith('// Start coding');

      final systemContent = hasExistingCode
          ? "You are a JavaScript code assistant for Script Automator, a mobile IDE. "
            "The user has existing code in their editor and needs your help. "
            "RULES:\n"
            "1. Output ONLY the COMPLETE fixed/modified JavaScript code. No markdown, no explanations.\n"
            "2. If the user describes a bug, find and fix it in their code.\n"
            "3. If the user wants a modification, apply it to their existing code.\n"
            "4. Preserve the user's code structure and style as much as possible.\n"
            "5. Add brief inline comments only where you made changes (// FIXED: ... or // ADDED: ...).\n"
            "6. If the user asks a non-code question, respond ONLY with: // This AI only helps with JavaScript code.\n"
            "7. Always return the FULL working script, not just the changed parts.\n"
            "8. Use modern ES6+ syntax.\n"
            "9. Available APIs: console.log(), setTimeout(), JSON.parse/stringify(), "
            "Math.*, Date, fetch() for HTTP, renderWidget(json) for UI."
          : "You are a JavaScript code generator for Script Automator, a mobile IDE. "
            "Your ONLY job is to generate JavaScript code based on the user's description. "
            "RULES:\n"
            "1. Output ONLY valid JavaScript code. No markdown, no explanations.\n"
            "2. If the user asks a non-code question (e.g. 'what is the weather?', 'tell me a joke'), "
            "respond ONLY with: // This AI only generates JavaScript code. Please describe what script you want to create.\n"
            "3. Add brief inline comments to explain logic.\n"
            "4. Use modern ES6+ syntax.\n"
            "5. The script runs in a sandboxed JS engine with console.log() for output "
            "and renderWidget(json) for UI rendering.\n"
            "6. Available APIs: console.log(), setTimeout(), JSON.parse/stringify(), "
            "Math.*, Date, fetch() for HTTP requests, renderWidget() for UI.";

      final userContentStr = hasExistingCode
          ? "My current code:\n```javascript\n$existingCode\n```\n\nRequest: $prompt"
          : prompt;

      String? text;

      if (_isUsingCustomKey) {
        final systemMessage = OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemContent)],
        );
        final userMessage = OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userContentStr)],
        );
        final completion = await OpenAI.instance.chat.create(
          model: _currentModel,
          messages: [systemMessage, userMessage],
          temperature: 0.3,
          maxTokens: 2048,
        );
        text = completion.choices.first.message.content?.first.text;
      } else {
        final callable = FirebaseFunctions.instance.httpsCallable('openAiProxy');
        final response = await callable.call({
          'model': _currentModel,
          'messages': [
            {'role': 'system', 'content': systemContent},
            {'role': 'user', 'content': userContentStr}
          ],
          'temperature': 0.3,
          'max_tokens': 2048
        });
        text = response.data['result'] as String?;
      }

      if (text != null) {
        String clean = text;
        if (clean.startsWith('```')) {
          clean = clean.replaceFirst(RegExp(r'```[a-zA-Z]*\n?'), '');
          if (clean.endsWith('```')) {
            clean = clean.substring(0, clean.length - 3);
          }
        }
        return clean.trim();
      }
      return '// No response from AI. Try again.';
    } catch (e) {
      debugPrint("[OpenAIService] Code generation failed: $e");
      return '// Error generating code: $e';
    }
  }
}
