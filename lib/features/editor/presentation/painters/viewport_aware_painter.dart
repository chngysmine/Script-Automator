import 'package:flutter/material.dart';
import '../../domain/code_forge_controller.dart';
import '../syntax_highlighter.dart';

/// Renders only the visible lines of the code editor onto a [Canvas].
///
/// Uses the [CodeForgeController] to read line data and cursor position,
/// then paints gutter line numbers and syntax-highlighted text for the
/// region visible within [viewportHeight] starting from [scrollOffset].
///
/// Performance: O(visible_lines) — independent of total file size.
///
/// Architecture:
/// The companion [TextField] provides native cursor, selection handles,
/// and IME input. Its text color MUST be set to [Colors.transparent] so
/// that this painter's syntax-colored output is the only visible text layer.
/// Both layers share identical [textStyle] and [StrutStyle] to guarantee
/// pixel-perfect vertical alignment.
class ViewportAwarePainter extends CustomPainter {
  /// Controller that owns the [Rope] and cursor/selection state.
  final CodeForgeController controller;

  /// Current vertical scroll position in logical pixels.
  final double scrollOffset;

  /// Height of the visible viewport in logical pixels.
  final double viewportHeight;

  /// Base monospace [TextStyle] shared with the companion [TextField].
  final TextStyle textStyle;

  /// Color for the blinking cursor indicator.
  final Color cursorColor;

  /// Color overlay for text selection highlights.
  final Color selectionColor;

  /// Width reserved for the line-number gutter column.
  final double gutterWidth;

  /// Horizontal padding between gutter border and first code character.
  final double codePaddingLeft;

  /// Optional syntax highlighter for token-based coloring.
  final SyntaxHighlighter? highlighter;

  /// Whether the editor is in dark mode.
  final bool isDark;

  /// Creates a [ViewportAwarePainter] bound to [controller].
  ///
  /// [codePaddingLeft] must match the TextField's left content padding
  /// (measured from the gutter's right edge) to keep paint and input aligned.
  ViewportAwarePainter({
    required this.controller,
    required this.scrollOffset,
    required this.viewportHeight,
    required this.textStyle,
    this.cursorColor = const Color(0xFF0284C7),
    this.selectionColor = const Color(0x402196F3),
    this.gutterWidth = 48.0,
    this.codePaddingLeft = 4.0,
    this.highlighter,
    this.isDark = true,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // ----- 1. Line Height Metric -----
    final metricPainter = TextPainter(
      text: TextSpan(text: 'M', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final lineHeight = metricPainter.height;

    // ----- 2. Visible Range -----
    final firstVisibleLine = (scrollOffset / lineHeight).floor().clamp(
      0,
      controller.lineCount,
    );
    final visibleLineCount = (viewportHeight / lineHeight).ceil() + 1;
    final lastVisibleLine = (firstVisibleLine + visibleLineCount).clamp(
      0,
      controller.lineCount,
    );

    // ----- 3. Gutter Background -----
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gutterWidth, size.height),
      Paint()
        ..color = isDark
            ? const Color(0xFF0D1117).withValues(alpha: 0.5)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
    );

    // Gutter right-edge separator
    canvas.drawLine(
      Offset(gutterWidth, 0),
      Offset(gutterWidth, size.height),
      Paint()
        ..color = isDark
            ? const Color(0xFF30363D).withValues(alpha: 0.8)
            : const Color(0xFFCBD5E1).withValues(alpha: 0.6)
        ..strokeWidth = 0.5,
    );

    // ----- 4. Per-Line Rendering -----
    final double codeX = gutterWidth + codePaddingLeft;

    for (int i = firstVisibleLine; i < lastVisibleLine; i++) {
      final double yOffset = i * lineHeight;

      // ---- 4a. Line Number ----
      final lineNumSpan = TextSpan(
        text: (i + 1).toString(),
        style: textStyle.copyWith(
          color: isDark
              ? const Color(0xFF6E7681) // GitHub Dark
              : const Color(0xFF94A3B8), // Slate 400
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
      final lineNumPainter = TextPainter(
        text: lineNumSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: gutterWidth - 12, maxWidth: gutterWidth - 12);
      lineNumPainter.paint(canvas, Offset(4, yOffset));

      // ---- 4b. Line Content ----
      final rawLine = controller.getLine(i);
      final contentToDraw = rawLine.endsWith('\n')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;

      // ---- 4c. Syntax Highlighting ----
      InlineSpan textSpan;
      if (highlighter != null) {
        textSpan = TextSpan(
          style: textStyle,
          children: highlighter!.parse(contentToDraw),
        );
      } else {
        textSpan = TextSpan(text: contentToDraw, style: textStyle);
      }

      // ---- 4d. Ghost Text (AI Suggestion) ----
      if (controller.ghostText != null && controller.selection.isCollapsed) {
        final cursorOffset = controller.selection.baseOffset;
        final pos = controller.getLineAndCol(cursorOffset);
        if (pos.$1 == i && pos.$2 >= contentToDraw.length) {
          textSpan = TextSpan(
            children: [
              textSpan,
              TextSpan(
                text: controller.ghostText,
                style: textStyle.copyWith(
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        }
      }

      // ---- 4e. Paint the Syntax-Colored Line ----
      final linePainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      linePainter.paint(canvas, Offset(codeX, yOffset));
    }

    // Selection highlighting is handled natively by the companion TextField.
    // Painting it here would cause double-rendering (visible as dark overlay).
  }

  @override
  bool shouldRepaint(ViewportAwarePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.controller != controller ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.highlighter != highlighter ||
        oldDelegate.isDark != isDark;
  }
}
