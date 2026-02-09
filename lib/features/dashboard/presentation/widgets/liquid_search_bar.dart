import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

class LiquidSearchBar extends StatelessWidget {
  const LiquidSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95), // Solid White
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white, // Pure White Border
          width: 0.5,
        ),
        boxShadow: [
          // Deep Shadow for 3D Effect
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: LiquidTheme.textLight, // Standardized
              size: 24,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Search scripts...",
                style: TextStyle(
                  color: LiquidTheme.textLight, // Standardized
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: LiquidTheme.textMedium.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.tune_rounded,
              color: LiquidTheme.textLight, // Standardized
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
