import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/sync/firestore_sync_service.dart';

/// Tracks user activity metrics for achievements and profile stats.
/// Stores counters in a dedicated Hive box.
class UserStatsService {
  static const String _boxName = 'user_stats';
  static const String _activityBoxName = 'daily_activity';
  Box<int>? _box;
  Box<int>? _activityBox;

  Future<void> init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final currentBoxName = '${_boxName}_$uid';
    final currentActivityBoxName = '${_activityBoxName}_$uid';

    // If already initialized for the current user, do nothing.
    if (_box != null &&
        _box!.name == currentBoxName &&
        _box!.isOpen &&
        _activityBox != null &&
        _activityBox!.name == currentActivityBoxName &&
        _activityBox!.isOpen) {
      return;
    }

    // Close old boxes if user switched
    if (_box != null && _box!.isOpen && _box!.name != currentBoxName) {
      await _box!.close();
    }
    if (_activityBox != null && _activityBox!.isOpen && _activityBox!.name != currentActivityBoxName) {
      await _activityBox!.close();
    }

    _box = await Hive.openBox<int>(currentBoxName);
    _activityBox = await Hive.openBox<int>(currentActivityBoxName);
  }

  Future<int> get(String key) async {
    await init();
    return _box?.get(key) ?? 0;
  }

  Future<void> increment(String key, {int by = 1}) async {
    await init();
    final current = _box?.get(key) ?? 0;
    await _box?.put(key, current + by);
  }

  Future<void> set(String key, int value) async {
    await init();
    await _box?.put(key, value);
  }

  /// Call after each script run
  Future<void> recordRun({required bool success}) async {
    await increment('total_runs');
    if (success) {
      await increment('error_free_runs');
    } else {
      await set('error_free_runs', 0); // Reset streak on error
    }
    await _updateStreak();
    await _recordDailyActivity();
    await _syncToCloud();
  }

  Future<void> recordWidgetDeploy() async {
    await increment('widgets_deployed');
    await _recordDailyActivity();
    await _syncToCloud();
  }

  Future<void> recordAiSuggestion() async {
    await increment('ai_suggestions');
    await _recordDailyActivity();
    await _syncToCloud();
  }

  Future<void> recordLinesWritten(int lines) async {
    await increment('lines_written', by: lines);
    await _recordDailyActivity();
    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid != 'guest') {
      if (GetIt.I.isRegistered<FirestoreSyncService>()) {
        GetIt.I<FirestoreSyncService>().pushProfile(uid).catchError((e) {
          // Ignore offline/network issues
        });
      }
    }
  }

  /// Records a +1 activity count for today (for heatmap).
  Future<void> _recordDailyActivity() async {
    await init();
    final today = _todayKey();
    final current = _activityBox?.get(today) ?? 0;
    await _activityBox?.put(today, current + 1);
  }

  /// Returns the daily activity map for the last [days] days.
  /// Key format: yyyyMMdd integer, Value: activity count.
  Future<Map<int, int>> getDailyActivity({int days = 364}) async {
    await init();
    final result = <int, int>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateToKey(date);
      result[key] = _activityBox?.get(key) ?? 0;
    }
    return result;
  }

  /// Returns the entire raw activity map from local Hive box.
  Future<Map<int, int>> getAllActivity() async {
    await init();
    final result = <int, int>{};
    if (_activityBox != null) {
      for (final key in _activityBox!.keys) {
        if (key is int) {
          result[key] = _activityBox!.get(key) ?? 0;
        }
      }
    }
    return result;
  }

  /// Merges a cloud daily activity map into the local Hive box (retains max count per day).
  Future<void> importDailyActivity(Map<int, int> cloudActivity) async {
    await init();
    for (final entry in cloudActivity.entries) {
      final localVal = _activityBox?.get(entry.key) ?? 0;
      if (entry.value > localVal) {
        await _activityBox?.put(entry.key, entry.value);
      }
    }
  }

  int _todayKey() => _dateToKey(DateTime.now());
  int _dateToKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  Future<void> _updateStreak() async {
    await init();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _box?.get('last_run_date_int');
    final todayInt = int.parse(today.replaceAll('-', ''));

    if (lastDate == null) {
      await set('streak_days', 1);
    } else {
      final diff = todayInt - lastDate;
      if (diff == 1) {
        await increment('streak_days');
      } else if (diff > 1) {
        await set('streak_days', 1); // Reset streak
      }
    }
    await set('last_run_date_int', todayInt);
  }

  /// Returns achievement unlock status based on real data.
  Future<Map<String, bool>> getAchievementStatus() async {
    return {
      'syntax_god': (await get('error_free_runs')) >= 50,
      'widget_lord': (await get('widgets_deployed')) >= 10,
      'streak_x7': (await get('streak_days')) >= 7,
      'ai_whisperer': (await get('ai_suggestions')) >= 100,
      'community_star': (await get('scripts_published')) >= 5,
      '1k_lines': (await get('lines_written')) >= 1000,
    };
  }
}
