import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'dart:ui';

class EditorAppBar extends StatelessWidget {
  final String scriptName;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onAiTap;
  final VoidCallback onAiLongPress;

  const EditorAppBar({
    super.key,
    required this.scriptName,
    required this.isSaving,
    required this.onBack,
    required this.onPlay,
    required this.onAiTap,
    required this.onAiLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                  Icons.grid_view_rounded,
                  onBack,
                  tooltip: "Gallery",
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
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
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
                    _buildActionButton(
                      context,
                      Icons.auto_awesome,
                      onAiTap,
                      onLongPress: onAiLongPress,
                      isHighlight: true,
                      tooltip: "AI Assistant",
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      Icons.play_arrow_rounded,
                      onPlay,
                      isHighlight: true,
                      tooltip: "Run",
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
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? "",
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: onLongPress != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onLongPress();
                }
              : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isHighlight
                  ? LiquidTheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isHighlight ? LiquidTheme.primary : LiquidTheme.textDeep,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
