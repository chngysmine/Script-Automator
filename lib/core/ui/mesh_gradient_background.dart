import 'dart:math' as math;
import 'package:flutter/material.dart';

class MeshGradientBackground extends StatefulWidget {
  final Widget? child;

  const MeshGradientBackground({super.key, this.child});

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Infinite loop for living mesh
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return RepaintBoundary(
          child: CustomPaint(
            painter: _MeshPainter(_controller.value, isDark),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _MeshPainter(this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;

    // Base background
    paint.color = isDark 
        ? const Color(0xFF0F172A) // Dark Slate 900
        : const Color(0xFFF1F5F9); // Slate 100 (lighter, cleaner)
    canvas.drawRect(rect, paint);

    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    // Orb 1: Purple
    final orb1Path = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.2 + math.sin(progress * 2 * math.pi) * 100,
            size.height * 0.2 + math.cos(progress * 2 * math.pi) * 50,
          ),
          radius: size.width * 0.5,
        ),
      );
    paint.color = isDark
        ? const Color(0xFF4C1D95).withValues(alpha: 0.6) // Dark Violet
        : const Color(0xFFE9D5FF).withValues(alpha: 0.6); // Light Purple (subtler)
    canvas.drawPath(orb1Path, paint);

    // Orb 2: Cyan
    final orb2Path = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.8 + math.cos(progress * 2 * math.pi) * 80,
            size.height * 0.6 + math.sin(progress * 2 * math.pi) * 120,
          ),
          radius: size.width * 0.6,
        ),
      );
    paint.color = isDark
        ? const Color(0xFF0E7490).withValues(alpha: 0.5) // Dark Cyan
        : const Color(0xFFCFFAFE).withValues(alpha: 0.6); // Light Cyan (subtler)
    canvas.drawPath(orb2Path, paint);

    // Orb 3: Light Pink
    final orb3Path = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.5 + math.sin(progress * 2 * math.pi + math.pi) * 150,
            size.height * 0.9 + math.cos(progress * 2 * math.pi + math.pi) * 100,
          ),
          radius: size.width * 0.55,
        ),
      );
    paint.color = isDark
        ? const Color(0xFFBE185D).withValues(alpha: 0.4) // Dark Pink
        : const Color(0xFFFBCFE8).withValues(alpha: 0.6); // Light Pink (subtler)
    canvas.drawPath(orb3Path, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
