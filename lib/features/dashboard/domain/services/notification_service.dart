import 'dart:async';
import 'dart:convert';
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
/// Social notifications (follow, star, comment) have been intentionally
/// removed as they are not relevant to a widget automation app.
class NotificationService {
  static const String _boxName = 'app_notifications';
  static const int _maxNotifications = 100;

  final _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();

  final List<AppNotification> _notifications = [];
  Box<String>? _box;

  /// Stream of all current notifications.
  Stream<List<AppNotification>> get notifications =>
      _notificationsController.stream;

  /// Stream of the current unread notification count.
  Stream<int> get unreadCount => _unreadCountController.stream;

  /// Initializes the Hive box and loads persisted notifications.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
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

  Future<void> _saveToDisk() async {
    if (_box == null) return;
    await _box!.clear();
    for (final n in _notifications) {
      await _box!.put(n.id, json.encode(n.toJson()));
    }
  }

  void _broadcast() {
    _notificationsController.add(List.from(_notifications));
    final unread = _notifications.where((n) => !n.isRead).length;
    _unreadCountController.add(unread);
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
