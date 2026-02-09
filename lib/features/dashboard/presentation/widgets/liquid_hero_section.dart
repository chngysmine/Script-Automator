import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class LiquidHeroSection extends StatefulWidget {
  const LiquidHeroSection({super.key});

  @override
  State<LiquidHeroSection> createState() => _LiquidHeroSectionState();
}

class _LiquidHeroSectionState extends State<LiquidHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Floating Particles (Background)
          ...List.generate(5, (index) => _buildFloatingParticle(index)),

          // 2. 3D Holographic Card
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateX(0.1 * (1 - value)) // Tilt up
                  ..rotateY(-0.1 * (1 - value)) // Tilt left
                  ..multiply(Matrix4.diagonal3Values(value, value, value)),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: _buildGlassCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 340,
          height: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyan.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "CodeForge Pro",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text(
                      "v2.0",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Code Snippet with Gutter
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Gutter
                    Column(
                      children: [
                        Text(
                          "1",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          "2",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          "3",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Code
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                            ),
                            children: [
                              const TextSpan(
                                text: "void ",
                                style: TextStyle(color: Colors.purpleAccent),
                              ),
                              const TextSpan(
                                text: "main",
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                              const TextSpan(
                                text: "() {\n",
                                style: TextStyle(color: Colors.white),
                              ),
                              const TextSpan(
                                text: "  print",
                                style: TextStyle(color: Colors.cyanAccent),
                              ),
                              const TextSpan(
                                text: "('Hello World');\n",
                                style: TextStyle(color: Colors.greenAccent),
                              ),
                              const TextSpan(
                                text: "}",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Text(
                  "Automate your workflow with AI.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = (_controller.value + (index * 0.2)) % 1.0;
        final double theta = t * 2 * math.pi;
        final double radius = 100.0 + (index * 20);

        return Transform.translate(
          offset: Offset(
            radius * math.cos(theta),
            radius * math.sin(theta) * 0.5, // Elliptical orbit
          ),
          child: Opacity(
            opacity: 0.5 * (1 - t), // Fade out
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
