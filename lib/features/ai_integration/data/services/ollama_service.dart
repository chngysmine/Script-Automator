import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:script_automator/core/security/app_secure_storage.dart';
import '../../domain/ai_backend.dart';
import '../../domain/ai_prompts.dart';

/// Optional "advanced" provider for a self-hosted Ollama server on the LAN.
class OllamaService implements AiBackend {
  OllamaService(this._secureStorage, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const String _kBaseUrlKey = 'ollama_base_url';
  static const String _kModelKey = 'ollama_model';
  static const String defaultModel = 'deepseek-coder:6.7b';

  final FlutterSecureStorage _secureStorage;
  final http.Client _http;

  String? _baseUrl;
  String _model = defaultModel;

  /// Ready once the user has configured a server URL.
  @override
  bool get isReady => _baseUrl != null && _baseUrl!.isNotEmpty;
  String get model => _model;

  Future<void> initialize() async {
    final savedUrl = await AppSecureStorage.readMigratingLegacy(
      _secureStorage,
      _kBaseUrlKey,
    );
    final savedModel = await AppSecureStorage.readMigratingLegacy(
      _secureStorage,
      _kModelKey,
    );
    if (savedUrl != null && savedUrl.isNotEmpty) _baseUrl = savedUrl;
    if (savedModel != null && savedModel.isNotEmpty) _model = savedModel;
  }

  Future<void> setConfig(String url, String model) async {
    _baseUrl = url.trim();
    _model = model.trim().isEmpty ? defaultModel : model.trim();
    await _secureStorage.write(key: _kBaseUrlKey, value: _baseUrl);
    await _secureStorage.write(key: _kModelKey, value: _model);
  }

  Future<String?> getConfiguredUrl() async =>
      await _secureStorage.read(key: _kBaseUrlKey);

  Future<String?> _chat(
    String system,
    List<Map<String, String>> messages, {
    required double temperature,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final response = await _http
        .post(
          Uri.parse('$_baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': _model,
            'stream': false,
            'messages': [
              {'role': 'system', 'content': system},
              ...messages.where((m) => m['role'] != 'system'),
            ],
            'options': {'temperature': temperature},
          }),
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      debugPrint('[Ollama] ${response.statusCode}: ${response.body}');
      return null;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['message'] as Map<String, dynamic>?)?['content'] as String?;
  }

  @override
  Future<String?> completeCode(String codeContext) async {
    if (!isReady) return null;
    try {
      final text = await _chat(
        AiPrompts.completion,
        [{'role': 'user', 'content': AiPrompts.completionUser(codeContext)}],
        temperature: 0.2,
        timeout: const Duration(seconds: 20),
      );
      return text == null ? null : AiPrompts.stripCodeFence(text);
    } catch (e) {
      debugPrint('[Ollama] Completion failed: $e');
      return null;
    }
  }

  @override
  Future<String> generateCode(String prompt, {String? existingCode}) async {
    if (!isReady) return '// Error: Ollama server is not configured.';
    try {
      final text = await _chat(
        AiPrompts.hasMeaningfulCode(existingCode)
            ? AiPrompts.generateEdit
            : AiPrompts.generateNew,
        [{'role': 'user', 'content': AiPrompts.generateUser(prompt, existingCode)}],
        temperature: 0.3,
      );
      if (text == null) return '// No response from Ollama. Is the server running?';
      return AiPrompts.stripCodeFence(text);
    } catch (e) {
      return '// Error contacting Ollama: $e';
    }
  }

  @override
  Future<String> chatWithAi(
    List<Map<String, String>> messages, {
    String? existingCode,
  }) async {
    if (!isReady) return 'Error: Ollama server is not configured.';
    try {
      final text = await _chat(
        AiPrompts.chat(existingCode),
        messages,
        temperature: 0.5,
      );
      if (text == null || text.trim().isEmpty) {
        return 'Error: No response from Ollama. Is the server running?';
      }
      return text.trim();
    } catch (e) {
      return 'Error contacting Ollama: $e';
    }
  }
}
