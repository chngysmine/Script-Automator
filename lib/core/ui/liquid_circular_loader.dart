import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

class LiquidCircularLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const LiquidCircularLoader({
    super.key,
    this.size = 40,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: size + 24,
        height: size + 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Background soft track ring
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: strokeWidth,
                ),
              ),
            ),
            // 2. Spinning variable-rate gradient indicator
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                valueColor: const AlwaysStoppedAnimation<Color>(LiquidTheme.primary),
                backgroundColor: Colors.transparent,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: 1200.ms, curve: Curves.easeInOutCubic),
          ],
        ),
      ),
    );
  }
}
