import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
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

  _LoginState copyWith({bool? isLoading, bool? obscurePassword, String? selectedRole}) =>
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

final _loginProvider =
    NotifierProvider<_LoginNotifier, _LoginState>(_LoginNotifier.new, isAutoDispose: true);

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
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppColors.error),
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
          context.go('/pro/dashboard');
        default:
          context.go('/complete-profile');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_loginProvider);
    final notifier = ref.read(_loginProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fondDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.surfaceAuth,
                  border: Border.all(color: AppColors.accent.withAlpha(77), width: 2),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Welcome Back', style: TextStyle(color: AppColors.blanc, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Login to your account to continue', style: TextStyle(color: AppColors.gris, fontSize: 15)),
              const SizedBox(height: 32),
              _RoleToggle(selected: s.selectedRole, onChanged: notifier.setRole),
              const SizedBox(height: 24),
              _Field(controller: _emailCtrl, hint: 'Email Address', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _Field(
                controller: _passwordCtrl, hint: 'Password', icon: Icons.lock_outline, obscure: s.obscurePassword,
                suffix: GestureDetector(
                  onTap: notifier.toggleObscure,
                  child: Icon(s.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.gris, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    if (_emailCtrl.text.trim().isNotEmpty) {
                      ref.read(authRepositoryProvider).resetPassword(_emailCtrl.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
                    }
                  },
                  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: s.isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.fondDark, disabledBackgroundColor: AppColors.accent.withAlpha(128), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: s.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fondDark))
                      : const Text('Login →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Divider(color: AppColors.gris.withAlpha(77), height: 1)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR CONTINUE WITH', style: TextStyle(color: AppColors.gris, fontSize: 12, letterSpacing: 0.5))),
                Expanded(child: Divider(color: AppColors.gris.withAlpha(77), height: 1)),
              ]),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _socialButton(Icons.g_mobiledata),
                const SizedBox(width: 16),
                _socialButton(Icons.apple),
              ]),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => context.go('/signup'),
                child: RichText(text: const TextSpan(text: "Don't have an account? ", style: TextStyle(color: AppColors.gris, fontSize: 14), children: [TextSpan(text: 'Sign Up', style: TextStyle(color: AppColors.accent))])),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon) {
    return Opacity(
      opacity: 0.4,
      child: Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.blanc, size: 28)),
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
      decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(children: [_btn('Client', 'client'), _btn('Service Provider', 'pro')]),
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
          decoration: BoxDecoration(color: sel ? AppColors.blanc.withAlpha(26) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(label, style: TextStyle(color: sel ? AppColors.blanc : AppColors.gris, fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400))),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, this.icon, this.keyboardType, this.obscure = false, this.suffix});
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, obscureText: obscure, keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.blanc),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: AppColors.gris.withAlpha(179)),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.gris, size: 20) : null,
        suffixIcon: suffix, filled: true, fillColor: AppColors.surfaceAuth,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
