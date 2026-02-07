import 'package:flutter/material.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'liquid_bento_card.dart';

class StaggeredScriptGrid extends StatelessWidget {
  final List<Script> scripts;
  final Function(Script) onTap;

  const StaggeredScriptGrid({
    super.key,
    required this.scripts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (scripts.isEmpty) return const SizedBox.shrink();

    // Custom "Bento" Logic:
    // First item is always LARGE (Hero).
    // Subsequent items alternate or fill available space.
    // For simplicity without external packages, we use Column of Rows.

    final List<Widget> rows = [];
    int i = 0;

    // 1. Hero Script (Large)
    if (i < scripts.length) {
      rows.add(_buildHeroRow(scripts[i]));
      i++;
    }

    // 2. Grid Items (2 per row usually, sometimes 1 wide)
    while (i < scripts.length) {
      if (i + 1 < scripts.length) {
        // Pair
        rows.add(_buildPairRow(scripts[i], scripts[i + 1]));
        i += 2;
      } else {
        // Single Leftover (make it Wide)
        rows.add(_buildWideRow(scripts[i]));
        i++;
      }
    }

    return Column(
      children: rows
          .map(
            (r) =>
                Padding(padding: const EdgeInsets.only(bottom: 16), child: r),
          )
          .toList(),
    );
  }

  Widget _buildHeroRow(Script script) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: LiquidBentoCard(
        script: script,
        size: BentoSize.large,
        onTap: () => onTap(script),
      ),
    );
  }

  Widget _buildWideRow(Script script) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: LiquidBentoCard(
        script: script,
        size: BentoSize.wide,
        onTap: () => onTap(script),
      ),
    );
  }

  Widget _buildPairRow(Script s1, Script s2) {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.85,
            child: LiquidBentoCard(
              script: s1,
              size: BentoSize.small,
              onTap: () => onTap(s1),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.85,
            child: LiquidBentoCard(
              script: s2,
              size: BentoSize.small,
              onTap: () => onTap(s2),
            ),
          ),
        ),
      ],
    );
  }
}
