import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/premium_bento_card.dart';

/// A staggered Bento-style grid layout for displaying user scripts.
///
/// Uses [PremiumBentoCard] with alternating [BentoSize] patterns to create
/// a visually dynamic grid inspired by Apple's Bento design language.
class StaggeredScriptGrid extends StatelessWidget {
  final List<Script> scripts;
  final void Function(Script) onTap;

  const StaggeredScriptGrid({
    super.key,
    required this.scripts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (scripts.isEmpty) {
      return const _EmptyScriptsView();
    }

    final List<Widget> rows = [];
    int index = 0;

    while (index < scripts.length) {
      final rowIndex = rows.length;
      final isEvenRow = rowIndex % 2 == 0;

      if (isEvenRow && index + 1 < scripts.length) {
        // Pattern A: One large + one small
        rows.add(
          _buildDualRow(
            left: _buildAnimatedCard(index, scripts[index], BentoSize.large),
            right: _buildAnimatedCard(
              index + 1,
              scripts[index + 1],
              BentoSize.small,
            ),
            leftFlex: 3,
            rightFlex: 2,
          ),
        );
        index += 2;
      } else if (!isEvenRow && index + 1 < scripts.length) {
        // Pattern B: Two equal cards
        rows.add(
          _buildDualRow(
            left: _buildAnimatedCard(index, scripts[index], BentoSize.small),
            right: _buildAnimatedCard(
              index + 1,
              scripts[index + 1],
              BentoSize.small,
            ),
            leftFlex: 1,
            rightFlex: 1,
          ),
        );
        index += 2;
      } else {
        // Single remaining card: full width
        rows.add(
          _buildAnimatedCard(index, scripts[index], BentoSize.wide),
        );
        index += 1;
      }
    }

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: row,
            ),
          )
          .toList(),
    );
  }

  Widget _buildDualRow({
    required Widget left,
    required Widget right,
    required int leftFlex,
    required int rightFlex,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: leftFlex, child: left),
          const SizedBox(width: 16),
          Expanded(flex: rightFlex, child: right),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(int index, Script script, BentoSize size) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: PremiumBentoCard(
            script: script,
            size: size,
            onTap: () => onTap(script),
          ),
        ),
      ),
    );
  }
}

class _EmptyScriptsView extends StatelessWidget {
  const _EmptyScriptsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code_rounded,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No Scripts Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap + to create your first automation",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
