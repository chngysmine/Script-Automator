import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class for debouncing rapid successive events.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Executes [action] after the configured delay. 
  /// If called again before the delay completes, the timer is reset.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancels any pending timer. Must be called in `dispose()`.
  void dispose() {
    _timer?.cancel();
  }
}
