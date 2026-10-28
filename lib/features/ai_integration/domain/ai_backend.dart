/// Common surface of every AI provider used by the editor.
abstract interface class AiBackend {
  bool get isReady;

  /// Ghost-text completion; null when unavailable.
  Future<String?> completeCode(String codeContext);

  /// Returns raw code, or a `// Error...` comment on failure.
  Future<String> generateCode(String prompt, {String? existingCode});

  /// Returns the reply, or text starting with `Error` on failure.
  Future<String> chatWithAi(
    List<Map<String, String>> messages, {
    String? existingCode,
  });
}

enum AiProvider {
  gemini('Google Gemini'),
  openai('OpenAI (your key)'),
  ollama('Ollama (local)');

  const AiProvider(this.label);
  final String label;

  static AiProvider fromName(String? name) => AiProvider.values.firstWhere(
        (p) => p.name == name,
        orElse: () => AiProvider.gemini,
      );
}
