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
  final VoidCallback? onPublish;
  final VoidCallback onDocsTap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onSave;

  const EditorAppBar({
    super.key,
    required this.scriptName,
    required this.isSaving,
    required this.onBack,
    required this.onPlay,
    this.onPublish,
    required this.onDocsTap,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.onSave,
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
                    // Undo
                    _buildSmallActionButton(
                      context,
                      Icons.chevron_left_rounded,
                      canUndo ? onUndo : () {},
                      tooltip: "Undo",
                      iconColor: canUndo ? iconDefaultColor : iconDefaultColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 2),

                    // Redo
                    _buildSmallActionButton(
                      context,
                      Icons.chevron_right_rounded,
                      canRedo ? onRedo : () {},
                      tooltip: "Redo",
                      iconColor: canRedo ? iconDefaultColor : iconDefaultColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 8),

                    // Play (Run) - Simplified to match < > style
                    _buildSmallActionButton(
                      context,
                      Icons.play_arrow_rounded,
                      onPlay,
                      tooltip: "Run/Play",
                      iconColor: LiquidTheme.primary,
                    ),
                    const SizedBox(width: 4),

                    // Burger Dropdown Menu (on the far right)
                    _buildBurgerMenu(context, iconDefaultColor, colors),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBurgerMenu(BuildContext context, Color iconColor, LiquidColors colors) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: colors.dialogBackground.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.glassBorder, width: 1.5),
          ),
          elevation: 8,
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.menu_rounded, color: iconColor, size: 22),
        tooltip: "More actions",
        offset: const Offset(0, 48), // Pushes dropdown below the burger menu button to avoid overlaying it
        onSelected: (value) {
          if (value == 'save') {
            onSave();
          } else if (value == 'docs') {
            onDocsTap();
          } else if (value == 'publish') {
            if (onPublish != null) {
              onPublish!();
            }
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'save',
              padding: EdgeInsets.zero,
              child: _HoverPopupMenuItem(
                icon: Icons.save_rounded,
                text: "Save",
              ),
            ),
            const PopupMenuItem<String>(
              value: 'docs',
              padding: EdgeInsets.zero,
              child: _HoverPopupMenuItem(
                icon: Icons.menu_book_rounded,
                text: "Documentation",
              ),
            ),
            if (onPublish != null)
              PopupMenuItem<String>(
                value: 'publish',
                padding: EdgeInsets.zero,
                child: _HoverPopupMenuItem(
                  icon: Icons.public_rounded,
                  text: "Publish",
                ),
              ),
          ];
        },
      ),
    );
  }

  Widget _buildSmallActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    required Color iconColor,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? "",
      child: ScaleButton(
        onTap: onTap,
        scaleFactor: 0.85,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
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

/// A custom stateful popup menu item content that handles hover state changes dynamically
/// to provide visual feedback on web/desktop with smooth animation.
class _HoverPopupMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;

  const _HoverPopupMenuItem({
    required this.icon,
    required this.text,
  });

  @override
  State<_HoverPopupMenuItem> createState() => _HoverPopupMenuItemState();
}

class _HoverPopupMenuItemState extends State<_HoverPopupMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final hoverBg = LiquidTheme.primary.withValues(alpha: 0.12);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? hoverBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: colors.textBody,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              widget.text,
              style: TextStyle(
                color: colors.textBody,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
