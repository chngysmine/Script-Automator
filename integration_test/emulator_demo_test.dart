// Verifies the offline demo fallback end-to-end from the real app code:
//   (cd functions && npm run demo)   # emulators, then: npm run demo:seed
//   flutter test integration_test/emulator_demo_test.dart -d <device> \
//     --dart-define=USE_FIREBASE_EMULATOR=true
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:script_automator/core/services/app_config_service.dart';
import 'package:script_automator/core/services/firebase_bootstrap.dart';
import 'package:script_automator/features/ai_integration/data/services/gemini_service.dart';
import 'package:script_automator/features/dashboard/data/repositories/cloud_gallery_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(FirebaseBootstrap.useEmulator, isTrue,
        reason: 'Run with --dart-define=USE_FIREBASE_EMULATOR=true');
    expect(await FirebaseBootstrap.initialize(), isTrue);
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'user@demo.local',
      password: 'demo1234',
    );
  });

  testWidgets('gallery loads seeded scripts from the emulator', (tester) async {
    final templates = await CloudGalleryRepository().getTemplates();
    expect(templates.map((t) => t['id']), contains('demo_clock'));
  });

  testWidgets('report is accepted by rules and counted once', (tester) async {
    final repo = CloudGalleryRepository();
    final first = await repo.reportScript('demo_counter', reason: 'demo');
    final second = await repo.reportScript('demo_counter');
    expect(first, anyOf(ReportResult.reported, ReportResult.alreadyReported));
    expect(second, ReportResult.alreadyReported);
    final mod = await FirebaseFirestore.instance.doc('script_moderation/demo_counter').get();
    expect(mod.data()?['reports_count'], greaterThanOrEqualTo(1));
  });

  testWidgets('Gemini still works while auth runs on the emulator', (tester) async {
    final code = await GeminiService(config: AppConfigService())
        .generateCode('Log "hello" to the console.');
    expect(code, isNot(startsWith('// Error')));
    expect(code, contains('console.log'));
  });
}
