import 'package:flutter/material.dart';

/// Physics-based animation curves for the Liquid Motion system.
/// Avoids standard Easing curves in favor of Spring-like dynamics.
class LiquidAnimations {
  /// A snappy, bouncy curve for buttons and interactions.
  static const Curve snappy = Curves.easeOutBack;

  /// A smooth, fluid curve for transitions and sheets.
  static const Curve fluid = Curves.easeOutCubic;

  /// A slow, deliberate curve for background movements.
  static const Curve drift = Curves.easeInOutSine;

  /// Duration for micro-interactions (clicks, toggles)
  static const Duration durationShort = Duration(milliseconds: 200);

  /// Duration for transitions (page changes, sheet open)
  static const Duration durationMedium = Duration(milliseconds: 450);

  /// Duration for heavy transitions.
  static const Duration durationLong = Duration(milliseconds: 700);
}
