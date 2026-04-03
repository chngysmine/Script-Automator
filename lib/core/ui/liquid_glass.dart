import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/liquid_theme.dart';

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

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [
          // Ambient Tinted Shadow
          BoxShadow(
            color: Color(0x1A4B0082), // Dark violet tint
            blurRadius: 30,
            spreadRadius: 5,
            offset: Offset(0, 15),
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
              padding: const EdgeInsets.all(0.5), // 0.5px Specular Border
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
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
