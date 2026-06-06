import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';

import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';

/// Displays in-app notifications with 3 filter tabs and chronological grouping.
///
/// Tabs: All | Unread | Read
/// Date Groups: Today, Yesterday, This Week, Earlier (Facebook-style)
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService =
      GetIt.I<NotificationService>();
  late TabController _tabController;

  final List<String> _tabLabels = ['All', 'Unread', 'Read'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notificationService.init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textTitle,
            fontSize: LiquidTheme.fontSectionTitle,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textTitle,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.done_all_rounded,
              color: colors.textTitle,
            ),
            tooltip: "Mark all as read",
            onPressed: () => _notificationService.markAllAsRead(),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: MeshGradientBackground()),
          SafeArea(
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService.notifications,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: LiquidTheme.primary,
                    ),
                  );
                }

                final allNotifications = snapshot.data!;
                final List<AppNotification> filtered;

                switch (_tabController.index) {
                  case 1:
                    filtered = allNotifications
                        .where((n) => !n.isRead)
                        .toList();
                    break;
                  case 2:
                    filtered = allNotifications
                        .where((n) => n.isRead)
                        .toList();
                    break;
                  default:
                    filtered = allNotifications;
                }

                // Group by date
                final groups =
                    _notificationService.groupByDate(filtered);
                final sectionOrder = [
                  'Today',
                  'Yesterday',
                  'This Week',
                  'Earlier',
                ];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // Filter Tab Bar (scrollable — NOT pinned)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: LiquidTheme.pageHorizontalPadding,
                          vertical: 8,
                        ),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.searchBarBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.searchBarBorder,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            onTap: (_) => setState(() {}),
                            indicatorPadding: const EdgeInsets.all(2),
                            indicator: BoxDecoration(
                              color: LiquidTheme.primary,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.08,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: colors.textBody,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Notification items
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: 100,
                          left: LiquidTheme.pageHorizontalPadding,
                          right: LiquidTheme.pageHorizontalPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 30.0,
                                  child: FadeInAnimation(
                                    child: _buildGroupedItem(
                                      index,
                                      groups,
                                      sectionOrder,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _calculateItemCount(
                              groups,
                              sectionOrder,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateItemCount(
    Map<String, List<AppNotification>> groups,
    List<String> order,
  ) {
    int count = 0;
    for (final section in order) {
      final items = groups[section];
      if (items != null && items.isNotEmpty) {
        count += 1 + items.length; // 1 header + N items
      }
    }
    return count;
  }

  Widget _buildGroupedItem(
    int index,
    Map<String, List<AppNotification>> groups,
    List<String> order,
  ) {
    int currentIndex = 0;

    for (final section in order) {
      final items = groups[section];
      if (items == null || items.isEmpty) continue;

      // Section header
      if (index == currentIndex) {
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<LiquidColors>()!;
              return Text(
                section,
                style: TextStyle(
                  fontSize: LiquidTheme.fontBody,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                  letterSpacing: -0.3,
                ),
              );
            },
          ),
        );
      }
      currentIndex++;

      // Items in this section
      if (index < currentIndex + items.length) {
        final itemIndex = index - currentIndex;
        final notif = items[itemIndex];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildNotificationItem(notif),
              ),
            ),
          ),
        );
      }
      currentIndex += items.length;
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    final label = _tabLabels[_tabController.index];
    final colors = Theme.of(context).extension<LiquidColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: colors.textCaption.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            label == 'Unread'
                ? "All caught up!"
                : label == 'Read'
                    ? "No read notifications"
                    : "No notifications yet",
            style: TextStyle(
              color: colors.textTitle,
              fontSize: LiquidTheme.fontSectionTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label == 'Unread'
                ? "You've read all your notifications"
                : "Run a script to see activity here",
            style: TextStyle(
              color: colors.textCaption,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notif) {
    final (icon, iconColor) = _resolveIcon(notif.type);
    final colors = Theme.of(context).extension<LiquidColors>()!;
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
              ? colors.cardBackground
              : LiquidTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead
                ? colors.cardBorder
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
              _showNotificationDetail(context, notif);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      if (!notif.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: LiquidTheme.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: colors.cardBackground, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
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
                                  color: colors.textTitle,
                                  fontSize: LiquidTheme.fontBody,
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
                                    ? colors.textCaption
                                    : LiquidTheme.primary,
                                fontSize: LiquidTheme.fontCaption,
                                fontWeight: notif.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.body,
                          style: TextStyle(
                            color: notif.isRead
                                ? colors.textBody.withValues(alpha: 0.6)
                                : colors.textBody.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    color: colors.sheetBackground,
                    surfaceTintColor: colors.sheetBackground,
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: colors.textCaption.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colors.cardBorder, width: 1),
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
                        PopupMenuItem(
                          value: 'read',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  color: colors.textTitle, size: 20),
                              const SizedBox(width: 12),
                              Text("Mark as read",
                                  style:
                                      TextStyle(color: colors.textTitle)),
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

  void _showNotificationDetail(BuildContext context, AppNotification notif) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, iconColor) = _resolveIcon(notif.type);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark 
                    ? LiquidTheme.darkBackground.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.glassBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: TextStyle(
                                color: colors.textTitle,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(notif.timestamp),
                              style: TextStyle(
                                color: colors.textCaption,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.cardBorder,
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 250,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          notif.body,
                          style: TextStyle(
                            color: colors.textBody,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textCaption,
                        ),
                        child: const Text("Close"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _notificationService.dismiss(notif.id);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Delete"),
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
