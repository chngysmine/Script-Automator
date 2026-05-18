import 'package:flutter/material.dart';

/// Shared monospace text style for the code editor.
///
/// Used by both the transparent [TextField] and the [ViewportAwarePainter]
/// to guarantee pixel-perfect vertical alignment between cursor and painted text.
const TextStyle kEditorTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13.5,
  color: Color(0xFFCBD5E1), // Slate 300 — balanced contrast for dark mode
  height: 1.6, // FIXED LINE HEIGHT matches TextField StrutStyle
  fontFeatures: [FontFeature.tabularFigures()],
  fontWeight: FontWeight.w500,
);

/// Common pastel colors used across the editor UI.
class CommonColors {
  CommonColors._();

  static const Color pastelBlue = Color(0xFFE0F2FE);
  static const Color pastelPurple = Color(0xFFF3E8FF);
}
