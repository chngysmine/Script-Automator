import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/dashboard/presentation/pages/dashboard_page.dart';

class LiquidSplashPage extends StatefulWidget {
  const LiquidSplashPage({super.key});

  @override
  State<LiquidSplashPage> createState() => _LiquidSplashPageState();
}

class _LiquidSplashPageState extends State<LiquidSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) async {
      // Reduced delay to match faster animation (approx 1.5s total)
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LiquidDashboardPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LiquidTheme.auroraGradient,
            ),
          ),

          // Orbs
          Positioned(
            top: -100,
            right: -50,
            child: _buildOrb(300, LiquidTheme.secondary.withValues(alpha: 0.3)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildOrb(250, LiquidTheme.cyan.withValues(alpha: 0.3)),
          ),

          // Living Glass Text
          Center(
            child: _LivingGlassText(
              text: "Hello World",
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: 48,
                height: 1.0,
                letterSpacing: 4.0, // Space for jumping
              ),
            ),
          ),

          // Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: const Column(
                children: [
                  Text(
                    "Script Automator",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Professional IDE Experience",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }
}

class _LivingGlassText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _LivingGlassText({required this.text, required this.style});

  @override
  State<_LivingGlassText> createState() => _LivingGlassTextState();
}

class _LivingGlassTextState extends State<_LivingGlassText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.text.length, (index) {
      // Fast, energetic characters
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
    });

    _startAliveSequence();
  }

  void _startAliveSequence() async {
    for (int i = 0; i < _controllers.length; i++) {
      if (widget.text[i] == " ") continue;

      // Staggered snake-line entrance
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end, // Align bottom for landing
      children: List.generate(widget.text.length, (index) {
        if (widget.text[index] == " ") {
          return const SizedBox(width: 20);
        }

        // 1. Fly In (X): From Off-screen (Right 300px) -> Center (0)
        final Animation<double> slideAnim =
            Tween<double>(begin: 300.0, end: 0.0).animate(
              CurvedAnimation(
                parent: _controllers[index],
                curve: Curves.easeOutCubic, // Fast approach, smooth stop
              ),
            );

        // 2. Jump (Y): High Arc (-100px) -> Land (0) -> Bounce
        final Animation<double> jumpAnim =
            TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(begin: 0.0, end: -80.0),
                weight: 40,
              ), // Jump High
              TweenSequenceItem(
                tween: Tween(begin: -80.0, end: 0.0),
                weight: 30,
              ), // Fall
              TweenSequenceItem(
                tween: Tween(begin: 0.0, end: -15.0),
                weight: 15,
              ), // Bounce 1
              TweenSequenceItem(
                tween: Tween(begin: -15.0, end: 0.0),
                weight: 15,
              ), // Land 1
            ]).animate(
              CurvedAnimation(
                parent: _controllers[index],
                curve: Curves.easeOut,
              ),
            );

        // 3. Waddle (Rotation): Spin slightly while flying
        final Animation<double> rotateAnim =
            TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(begin: 0.2, end: -0.1),
                weight: 50,
              ),
              TweenSequenceItem(
                tween: Tween(begin: -0.1, end: 0.0),
                weight: 50,
              ),
            ]).animate(
              CurvedAnimation(
                parent: _controllers[index],
                curve: Curves.easeInOut,
              ),
            );

        // 4. Fade In
        final Animation<double> opacityAnim =
            Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controllers[index],
                curve: const Interval(0.0, 0.2, curve: Curves.linear),
              ),
            );

        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setTranslationRaw(slideAnim.value, jumpAnim.value, 0.0)
                ..rotateZ(rotateAnim.value),
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacityAnim.value,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LiquidTheme.brandDarkGradient.createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    widget.text[index],
                    style: widget.style.copyWith(
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.5,
                          ), // Darker shadow for contrast
                          blurRadius: 8, // Sharper shadow
                          offset: const Offset(2, 4),
                        ),
                        // Add a second soft shadow for glow
                        BoxShadow(
                          color: Colors.cyan.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
