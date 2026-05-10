import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/liquid_glass.dart';

enum BentoSize { small, wide, large }

class PremiumBentoCard extends StatefulWidget {
  final Script script;
  final BentoSize size;
  final VoidCallback onTap;
  final bool isUpdateAvailable;

  const PremiumBentoCard({
    super.key,
    required this.script,
    this.size = BentoSize.small,
    required this.onTap,
    this.isUpdateAvailable = false,
  });

  @override
  State<PremiumBentoCard> createState() => _PremiumBentoCardState();
}

class _PremiumBentoCardState extends State<PremiumBentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String? _previewPath;

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
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final path = '${appDir.path}/sasup_ui_${widget.script.id}.png';
      if (await File(path).exists()) {
        if (mounted) setState(() => _previewPath = path);
      }
    } catch (_) {}
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
    final colors = Theme.of(context).extension<LiquidColors>()!;

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: isLarge ? 280 : 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Visual Area: Widget preview or code snippet with gradient overlay
                  Expanded(
                    flex: 3,
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
                          // Image preview or code snippet
                          if (_previewPath != null)
                            Positioned.fill(
                              child: Image.file(
                                File(_previewPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          else
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
                  // Info Area: Fixed height to prevent overflow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.script.name,
                          style: TextStyle(
                            fontSize: isLarge ? 16 : 14,
                            fontWeight: FontWeight.w800,
                            color: colors.textTitle,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundColor: LiquidTheme.primary.withValues(alpha: 0.2),
                                    child: const Icon(Icons.person, size: 10, color: LiquidTheme.primary),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      DateFormat.MMMd().format(widget.script.updatedAt),
                                      style: TextStyle(
                                        fontSize: LiquidTheme.fontSmall,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textCaption,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.isUpdateAvailable ? Colors.orange.shade500 : colors.textTitle,
                                borderRadius: BorderRadius.circular(20), // Pill Shape
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  )
                                ]
                              ),
                              child: Text(
                                widget.isUpdateAvailable ? "UPDATE" : "GET",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
