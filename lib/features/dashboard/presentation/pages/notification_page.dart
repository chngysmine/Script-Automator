import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/ui/liquid_glass.dart';
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
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
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
                    child: CircularProgressIndicator(
                        color: LiquidTheme.primary));
              }

              final notifications = snapshot.data!;

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        "No notifications yet",
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Run a script to see activity here",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        20,
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
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child:
            const Icon(Icons.delete_sweep_rounded, color: Colors.white),
      ),
      child: LiquidGlass(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          onTap: () {
            if (!notif.isRead) {
              _notificationService.markAsRead(notif.id);
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                        Text(
                          _formatTime(notif.timestamp),
                          style: TextStyle(
                            color: notif.isRead
                                ? Colors.white54
                                : LiquidTheme.cyan,
                            fontSize: 12,
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(
                        color: notif.isRead
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight:
                            notif.isRead ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notif.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 12, top: 20),
                  decoration: const BoxDecoration(
                    color: LiquidTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
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
