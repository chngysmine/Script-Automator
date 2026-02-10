import 'dart:ui';
import 'package:flutter/material.dart';

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

    final keys = ['{', '}', '(', ')', '[', ']', '=>', ';', '=', '"', "'"];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.85,
            ), // Light Glass High Contrast
            border: Border(
              top: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildActionButton(Icons.keyboard_tab, onTab),
              const VerticalDivider(width: 8, indent: 8, endIndent: 8),
              ...keys.map((k) => _buildKeyButton(k)),
              const VerticalDivider(width: 8, indent: 8, endIndent: 8),
              _buildActionButton(Icons.undo, onUndo),
              _buildActionButton(Icons.redo, onRedo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A), // Slate 900 Text
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

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: const Color(0xFF64748B),
      ), // Slate 500 Icons
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32),
    );
  }
}
