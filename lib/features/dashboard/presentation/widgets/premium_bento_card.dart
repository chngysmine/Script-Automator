import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/ui/liquid_glass.dart';

enum BentoSize { small, wide, large }

class PremiumBentoCard extends StatefulWidget {
  final Script script;
  final BentoSize size;
  final VoidCallback onTap;

  const PremiumBentoCard({
    super.key,
    required this.script,
    this.size = BentoSize.small,
    required this.onTap,
  });

  @override
  State<PremiumBentoCard> createState() => _PremiumBentoCardState();
}

class _PremiumBentoCardState extends State<PremiumBentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    // Spring physics configuration
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack, // Gives the bouncy spring effect 
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    HapticFeedback.lightImpact();
    _animController.forward();
  }

  void _handleTapUp(_) {
    _animController.reverse();
  }

  void _handleTapCancel() {
    _animController.reverse();
  }

  /// Extract first meaningful lines of code for card preview.
  String _getCodePreview(String content) {
    if (content.isEmpty) return '// Start coding...';
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).take(8);
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = widget.size == BentoSize.large;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: (details) {
        _handleTapUp(details);
        widget.onTap();
      },
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LiquidGlass(
          height: isLarge ? 280 : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual Area: 60%
              Expanded(
                flex: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.script.name.hashCode % 2 == 0
                            ? LiquidTheme.primary.withValues(alpha: 0.5)
                            : LiquidTheme.cyan.withValues(alpha: 0.5),
                        Colors.black12,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Code snippet preview
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _getCodePreview(widget.script.content),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: isLarge ? 10 : 8.5,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                          maxLines: isLarge ? 8 : 5,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      // Fade-out gradient at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                widget.script.name.hashCode % 2 == 0
                                    ? LiquidTheme.primary.withValues(alpha: 0.4)
                                    : LiquidTheme.cyan.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Language badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "JS",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Info Area: 40%
              Expanded(
                flex: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.script.name,
                        style: TextStyle(
                          fontSize: isLarge ? 20 : 15,
                          fontWeight: FontWeight.w800,
                          color: LiquidTheme.textDeep,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: LiquidTheme.primary.withValues(alpha: 0.2),
                                  child: const Icon(Icons.person, size: 12, color: LiquidTheme.primary),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Local Script", 
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LiquidTheme.textDeep),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        DateFormat.MMMd().format(widget.script.updatedAt),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: LiquidTheme.textLight),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: LiquidTheme.textDeep,
                              borderRadius: BorderRadius.circular(20), // Pill Shape
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ]
                            ),
                            child: const Text(
                              "GET",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
