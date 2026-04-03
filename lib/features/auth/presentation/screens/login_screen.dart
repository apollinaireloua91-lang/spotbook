import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/auth_repository.dart';
import '../../data/user_setup_repository.dart';

// ─── State ───

class _LoginState {
  const _LoginState({
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.obscurePassword = true,
  });
  final bool isLoading;
  final bool isGoogleLoading;
  final bool obscurePassword;

  _LoginState copyWith({
    bool? isLoading,
    bool? isGoogleLoading,
    bool? obscurePassword,
  }) =>
      _LoginState(
        isLoading: isLoading ?? this.isLoading,
        isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
        obscurePassword: obscurePassword ?? this.obscurePassword,
      );
}

class _LoginNotifier extends Notifier<_LoginState> {
  @override
  _LoginState build() => const _LoginState();

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  Future<String?> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmail(email: email, password: password);
      final profile = await repo.getUserProfile();
      state = state.copyWith(isLoading: false);
      return profile?['role'] as String?;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<String?> signInWithGoogle() async {
    state = state.copyWith(isGoogleLoading: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
      // Setup user row if first time
      await ref.read(userSetupRepositoryProvider).setupNewUser();
      final profile = await repo.getUserProfile();
      state = state.copyWith(isGoogleLoading: false);
      return profile?['role'] as String?;
    } catch (e) {
      state = state.copyWith(isGoogleLoading: false);
      rethrow;
    }
  }
}

final _loginProvider = NotifierProvider<_LoginNotifier, _LoginState>(
  _LoginNotifier.new,
  isAutoDispose: true,
);

// ─── Screen ───

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _navigateByRole(String? role) {
    if (!mounted) return;
    switch (role) {
      case 'client':
        context.go('/client/feed');
      case 'pro':
        context.go('/pro/dashboard');
      default:
        context.go('/select-account-type');
    }
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    try {
      final role = await ref.read(_loginProvider.notifier).signIn(email, password);
      _navigateByRole(role);
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final role = await ref.read(_loginProvider.notifier).signInWithGoogle();
      _navigateByRole(role);
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('annulée')) _showError(msg);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_loginProvider);
    final notifier = ref.read(_loginProvider.notifier);
    final anyLoading = s.isLoading || s.isGoogleLoading;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.gradientAccent,
                  ),
                  child: const Center(
                    child: Text(
                      'Sb',
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Bon retour !',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour continuer.',
                style: TextStyle(color: AppColors.gris, fontSize: 15),
              ),
              const SizedBox(height: 32),

              // Email
              _AuthField(
                controller: _emailCtrl,
                hint: 'Adresse email',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Password
              _AuthField(
                controller: _passwordCtrl,
                hint: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: s.obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
                suffixIcon: GestureDetector(
                  onTap: notifier.toggleObscure,
                  child: Icon(
                    s.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.gris,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/forgot-password'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.violetClair,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign in button (gradient)
              _GradientButton(
                label: 'Sign in',
                isLoading: s.isLoading,
                onPressed: anyLoading ? null : _signIn,
              ),
              const SizedBox(height: 28),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.gris.withAlpha(50),
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or continue with',
                      style: TextStyle(
                        color: AppColors.gris.withAlpha(180),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.gris.withAlpha(50),
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Google button
              _SocialButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                iconColor: AppColors.fond,
                backgroundColor: AppColors.blanc,
                textColor: AppColors.fond,
                isLoading: s.isGoogleLoading,
                onPressed: anyLoading ? null : _signInWithGoogle,
              ),
              const SizedBox(height: 12),

              // Apple button (iOS only)
              if (Platform.isIOS)
                _SocialButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple_rounded,
                  iconColor: AppColors.blanc,
                  backgroundColor: AppColors.surface,
                  textColor: AppColors.blanc,
                  borderColor: AppColors.border,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Apple Sign In — coming soon (v1.1)'), backgroundColor: AppColors.surface),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Sign up link
              Center(
                child: GestureDetector(
                  onTap: anyLoading ? null : () => context.go('/select-account-type'),
                  child: RichText(
                    text: const TextSpan(
                      text: 'No account? ',
                      style: TextStyle(color: AppColors.gris, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: AppColors.violetClair,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.blanc, fontSize: 16),
      cursorColor: AppColors.violet,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.gris.withAlpha(150), fontSize: 16),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.gris, size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.violet),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: onPressed != null
              ? AppColors.gradientAccent
              : LinearGradient(colors: [
                  AppColors.violet.withAlpha(100),
                  AppColors.rose.withAlpha(100),
                ]),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : () {
            HapticFeedback.mediumImpact();
            onPressed?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blanc,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: AppColors.blanc.withAlpha(120),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.blanc,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.borderColor,
    this.isLoading = false,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : () {
          HapticFeedback.selectionClick();
          onPressed?.call();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor ?? Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: iconColor),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
