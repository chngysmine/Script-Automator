import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/auth_brand_logo.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/features/auth/presentation/pages/signup_page.dart';
import 'package:script_automator/features/auth/presentation/pages/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await fn();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _msg(e.toString());
        });
      }
    }
  }

  String _msg(String r) {
    if (r.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (r.contains('wrong-password') || r.contains('invalid-credential')) {
      return 'Incorrect password.';
    }
    if (r.contains('invalid-email')) return 'Please enter a valid email.';
    if (r.contains('too-many-requests')) {
      return 'Too many attempts. Wait a moment.';
    }
    if (r.contains('network')) return 'Check your internet connection.';
    if (r.contains('cancelled') || r.contains('canceled')) {
      return 'Sign-in cancelled.';
    }
    return 'Sign-in failed. Please try again.';
  }

  void _nav(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LiquidColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshGradientBackground()),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottom),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // ── Brand ──
                          const AuthBrandLogo(size: 76)
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.85, 0.85),
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 20),
                          Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: c.textTitle,
                                  letterSpacing: -1.2,
                                ),
                              )
                              .animate(delay: 150.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.12),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to sync your scripts',
                            style: TextStyle(
                              fontSize: 15,
                              color: c.textCaption,
                            ),
                          ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                          const SizedBox(height: 36),

                          // ── Glass Card ──
                          _glassCard(c, isDark, [
                                _input(
                                      ctrl: _emailCtrl,
                                      hint: 'Email',
                                      icon: Icons.email_outlined,
                                      c: c,
                                      keyboard: TextInputType.emailAddress,
                                    )
                                    .animate(delay: 500.ms)
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: -0.03),
                                const SizedBox(height: 14),
                                _input(
                                      ctrl: _passCtrl,
                                      hint: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      c: c,
                                      obscure: _obscure,
                                      suffix: GestureDetector(
                                        onTap: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: c.textCaption,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                    .animate(delay: 550.ms)
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: -0.03),

                                // Error
                                if (_error != null) ...[
                                  const SizedBox(height: 14),
                                  _errorBox(_error!).animate().shake(
                                    hz: 2,
                                    offset: const Offset(6, 0),
                                  ),
                                ],

                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _nav(const ForgotPasswordPage()),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: LiquidTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _primaryBtn('Sign In', () {
                                      if (_emailCtrl.text.trim().isEmpty ||
                                          _passCtrl.text.isEmpty) {
                                        setState(
                                          () => _error =
                                              'Please fill in all fields.',
                                        );
                                        return;
                                      }
                                      _run(
                                        () => GetIt.I<AuthService>()
                                            .signInWithEmail(
                                              _emailCtrl.text.trim(),
                                              _passCtrl.text,
                                            ),
                                      );
                                    }, c)
                                    .animate(delay: 650.ms)
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: 0.06),
                              ])
                              .animate(delay: 400.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.05),

                          const SizedBox(height: 28),

                          // ── Divider ──
                          _divider(
                            c,
                          ).animate(delay: 750.ms).fadeIn(duration: 300.ms),
                          const SizedBox(height: 20),

                          // ── Social ──
                          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                            _socialBtn(
                                  Icons.apple_rounded,
                                  'Continue with Apple',
                                  c,
                                  isDark,
                                  isApple: true,
                                  onTap: () => _run(
                                    () =>
                                        GetIt.I<AuthService>().signInWithApple(),
                                  ),
                                )
                                .animate(delay: 800.ms)
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.04),
                            const SizedBox(height: 10),
                          ],
                          _socialBtn(
                                Icons.g_mobiledata_rounded,
                                'Continue with Google',
                                c,
                                isDark,
                                onTap: () => _run(
                                  () =>
                                      GetIt.I<AuthService>().signInWithGoogle(),
                                ),
                              )
                              .animate(delay: 850.ms)
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.04),

                          const SizedBox(height: 20),

                          // ── Guest ──
                          GestureDetector(
                            onTap: _loading
                                ? null
                                : () => _run(
                                    () => GetIt.I<AuthService>()
                                        .signInAnonymously(),
                                  ),
                            child: Text(
                              'Skip — Continue as Guest',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: LiquidTheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ).animate(delay: 900.ms).fadeIn(duration: 300.ms),

                          const Spacer(flex: 1),

                          // ── Sign Up link ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: c.textCaption,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _nav(const SignUpPage()),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: LiquidTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ).animate(delay: 950.ms).fadeIn(duration: 300.ms),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── Shared Widgets ──────────────────────

  Widget _glassCard(LiquidColors c, bool isDark, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0x1AFFFFFF), const Color(0x0DFFFFFF)]
                  : [c.cardBackground, c.cardBackground.withValues(alpha: 0.7)],
            ),
            border: Border.all(
              color: isDark ? const Color(0x1AFFFFFF) : c.cardBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required LiquidColors c,
    bool obscure = false,
    TextInputType? keyboard,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.inputBorder),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: c.textTitle,
        ),
        cursorColor: LiquidTheme.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: c.searchBarHint,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: c.textCaption, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap, LiquidColors c) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: AnimatedScale(
        scale: _loading ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LiquidTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: LiquidTheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _divider(LiquidColors c) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(
              fontSize: 12,
              color: c.textCaption,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.divider)),
      ],
    );
  }

  Widget _socialBtn(
    IconData icon,
    String label,
    LiquidColors c,
    bool isDark, {
    bool isApple = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: isApple
              ? (isDark ? Colors.white : const Color(0xFF1D1D1F))
              : c.secondaryButtonBackground,
          borderRadius: BorderRadius.circular(14),
          border: isApple ? null : Border.all(color: c.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isApple
                  ? (isDark ? Colors.black : Colors.white)
                  : c.textTitle,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isApple
                    ? (isDark ? Colors.black : Colors.white)
                    : c.textTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
