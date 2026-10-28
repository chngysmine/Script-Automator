import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fade + slide-up entrance for list/grid items, staggered by [position].
///
/// The delay is capped so long lists don't make late items wait for seconds.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.position,
    required this.child,
    this.duration = const Duration(milliseconds: 375),
    this.verticalOffset = 30,
    this.columnCount = 1,
  });

  final int position;
  final Widget child;
  final Duration duration;
  final double verticalOffset;

  /// For grids, items in the same row share a similar delay.
  final int columnCount;

  static const Duration _step = Duration(milliseconds: 50);
  static const int _maxSteps = 8;

  @override
  Widget build(BuildContext context) {
    final row = position ~/ columnCount;
    final col = position % columnCount;
    final steps = (row + col).clamp(0, _maxSteps);
    return child
        .animate(delay: _step * steps)
        .fadeIn(duration: duration, curve: Curves.easeOut)
        .moveY(
          begin: verticalOffset,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
