import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/premium_bento_card.dart';

/// A staggered Bento-style grid layout for displaying user scripts.
///
/// Uses [PremiumBentoCard] with a standard 2-column grid and fixed aspect
/// ratios to prevent layout overflow. Cards use [ClipRRect] internally to
/// handle content that exceeds bounds.
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: scripts.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: 2,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: PremiumBentoCard(
                script: scripts[index],
                size: BentoSize.small,
                onTap: () => onTap(scripts[index]),
              ),
            ),
          ),
        );
      },
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
