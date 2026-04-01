import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/auth_repository.dart';
import '../../data/user_setup_repository.dart';

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

String _loginErrorMessage(Object e) {
  if (e is AuthException) return e.message;
  if (e is FunctionException) {
    if (e.status == 429) {
      final d = e.details;
      if (d is Map && d['error'] != null) return d['error'].toString();
      return 'Trop de tentatives. Réessaie plus tard.';
    }
    return 'Service momentanément indisponible. Réessaie dans quelques instants.';
  }
  return e.toString().replaceFirst('Exception: ', '');
}

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
          context.go('/client');
        case 'pro':
          context.go('/pro');
        default:
          context.go('/complete-profile');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loginErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _googleSignIn() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signInWithGoogle();
      if (response == null) return; // annulé par l'utilisateur
      if (!mounted) return;
      await ref.read(userSetupRepositoryProvider).setupNewUser();
      if (!mounted) return;
      final profile = await repo.getUserProfile();
      if (!mounted) return;
      final role = profile?['role'] as String?;
      switch (role) {
        case 'client':
          context.go('/client');
        case 'pro':
          context.go('/pro');
        default:
          context.go('/complete-profile');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loginErrorMessage(e)),
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.1),
            radius: 1.4,
            colors: [
              AppColors.violet.withAlpha(75),
              AppColors.fond,
            ],
          ),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo avec gradient + glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withAlpha(100),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.rose.withAlpha(50),
                      blurRadius: 32,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.blanc,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bon retour',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous à votre compte',
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
                hint: 'Adresse e-mail',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Password field
              _Field(
                controller: _passwordCtrl,
                hint: 'Mot de passe',
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
                  onTap: () => context.push('/auth/forgot-password'),
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(color: AppColors.violetClair, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sign In button
              SpotbookButton.primary(
                label: 'Se connecter',
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
                      'ou',
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
                label: 'Continuer avec Google',
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
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AppColors.gris, fontSize: 14),
                    children: [
                      TextSpan(text: 'Pas de compte ? '),
                      TextSpan(
                        text: "S'inscrire",
                        style: TextStyle(
                          color: AppColors.violetClair,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
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
        children: [_btn('Client', 'client'), _btn('Professionnel', 'pro')],
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
            color: sel ? AppColors.violet.withAlpha(45) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: sel
                ? Border.all(color: AppColors.violet.withAlpha(160), width: 1)
                : null,
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: AppColors.violet.withAlpha(40),
                      blurRadius: 8,
                    ),
                  ]
                : null,
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
