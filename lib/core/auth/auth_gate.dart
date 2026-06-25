import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/sync/firestore_sync_service.dart';
import 'package:script_automator/core/sync/sync_retry_queue.dart';
import 'package:script_automator/features/auth/presentation/pages/login_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/app_shell.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/services/app_config_service.dart';
import 'package:script_automator/features/onboarding/presentation/pages/daily_landing_page.dart';

/// Root navigation widget that reacts to Firebase auth state.
///
/// Behavior:
///   1. While waiting for auth state → shows loading spinner
///   2. No user → shows [LoginPage] (user picks sign-in method)
///   3. User exists → shows [AppShell] + triggers background sync
///
/// This widget is the `home` of [MaterialApp].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastSeenUid;
  StreamSubscription<DocumentSnapshot>? _banSubscription;
  bool? _showDailySplash;

  @override
  void initState() {
    super.initState();
    _checkDailySplash();
  }

  Future<void> _checkDailySplash() async {
    final shouldShow = await shouldShowDailySplash();
    if (mounted) {
      setState(() => _showDailySplash = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phase 0: Daily splash check (before any auth)
    if (_showDailySplash == null) {
      return const _AuthLoadingScreen();
    }
    if (_showDailySplash!) {
      return DailyLandingPage(
        onContinue: () {
          setState(() => _showDailySplash = false);
        },
      );
    }

    final authService = GetIt.I<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Still resolving auth state (Firebase checking persisted session)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        // No user → show Login page (user can pick Guest, Google, Apple)
        if (!snapshot.hasData) {
          _lastSeenUid = null;
          if (GetIt.I.isRegistered<FirestoreSyncService>()) {
            GetIt.I<FirestoreSyncService>().cancelNotificationListener();
          }
          if (GetIt.I.isRegistered<UserPreferencesService>()) {
            unawaited(GetIt.I<UserPreferencesService>().init());
          }
          return const LoginPage();
        }

        // User exists → go to main app + trigger background sync once
        _triggerBackgroundSync(snapshot.data!);

        return const AppShell();
      },
    );
  }

  /// Triggers a background sync once per session when user becomes authenticated.
  void _triggerBackgroundSync(User user) {
    if (_lastSeenUid == user.uid) return;
    _lastSeenUid = user.uid;

    // Refresh user-specific local preferences & theme on user switch
    if (GetIt.I.isRegistered<UserPreferencesService>()) {
      unawaited(GetIt.I<UserPreferencesService>().init());
    }

    // Refresh user-specific local caches (e.g. Hive boxes keyed by uid)
    if (GetIt.I.isRegistered<NotificationService>()) {
      GetIt.I<NotificationService>().init();
    }

    // Fetch remote feature flags (maintenance mode, gallery submissions, etc.)
    if (GetIt.I.isRegistered<AppConfigService>()) {
      GetIt.I<AppConfigService>().fetch();
    }

    // Don't sync for anonymous users — they have no cloud data yet
    if (user.isAnonymous) return;

    // Start real-time notifications listener
    if (GetIt.I.isRegistered<FirestoreSyncService>()) {
      GetIt.I<FirestoreSyncService>().listenForNotifications(user.uid);
    }

    // Ban enforcement — check before allowing app access
    Future.microtask(() async {
      bool isBanned = false;
      final banCacheBox = await Hive.openBox('ban_status_cache');
      final cacheKey = 'banned_${user.uid}';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        isBanned = userDoc.exists && userDoc.data()?['is_banned'] == true;
        await banCacheBox.put(cacheKey, isBanned);
      } catch (e) {
        isBanned = banCacheBox.get(cacheKey, defaultValue: false) as bool;
        debugPrint('[AuthGate] Ban check failed (using cache: $isBanned): $e');
      }

      if (isBanned) {
        debugPrint('[AuthGate] User ${user.uid} is BANNED — forcing sign out');
        await GetIt.I<AuthService>().signOut();
        _lastSeenUid = null;
        if (mounted) {
          _showBannedDialog(context);
        }
        return;
      }

      _banSubscription?.cancel();
      _banSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) async {
        final nextIsBanned = doc.data()?['is_banned'] == true;
        final cacheBox = await Hive.openBox('ban_status_cache');
        await cacheBox.put(cacheKey, nextIsBanned);

        if (!nextIsBanned) return;

        debugPrint('[AuthGate] User ${user.uid} was banned in real time — forcing sign out');
        await GetIt.I<AuthService>().signOut();
        _lastSeenUid = null;
        if (mounted) {
          _showBannedDialog(context);
        }
      }, onError: (e) {
        debugPrint('[AuthGate] Ban listener error: $e');
      });

      // Fire-and-forget background sync
      try {
        final syncService = GetIt.I<FirestoreSyncService>();
        await syncService.fullSync(user.uid);
        if (SyncRetryQueue.instance.hasPendingRetries) {
          SyncRetryQueue.instance.clearPersistedMeta();
        }
        debugPrint('[AuthGate] Background sync completed for ${user.uid}');
      } catch (e) {
        debugPrint('[AuthGate] Background sync failed: $e');
      }
    });
  }

  void _showBannedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Banned',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glow lock icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_person_outlined,
                              size: 44,
                              color: Color(0xFFF87171),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'ACCOUNT SUSPENDED',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF8FAFC),
                              letterSpacing: 1.5,
                              fontFamily: 'Inter',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Your access to the Automator ecosystem has been restricted by an administrator. Please check your registry details or contact support.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                              height: 1.5,
                              fontFamily: 'Inter',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          // Glassmorphic action button
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFB91C1C),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Acknowledge',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Minimal loading screen shown while Firebase resolves persisted auth state.
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final captionColor = Theme.of(context).extension<LiquidColors>()?.textCaption ?? const Color(0xFF64748B);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LiquidTheme.auroraGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: LiquidTheme.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: captionColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
