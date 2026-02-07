import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('CodeForge Scroll Performance Test (10k Lines)', (tester) async {
    // Isolate: Pump the EditorPage directly to verify ITS performance/rendering
    // avoiding login/navigation/database complexities of full app.
    await tester.pumpWidget(
      const MaterialApp(debugShowCheckedModeBanner: false, home: EditorPage()),
    );
    await tester.pumpAndSettle();

    // Verify EditorPage is present
    expect(find.text('CodeForge Editor (10k Lines)'), findsOneWidget);

    final listFinder = find.byType(SingleChildScrollView);
    expect(listFinder, findsOneWidget);

    // Warm up
    await tester.drag(listFinder, const Offset(0, -500));
    await tester.pump();

    // Fling scroll down
    await tester.fling(listFinder, const Offset(0, -2000), 5000);
    // Allow animation to play out (pumpAndSettle might timeout if animation is infinite,
    // but fling usually settles. EditorPage has static content size)
    await tester.pumpAndSettle();

    // Fling scroll up
    await tester.fling(listFinder, const Offset(0, 2000), 5000);
    await tester.pumpAndSettle();

    // DELAY FOR USER INSPECTION
    debugPrint('Waiting for user inspection...');
    await Future.delayed(const Duration(seconds: 30));
  });
}
