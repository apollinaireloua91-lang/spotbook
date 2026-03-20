import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/auth_repository.dart';

class _LoginState {
  const _LoginState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.selectedRole = 'client',
  });
  final bool isLoading;
  final bool obscurePassword;
  final String selectedRole;

  _LoginState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    String? selectedRole,
  }) =>
      _LoginState(
        isLoading: isLoading ?? this.isLoading,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        selectedRole: selectedRole ?? this.selectedRole,
      );
}

class _LoginNotifier extends Notifier<_LoginState> {
  @override
  _LoginState build() => const _LoginState();

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  void setRole(String role) => state = state.copyWith(selectedRole: role);

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
}

final _loginProvider = NotifierProvider<_LoginNotifier, _LoginState>(
  _LoginNotifier.new,
  isAutoDispose: true,
);

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

  Future<void> _signIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      final role = await ref.read(_loginProvider.notifier).signIn(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
      if (!mounted) return;
      switch (role) {
        case 'client':
          context.go('/client/feed');
        case 'pro':
          context.go('/pro/feed');
        default:
          context.go('/complete-profile');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _googleSignIn() async {
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Navigation handled by auth state listener in app_router
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_loginProvider);
    final notifier = ref.read(_loginProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.blanc,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to your account',
                style: TextStyle(color: AppColors.gris, fontSize: 15),
              ),
              const SizedBox(height: 32),
              // Role toggle
              _RoleToggle(
                selected: s.selectedRole,
                onChanged: notifier.setRole,
              ),
              const SizedBox(height: 24),
              // Email field
              _Field(
                controller: _emailCtrl,
                hint: 'Email Address',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Password field
              _Field(
                controller: _passwordCtrl,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: s.obscurePassword,
                suffix: GestureDetector(
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
                  onTap: () {
                    if (_emailCtrl.text.trim().isNotEmpty) {
                      ref
                          .read(authRepositoryProvider)
                          .resetPassword(_emailCtrl.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email de réinitialisation envoyé'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.gris, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sign In button
              SpotbookButton.primary(
                label: 'Sign In',
                isLoading: s.isLoading,
                onPressed: s.isLoading ? null : _signIn,
              ),
              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: AppColors.border),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(color: AppColors.gris, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: AppColors.border),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Google button
              SpotbookButton.secondary(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                onPressed: _googleSignIn,
              ),
              const SizedBox(height: 32),
              // Sign Up link
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/signup');
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 14,
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

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [_btn('Client', 'client'), _btn('Service Provider', 'pro')],
      ),
    );
  }

  Widget _btn(String label, String role) {
    final sel = selected == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.surfaceAlt : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: sel ? Border.all(color: AppColors.border) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: sel ? AppColors.blanc : AppColors.gris,
                fontSize: 14,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.blanc),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gris),
        prefixIcon:
            icon != null ? Icon(icon, color: AppColors.gris, size: 20) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.blanc, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
