import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';

/// A fixed-height [SliverPersistentHeaderDelegate] that stays pinned at the
/// top and shows a frosted-glass backdrop when content scrolls underneath —
/// exactly matching the [SettingsPage] AppBar behavior.
///
/// **Important:** This delegate does NOT collapse. `maxExtent == minExtent`.
///
/// Usage:
/// ```dart
/// SliverPersistentHeader(
///   pinned: true,
///   delegate: GlassSliverHeaderDelegate(
///     height: MediaQuery.of(context).padding.top + 80,
///     child: SafeArea(
///       bottom: false,
///       child: Padding(
///         padding: EdgeInsets.symmetric(horizontal: 24),
///         child: Row(children: [title, actions]),
///       ),
///     ),
///   ),
/// )
/// ```
class GlassSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  GlassSliverHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant GlassSliverHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // When content is scrolling underneath (shrinkOffset > 0), activate glass
    final bool isScrolled = shrinkOffset > 0;
    final colors = Theme.of(context).extension<LiquidColors>();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 20.0 : 0.0,
          sigmaY: isScrolled ? 20.0 : 0.0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isScrolled
                ? (colors?.glassOverlay ?? Colors.white.withValues(alpha: 0.2))
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isScrolled
                    ? (colors?.glassBorder ?? Colors.white.withValues(alpha: 0.15))
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
