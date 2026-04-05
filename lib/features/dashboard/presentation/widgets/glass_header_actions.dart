import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/dashboard/presentation/pages/notification_page.dart';

class GlassHeaderActions extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final bool hasNotificationBadge;

  const GlassHeaderActions({
    super.key,
    this.onMenuTap,
    this.hasNotificationBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderButton(
          icon: Icons.menu_rounded,
          onTap: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 12),
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
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
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
            child: Icon(icon, color: color ?? LiquidTheme.textDeep, size: 22),
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
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
