import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Returns a reliable system monospace font family depending on the platform.
/// On iOS/macOS, 'Menlo' is a beautiful, built-in monospace font.
/// On Android and other platforms, we fall back to the generic 'monospace'.
String getSystemMonospaceFont() {
  if (kIsWeb) return 'monospace';
  if (Platform.isIOS || Platform.isMacOS) return 'Menlo';
  return 'monospace';
}

/// Shared monospace text style for the code editor.
///
/// Used by both the transparent [TextField] and the [ViewportAwarePainter]
/// to guarantee pixel-perfect vertical alignment between cursor and painted text.
final TextStyle kEditorTextStyle = TextStyle(
  inherit: false,
  fontFamily: getSystemMonospaceFont(),
  fontSize: 13.5,
  textBaseline: TextBaseline.alphabetic,
  color: const Color(0xFFCBD5E1), // Slate 300 — balanced contrast for dark mode
  height: 1.6, // FIXED LINE HEIGHT matches TextField StrutStyle
  fontFeatures: const [FontFeature.tabularFigures()],
  fontWeight: FontWeight.w500,
);

final StrutStyle kEditorStrutStyle = StrutStyle(
  fontFamily: getSystemMonospaceFont(),
  fontSize: 13.5,
  height: 1.6,
  leading: 0,
  forceStrutHeight: true,
);

/// Computes a snapped height factor such that when multiplied by [fontSize]
/// and [devicePixelRatio], it results in an exact integer number of physical pixels.
/// This eliminates sub-pixel rounding drift in scrollable lists/editors.
double getSnappedHeightFactor(double fontSize, double targetHeightFactor, double devicePixelRatio) {
  final double targetLogicalHeight = fontSize * targetHeightFactor;
  final double targetPhysicalHeight = targetLogicalHeight * devicePixelRatio;
  final double snappedPhysicalHeight = targetPhysicalHeight.roundToDouble();
  final double snappedLogicalHeight = snappedPhysicalHeight / devicePixelRatio;
  return snappedLogicalHeight / fontSize;
}

/// Common pastel colors used across the editor UI.
class CommonColors {
  CommonColors._();

  static const Color pastelBlue = Color(0xFFE0F2FE);
  static const Color pastelPurple = Color(0xFFF3E8FF);
}
