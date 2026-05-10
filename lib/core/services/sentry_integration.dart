import 'package:flutter/foundation.dart';

/// Integrates Sentry for crash reporting and telemetry.
/// This is a mock/stub layer for MVP purposes before linking the real Sentry SDK.
class SentryIntegration {
  static bool _isEnabled = true; // Enabled for testing MVP capturing

  static Future<void> init(String dsn) async {
    if (dsn.isEmpty) return;
    _isEnabled = true;
    debugPrint("Sentry Mock initialized with DSN: $dsn");
  }

  /// Captures an exception, typically a `dart:ffi` panic or engine error.
  static Future<void> captureException(dynamic exception, dynamic stackTrace, {dynamic hint}) async {
    if (!_isEnabled) return;
    debugPrint("\n--- SENTRY CATCH ---");
    debugPrint("Exception: $exception");
    debugPrint("StackTrace: $stackTrace");
    if (hint != null) debugPrint("Hint: $hint");
    debugPrint("--------------------\n");
  }

  static void captureMessage(String message, {String level = 'info'}) {
    if (!_isEnabled) return;
    debugPrint("[Sentry $level] $message");
  }
}
