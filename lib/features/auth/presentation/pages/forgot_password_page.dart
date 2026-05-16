import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'dart:ui';

/// Forgot Password page — sends a Firebase password reset email.
/// Shares the same mesh gradient + glassmorphism design language.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() { _isLoading = false; _emailSent = true; });
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
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('invalid-email')) return 'Please enter a valid email address.';
    if (raw.contains('too-many-requests')) return 'Too many attempts. Please wait.';
    if (raw.contains('network')) return 'No internet connection.';
    return 'Could not send reset email. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(child: MeshGradientBackground()),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: colors.headerActionBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.headerActionBorder),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: colors.textTitle),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    _buildLogo().animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 16),
                    Text('Reset Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colors.textTitle, letterSpacing: -1.0))
                        .animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.12),
                    const SizedBox(height: 4),
                    Text('Enter your email to receive a reset link', style: TextStyle(fontSize: 14, color: colors.textCaption), textAlign: TextAlign.center)
                        .animate(delay: 120.ms).fadeIn(duration: 350.ms),
                    const SizedBox(height: 28),
                    _emailSent ? _buildSuccessCard(colors).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95))
                        : _buildGlassCard(colors).animate(delay: 180.ms).fadeIn(duration: 450.ms).slideY(begin: 0.06),
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

  Widget _buildLogo() {
    return Hero(
      tag: 'auth_logo',
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          gradient: LiquidTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: LiquidTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: const Icon(Icons.code_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildGlassCard(LiquidColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: colors.searchBarBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.searchBarBorder)),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textTitle),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: colors.searchBarHint, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.email_outlined, color: colors.textCaption, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_errorMessage!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                ),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isLoading ? null : _sendResetEmail,
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(gradient: LiquidTheme.primaryGradient, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: LiquidTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(LiquidColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.cardBackground.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 32),
              ),
              const SizedBox(height: 20),
              Text('Check Your Inbox', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textTitle)),
              const SizedBox(height: 8),
              Text(
                'We sent a password reset link to\n${_emailController.text.trim()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textCaption, height: 1.5),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity, height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: LiquidTheme.primary.withValues(alpha: 0.3), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('Back to Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LiquidTheme.primary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
