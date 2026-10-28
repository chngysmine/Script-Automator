import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_backend.dart';

/// Routes AI requests to the provider the user picked, falling back to
/// Gemini whenever the selected provider isn't configured.
class AiService extends ChangeNotifier implements AiBackend {
  AiService({
    required AiBackend gemini,
    required AiBackend openai,
    required AiBackend ollama,
    this._storage,
  })  : _backends = {
          AiProvider.gemini: gemini,
          AiProvider.openai: openai,
          AiProvider.ollama: ollama,
        };

  static const String _providerKey = 'ai_provider';

  final Map<AiProvider, AiBackend> _backends;
  final FlutterSecureStorage? _storage;
  AiProvider _selected = AiProvider.gemini;

  /// Provider chosen by the user (may not be ready).
  AiProvider get selectedProvider => _selected;

  /// Provider that will actually serve the next request.
  AiProvider get activeProvider {
    if (_backends[_selected]!.isReady) return _selected;
    return AiProvider.gemini;
  }

  bool isProviderReady(AiProvider provider) => _backends[provider]!.isReady;

  AiBackend get _active => _backends[activeProvider]!;

  Future<void> initialize() async {
    try {
      final saved = await _storage?.read(key: _providerKey);
      _selected = AiProvider.fromName(saved);
    } catch (e) {
      debugPrint('[AiService] Failed to load provider preference: $e');
    }
  }

  Future<void> selectProvider(AiProvider provider) async {
    _selected = provider;
    notifyListeners();
    try {
      await _storage?.write(key: _providerKey, value: provider.name);
    } catch (e) {
      debugPrint('[AiService] Failed to persist provider preference: $e');
    }
  }

  @override
  bool get isReady => _active.isReady;

  @override
  Future<String?> completeCode(String codeContext) =>
      _active.completeCode(codeContext);

  @override
  Future<String> generateCode(String prompt, {String? existingCode}) =>
      _active.generateCode(prompt, existingCode: existingCode);

  @override
  Future<String> chatWithAi(
    List<Map<String, String>> messages, {
    String? existingCode,
  }) =>
      _active.chatWithAi(messages, existingCode: existingCode);
}
