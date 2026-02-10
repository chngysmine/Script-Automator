import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/ai/presentation/overlay/ai_assistant_overlay.dart';

void main() {
  testWidgets('AIAssistantOverlay renders and handles interaction', (
    WidgetTester tester,
  ) async {
    // Set screen size to iPhone 14 Pro Max (logical 430 x 932)
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;

    // Reset on tearDown
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool closed = false;
    String? sentQuery;

    await tester.pumpWidget(
      MaterialApp(
        theme: LiquidTheme.darkTheme,
        home: Scaffold(
          body: Stack(
            children: [
              const Center(child: Text("Background")),
              AIAssistantOverlay(
                onClose: () => closed = true,
                onPromptSubmit: (q) => sentQuery = q,
              ),
            ],
          ),
        ),
      ),
    );

    // Initial pump -> Start animation
    await tester.pump();
    // Advance animation to completion using pumpAndSettle just to be safe
    await tester.pumpAndSettle();

    // 1. Verify Header
    expect(find.text('AI Assistant'), findsOneWidget);

    // 2. Verify Input (While open)
    await tester.enterText(find.byType(TextField), "Hello AI");
    await tester.tap(find.text("Generate")); // Tap FilledButton
    await tester.pump();

    expect(sentQuery, "Hello AI");

    // 3. Verify Close Button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(closed, true);
  });
}
