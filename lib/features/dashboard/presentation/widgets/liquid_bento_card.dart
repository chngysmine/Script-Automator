import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum BentoSize { small, wide, large }

class LiquidBentoCard extends StatefulWidget {
  final Script script;
  final BentoSize size;
  final VoidCallback onTap;
  final VoidCallback? onSettingsTap;

  const LiquidBentoCard({
    super.key,
    required this.script,
    this.size = BentoSize.small,
    required this.onTap,
    this.onSettingsTap,
  });

  @override
  State<LiquidBentoCard> createState() => _LiquidBentoCardState();
}

class _LiquidBentoCardState extends State<LiquidBentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(_) => _animController.forward();
  void _handleTapUp(_) => _animController.reverse();
  void _handleTapCancel() => _animController.reverse();

  @override
  Widget build(BuildContext context) {
    // Dynamic Height/Width handled by Parent Layout, but we control content density
    final isLarge = widget.size == BentoSize.large;
    final isWide = widget.size == BentoSize.wide;

    // Gradient based on Script Type or Index (Randomized for variety visually)
    final gradientIndex = widget.script.name.hashCode % 3;
    final gradients = [
      [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)], // Sky Light
      [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)], // Purple Light
      [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)], // Orange Light
    ];
    final activeGradient = gradients[gradientIndex];

    return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              HapticFeedback.lightImpact();
              _handleTapDown(details);
            },
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  32,
                ), // Extra Rounded for Bento
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          activeGradient[0].withValues(alpha: 0.9),
                          activeGradient[1].withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeGradient[1].withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        if (_isHovered)
                          BoxShadow(
                            color: activeGradient[1].withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decoration Circle (Subtle brand watermark)
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Header: Icon + Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildGlassIcon(widget.script.name),
                                  _buildLanguageBadge(),
                                ],
                              ),

                              const Spacer(),

                              // Body: Title + Meta
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.script.name,
                                    style: TextStyle(
                                      fontSize: isLarge ? 26 : 20,
                                      fontWeight: FontWeight.w800,
                                      color: LiquidTheme.textDeep,
                                      height: 1.1,
                                      letterSpacing: -0.8,
                                    ),
                                    maxLines: isLarge ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: LiquidTheme.textLight,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isLarge || isWide
                                            ? "Edited ${DateFormat.MMMd().format(widget.script.updatedAt)} • JS"
                                            : DateFormat.MMMd().format(
                                                widget.script.updatedAt,
                                              ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: LiquidTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              if (isLarge) ...[
                                const SizedBox(height: 24),
                                _buildRunButton(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildGlassIcon(String name) {
    // Deterministic Icon based on hash
    final icons = [
      Icons.code_rounded,
      Icons.data_object_rounded,
      Icons.webhook_rounded,
    ];
    final icon = icons[name.hashCode % icons.length];

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.textDeep.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: LiquidTheme.textDeep, size: 24),
    );
  }

  Widget _buildLanguageBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF7DF1E), // JS Yellow
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "JS",
            style: TextStyle(
              color: LiquidTheme.textMedium,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LiquidTheme.brandDarkGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.textDeep.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            "Run Script",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
