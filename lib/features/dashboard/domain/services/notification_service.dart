import 'package:synchronized/synchronized.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive.dart';

/// Represents the type of in-app notification.
enum NotificationType { scriptRun, widgetDeploy, system }

/// A single in-app notification entry.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  /// Returns a copy with the specified fields overridden.
  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values[json['type'] as int],
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

/// Manages in-app notifications for script execution events and system alerts.
///
/// Notifications are persisted in a Hive box and broadcast via [Stream].
/// Both streams replay the latest value to every new subscriber, so a widget
/// that subscribes after [init] still receives the current state.
/// Social notifications (follow, star, comment) have been intentionally
/// removed as they are not relevant to a widget automation app.
class NotificationService {
  static const String _boxName = 'app_notifications';
  static const int _maxNotifications = 100;

  /// [auth] is injectable for tests; defaults to [FirebaseAuth.instance].
  NotificationService({FirebaseAuth? auth}) : _authOverride = auth;

  final FirebaseAuth? _authOverride;

  final _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();

  final List<AppNotification> _notifications = [];
  Box<String>? _box;

  /// Emits the current list to each new subscriber, then every update.
  late final Stream<List<AppNotification>> notifications =
      _replayLatest(_notificationsController.stream, () => allNotifications);

  /// Emits the current unread count to each new subscriber, then every update.
  late final Stream<int> unreadCount =
      _replayLatest(_unreadCountController.stream, () => currentUnreadCount);

  /// Current unread notification count (synchronous snapshot).
  int get currentUnreadCount => _notifications.where((n) => !n.isRead).length;

  static Stream<T> _replayLatest<T>(Stream<T> updates, T Function() current) {
    return Stream<T>.multi((controller) {
      controller.add(current());
      controller.addStream(updates).whenComplete(controller.close);
    }, isBroadcast: true);
  }

  /// Initializes the Hive box and loads persisted notifications.
  // Serializes box switching on account changes (see UserStatsService).
  final Lock _initLock = Lock();

  Future<void> init() => _initLock.synchronized(_initLocked);

  Future<void> _initLocked() async {
    final uid =
        (_authOverride ?? FirebaseAuth.instance).currentUser?.uid ?? 'guest';
    // Hive lowercases box names; compare in the same form.
    final currentBoxName = '${_boxName}_$uid'.toLowerCase();

    if (_box != null && _box!.name == currentBoxName && _box!.isOpen) {
      return;
    }

    if (_box != null && _box!.isOpen && _box!.name != currentBoxName) {
      await _box!.close();
    }

    _box = await Hive.openBox<String>(currentBoxName);
    _loadFromDisk();
    _broadcast();
  }

  void _loadFromDisk() {
    if (_box == null) return;
    _notifications.clear();
    for (final key in _box!.keys) {
      try {
        final jsonStr = _box!.get(key);
        if (jsonStr != null) {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          _notifications.add(AppNotification.fromJson(map));
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }
    // Sort newest first
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Serializes saves so overlapping writes cannot interleave clear/put.
  final Lock _saveLock = Lock();

  Future<void> _saveToDisk() => _saveLock.synchronized(() async {
    final box = _box;
    if (box == null) return;
    // Snapshot: the list may change while the writes below are awaited.
    final snapshot = List<AppNotification>.of(_notifications);
    await box.clear();
    for (final n in snapshot) {
      await box.put(n.id, json.encode(n.toJson()));
    }
  });

  void _broadcast() {
    _notificationsController.add(List.from(_notifications));
    _unreadCountController.add(currentUnreadCount);
  }

  /// Adds a new notification and broadcasts the updated list.
  ///
  /// [type] determines the notification icon and behavior.
  /// [title] is the notification headline.
  /// [body] is the notification detail text.
  void addNotification({
    required NotificationType type,
    required String title,
    required String body,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        body: body,
        timestamp: DateTime.now(),
      ),
    );

    // Cap at _maxNotifications to prevent unbounded growth
    while (_notifications.length > _maxNotifications) {
      _notifications.removeLast();
    }

    _broadcast();
    _saveToDisk();
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _broadcast();
      await _saveToDisk();
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _broadcast();
    await _saveToDisk();
  }

  /// Returns only unread notifications.
  List<AppNotification> getUnread() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Returns only read notifications.
  List<AppNotification> getRead() {
    return _notifications.where((n) => n.isRead).toList();
  }

  /// Groups notifications by relative date: "Today", "Yesterday", "This Week", "Earlier".
  Map<String, List<AppNotification>> groupByDate(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final Map<String, List<AppNotification>> groups = {};

    for (final n in items) {
      final date = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      String key;
      if (date == today) {
        key = 'Today';
      } else if (date == yesterday) {
        key = 'Yesterday';
      } else if (date.isAfter(weekAgo)) {
        key = 'This Week';
      } else {
        key = 'Earlier';
      }
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(n);
    }
    return groups;
  }

  /// Returns a snapshot of all current notifications.
  List<AppNotification> get allNotifications => List.from(_notifications);

  /// Removes a notification by [id].
  Future<void> dismiss(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _broadcast();
    await _saveToDisk();
  }

  /// Closes all stream controllers.
  void dispose() {
    _notificationsController.close();
    _unreadCountController.close();
  }
}
