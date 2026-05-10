import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/liquid_theme.dart';
import '../theme/liquid_colors.dart';

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const LiquidGlass({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        LiquidTheme.glassDecoration.borderRadius as BorderRadius;
    final colors = Theme.of(context).extension<LiquidColors>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          // Ambient Tinted Shadow
          BoxShadow(
            color: isDark
                ? const Color(0x33000000) // dark shadow
                : const Color(0x1A4B0082), // violet tint
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(1.0), // 1px Specular Border
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.02),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                ),
              ),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: colors?.cardBackground ?? Colors.white.withValues(alpha: 0.2),
                  borderRadius: borderRadius,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
