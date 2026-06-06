import 'package:flutter/material.dart';

// ignore_for_file: prefer_interpolation_to_compose_strings
/// Token-based syntax highlighter for JavaScript/QuickJS code.
///
/// Parses source text using a single-pass regex and returns a list of
/// [TextSpan] with colors from the **One Light** color scheme — a
/// professional, high-contrast palette designed for light-mode editors.
///
/// Supported token types:
/// - **Keywords**: language reserved words + common builtins
/// - **Strings**: single and double quoted
/// - **Numbers**: integer and float literals
/// - **Comments**: single-line `//` comments
///
/// Usage:
/// ```dart
/// final highlighter = SyntaxHighlighter(baseStyle: myTextStyle);
/// final spans = highlighter.parse('const x = 42;');
/// ```
class SyntaxHighlighter {
  // ---------------------------------------------------------------
  // Token Definitions
  // ---------------------------------------------------------------

  /// JavaScript/QuickJS reserved keywords and common builtins.
  // ignore: unused_field
  static const List<String> _keywords = [
    // JS reserved words
    'break', 'case', 'catch', 'class', 'const', 'continue', 'debugger',
    'default', 'delete', 'do', 'else', 'export', 'extends', 'false',
    'finally', 'for', 'function', 'if', 'import', 'in', 'instanceof',
    'let', 'new', 'null', 'return', 'static', 'super', 'switch',
    'this', 'throw', 'true', 'try', 'typeof', 'undefined', 'var',
    'void', 'while', 'with', 'yield',
    // Async
    'async', 'await',
    // Common builtins (not strict reserved, but highlighted for readability)
    'console', 'log', 'print', 'Math', 'JSON', 'Date', 'Array',
    'Object', 'String', 'Number', 'Boolean', 'Promise', 'Map', 'Set',
    'setTimeout', 'setInterval', 'clearTimeout', 'clearInterval',
  ];

  /// Single-pass tokenizer regex with four capture groups.
  ///
  /// Group 1: Single-line comments (`// ...`)
  /// Group 2: String literals (single or double quoted)
  /// Group 3: Numeric literals (integers and decimals)
  /// Group 4: Keywords (word-boundary matched)
  static final RegExp _tokenRegex = RegExp(
    r"(\/\/.*)" // Group 1: Comments
            r"|(['](?:[^'\\]|\\.)*[']|[\x22](?:[^\x22\\]|\\.)*[\x22])" // Group 2: Strings
            r"|(\b\d+\.?\d*\b)" // Group 3: Numbers
            r"|(\b(?:" +
        _keywords.join('|') +
        r")\b)", // Group 4: Keywords
    multiLine: false,
  );

  // ---------------------------------------------------------------
  // One Light Palette (Atom One Light / GitHub Light family)
  // ---------------------------------------------------------------

  /// Base text style inherited from the editor's monospace font.
  final TextStyle baseStyle;

  /// Style for `// comment` tokens — muted gray, italic.
  final TextStyle commentStyle;

  /// Style for `'string'` and `"string"` tokens — forest green.
  final TextStyle stringStyle;

  /// Style for numeric `42` or `3.14` tokens — warm amber.
  final TextStyle numberStyle;

  /// Style for reserved keyword tokens — muted purple.
  final TextStyle keywordStyle;

  /// Creates a [SyntaxHighlighter] using the **One Dark** color palette (dark mode).
  ///
  /// [baseStyle] is the editor's base monospace [TextStyle] and determines
  /// font family, size, height, and weight. Token colors are derived from it.
  SyntaxHighlighter({required this.baseStyle})
    : commentStyle = baseStyle.copyWith(
        color: const Color(0xFF5C6370), // One Dark: Gray
      ),
      stringStyle = baseStyle.copyWith(
        color: const Color(0xFF98C379), // One Dark: Green
      ),
      numberStyle = baseStyle.copyWith(
        color: const Color(0xFFD19A66), // One Dark: Amber
      ),
      keywordStyle = baseStyle.copyWith(
        color: const Color(0xFFC678DD), // One Dark: Purple
      );

  /// Creates a [SyntaxHighlighter] using the **One Light** color palette (light mode).
  SyntaxHighlighter.light({required this.baseStyle})
    : commentStyle = baseStyle.copyWith(
        color: const Color(0xFFA0A1A7), // One Light: Gray
      ),
      stringStyle = baseStyle.copyWith(
        color: const Color(0xFF50A14F), // One Light: Green
      ),
      numberStyle = baseStyle.copyWith(
        color: const Color(0xFF986801), // One Light: Amber
      ),
      keywordStyle = baseStyle.copyWith(
        color: const Color(0xFFA626A4), // One Light: Purple
      );

  /// Creates a brightness-aware [SyntaxHighlighter].
  factory SyntaxHighlighter.adaptive({
    required TextStyle baseStyle,
    required Brightness brightness,
  }) {
    if (brightness == Brightness.dark) {
      return SyntaxHighlighter(baseStyle: baseStyle);
    }
    return SyntaxHighlighter.light(baseStyle: baseStyle);
  }

  /// Parses [text] into a list of syntax-colored [TextSpan] nodes.
  ///
  /// Non-matching characters inherit [baseStyle]. Each regex match is
  /// assigned the appropriate token style based on which capture group
  /// matched.
  ///
  /// Returns an empty list for empty input.
  List<TextSpan> parse(String text) {
    if (text.isEmpty) return [];

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in _tokenRegex.allMatches(text)) {
      // Emit plain text before this token
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      // Determine token type from capture groups
      final TextStyle style;
      if (match.group(1) != null) {
        style = commentStyle;
      } else if (match.group(2) != null) {
        style = stringStyle;
      } else if (match.group(3) != null) {
        style = numberStyle;
      } else if (match.group(4) != null) {
        style = keywordStyle;
      } else {
        style = baseStyle;
      }

      spans.add(TextSpan(text: match.group(0)!, style: style));
      currentIndex = match.end;
    }

    // Emit trailing plain text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex), style: baseStyle));
    }

    return spans;
  }
}
