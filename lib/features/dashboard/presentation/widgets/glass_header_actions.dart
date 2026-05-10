import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/dashboard/presentation/pages/notification_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/settings_page.dart';

/// Header action buttons displayed on all main pages.
///
/// Contains a Notification button (left) and Settings button (right),
/// replacing the old Burger + Notification layout after sidebar removal.
class GlassHeaderActions extends StatelessWidget {
  final bool hasNotificationBadge;

  const GlassHeaderActions({
    super.key,
    this.hasNotificationBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderButton(
          icon: Icons.notifications_none_rounded,
          color: LiquidTheme.primary,
          onTap: () {
            Navigator.push(
              context,
              LiquidPageRoute(page: const NotificationPage()),
            );
          },
          hasBadge: hasNotificationBadge,
        ),
        const SizedBox(width: 12),
        _buildHeaderButton(
          icon: Icons.settings_rounded,
          onTap: () {
            Navigator.push(
              context,
              LiquidPageRoute(page: const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool hasBadge = false,
  }) {
    return Builder(
      builder: (context) {
        final colors = Theme.of(context).extension<LiquidColors>()!;
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.headerActionBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.headerActionBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color ?? colors.textTitle, size: 22),
              ),
              if (hasBadge)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.cardBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
