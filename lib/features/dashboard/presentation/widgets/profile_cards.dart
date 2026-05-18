import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';

/// A gradient-bordered card displaying a single stat (value + label).
class ProfileStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const ProfileStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).extension<LiquidColors>()!.textBody,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card displaying an achievement badge with icon, title, and status.
class ProfileBadgeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const ProfileBadgeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? color.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.15),
          width: isUnlocked ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : Colors.grey.withValues(alpha: 0.4),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isUnlocked
                  ? color
                  : Colors.grey.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isUnlocked ? "Unlocked ✓" : description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isUnlocked
                  ? Colors.green.shade600
                  : Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
