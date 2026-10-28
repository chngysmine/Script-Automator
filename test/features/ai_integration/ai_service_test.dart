import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/ai_integration/domain/ai_backend.dart';
import 'package:script_automator/features/ai_integration/domain/ai_service.dart';

class FakeBackend implements AiBackend {
  FakeBackend(this.name, {this.ready = true});

  final String name;
  bool ready;

  @override
  bool get isReady => ready;

  @override
  Future<String> chatWithAi(List<Map<String, String>> messages, {String? existingCode}) async =>
      name;

  @override
  Future<String?> completeCode(String codeContext) async => name;

  @override
  Future<String> generateCode(String prompt, {String? existingCode}) async => name;
}

void main() {
  late FakeBackend gemini;
  late FakeBackend openai;
  late FakeBackend ollama;
  late AiService service;

  setUp(() {
    gemini = FakeBackend('gemini');
    openai = FakeBackend('openai', ready: false);
    ollama = FakeBackend('ollama', ready: false);
    service = AiService(gemini: gemini, openai: openai, ollama: ollama);
  });

  test('defaults to Gemini', () async {
    expect(service.selectedProvider, AiProvider.gemini);
    expect(await service.chatWithAi([]), 'gemini');
  });

  test('falls back to Gemini when the selected provider is not configured', () async {
    await service.selectProvider(AiProvider.openai);

    expect(service.selectedProvider, AiProvider.openai);
    expect(service.activeProvider, AiProvider.gemini);
    expect(await service.generateCode('x'), 'gemini');
  });

  test('routes to the selected provider once it is ready', () async {
    await service.selectProvider(AiProvider.openai);
    openai.ready = true;

    expect(service.activeProvider, AiProvider.openai);
    expect(await service.completeCode('x'), 'openai');

    await service.selectProvider(AiProvider.ollama);
    ollama.ready = true;
    expect(await service.chatWithAi([]), 'ollama');
  });

  test('unknown stored provider names resolve to Gemini', () {
    expect(AiProvider.fromName('legacy'), AiProvider.gemini);
    expect(AiProvider.fromName(null), AiProvider.gemini);
    expect(AiProvider.fromName('ollama'), AiProvider.ollama);
  });
}
