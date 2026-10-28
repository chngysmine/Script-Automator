import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:script_automator/core/config/build_secrets.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';
import '../../domain/ai_backend.dart';
import '../../domain/ai_prompts.dart';

/// Optional "advanced" provider that talks to OpenAI with the user's own key.
///
/// Key resolution order: secure storage (set in the app) → `--dart-define`
/// `OPENAI_API_KEY` (local development only). There is no server-side proxy;
/// without a key this provider is simply not ready and [AiService] falls
/// back to Gemini.
class OpenAIService implements AiBackend {
  static const String _storageKey = 'openai_api_key';
  static const String defaultModel = 'gpt-4o-mini';

  OpenAIService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  bool _hasKey = false;
  bool _isUsingCustomKey = false;
  String _currentModel = defaultModel;

  /// True when an API key is configured.
  @override
  bool get isReady => _hasKey;

  /// True when the key was entered by the user (not a dev dart-define).
  bool get isUsingCustomKey => _isUsingCustomKey;

  String get currentModel => _currentModel;

  void setModel(String modelId) {
    if (modelId.trim().isNotEmpty) _currentModel = modelId.trim();
  }

  Future<void> initialize() async {
    try {
      final stored = await AppSecureStorage.readMigratingLegacy(
        _secureStorage,
        _storageKey,
      );
      if (stored != null && stored.isNotEmpty) {
        _applyKey(stored, custom: true);
      } else if (BuildSecrets.openAiApiKey.isNotEmpty) {
        _applyKey(BuildSecrets.openAiApiKey, custom: false);
      }
    } catch (e) {
      debugPrint('[OpenAIService] Error initializing: $e');
    }
  }

  void _applyKey(String key, {required bool custom}) {
    OpenAI.apiKey = key;
    _hasKey = true;
    _isUsingCustomKey = custom;
  }

  Future<bool> hasCustomApiKey() async {
    try {
      final key = await AppSecureStorage.readMigratingLegacy(
        _secureStorage,
        _storageKey,
      );
      return key != null && key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> setApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return;
    await _secureStorage.write(key: _storageKey, value: trimmed);
    _applyKey(trimmed, custom: true);
  }

  Future<void> clearApiKey() async {
    try {
      await _secureStorage.delete(key: _storageKey);
    } catch (e) {
      debugPrint('[OpenAIService] Failed to clear key: $e');
    }
    _hasKey = false;
    _isUsingCustomKey = false;
  }

  Future<String?> _chat(
    String system,
    List<Map<String, String>> messages, {
    required double temperature,
    required int maxTokens,
  }) async {
    final sdkMessages = [
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(system)],
      ),
      for (final msg in messages)
        if (msg['role'] != 'system')
          OpenAIChatCompletionChoiceMessageModel(
            role: msg['role'] == 'assistant'
                ? OpenAIChatMessageRole.assistant
                : OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(msg['content'] ?? ''),
            ],
          ),
    ];
    final completion = await OpenAI.instance.chat.create(
      model: _currentModel,
      messages: sdkMessages,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    if (completion.choices.isEmpty) return null;
    final content = completion.choices.first.message.content;
    if (content == null || content.isEmpty) return null;
    return content.first.text;
  }

  @override
  Future<String?> completeCode(String codeContext) async {
    if (!_hasKey) return null;
    try {
      final text = await _chat(
        AiPrompts.completion,
        [{'role': 'user', 'content': AiPrompts.completionUser(codeContext)}],
        temperature: 0.1,
        maxTokens: 128,
      );
      return text == null ? null : AiPrompts.stripCodeFence(text);
    } catch (e) {
      debugPrint('[OpenAIService] Completion failed: $e');
      return null;
    }
  }

  @override
  Future<String> generateCode(String prompt, {String? existingCode}) async {
    if (!_hasKey) return '// Error: OpenAI API key is not set.';
    try {
      final text = await _chat(
        AiPrompts.hasMeaningfulCode(existingCode)
            ? AiPrompts.generateEdit
            : AiPrompts.generateNew,
        [{'role': 'user', 'content': AiPrompts.generateUser(prompt, existingCode)}],
        temperature: 0.3,
        maxTokens: 2048,
      );
      if (text == null) return '// No response from AI. Try again.';
      return AiPrompts.stripCodeFence(text);
    } catch (e) {
      debugPrint('[OpenAIService] Code generation failed: $e');
      return '// Error generating code: $e';
    }
  }

  @override
  Future<String> chatWithAi(
    List<Map<String, String>> messages, {
    String? existingCode,
  }) async {
    if (!_hasKey) return 'Error: OpenAI API key is not set.';
    try {
      final text = await _chat(
        AiPrompts.chat(existingCode),
        messages,
        temperature: 0.5,
        maxTokens: 2048,
      );
      if (text == null || text.trim().isEmpty) {
        return 'Error: OpenAI returned an empty response.';
      }
      return text.trim();
    } catch (e) {
      debugPrint('[OpenAIService] Chat failed: $e');
      return 'Error chatting with AI: $e';
    }
  }
}
