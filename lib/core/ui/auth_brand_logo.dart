import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

/// Animated brand logo for auth screens.
///
/// Renders a stylized "SA" monogram with gradient shader and
/// a breathing glow animation. Wrapped in [Hero] for smooth
/// transitions between Login ↔ SignUp ↔ ForgotPassword.
class AuthBrandLogo extends StatefulWidget {
  final double size;

  const AuthBrandLogo({super.key, this.size = 80});

  @override
  State<AuthBrandLogo> createState() => _AuthBrandLogoState();
}

class _AuthBrandLogoState extends State<AuthBrandLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'auth_brand',
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowIntensity = 0.25 + (_glowController.value * 0.2);
          final scale = 1.0 + (_glowController.value * 0.015);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: LiquidTheme.primary.withValues(alpha: glowIntensity),
                    blurRadius: 28 + (_glowController.value * 12),
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: LiquidTheme.secondary.withValues(alpha: glowIntensity * 0.5),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.size * 0.28),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
