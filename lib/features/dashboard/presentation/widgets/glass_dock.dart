import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

import 'package:flutter/services.dart';

class GlassDock extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const GlassDock({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<GlassDock> createState() => _GlassDockState();
}

class _GlassDockState extends State<GlassDock> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), // Solid White (Layer 2)
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDockItem(Icons.grid_view_rounded, 0),
          _buildDockItem(Icons.search_rounded, 1),
          _buildDockItem(Icons.add_rounded, 2, isFab: true),
          _buildDockItem(Icons.analytics_rounded, 3),
          _buildDockItem(Icons.person_rounded, 4),
        ],
      ),
    );
  }

  Widget _buildDockItem(IconData icon, int index, {bool isFab = false}) {
    final isSelected = widget.selectedIndex == index;

    if (isFab) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onItemSelected(index);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: LiquidTheme.textDeep, // Standardized
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LiquidTheme.textDeep.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _hoveredIndex = index),
      onTapUp: (_) => setState(() => _hoveredIndex = -1),
      onTapCancel: () => setState(() => _hoveredIndex = -1),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onItemSelected(index);
      },
      child: AnimatedScale(
        scale: _hoveredIndex == index ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isSelected
                ? LiquidTheme
                      .textDeep // Standardized
                : LiquidTheme.textLight, // Standardized
            size: 26,
          ),
        ),
      ),
    );
  }
}
