import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:script_automator/features/dashboard/data/services/user_stats_service.dart';

/// Bidirectional sync engine between local Hive storage and Cloud Firestore.
///
/// Sync strategy: **last-write-wins** based on [updatedAt] timestamp.
/// Sync is non-blocking and runs after UI is visible.
///
/// Firestore paths:
///   - `users/{uid}/scripts/{scriptId}` — user's scripts
///   - `users/{uid}/profile` — display name, bio, stats
///   - `users/{uid}/preferences` — dark mode, notifications, etc.
class FirestoreSyncService {
  final FirebaseFirestore _firestore;

  FirestoreSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ────────────────────── Script Sync ──────────────────────

  /// Pushes all local scripts to Firestore. Used after Guest→Account linking.
  Future<void> pushLocalToCloud(String uid) async {
    try {
      final repo = GetIt.I<ScriptRepository>();
      final result = await repo.getScripts();

      await result.fold(
        (failure) async {
          debugPrint('[Sync] Failed to read local scripts: $failure');
        },
        (scripts) async {
          final batch = _firestore.batch();
          final collection = _firestore.collection('users').doc(uid).collection('scripts');

          for (final script in scripts) {
            final docRef = collection.doc(script.id);
            batch.set(docRef, _scriptToMap(script), SetOptions(merge: true));
          }

          await batch.commit();
          debugPrint('[Sync] Pushed ${scripts.length} scripts to cloud.');
        },
      );
    } catch (e) {
      debugPrint('[Sync] Push failed: $e');
    }
  }

  /// Pulls all cloud scripts to local storage. Used on new device sign-in.
  Future<void> pullCloudToLocal(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scripts')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('[Sync] No cloud scripts to pull.');
        return;
      }

      final repo = GetIt.I<ScriptRepository>();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final script = _mapToScript(doc.id, data);
        await repo.saveScript(script);
      }

      debugPrint('[Sync] Pulled ${snapshot.docs.length} scripts from cloud.');
    } catch (e) {
      debugPrint('[Sync] Pull failed: $e');
    }
  }

  /// Bidirectional merge: compares timestamps, newer version wins.
  Future<void> syncBidirectional(String uid) async {
    try {
      final repo = GetIt.I<ScriptRepository>();
      final localResult = await repo.getScripts();

      final localScripts = localResult.fold(
        (failure) => <Script>[],
        (scripts) => scripts,
      );

      final cloudSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scripts')
          .get();

      final localMap = {for (final s in localScripts) s.id: s};
      final cloudMap = {
        for (final doc in cloudSnapshot.docs)
          doc.id: _mapToScript(doc.id, doc.data()),
      };

      final allIds = {...localMap.keys, ...cloudMap.keys};
      final batch = _firestore.batch();
      final collection = _firestore.collection('users').doc(uid).collection('scripts');
      int pushed = 0, pulled = 0;

      for (final id in allIds) {
        final local = localMap[id];
        final cloud = cloudMap[id];

        if (local != null && cloud == null) {
          // Local only → push to cloud
          batch.set(collection.doc(id), _scriptToMap(local));
          pushed++;
        } else if (local == null && cloud != null) {
          // Cloud only → pull to local
          await repo.saveScript(cloud);
          pulled++;
        } else if (local != null && cloud != null) {
          // Both exist → newer wins
          if (local.updatedAt.isAfter(cloud.updatedAt)) {
            batch.set(collection.doc(id), _scriptToMap(local), SetOptions(merge: true));
            pushed++;
          } else if (cloud.updatedAt.isAfter(local.updatedAt)) {
            await repo.saveScript(cloud);
            pulled++;
          }
        }
      }

      await batch.commit();
      debugPrint('[Sync] Bidirectional complete: pushed=$pushed, pulled=$pulled');
    } catch (e) {
      debugPrint('[Sync] Bidirectional sync failed: $e');
    }
  }

  // ────────────────────── Profile Sync ──────────────────────

  /// Pushes local user profile and preferences to Firestore.
  Future<void> pushProfile(String uid) async {
    try {
      final prefs = GetIt.I<UserPreferencesService>();
      final profileDoc = _firestore.collection('users').doc(uid);

      await profileDoc.set({
        'displayName': await prefs.displayName,
        'bio': await prefs.bio,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Push preferences as a sub-document
      await profileDoc.collection('preferences').doc('settings').set({
        'darkMode': await prefs.isDarkMode,
        'notifications': await prefs.notificationsEnabled,
      }, SetOptions(merge: true));

      // Push stats if available
      if (GetIt.I.isRegistered<UserStatsService>()) {
        final stats = GetIt.I<UserStatsService>();
        await profileDoc.update({
          'totalRuns': await stats.get('total_runs'),
          'streakDays': await stats.get('streak_days'),
        });
      }

      debugPrint('[Sync] Profile pushed for $uid');
    } catch (e) {
      debugPrint('[Sync] Profile push failed: $e');
    }
  }

  /// Pulls cloud profile to local preferences.
  Future<void> pullProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final prefs = GetIt.I<UserPreferencesService>();

      if (data['displayName'] != null) {
        await prefs.setDisplayName(data['displayName'] as String);
      }
      if (data['bio'] != null) {
        await prefs.setBio(data['bio'] as String);
      }

      // Pull preferences
      final prefsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('settings')
          .get();

      if (prefsDoc.exists) {
        final prefsData = prefsDoc.data()!;
        if (prefsData['darkMode'] != null) {
          await prefs.setDarkMode(prefsData['darkMode'] as bool);
        }
        if (prefsData['notifications'] != null) {
          await prefs.setNotificationsEnabled(prefsData['notifications'] as bool);
        }
      }

      debugPrint('[Sync] Profile pulled for $uid');
    } catch (e) {
      debugPrint('[Sync] Profile pull failed: $e');
    }
  }

  // ────────────────────── Full Sync ──────────────────────

  /// Performs a complete bidirectional sync of all data.
  Future<void> fullSync(String uid) async {
    await syncBidirectional(uid);
    await pushProfile(uid);
  }

  // ────────────────────── Converters ──────────────────────

  Map<String, dynamic> _scriptToMap(Script script) => {
        'name': script.name,
        'content': script.content,
        'createdAt': Timestamp.fromDate(script.createdAt),
        'updatedAt': Timestamp.fromDate(script.updatedAt),
        'settings': script.settings,
      };

  Script _mapToScript(String id, Map<String, dynamic> data) => Script(
        id: id,
        name: data['name'] as String? ?? 'Untitled',
        content: data['content'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        settings: (data['settings'] as Map<String, dynamic>?) ?? {},
      );
}
