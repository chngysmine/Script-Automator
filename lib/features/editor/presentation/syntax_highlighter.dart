import 'package:flutter/material.dart';

class SyntaxHighlighter {
  static const List<String> _keywords = [
    'abstract',
    'else',
    'import',
    'show',
    'as',
    'enum',
    'in',
    'static',
    'assert',
    'export',
    'interface',
    'super',
    'async',
    'extends',
    'is',
    'switch',
    'await',
    'extension',
    'library',
    'sync',
    'break',
    'external',
    'mixin',
    'this',
    'case',
    'factory',
    'new',
    'throw',
    'catch',
    'false',
    'null',
    'true',
    'class',
    'final',
    'on',
    'try',
    'const',
    'finally',
    'operator',
    'typedef',
    'continue',
    'for',
    'part',
    'var',
    'covariant',
    'function',
    'rethrow',
    'void',
    'default',
    'get',
    'return',
    'while',
    'deferred',
    'hide',
    'set',
    'with',
    'do',
    'if',
    'dynamic',
    'implements',
    'yield',
    'let',
    'console',
    'log',
    'print',
  ];

  final RegExp _tokenRegex = RegExp(
    // ignore: prefer_adjacent_string_concatenation
    r"(\/\/.*)|" + // Comments (Group 1)
        r"(['].*?[']|[\x22].*?[\x22])|" + // Strings (Group 2) - using hex for double quote to avoid escaping hell
        r"(\b\d+\b)|" + // Numbers (Group 3)
        r"(\b(?:" +
        _keywords.join('|') +
        r")\b)", // Keywords (Group 4)
    multiLine: false,
  );

  final TextStyle baseStyle;
  final TextStyle commentStyle;
  final TextStyle stringStyle;
  final TextStyle numberStyle;
  final TextStyle keywordStyle;

  SyntaxHighlighter({required this.baseStyle})
    : commentStyle = baseStyle.copyWith(
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
      stringStyle = baseStyle.copyWith(color: Colors.green),
      numberStyle = baseStyle.copyWith(color: Colors.orange),
      keywordStyle = baseStyle.copyWith(
        color: const Color(0xFFC792EA),
        fontWeight: FontWeight.bold,
      ); // Material Design Purple

  List<TextSpan> parse(String text) {
    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in _tokenRegex.allMatches(text)) {
      // Add preceding non-matching text
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      TextStyle style = baseStyle;
      final content = match.group(0)!;

      if (match.group(1) != null) {
        // Comment
        style = commentStyle;
      } else if (match.group(2) != null) {
        // String
        style = stringStyle;
      } else if (match.group(3) != null) {
        // Number
        style = numberStyle;
      } else if (match.group(4) != null) {
        // Keyword
        style = keywordStyle;
      }

      spans.add(TextSpan(text: content, style: style));
      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex), style: baseStyle));
    }

    return spans;
  }
}
