import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'dart:ui';

/// Sign Up page with Hero-animated logo, glassmorphism form,
/// and smooth fade transition from LoginPage.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await GetIt.I<AuthService>().createAccount(email, password);
      // AuthGate will handle navigation on auth state change
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
    if (raw.contains('email-already-in-use')) return 'An account with this email already exists.';
    if (raw.contains('weak-password')) return 'Password is too weak. Use at least 6 characters.';
    if (raw.contains('invalid-email')) return 'Please enter a valid email address.';
    if (raw.contains('network')) return 'No internet connection.';
    return 'Account creation failed. Please try again.';
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
                          // Back button
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
                          const Spacer(flex: 1),
                          _buildLogo().animate().fadeIn(duration: 500.ms),
                          const SizedBox(height: 16),
                          Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colors.textTitle, letterSpacing: -1.0))
                              .animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.12),
                          const SizedBox(height: 4),
                          Text('Join to backup and share your scripts', style: TextStyle(fontSize: 14, color: colors.textCaption), textAlign: TextAlign.center)
                              .animate(delay: 120.ms).fadeIn(duration: 350.ms),
                          const SizedBox(height: 28),
                          _buildGlassCard(colors).animate(delay: 180.ms).fadeIn(duration: 450.ms).slideY(begin: 0.06),
                          const Spacer(flex: 2),
                          _buildSignInLink(colors).animate(delay: 300.ms).fadeIn(duration: 350.ms),
                          const SizedBox(height: 24),
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
              _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, colors: colors),
              const SizedBox(height: 14),
              _buildTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock_outline_rounded, obscure: _obscurePassword, colors: colors,
                suffixIcon: GestureDetector(onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: colors.textCaption, size: 20))),
              const SizedBox(height: 14),
              _buildTextField(controller: _confirmController, hint: 'Confirm Password', icon: Icons.lock_rounded, obscure: _obscureConfirm, colors: colors,
                suffixIcon: GestureDetector(onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: colors.textCaption, size: 20))),
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
              _buildPrimaryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, TextInputType? keyboardType, Widget? suffixIcon, required LiquidColors colors}) {
    return Container(
      decoration: BoxDecoration(color: colors.searchBarBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.searchBarBorder)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textTitle),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.searchBarHint, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: colors.textCaption, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signUp,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(gradient: LiquidTheme.primaryGradient, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: LiquidTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
        ),
      ),
    );
  }

  Widget _buildSignInLink(LiquidColors colors) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Already have an account? ', style: TextStyle(fontSize: 14, color: colors.textCaption)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LiquidTheme.primary)),
      ),
    ]);
  }
}
