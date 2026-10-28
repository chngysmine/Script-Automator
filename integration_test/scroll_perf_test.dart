// Editor rendering/scroll smoke test with the real DI graph:
//   flutter test integration_test/scroll_perf_test.dart -d <device>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:script_automator/core/services/firebase_bootstrap.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/main.dart' show setupDependencies;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    await FirebaseBootstrap.initialize();
    await setupDependencies();
  });

  testWidgets('editor renders and scrolls a 2k-line script', (tester) async {
    final content = List.generate(2000, (i) => 'console.log("line $i");').join('\n');
    final now = DateTime.now();
    final script = Script(
      id: 'perf_test',
      name: 'Perf Test',
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LiquidTheme.lightTheme,
      home: EditorPage(script: script),
    ));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(EditorPage), findsOneWidget);
    final scrollable = find.byType(Scrollable).first;

    // Frame timings: run with `flutter drive` + binding.traceAction if needed.
    await tester.fling(scrollable, const Offset(0, -2000), 5000);
    await tester.pump(const Duration(seconds: 1));
    await tester.fling(scrollable, const Offset(0, 2000), 5000);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
