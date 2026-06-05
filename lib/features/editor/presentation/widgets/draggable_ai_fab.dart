import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:script_automator/core/theme/liquid_theme.dart';


class DraggableAiFab extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DraggableAiFab({
    super.key,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<DraggableAiFab> createState() => _DraggableAiFabState();
}

class _DraggableAiFabState extends State<DraggableAiFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowScaleAnimation;
  late Animation<double> _glowOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _glowScaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _glowOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Pulsing glow ring
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _glowScaleAnimation.value,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LiquidTheme.primary.withValues(
                        alpha: _glowOpacityAnimation.value * 0.45,
                      ),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Main Button Body
        Material(
          color: Colors.transparent,
          child: Tooltip(
            message: "Drag to reposition · Tap to generate · Long press for settings",
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E1E38).withValues(alpha: 0.85),
                            const Color(0xFF0F0F24).withValues(alpha: 0.85),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.9),
                            const Color(0xFFF1F5F9).withValues(alpha: 0.9),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LiquidTheme.primary.withValues(
                        alpha: isDark ? 0.35 : 0.18,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              LiquidTheme.primary,
                              LiquidTheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded, // Premium AI brain/mind logo
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
