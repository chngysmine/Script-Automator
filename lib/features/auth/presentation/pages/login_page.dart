import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/mesh_gradient_background.dart';
import 'package:script_automator/features/auth/presentation/pages/signup_page.dart';
import 'package:script_automator/features/auth/presentation/pages/forgot_password_page.dart';
import 'dart:ui';

/// Premium Login page with animated mesh background, glassmorphism form,
/// and Hero-animated logo for seamless transitions to SignUp/ForgotPassword.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = _friendlyError(e.toString()); });
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) return 'Incorrect password. Try again.';
    if (raw.contains('invalid-email')) return 'Please enter a valid email address.';
    if (raw.contains('too-many-requests')) return 'Too many attempts. Please wait a moment.';
    if (raw.contains('network')) return 'No internet connection.';
    if (raw.contains('cancelled')) return 'Sign-in was cancelled.';
    return 'Sign-in failed. Please try again.';
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
                          const Spacer(flex: 2),
                          _buildLogo().animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                          const SizedBox(height: 12),
                          Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colors.textTitle, letterSpacing: -1.0))
                              .animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15),
                          const SizedBox(height: 4),
                          Text('Sign in to sync your scripts across devices', style: TextStyle(fontSize: 14, color: colors.textCaption), textAlign: TextAlign.center)
                              .animate(delay: 150.ms).fadeIn(duration: 400.ms),
                          const SizedBox(height: 32),
                          _buildGlassCard(colors).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.08),
                          const SizedBox(height: 20),
                          _buildSocialButtons(colors).animate(delay: 350.ms).fadeIn(duration: 400.ms),
                          const SizedBox(height: 24),
                          _buildGuestButton().animate(delay: 450.ms).fadeIn(duration: 400.ms),
                          const Spacer(flex: 1),
                          _buildSignUpLink(colors).animate(delay: 500.ms).fadeIn(duration: 400.ms),
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
        width: 72, height: 72,
        decoration: BoxDecoration(
          gradient: LiquidTheme.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: LiquidTheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.code_rounded, color: Colors.white, size: 36),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, colors: colors),
                const SizedBox(height: 14),
                _buildTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock_outline_rounded, obscure: _obscurePassword, colors: colors,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: colors.textCaption, size: 20),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, _smoothRoute(const ForgotPasswordPage())),
                    child: Text('Forgot password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LiquidTheme.primary.withValues(alpha: 0.8))),
                  ),
                ),
                const SizedBox(height: 18),
                _buildPrimaryButton('Sign In', () {
                  if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
                    setState(() => _errorMessage = 'Please fill in all fields.');
                    return;
                  }
                  _handleAction(() => GetIt.I<AuthService>().signInWithEmail(_emailController.text.trim(), _passwordController.text));
                }),
              ],
            ),
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

  Widget _buildPrimaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(gradient: LiquidTheme.primaryGradient, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: LiquidTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(LiquidColors colors) {
    final auth = GetIt.I<AuthService>();
    return Column(
      children: [
        Row(children: [Expanded(child: Divider(color: colors.cardBorder)), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: TextStyle(fontSize: 13, color: colors.textCaption, fontWeight: FontWeight.w500))), Expanded(child: Divider(color: colors.cardBorder))]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildSocialTile(Icons.apple_rounded, 'Apple', colors, () => _handleAction(() => auth.signInWithApple()))),
          const SizedBox(width: 12),
          Expanded(child: _buildSocialTile(Icons.g_mobiledata_rounded, 'Google', colors, () => _handleAction(() => auth.signInWithGoogle()))),
        ]),
      ],
    );
  }

  Widget _buildSocialTile(IconData icon, String label, LiquidColors colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(color: colors.secondaryButtonBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.cardBorder)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 24, color: colors.textTitle),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textTitle)),
        ]),
      ),
    );
  }

  Widget _buildGuestButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () => _handleAction(() => GetIt.I<AuthService>().signInAnonymously()),
      child: Text('Skip — Continue as Guest', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LiquidTheme.primary.withValues(alpha: 0.7))),
    );
  }

  Widget _buildSignUpLink(LiquidColors colors) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Don't have an account? ", style: TextStyle(fontSize: 14, color: colors.textCaption)),
      GestureDetector(
        onTap: () => Navigator.push(context, _smoothRoute(const SignUpPage())),
        child: const Text('Sign Up', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LiquidTheme.primary)),
      ),
    ]);
  }

  PageRouteBuilder _smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, anim, secondaryAnim, child) => FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut), child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
