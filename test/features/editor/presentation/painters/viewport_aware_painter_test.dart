import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/editor/domain/code_forge_controller.dart';
import 'package:script_automator/features/editor/presentation/painters/viewport_aware_painter.dart';

void main() {
  testWidgets('CodeForge Editor Rendering Test', (WidgetTester tester) async {
    final controller = CodeForgeController(text: "Line 1\nLine 2\nLine 3");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 100,
              child: CustomPaint(
                key: const Key('editor_painter'),
                painter: ViewportAwarePainter(
                  controller: controller,
                  scrollOffset: 0,
                  viewportHeight: 100,
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  textScaler: TextScaler.noScaling,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verification: We can't easily assert pixels in unit test environment without Golden Files.
    // But we can verify no crash occurred during painting.
    expect(find.byKey(const Key('editor_painter')), findsOneWidget);

    // Verify Controller Logic Integration
    expect(controller.getLine(0).trim(), "Line 1");
    final pos = controller.getLineAndCol(0);
    expect(pos.$1, 0); // Line 0
    expect(pos.$2, 0); // Col 0

    final pos2 = controller.getLineAndCol(
      8,
    ); // 'L' of Line 2 (Length of "Line 1\n" is 7)
    // "Line 1\n" -> indices 0-6. Index 7 is 'L'.
    expect(pos2.$1, 1);
    expect(pos2.$2, 1); // Uh oh. "Line 1\n" length is 7 chars. 0..6.
    // _lineStarts: [0, 7, 14].
    // offset 8: index 8. 8 - 7 = 1. 'i' of Line 2?
    // "Line 2" -> L(7) i(8) n(9) e(10)
    // So 8 is col 1. Correct.
  });
}
