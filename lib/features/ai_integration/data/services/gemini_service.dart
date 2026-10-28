import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:script_automator/core/services/app_config_service.dart';
import '../../domain/ai_backend.dart';
import '../../domain/ai_prompts.dart';
import '../../domain/ai_text_client.dart';
import '../clients/firebase_ai_text_client.dart';

/// Default AI provider: Gemini through Firebase AI Logic.
///
/// Model names come from [AppConfigService] (`app_config/global`) so they can
/// be changed without shipping a new build.
class GeminiService implements AiBackend {
  GeminiService({
    this._config,
    AiTextClient? client,
    this._legacyStorage,
    bool Function()? isFirebaseReady,
  })  : _client = client ?? FirebaseAiTextClient(),
        _isFirebaseReady = isFirebaseReady ?? (() => Firebase.apps.isNotEmpty);

  /// Key used by the old google_generative_ai integration (user-supplied key).
  static const String legacyApiKeyStorageKey = 'gemini_api_key';

  final AppConfigService? _config;
  final AiTextClient _client;
  final FlutterSecureStorage? _legacyStorage;
  final bool Function() _isFirebaseReady;

  @override
  bool get isReady => _isFirebaseReady();

  String get chatModel =>
      _config?.aiChatModel ?? AppConfigService.defaultChatModel;
  String get completionModel =>
      _config?.aiCompletionModel ?? AppConfigService.defaultCompletionModel;

  /// Removes the API key stored by the previous Gemini integration; keys are
  /// no longer kept on device.
  Future<void> initialize() async {
    final storage = _legacyStorage;
    if (storage == null) return;
    try {
      await storage.delete(key: legacyApiKeyStorageKey);
    } catch (e) {
      debugPrint('[GeminiService] Legacy key cleanup failed: $e');
    }
  }

  /// Ghost-text completion. Returns null on any failure so typing is never
  /// interrupted.
  @override
  Future<String?> completeCode(String codeContext) async {
    if (!isReady || codeContext.trim().isEmpty) return null;
    try {
      final text = await _client.generate(
        model: completionModel,
        systemInstruction: AiPrompts.completion,
        turns: [AiTurn(isUser: true, text: AiPrompts.completionUser(codeContext))],
        temperature: 0.1,
        maxOutputTokens: 256,
        lowLatency: true,
      );
      if (text == null || text.trim().isEmpty) return null;
      return AiPrompts.stripCodeFence(text);
    } catch (e) {
      debugPrint('[GeminiService] Completion failed: $e');
      return null;
    }
  }

  /// Generates new code, or fixes/modifies [existingCode] according to [prompt].
  @override
  Future<String> generateCode(String prompt, {String? existingCode}) async {
    if (!isReady) return '// Error: AI service is not ready (offline?).';
    try {
      final text = await _client.generate(
        model: chatModel,
        systemInstruction: AiPrompts.hasMeaningfulCode(existingCode)
            ? AiPrompts.generateEdit
            : AiPrompts.generateNew,
        turns: [
          AiTurn(isUser: true, text: AiPrompts.generateUser(prompt, existingCode)),
        ],
        temperature: 0.3,
        maxOutputTokens: 8192,
      );
      if (text == null || text.trim().isEmpty) {
        return '// No response from AI. Try again.';
      }
      return AiPrompts.stripCodeFence(text);
    } on AiException catch (e) {
      return '// Error: ${e.message}';
    } catch (e) {
      debugPrint('[GeminiService] Generation failed: $e');
      return '// Error generating code: $e';
    }
  }

  /// Multi-turn chat. [messages] use `{'role': 'user'|'assistant', 'content': ...}`.
  /// Errors are returned as text starting with `Error` so the chat UI can flag them.
  @override
  Future<String> chatWithAi(
    List<Map<String, String>> messages, {
    String? existingCode,
  }) async {
    if (!isReady) return 'Error: AI service is not ready (offline?).';
    try {
      final turns = messages
          .where((m) => m['role'] != 'system')
          .map((m) => AiTurn(isUser: m['role'] != 'assistant', text: m['content'] ?? ''))
          .toList();
      final text = await _client.generate(
        model: chatModel,
        systemInstruction: AiPrompts.chat(existingCode),
        turns: turns,
        temperature: 0.5,
        maxOutputTokens: 8192,
      );
      if (text == null || text.trim().isEmpty) {
        return 'Error: Gemini returned an empty response. Try rephrasing.';
      }
      return text.trim();
    } on AiException catch (e) {
      return 'Error: ${e.message}';
    } catch (e) {
      debugPrint('[GeminiService] Chat failed: $e');
      return 'Error chatting with AI: $e';
    }
  }
}
