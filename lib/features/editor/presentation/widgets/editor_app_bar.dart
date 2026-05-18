import 'package:flutter/material.dart';

import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/scale_button.dart';
import 'dart:ui';

class EditorAppBar extends StatelessWidget {
  final String scriptName;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onAiTap;
  final VoidCallback onAiLongPress;
  final VoidCallback? onAiGenerate;

  const EditorAppBar({
    super.key,
    required this.scriptName,
    required this.isSaving,
    required this.onBack,
    required this.onPlay,
    required this.onAiTap,
    required this.onAiLongPress,
    this.onAiGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).extension<LiquidColors>()!;

    final glassColor = isDark
        ? LiquidTheme.darkBackground.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);
    final titleColor = colors.textTitle;
    final iconDefaultColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF475569);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  context,
                  Icons.arrow_back_ios_new_rounded,
                  onBack,
                  tooltip: "Back",
                  iconColor: iconDefaultColor,
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            scriptName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (isSaving)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: LiquidTheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // AI Code Generate (replaces old gear/settings icon)
                    _buildActionButton(
                      context,
                      Icons.auto_awesome_rounded,
                      onAiGenerate ?? onAiTap,
                      onLongPress: onAiLongPress,
                      isHighlight: true,
                      tooltip: "AI Generate",
                      iconColor: iconDefaultColor,
                      highlightColor: LiquidTheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      Icons.play_arrow_rounded,
                      onPlay,
                      isHighlight: true,
                      tooltip: "Run/Play",
                      iconColor: iconDefaultColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    VoidCallback? onLongPress,
    bool isHighlight = false,
    String? tooltip,
    required Color iconColor,
    Color? highlightColor,
  }) {
    final color = highlightColor ?? LiquidTheme.primary;
    return Tooltip(
      message: tooltip ?? "",
      child: ScaleButton(
        onTap: onTap,
        onLongPress: onLongPress,
        scaleFactor: 0.85,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isHighlight
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isHighlight ? color : iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}
