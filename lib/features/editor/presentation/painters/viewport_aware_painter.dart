import 'package:flutter/material.dart';
import '../../domain/code_forge_controller.dart';
import '../syntax_highlighter.dart';

/// A CustomPainter that renders only the visible lines of the code editor.
/// This ensures O(1) rendering performance regardless of file size.
class ViewportAwarePainter extends CustomPainter {
  final CodeForgeController controller;
  final double scrollOffset;
  final double viewportHeight;
  final TextStyle textStyle;
  final Color cursorColor;
  final Color selectionColor;
  final double gutterWidth;
  final SyntaxHighlighter? highlighter;

  ViewportAwarePainter({
    required this.controller,
    required this.scrollOffset,
    required this.viewportHeight,
    required this.textStyle,
    this.cursorColor = Colors.blue,
    this.selectionColor = const Color(0x402196F3),
    this.gutterWidth = 40.0, // Fixed gutter for MVP
    this.highlighter,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate Metrics
    final textPainter = TextPainter(
      text: TextSpan(
        text: "M",
        style: textStyle,
      ), // Use 'M' for standard width measure
      textDirection: TextDirection.ltr,
    )..layout();

    final lineHeight = textPainter.height;

    // 2. Visible Range Calculation
    final firstVisibleLine = (scrollOffset / lineHeight).floor().clamp(
      0,
      controller.lineCount,
    );
    final visibleLineCount =
        (viewportHeight / lineHeight).ceil() + 1; // +1 buffer
    final lastVisibleLine = (firstVisibleLine + visibleLineCount).clamp(
      0,
      controller.lineCount,
    );

    // 3. Paint Text & Gutter

    // Paint Gutter Background (Liquid Light Glass)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gutterWidth, size.height),
      Paint()
        ..color = const Color(0xFFF1F5F9).withValues(alpha: 0.5), // Slate 100
    );
    // Draw Border (Subtle)
    canvas.drawLine(
      Offset(gutterWidth, 0),
      Offset(gutterWidth, size.height),
      Paint()
        ..color = const Color(0xFFCBD5E1)
            .withValues(alpha: 0.5) // Slate 300
        ..strokeWidth = 1,
    );

    for (int i = firstVisibleLine; i < lastVisibleLine; i++) {
      final yOffset =
          (i * lineHeight); // Absolute position, no scrollOffset subtraction

      // Draw Line Number
      final lineNum = (i + 1).toString();
      final lineNumSpan = TextSpan(
        text: lineNum,
        style: textStyle.copyWith(
          color: const Color(0xFF94A3B8),
          fontSize: 10,
        ), // Slate 400
      );
      final lineNumPainter = TextPainter(
        text: lineNumSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: gutterWidth - 8, maxWidth: gutterWidth - 8);
      lineNumPainter.paint(canvas, Offset(0, yOffset + 2));

      final lineContent = controller.getLine(i);
      String contentToDraw = lineContent.endsWith('\n')
          ? lineContent.substring(0, lineContent.length - 1)
          : lineContent;

      // --- Syntax Highlighting ---
      InlineSpan textSpan;
      if (highlighter != null) {
        textSpan = TextSpan(
          style: textStyle,
          children: highlighter!.parse(contentToDraw),
        );
      } else {
        textSpan = TextSpan(text: contentToDraw, style: textStyle);
      }

      // --- Ghost Text (AI) ---
      // Check if cursor is on this line and at the end (Simple Mockup)
      if (controller.ghostText != null && controller.selection.isCollapsed) {
        final cursorOffset = controller.selection.baseOffset;
        final pos = controller.getLineAndCol(cursorOffset);
        if (pos.$1 == i) {
          // If cursor is at end of line (or we just force append for now)
          // ideally we verify col index >= content length
          if (pos.$2 >= contentToDraw.length) {
            textSpan = TextSpan(
              children: [
                textSpan,
                TextSpan(
                  text: controller.ghostText,
                  style: textStyle.copyWith(
                    color: Colors.grey.withValues(alpha: 0.5),
                  ), // Ghost Style
                ),
              ],
            );
          }
        }
      }

      // final linePainter = TextPainter(
      //   text: textSpan,
      //   textDirection: TextDirection.ltr,
      // )..layout();

      // OFFSET Text Painting for now to debug input.
      // linePainter.paint(canvas, Offset(gutterWidth + 8, yOffset));

      // We ONLY paint syntax highlighting if we want to obscure the real text.
      // For now, let's ENABLE standard text to ensure input works,
      // and disable this painter's text.

      // If we want Syntax Highlighting, we MUST paint text and make TextField transparent.
      // The issue is likely implicit: The TextField is there, but maybe the custom painter
      // is drawing over it or the constraints are wrong?

      // 4. Paint Text (DISABLED - Using Native TextField)
      // linePainter.paint(canvas, Offset(gutterWidth + 8, yOffset));
    }

    // 4. Paint Cursor / Selection
    if (controller.selection.isCollapsed) {
      final cursorOffset = controller.selection.baseOffset;
      final pos = controller.getLineAndCol(cursorOffset);
      final lineIndex = pos.$1;

      // Only draw if line is visible
      if (lineIndex >= firstVisibleLine && lineIndex < lastVisibleLine) {
        // Calculate X position
        // Precise way: Measure substring width
        // final lineStart = controller.getLine(lineIndex); // raw line
        // final prefix = (colIndex < lineStart.length)
        //     ? lineStart.substring(0, colIndex)
        //     : lineStart; // Clamping for safety

        // final prefixPainter = TextPainter(
        //   text: TextSpan(
        //     text: prefix,
        //     style: textStyle,
        //   ), // metrics measure needs same font
        //   textDirection: TextDirection.ltr,
        // )..layout();

        // final x = prefixPainter.width + gutterWidth + 8; // Unused
        // final y = (lineIndex * lineHeight) - scrollOffset; // Unused

        // Cursor handled by TextField
      }
    }
  }

  @override
  bool shouldRepaint(ViewportAwarePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.controller != controller ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.highlighter != highlighter;
  }
}
