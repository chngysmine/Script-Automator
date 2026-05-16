import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';

/// Login page displayed after sign-out or on first launch when no
/// persisted Firebase session exists.
///
/// Provides Google, Apple, Email, and Guest (anonymous) sign-in options.
/// Guest accounts can be upgraded later via Settings → Link Account.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSignIn(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await action();
      // AuthGate will automatically navigate to AppShell on auth state change
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _friendlyError(e.toString());
        });
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('cancelled')) return 'Sign-in was cancelled.';
    if (raw.contains('network')) return 'No internet connection.';
    if (raw.contains('credential-already-in-use')) {
      return 'This account is already linked to another user.';
    }
    return 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).extension<LiquidColors>()!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? LiquidTheme.darkAuroraGradient
              : LiquidTheme.auroraGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo + Brand
                _buildBrandSection(colors)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.1),

                const SizedBox(height: 48),

                // Sign-in buttons
                _buildSignInButtons(colors, isDark)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.05),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],

                const Spacer(flex: 1),

                // Guest / Skip
                _buildGuestButton(colors)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 20),

                // Terms
                Text(
                  'By continuing, you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? Colors.white : LiquidTheme.textLight)
                        .withValues(alpha: 0.5),
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSection(LiquidColors colors) {
    return Column(
      children: [
        // App icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LiquidTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: LiquidTheme.primary.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.code_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Script Automator',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colors.textTitle,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Automate. Create. Deploy.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.textCaption,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButtons(LiquidColors colors, bool isDark) {
    final auth = GetIt.I<AuthService>();

    return Column(
      children: [
        // Apple Sign-In
        _buildProviderButton(
          icon: Icons.apple_rounded,
          label: 'Continue with Apple',
          backgroundColor: isDark ? Colors.white : const Color(0xFF1D1D1F),
          textColor: isDark ? Colors.black : Colors.white,
          onTap: () => _handleSignIn(() => auth.signInWithApple()),
        ),
        const SizedBox(height: 12),

        // Google Sign-In
        _buildProviderButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Continue with Google',
          backgroundColor: isDark
              ? const Color(0xFF1E293B)
              : Colors.white,
          textColor: isDark ? Colors.white : const Color(0xFF1D1D1F),
          borderColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFE2E8F0),
          onTap: () => _handleSignIn(() => auth.signInWithGoogle()),
        ),
      ],
    );
  }

  Widget _buildProviderButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: textColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGuestButton(LiquidColors colors) {
    final auth = GetIt.I<AuthService>();

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () => _handleSignIn(() => auth.signInAnonymously()),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: LiquidTheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'Skip — Continue as Guest',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LiquidTheme.primary.withValues(alpha: 0.8),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
