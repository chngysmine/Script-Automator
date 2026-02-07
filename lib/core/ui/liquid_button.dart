import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/liquid_theme.dart';
import '../theme/liquid_animations.dart';

/// A premium, physics-based button with scale animation and haptic feedback.
class LiquidButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;

  const LiquidButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isPrimary = true,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: LiquidAnimations.durationShort,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: LiquidAnimations.snappy),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null;

    final backgroundColor = widget.isPrimary
        ? LiquidTheme.primary
        : LiquidTheme.surface;

    final textColor = widget.isPrimary ? Colors.white : LiquidTheme.textPrimary;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LiquidTheme.spacingL,
            vertical: LiquidTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: isEnabled
                ? backgroundColor
                : backgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.all(LiquidTheme.radiusM),
            boxShadow: widget.isPrimary && isEnabled
                ? [
                    BoxShadow(
                      color: LiquidTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: 20),
                const SizedBox(width: LiquidTheme.spacingS),
              ],
              Text(
                widget.label,
                style: theme.textTheme.titleMedium?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
