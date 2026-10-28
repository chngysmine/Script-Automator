import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/core/services/app_config_service.dart';
import 'package:script_automator/features/ai_integration/data/clients/firebase_ai_text_client.dart';
import 'package:script_automator/features/ai_integration/data/services/gemini_service.dart';
import 'package:script_automator/features/ai_integration/domain/ai_prompts.dart';
import 'package:script_automator/features/ai_integration/domain/ai_text_client.dart';

class _Call {
  _Call(this.model, this.system, this.turns, this.lowLatency);
  final String model;
  final String system;
  final List<AiTurn> turns;
  final bool lowLatency;
}

class FakeAiClient implements AiTextClient {
  FakeAiClient({this.reply, this.error});

  final String? reply;
  final Object? error;
  final calls = <_Call>[];

  @override
  Future<String?> generate({
    required String model,
    required String systemInstruction,
    required List<AiTurn> turns,
    double temperature = 0.4,
    int maxOutputTokens = 2048,
    bool lowLatency = false,
  }) async {
    calls.add(_Call(model, systemInstruction, turns, lowLatency));
    if (error != null) throw error!;
    return reply;
  }
}

void main() {
  GeminiService build(FakeAiClient client, {AppConfigService? config, bool ready = true}) =>
      GeminiService(config: config, client: client, isFirebaseReady: () => ready);

  group('GeminiService', () {
    test('uses remote chat model and strips markdown fences when generating', () async {
      final config = AppConfigService()
        ..applyRemoteData({'ai_chat_model': 'gemini-remote'});
      final client = FakeAiClient(reply: '```javascript\nconsole.log(1);\n```');

      final code = await build(client, config: config).generateCode('log one');

      expect(code, 'console.log(1);');
      expect(client.calls.single.model, 'gemini-remote');
      expect(client.calls.single.system, AiPrompts.generateNew);
    });

    test('uses the edit prompt when the editor already has code', () async {
      final client = FakeAiClient(reply: 'let a = 2;');

      await build(client).generateCode('fix it', existingCode: 'let a = ;');

      expect(client.calls.single.system, AiPrompts.generateEdit);
      expect(client.calls.single.turns.single.text, contains('let a = ;'));
    });

    test('completion uses the fast model in low-latency mode', () async {
      final client = FakeAiClient(reply: '();');

      final completion = await build(client).completeCode('console.log');

      expect(completion, '();');
      expect(client.calls.single.model, AppConfigService.defaultCompletionModel);
      expect(client.calls.single.lowLatency, isTrue);
    });

    test('completion swallows errors so typing is never interrupted', () async {
      final client = FakeAiClient(error: const AiException('boom'));
      expect(await build(client).completeCode('x'), isNull);
    });

    test('chat maps roles, skips system messages and surfaces quota errors', () async {
      final client = FakeAiClient(
        error: const AiException('quota used', isQuota: true),
      );

      final reply = await build(client).chatWithAi([
        {'role': 'system', 'content': 'ignored'},
        {'role': 'assistant', 'content': 'Hi!'},
        {'role': 'user', 'content': 'Write a timer'},
      ]);

      expect(reply, startsWith('Error'));
      expect(reply, contains('quota used'));
      final turns = client.calls.single.turns;
      expect(turns.map((t) => t.isUser), [false, true]);
    });

    test('reports not ready when Firebase is unavailable', () async {
      final client = FakeAiClient(reply: 'x');
      final service = build(client, ready: false);

      expect(service.isReady, isFalse);
      expect(await service.chatWithAi([]), startsWith('Error'));
      expect(client.calls, isEmpty);
    });
  });

  group('FirebaseAiTextClient.toContents', () {
    test('drops leading model turns and merges consecutive roles', () {
      final contents = FirebaseAiTextClient.toContents(const [
        AiTurn(isUser: false, text: 'greeting'),
        AiTurn(isUser: true, text: 'a'),
        AiTurn(isUser: true, text: 'b'),
        AiTurn(isUser: false, text: 'reply'),
        AiTurn(isUser: true, text: '  '),
      ]);

      expect(contents.map((c) => c.role), ['user', 'model']);
      expect((contents.first.parts.single as TextPart).text, 'a\n\nb');
    });
  });

  group('AiPrompts.stripCodeFence', () {
    test('handles fenced, unterminated and plain output', () {
      expect(AiPrompts.stripCodeFence('```js\nx();\n```'), 'x();');
      expect(AiPrompts.stripCodeFence('```\nx();'), 'x();');
      expect(AiPrompts.stripCodeFence('  x();  '), 'x();');
    });
  });
}
