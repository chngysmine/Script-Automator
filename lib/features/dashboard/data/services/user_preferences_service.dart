import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive.dart';

/// Persistent key-value store for user preferences (profile, settings).
/// Uses a UID-namespaced Hive box to prevent cross-account data leakage.
class UserPreferencesService {
  static const String _boxName = 'user_preferences';
  LazyBox<String>? _box;

  Future<void> init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final currentBoxName = '${_boxName}_$uid';

    // Already initialized for the current user
    if (_box != null && _box!.name == currentBoxName && _box!.isOpen) return;

    // Close old box if user switched
    if (_box != null && _box!.isOpen && _box!.name != currentBoxName) {
      await _box!.close();
    }

    _box = await Hive.openLazyBox<String>(currentBoxName);
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
  Future<String?> get avatarPath async {
    final path = await get('avatarPath', defaultValue: '');
    return path.isEmpty ? null : path;
  }
  Future<bool> get isDarkMode async => (await get('dark_mode')) == 'true';
  Future<bool> get notificationsEnabled async => (await get('notifications', defaultValue: 'true')) == 'true';
  
  // Convenience setters
  Future<void> setDisplayName(String name) => set('display_name', name);
  Future<void> setBio(String bio) => set('bio', bio);
  Future<void> setAvatarPath(String path) => set('avatarPath', path);
  Future<void> setDarkMode(bool enabled) => set('dark_mode', enabled.toString());
  Future<void> setNotificationsEnabled(bool enabled) => set('notifications', enabled.toString());
}
