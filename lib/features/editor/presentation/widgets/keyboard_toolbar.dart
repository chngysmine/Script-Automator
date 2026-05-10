import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';

class KeyboardToolbar extends StatelessWidget {
  final Function(String) onInsert;
  final VoidCallback onTab;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const KeyboardToolbar({
    super.key,
    required this.onInsert,
    required this.onTab,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if keyboard is actually open (threshold 100 to avoid safe area artifacts)
    if (MediaQuery.of(context).viewInsets.bottom < 100) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final keys = ['{', '}', '(', ')', '[', ']', '=>', ';', '=', '"', "'"];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: colors.divider,
                width: 0.5,
              ),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildActionButton(Icons.keyboard_tab, onTab, colors),
              VerticalDivider(width: 8, indent: 8, endIndent: 8, color: colors.divider),
              ...keys.map((k) => _buildKeyButton(k, colors)),
              VerticalDivider(width: 8, indent: 8, endIndent: 8, color: colors.divider),
              _buildActionButton(Icons.undo, onUndo, colors),
              _buildActionButton(Icons.redo, onRedo, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton(String label, LiquidColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: colors.textTitle,
          minimumSize: const Size(32, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () => onInsert(label),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, LiquidColors colors) {
    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: colors.textCaption,
      ),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32),
    );
  }
}
