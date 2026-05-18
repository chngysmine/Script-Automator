import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/auth_brand_logo.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await GetIt.I<AuthService>().createAccount(email, pass);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = _msg(e.toString()); });
    }
  }

  String _msg(String r) {
    if (r.contains('email-already-in-use')) return 'An account with this email already exists.';
    if (r.contains('weak-password')) return 'Password too weak. Use at least 6 characters.';
    if (r.contains('invalid-email')) return 'Please enter a valid email.';
    if (r.contains('network')) return 'Check your internet connection.';
    return 'Account creation failed. Try again.';
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
                          const SizedBox(height: 12),
                          _backBtn(c),
                          const Spacer(flex: 1),

                          const AuthBrandLogo(size: 64).animate().fadeIn(duration: 500.ms),
                          const SizedBox(height: 18),
                          Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c.textTitle, letterSpacing: -1.0))
                              .animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                          const SizedBox(height: 6),
                          Text('Join to backup and share your scripts', style: TextStyle(fontSize: 14, color: c.textCaption))
                              .animate(delay: 150.ms).fadeIn(duration: 350.ms),

                          const SizedBox(height: 32),

                          _glassCard(c, isDark, [
                            _input(ctrl: _emailCtrl, hint: 'Email', icon: Icons.email_outlined, c: c, keyboard: TextInputType.emailAddress)
                                .animate(delay: 350.ms).fadeIn(duration: 300.ms).slideX(begin: -0.03),
                            const SizedBox(height: 14),
                            _input(ctrl: _passCtrl, hint: 'Password', icon: Icons.lock_outline_rounded, c: c, obscure: _obscure1,
                              suffix: GestureDetector(onTap: () => setState(() => _obscure1 = !_obscure1),
                                child: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: c.textCaption, size: 20)))
                                .animate(delay: 400.ms).fadeIn(duration: 300.ms).slideX(begin: -0.03),
                            const SizedBox(height: 14),
                            _input(ctrl: _confirmCtrl, hint: 'Confirm Password', icon: Icons.lock_rounded, c: c, obscure: _obscure2,
                              suffix: GestureDetector(onTap: () => setState(() => _obscure2 = !_obscure2),
                                child: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: c.textCaption, size: 20)))
                                .animate(delay: 450.ms).fadeIn(duration: 300.ms).slideX(begin: -0.03),

                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              _errorBox(_error!).animate().shake(hz: 2, offset: const Offset(6, 0)),
                            ],

                            const SizedBox(height: 22),
                            _primaryBtn().animate(delay: 550.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
                          ]).animate(delay: 250.ms).fadeIn(duration: 500.ms).slideY(begin: 0.05),

                          const Spacer(flex: 2),

                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Already have an account? ', style: TextStyle(fontSize: 14, color: c.textCaption)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LiquidTheme.primary)),
                            ),
                          ]).animate(delay: 600.ms).fadeIn(duration: 300.ms),
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

  // ────────────────────── Shared ──────────────────────

  Widget _backBtn(LiquidColors c) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: c.headerActionBackground, borderRadius: BorderRadius.circular(13), border: Border.all(color: c.headerActionBorder)),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: c.textTitle),
        ),
      ),
    );
  }

  Widget _glassCard(LiquidColors c, bool isDark, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isDark ? [const Color(0x1AFFFFFF), const Color(0x0DFFFFFF)] : [c.cardBackground, c.cardBackground.withValues(alpha: 0.7)]),
            border: Border.all(color: isDark ? const Color(0x1AFFFFFF) : c.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 40, offset: const Offset(0, 16))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }

  Widget _input({required TextEditingController ctrl, required String hint, required IconData icon, required LiquidColors c, bool obscure = false, TextInputType? keyboard, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(color: c.inputBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.inputBorder)),
      child: TextField(
        controller: ctrl, obscureText: obscure, keyboardType: keyboard,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textTitle),
        cursorColor: LiquidTheme.primary,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: c.searchBarHint, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: c.textCaption, size: 20), suffixIcon: suffix,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16), const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)))),
      ]),
    );
  }

  Widget _primaryBtn() {
    return GestureDetector(
      onTap: _loading ? null : _signUp,
      child: AnimatedScale(
        scale: _loading ? 0.97 : 1.0, duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(gradient: LiquidTheme.primaryGradient, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: LiquidTheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Center(
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
          ),
        ),
      ),
    );
  }
}
