import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/features/dashboard/presentation/pages/app_shell.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

/// Root navigation widget that reacts to Firebase auth state.
///
/// Behavior:
///   1. While waiting for auth state → shows loading spinner
///   2. No user → auto-triggers anonymous sign-in (zero-friction onboarding)
///   3. User exists → navigates to [AppShell]
///
/// This widget replaces [LiquidSplashPage] as the `home` in [MaterialApp].
/// The splash animation is preserved as a loading state within AuthGate.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = GetIt.I<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Still resolving auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        // No user — trigger anonymous sign-in silently
        if (!snapshot.hasData) {
          _autoSignIn(authService);
          return const _AuthLoadingScreen();
        }

        // User exists — go to main app
        return const AppShell();
      },
    );
  }

  void _autoSignIn(AuthService authService) {
    authService.signInAnonymously().then((_) {}).catchError((e) {
      debugPrint('[AuthGate] Auto sign-in failed: $e');
      return null;
    });
  }
}

/// Minimal loading screen shown while auth state resolves.
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
