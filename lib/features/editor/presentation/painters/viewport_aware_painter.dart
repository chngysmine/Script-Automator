import 'package:flutter/material.dart';
import '../../domain/code_forge_controller.dart';
import '../syntax_highlighter.dart';

/// Renders only the visible lines of the code editor onto a [Canvas].
///
/// Uses the [CodeForgeController] to read line data and cursor position,
/// then paints gutter line numbers and syntax-highlighted text for the
/// region visible within [viewportHeight] starting from [scrollOffset].
///
/// Supports soft word-wrapping: long lines wrap within [maxLineWidth],
/// but the line number in the gutter stays on the first visual row and
/// only increments for each logical line (newline character).
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

  /// Maximum width for code text before wrapping.
  /// When null, text does not wrap (extends infinitely).
  final double? maxLineWidth;

  /// Optional syntax highlighter for token-based coloring.
  final SyntaxHighlighter? highlighter;

  /// Whether the editor is in dark mode.
  final bool isDark;

  /// Creates a [ViewportAwarePainter] bound to [controller].
  ViewportAwarePainter({
    required this.controller,
    required this.scrollOffset,
    required this.viewportHeight,
    required this.textStyle,
    this.cursorColor = const Color(0xFF0284C7),
    this.selectionColor = const Color(0x402196F3),
    this.gutterWidth = 48.0,
    this.codePaddingLeft = 4.0,
    this.maxLineWidth,
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
    final singleLineHeight = metricPainter.height;

    // ----- 2. Gutter Background -----
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

    // ----- 3. Per-Line Rendering with Wrapping -----
    final double codeX = gutterWidth + codePaddingLeft;
    final double wrapWidth = maxLineWidth ?? (size.width - codeX);
    double currentY = 0;

    for (int i = 0; i < controller.lineCount; i++) {
      // Skip lines entirely above viewport
      // We still need to calculate their height for correct Y positioning

      final rawLine = controller.getLine(i);
      final contentToDraw = rawLine.endsWith('\n')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;

      // Build syntax-highlighted span
      InlineSpan textSpan;
      if (highlighter != null) {
        textSpan = TextSpan(
          style: textStyle,
          children: highlighter!.parse(contentToDraw),
        );
      } else {
        textSpan = TextSpan(text: contentToDraw, style: textStyle);
      }

      // Ghost text overlay
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

      // Layout with wrapping constraint
      final linePainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: null, // allow wrapping
      )..layout(maxWidth: wrapWidth);

      final lineVisualHeight = linePainter.height;

      // Only paint if this line is within the visible viewport
      final lineBottom = currentY + lineVisualHeight;
      final isVisible = lineBottom > scrollOffset &&
          currentY < scrollOffset + viewportHeight + singleLineHeight;

      if (isVisible) {
        // Line number — only on the first visual row of the logical line
        final lineNumSpan = TextSpan(
          text: (i + 1).toString(),
          style: textStyle.copyWith(
            color: isDark
                ? const Color(0xFF6E7681)
                : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
        final lineNumPainter = TextPainter(
          text: lineNumSpan,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: gutterWidth - 12, maxWidth: gutterWidth - 12);
        lineNumPainter.paint(canvas, Offset(4, currentY));

        // Code content
        linePainter.paint(canvas, Offset(codeX, currentY));
      }

      currentY += lineVisualHeight;

      // Early exit if we're past the viewport
      if (currentY > scrollOffset + viewportHeight + singleLineHeight * 2) {
        break;
      }
    }
  }

  @override
  bool shouldRepaint(ViewportAwarePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.controller != controller ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.highlighter != highlighter ||
        oldDelegate.isDark != isDark ||
        oldDelegate.maxLineWidth != maxLineWidth;
  }
}
