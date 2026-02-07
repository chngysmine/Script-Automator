import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:script_automator/features/script_management/domain/entities/script.dart';

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
    // We'll use the ID hash to pick a gradient to maintain consistency
    final gradientIndex = widget.script.name.hashCode % 3;
    final gradients = [
      [const Color(0xFFE0F2FE), const Color(0xFFE0E7FF)], // Sky
      [const Color(0xFFF3E8FF), const Color(0xFFFAE8FF)], // Purple
      [const Color(0xFFFFF7ED), const Color(0xFFFFE4E6)], // Orange
    ];
    final activeGradient = gradients[gradientIndex];

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32), // Extra Rounded for Bento
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    activeGradient[0].withValues(alpha: 0.85),
                    activeGradient[1].withValues(alpha: 0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeGradient[1].withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decoration Circle
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header: Icon + Menu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGlassIcon(),
                            if (widget.onSettingsTap != null)
                              GestureDetector(
                                onTap: widget.onSettingsTap,
                                child: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: Colors.black45,
                                ),
                              ),
                          ],
                        ),

                        const Spacer(),

                        // Footer: Title + Meta
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.script.name,
                              style: TextStyle(
                                fontSize: isLarge ? 24 : 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                              maxLines: isLarge ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (isLarge || isWide)
                              Text(
                                "Edited ${DateFormat.MMMd().format(widget.script.updatedAt)} • JS",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              )
                            else
                              Text(
                                DateFormat.MMMd().format(
                                  widget.script.updatedAt,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                ),
                              ),
                          ],
                        ),

                        if (isLarge) ...[
                          const SizedBox(height: 20),
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
    );
  }

  Widget _buildGlassIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.code_rounded, color: Color(0xFF1E293B), size: 24),
    );
  }

  Widget _buildRunButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            "Run Script",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
