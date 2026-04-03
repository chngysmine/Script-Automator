import 'package:hive_ce/hive.dart';

/// Persistent key-value store for user preferences (profile, settings).
/// Uses a separate Hive box to avoid polluting script data.
class UserPreferencesService {
  static const String _boxName = 'user_preferences';
  LazyBox<String>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openLazyBox<String>(_boxName);
  }

  Future<String> get(String key, {String defaultValue = ''}) async {
    await init();
    return await _box?.get(key) ?? defaultValue;
  }

  Future<void> set(String key, String value) async {
    await init();
    await _box?.put(key, value);
  }

  // Convenience getters
  Future<String> get displayName async => await get('display_name', defaultValue: 'My Workspace');
  Future<String> get bio async => await get('bio', defaultValue: 'Widget automation workspace');
  Future<bool> get isDarkMode async => (await get('dark_mode')) == 'true';
  Future<bool> get notificationsEnabled async => (await get('notifications', defaultValue: 'true')) == 'true';
  
  // Convenience setters
  Future<void> setDisplayName(String name) => set('display_name', name);
  Future<void> setBio(String bio) => set('bio', bio);
  Future<void> setDarkMode(bool enabled) => set('dark_mode', enabled.toString());
  Future<void> setNotificationsEnabled(bool enabled) => set('notifications', enabled.toString());
}
