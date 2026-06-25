import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/premium_bento_card.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

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
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LiquidTheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                  border: Border.all(
                    color: LiquidTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.code_rounded,
                  size: 40,
                  color: LiquidTheme.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Create Your First Script",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                  letterSpacing: -0.5,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tap the + button in the navigation dock to spin up a new sandboxed automation script.",
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textCaption,
                  height: 1.5,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
