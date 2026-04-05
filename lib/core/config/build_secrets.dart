/// Compile-time secrets injected by the Flutter tool.
///
/// Local development (no key in repo):
/// ```bash
/// flutter run --dart-define=OPENAI_API_KEY=sk-your-key
/// ```
///
/// Or pass a JSON file (Flutter 3.7+):
/// ```bash
/// flutter run --dart-define-from-file=api-keys.json
/// ```
/// with contents like: `{"OPENAI_API_KEY":"sk-..."}`.
abstract final class BuildSecrets {
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
}
