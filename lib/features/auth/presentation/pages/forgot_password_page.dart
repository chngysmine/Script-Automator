import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/auth_brand_logo.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() { _loading = false; _sent = true; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = _msg(e.toString()); });
    }
  }

  String _msg(String r) {
    if (r.contains('user-not-found')) return 'No account found with this email.';
    if (r.contains('invalid-email')) return 'Please enter a valid email.';
    if (r.contains('too-many-requests')) return 'Too many attempts. Wait a moment.';
    if (r.contains('network')) return 'Check your internet connection.';
    return 'Could not send reset email. Try again.';
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _backBtn(c),
                    const Spacer(flex: 2),

                    const AuthBrandLogo(size: 64).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 18),
                    Text('Reset Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c.textTitle, letterSpacing: -1.0))
                        .animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 6),
                    Text("Enter your email to receive a reset link", style: TextStyle(fontSize: 14, color: c.textCaption), textAlign: TextAlign.center)
                        .animate(delay: 150.ms).fadeIn(duration: 350.ms),
                    const SizedBox(height: 32),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(anim), child: child),
                      ),
                      child: _sent ? _successCard(c, isDark) : _formCard(c, isDark),
                    ),

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard(LiquidColors c, bool isDark) {
    return _glassCard(c, isDark, key: const ValueKey('form'), children: [
      _input(c).animate(delay: 350.ms).fadeIn(duration: 300.ms).slideX(begin: -0.03),

      if (_error != null) ...[
        const SizedBox(height: 14),
        _errorBox(_error!).animate().shake(hz: 2, offset: const Offset(6, 0)),
      ],

      const SizedBox(height: 22),
      GestureDetector(
        onTap: _loading ? null : _send,
        child: AnimatedScale(
          scale: _loading ? 0.97 : 1.0, duration: const Duration(milliseconds: 150),
          child: Container(
            width: double.infinity, height: 54,
            decoration: BoxDecoration(gradient: LiquidTheme.primaryGradient, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: LiquidTheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Center(
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
            ),
          ),
        ),
      ).animate(delay: 450.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
    ]);
  }

  Widget _successCard(LiquidColors c, bool isDark) {
    return _glassCard(c, isDark, key: const ValueKey('success'), children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 30),
      ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack, duration: 500.ms),
      const SizedBox(height: 20),
      Text('Check Your Inbox', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textTitle), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text(
        'We sent a password reset link to\n${_emailCtrl.text.trim()}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: c.textCaption, height: 1.5),
      ),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity, height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LiquidTheme.primary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Center(child: Text('Back to Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LiquidTheme.primary))),
        ),
      ),
    ]);
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

  Widget _glassCard(LiquidColors c, bool isDark, {Key? key, required List<Widget> children}) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isDark ? [const Color(0x1AFFFFFF), const Color(0x0DFFFFFF)] : [c.cardBackground, c.cardBackground.withValues(alpha: 0.7)]),
            border: Border.all(color: isDark ? const Color(0x1AFFFFFF) : c.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 40, offset: const Offset(0, 16))],
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _input(LiquidColors c) {
    return Container(
      decoration: BoxDecoration(color: c.inputBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.inputBorder)),
      child: TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textTitle),
        cursorColor: LiquidTheme.primary,
        decoration: InputDecoration(
          hintText: 'Email', hintStyle: TextStyle(color: c.searchBarHint, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.email_outlined, color: c.textCaption, size: 20),
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
}
