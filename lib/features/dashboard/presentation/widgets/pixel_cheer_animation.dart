import 'dart:math';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

/// A delightful micro-interaction widget that animates small pixel squares
/// to assemble an encouraging word (e.g., "CODE").
class PixelCheerAnimation extends StatefulWidget {
  const PixelCheerAnimation({super.key});

  @override
  State<PixelCheerAnimation> createState() => _PixelCheerAnimationState();
}

class _PixelCheerAnimationState extends State<PixelCheerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_PixelParticle> _particles = [];

  // 5x7 Pixel matrix for "NEVER GIVE UP" (Compact Version)
  final List<String> _matrix = [
    // NEVER(21) + SP(2) + GIVE(14) + SP(2) + UP(8) = 47 cols
    "10010111010101110111000011101010101110010101110",
    "11010100010101000100100100001010101000010101001",
    "10110100010101000100100100001010101000010101001",
    "10010111010101110111000101101010101110010101110",
    "10010100010101000101000100101010101000010101000",
    "10010100001001000100100100101001001000010101000",
    "10010111001001110100100011101001001110011101000",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _initParticles();

    // Start animation
    _controller.forward();

    // Loop animation sequence
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _controller.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        _initParticles(); // Re-scramble to new random positions
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _controller.forward();
        });
      }
    });
  }

  void _initParticles() {
    _particles.clear();
    const double pixelSize = 5.0; // Large pixels to match dropdown height
    const double spacing = 1.0;

    for (int y = 0; y < _matrix.length; y++) {
      final row = _matrix[y];
      for (int x = 0; x < row.length; x++) {
        if (row[x] == '1') {
          final targetX = x * (pixelSize + spacing);
          final targetY = y * (pixelSize + spacing);

          // Explode from a much wider and chaotic area
          final startX = targetX + (_random.nextDouble() * 200 - 100);
          final startY = targetY + (_random.nextDouble() * 100 - 50);

          // "NEVER" is primary color, "GIVE" is cyan, "UP" is vibrant pink
          Color color;
          if (x < 21) {
            color = LiquidTheme.primary;
          } else if (x < 37) {
            color = LiquidTheme.cyan;
          } else {
            color = const Color(0xFFFF2A85); // Vibrant Pink
          }

          _particles.add(_PixelParticle(
            startX: startX,
            startY: startY,
            targetX: targetX,
            targetY: targetY,
            color: color,
            delay: _random.nextDouble() * 0.5, // Staggered start
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 282, // Fits the new 47 column width (47 * 6.0 = 282)
      height: 42, // Exactly matches dropdown height (7 * 6.0 = 42)
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PixelPainter(
              particles: _particles,
              progress: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutCubic,
              ).value,
            ),
          );
        },
      ),
    );
  }
}

class _PixelParticle {
  final double startX;
  final double startY;
  final double targetX;
  final double targetY;
  final Color color;
  final double delay;

  _PixelParticle({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.color,
    required this.delay,
  });
}

class _PixelPainter extends CustomPainter {
  final List<_PixelParticle> particles;
  final double progress;

  _PixelPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const pixelSize = 5.0; // Match large size

    for (final p in particles) {
      double particleProgress = (progress - p.delay) / (1.0 - p.delay);
      particleProgress = particleProgress.clamp(0.0, 1.0);

      final easedProgress = _spring(particleProgress);

      final currentX = p.startX + (p.targetX - p.startX) * easedProgress;
      final currentY = p.startY + (p.targetY - p.startY) * easedProgress;

      final alphaProgress = particleProgress.clamp(0.0, 1.0);
      
      // Neon Glow Effect
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: alphaProgress * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        
      final paint = Paint()
        ..color = p.color.withValues(alpha: alphaProgress)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(currentX, currentY, pixelSize, pixelSize);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1.2));

      // Draw Glow
      canvas.drawRRect(rrect, glowPaint);
      // Draw Solid Pixel
      canvas.drawRRect(rrect, paint);
    }
  }

  // Custom simple spring curve
  double _spring(double t) {
    if (t == 0 || t == 1) return t;
    return 1 - pow(e, -6 * t) * cos(t * 12);
  }

  @override
  bool shouldRepaint(covariant _PixelPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
