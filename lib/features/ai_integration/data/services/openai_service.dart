import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:script_automator/core/config/build_secrets.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';

/// Service responsible for communicating with OpenAI's API.
/// Uses the [dart_openai] package for native Dart bindings.
///
/// Key resolution order:
///   1. Secure storage (user's custom key from Settings)
///   2. `.env` asset via flutter_dotenv (built-in app key)
///   3. `--dart-define=OPENAI_API_KEY=…` (CI/CD override)
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

  /// Initializes the service by attempting to load the API key from secure storage.
  /// If successful, configures the global OpenAI instance.
  /// @return `Future<void>`
  Future<void> initialize() async {
    try {
      // Priority 1: User's custom key from secure storage (Settings page)
      final stored = await AppSecureStorage.readMigratingLegacy(
        _secureStorage,
        _storageKey,
      );
      if (stored != null && stored.isNotEmpty) {
        OpenAI.apiKey = stored;
        _isConfigured = true;
        _isUsingCustomKey = true;
        debugPrint("[OpenAIService] Initialized from user's custom key.");
        return;
      }

      // Priority 2: Built-in key from .env asset (bundled with app)
      final fromEnv = dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
      if (fromEnv.isNotEmpty) {
        OpenAI.apiKey = fromEnv;
        _isConfigured = true;
        _isUsingCustomKey = false;
        debugPrint("[OpenAIService] Initialized from built-in .env key.");
        return;
      }

      // Priority 3: CI/CD dart-define fallback
      final fromBuild = BuildSecrets.openAiApiKey.trim();
      if (fromBuild.isNotEmpty) {
        OpenAI.apiKey = fromBuild;
        _isConfigured = true;
        _isUsingCustomKey = false;
        debugPrint("[OpenAIService] Initialized from dart-define.");
        return;
      }

      _isConfigured = false;
      debugPrint("[OpenAIService] No API key found in any source.");
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
    if (!_isConfigured) {
      debugPrint("[OpenAIService] Cannot complete code: API Key missing.");
      return null;
    }

    try {
      // Extremely restrictive system prompt to force pure code responses without markdown
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
           "You are an expert JavaScript coding assistant inside a mobile App editor. "
           "Your task is to COMPLETE the code given by the user context. "
           "Output ONLY the raw code required to complete the snippet. "
           "DO NOT wrap your response in markdown code blocks (e.g. ```javascript). "
           "DO NOT provide explanations. Just output the exact characters to append."
          )
        ],
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Context up to cursor:\n\n$codeContext"
          )
        ],
      );

      final completion = await OpenAI.instance.chat.create(
        model: _currentModel,
        messages: [systemMessage, userMessage],
        temperature: 0.1, // Near 0 for deterministic code completion
        maxTokens: 128,   // Keep ghost text concise
      );

      final text = completion.choices.first.message.content?.first.text;
      
      if (text != null) {
        // Strip out any markdown blocks if the model disobeyed
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
}
