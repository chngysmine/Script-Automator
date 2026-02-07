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
    return ClipRRect(
      borderRadius: LiquidTheme.glassDecoration.borderRadius as BorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: LiquidTheme.glassDecoration,
            child: child,
          ),
        ),
      ),
    );
  }
}
