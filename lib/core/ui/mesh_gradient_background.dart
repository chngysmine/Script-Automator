import 'dart:math' as math;
import 'package:flutter/material.dart';

class MeshGradientBackground extends StatefulWidget {
  final Widget? child;

  const MeshGradientBackground({super.key, this.child});

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Infinite loop for living mesh
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop GPU-intensive animation when app is not visible to save battery.
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;
        final progress = _controller.value;

        // Base background color
        final bgColor = isDark 
            ? const Color(0xFF0F172A) // Dark Slate 900
            : const Color(0xFFF1F5F9); // Slate 100

        // Orb 1: Purple
        final orb1Color = isDark
            ? const Color(0xFF4C1D95).withValues(alpha: 0.35)
            : const Color(0xFFE9D5FF).withValues(alpha: 0.45);
        final orb1Radius = width * 0.6;
        final orb1CenterX = width * 0.2 + math.sin(progress * 2 * math.pi) * 80;
        final orb1CenterY = height * 0.2 + math.cos(progress * 2 * math.pi) * 40;

        // Orb 2: Cyan
        final orb2Color = isDark
            ? const Color(0xFF0E7490).withValues(alpha: 0.3)
            : const Color(0xFFCFFAFE).withValues(alpha: 0.45);
        final orb2Radius = width * 0.7;
        final orb2CenterX = width * 0.8 + math.cos(progress * 2 * math.pi) * 60;
        final orb2CenterY = height * 0.6 + math.sin(progress * 2 * math.pi) * 90;

        // Orb 3: Pink
        final orb3Color = isDark
            ? const Color(0xFFBE185D).withValues(alpha: 0.25)
            : const Color(0xFFFBCFE8).withValues(alpha: 0.45);
        final orb3Radius = width * 0.65;
        final orb3CenterX = width * 0.5 + math.sin(progress * 2 * math.pi + math.pi) * 110;
        final orb3CenterY = height * 0.9 + math.cos(progress * 2 * math.pi + math.pi) * 80;

        return Container(
          color: bgColor,
          child: Stack(
            children: [
              // Purple Orb
              Positioned(
                left: orb1CenterX - orb1Radius,
                top: orb1CenterY - orb1Radius,
                width: orb1Radius * 2,
                height: orb1Radius * 2,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [orb1Color, orb1Color.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              // Cyan Orb
              Positioned(
                left: orb2CenterX - orb2Radius,
                top: orb2CenterY - orb2Radius,
                width: orb2Radius * 2,
                height: orb2Radius * 2,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [orb2Color, orb2Color.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              // Pink Orb
              Positioned(
                left: orb3CenterX - orb3Radius,
                top: orb3CenterY - orb3Radius,
                width: orb3Radius * 2,
                height: orb3Radius * 2,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [orb3Color, orb3Color.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}
