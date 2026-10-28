// On-device smoke test against the real Firebase AI Logic backend.
//   flutter test integration_test/gemini_smoke_test.dart -d <device>
// Requires network; uses the default models from AppConfigService.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:script_automator/core/services/app_config_service.dart';
import 'package:script_automator/core/services/firebase_bootstrap.dart';
import 'package:script_automator/features/ai_integration/data/services/gemini_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late GeminiService gemini;

  setUpAll(() async {
    expect(await FirebaseBootstrap.initialize(), isTrue);
    gemini = GeminiService(config: AppConfigService());
  });

  testWidgets('chat model generates JavaScript', (tester) async {
    final code = await gemini.generateCode('Log the sum of 2 and 3 to the console.');
    // ignore: avoid_print
    print('[GeminiSmoke] chat model=${gemini.chatModel} → $code');
    expect(code, isNot(startsWith('// Error')));
    expect(code, contains('console.log'));
  });

  testWidgets('completion model returns ghost text', (tester) async {
    final completion = await gemini.completeCode('const total = [1, 2, 3].reduce(');
    // ignore: avoid_print
    print('[GeminiSmoke] completion model=${gemini.completionModel} → $completion');
    expect(completion, isNotNull);
    expect(completion!.trim(), isNotEmpty);
  });

  testWidgets('chat keeps context across turns', (tester) async {
    final reply = await gemini.chatWithAi([
      {'role': 'user', 'content': 'My variable is named rocketSpeed.'},
      {'role': 'assistant', 'content': 'Got it.'},
      {'role': 'user', 'content': 'Write one line that logs it.'},
    ]);
    // ignore: avoid_print
    print('[GeminiSmoke] chat → $reply');
    expect(reply, isNot(startsWith('Error')));
    expect(reply, contains('rocketSpeed'));
  });
}
