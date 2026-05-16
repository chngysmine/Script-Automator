import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/sync/firestore_sync_service.dart';
import 'package:script_automator/features/auth/presentation/pages/login_page.dart';
import 'package:script_automator/features/dashboard/presentation/pages/app_shell.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

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
  bool _hasSyncedThisSession = false;

  @override
  Widget build(BuildContext context) {
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
          _hasSyncedThisSession = false;
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
    if (_hasSyncedThisSession) return;
    _hasSyncedThisSession = true;

    // Don't sync for anonymous users — they have no cloud data yet
    if (user.isAnonymous) return;

    // Fire-and-forget background sync
    Future.microtask(() async {
      try {
        final syncService = GetIt.I<FirestoreSyncService>();
        await syncService.syncBidirectional(user.uid);
        debugPrint('[AuthGate] Background sync completed for ${user.uid}');
      } catch (e) {
        debugPrint('[AuthGate] Background sync failed: $e');
      }
    });
  }
}

/// Minimal loading screen shown while Firebase resolves persisted auth state.
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LiquidTheme.auroraGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: LiquidTheme.primary,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
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
