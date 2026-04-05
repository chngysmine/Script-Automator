import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';

/// Displays a list of in-app notifications (script runs, widget deploys, system).
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService =
      GetIt.I<NotificationService>();

  @override
  void initState() {
    super.initState();
    _notificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: LiquidTheme.textDeep,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: LiquidTheme.textDeep,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.done_all_rounded,
              color: LiquidTheme.textDeep,
            ),
            tooltip: "Mark all as read",
            onPressed: () => _notificationService.markAllAsRead(),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: MeshGradientBackground()),
          StreamBuilder<List<AppNotification>>(
            stream: _notificationService.notifications,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: LiquidTheme.primary),
                );
              }

              final notifications = snapshot.data!;

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 64,
                        color: LiquidTheme.textLight.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No notifications yet",
                        style: TextStyle(
                          color: LiquidTheme.textDeep,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Run a script to see activity here",
                        style: TextStyle(
                          color: LiquidTheme.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight,
                    bottom: 100,
                    left: 20,
                    right: 20,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildNotificationItem(notif),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notif) {
    final (icon, iconColor) = _resolveIcon(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _notificationService.dismiss(notif.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.white.withValues(alpha: 0.8)
              : LiquidTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead
                ? Colors.white.withValues(alpha: 0.5)
                : LiquidTheme.primary.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            if (!notif.isRead)
              BoxShadow(
                color: LiquidTheme.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            if (notif.isRead)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (!notif.isRead) {
                _notificationService.markAsRead(notif.id);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      if (!notif.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: LiquidTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  color: LiquidTheme.textDeep,
                                  fontSize: 16,
                                  fontWeight: notif.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(notif.timestamp),
                              style: TextStyle(
                                color: notif.isRead
                                    ? LiquidTheme.textLight
                                    : LiquidTheme.primary,
                                fontSize: 13,
                                fontWeight: notif.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif.body,
                          style: TextStyle(
                            color: notif.isRead
                                ? LiquidTheme.textDeep.withValues(alpha: 0.6)
                                : LiquidTheme.textDeep.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: LiquidTheme.textLight.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'read') {
                        _notificationService.markAsRead(notif.id);
                      } else if (value == 'delete') {
                        _notificationService.dismiss(notif.id);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notif.isRead)
                        const PopupMenuItem(
                          value: 'read',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  color: LiquidTheme.textDeep, size: 20),
                              SizedBox(width: 12),
                              Text("Mark as read",
                                  style:
                                      TextStyle(color: LiquidTheme.textDeep)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 20),
                            SizedBox(width: 12),
                            Text("Delete notification",
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Resolves the display icon and color for a given [NotificationType].
  (IconData, Color) _resolveIcon(NotificationType type) {
    switch (type) {
      case NotificationType.scriptRun:
        return (Icons.play_circle_rounded, LiquidTheme.primary);
      case NotificationType.widgetDeploy:
        return (Icons.widgets_rounded, LiquidTheme.cyan);
      case NotificationType.system:
        return (Icons.info_rounded, const Color(0xFFEC4899));
    }
  }

  /// Formats a [DateTime] into a human-readable relative time string.
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return "Yesterday";
      return DateFormat.MMMd().format(time);
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    }
    return "Just now";
  }
}
