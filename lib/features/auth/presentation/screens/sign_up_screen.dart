import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../data/auth_repository.dart';
import '../../data/user_setup_repository.dart';

class _SignUpState {
  const _SignUpState({this.isLoading = false, this.obscurePassword = true, this.selectedRole = 'client'});
  final bool isLoading;
  final bool obscurePassword;
  final String selectedRole;
  _SignUpState copyWith({bool? isLoading, bool? obscurePassword, String? selectedRole}) =>
      _SignUpState(isLoading: isLoading ?? this.isLoading, obscurePassword: obscurePassword ?? this.obscurePassword, selectedRole: selectedRole ?? this.selectedRole);
}

class _SignUpNotifier extends Notifier<_SignUpState> {
  @override
  _SignUpState build() => const _SignUpState();
  void toggleObscure() => state = state.copyWith(obscurePassword: !state.obscurePassword);
  void setRole(String role) => state = state.copyWith(selectedRole: role);

  Future<void> signUp({required String email, required String password, required String fullName, required String phone, required String age, required String address}) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(email: email, password: password, fullName: fullName, phone: phone, age: age, address: address, role: state.selectedRole);
      await ref.read(userSetupRepositoryProvider).setupNewUser();
      await AnalyticsService.instance.capture('signup_completed', properties: {
        'role': state.selectedRole,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final _signUpProvider = NotifierProvider<_SignUpNotifier, _SignUpState>(_SignUpNotifier.new, isAutoDispose: true);

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.initialRole});
  final String? initialRole;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      Future.microtask(() => ref.read(_signUpProvider.notifier).setRole(widget.initialRole!));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _ageCtrl.dispose(); _addressCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(_signUpProvider.notifier).signUp(
        email: _emailCtrl.text.trim(), password: _passwordCtrl.text, fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(), age: _ageCtrl.text.trim(), address: _addressCtrl.text.trim(),
      );
      if (!mounted) return;
      context.go('/complete-profile');
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_signUpProvider);
    final n = ref.read(_signUpProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.fondDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            _RoleToggle(selected: s.selectedRole, onChanged: n.setRole),
            const SizedBox(height: 32),
            const Text('Create your account', style: TextStyle(color: AppColors.blanc, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Join the community to discover, book, and experience events.', style: TextStyle(color: AppColors.gris, fontSize: 15)),
            const SizedBox(height: 32),
            _FormField(controller: _nameCtrl, hint: 'Jane Doe', label: 'Full Name', icon: Icons.person_outline, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 16),
            _FormField(controller: _emailCtrl, hint: 'name@example.com', label: 'Email Address', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.isEmpty) return 'Required'; if (!v.contains('@')) return 'Invalid email'; return null; }),
            const SizedBox(height: 16),
            _FormField(controller: _phoneCtrl, hint: '+1 (555) 000-0000', label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            Row(children: [
              SizedBox(width: 80, child: _FormField(controller: _ageCtrl, hint: 'Age', label: 'Age', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _FormField(controller: _addressCtrl, hint: '123 Main St', label: 'Address', icon: Icons.pin_drop_outlined)),
            ]),
            const SizedBox(height: 16),
            _FormField(controller: _passwordCtrl, hint: '••••••••', label: 'Password', icon: Icons.lock_outline, obscure: s.obscurePassword,
              suffix: GestureDetector(onTap: n.toggleObscure, child: Icon(s.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.gris, size: 20)),
              validator: (v) { if (v == null || v.length < 6) return 'Min 6 characters'; return null; }),
            const SizedBox(height: 24),
            RichText(text: const TextSpan(style: TextStyle(color: AppColors.gris, fontSize: 12), children: [
              TextSpan(text: 'By selecting "Create Account", you agree to our '),
              TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.accent)),
              TextSpan(text: ' and '),
              TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.accent)),
              TextSpan(text: '.'),
            ])),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: s.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.fondDark, disabledBackgroundColor: AppColors.accent.withAlpha(128), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: s.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fondDark)) : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 24),
            Center(child: GestureDetector(onTap: () => context.go('/login'), child: RichText(text: const TextSpan(text: 'Already have an account? ', style: TextStyle(color: AppColors.gris, fontSize: 14), children: [TextSpan(text: 'Log in', style: TextStyle(color: AppColors.accent))])))),
            const SizedBox(height: 32),
          ])),
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
    return Container(decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(4), child: Row(children: [_b('Client', 'client'), _b('Service Provider', 'pro')]));
  }
  Widget _b(String label, String role) {
    final sel = selected == role;
    return Expanded(child: GestureDetector(onTap: () => onChanged(role), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? AppColors.blanc.withAlpha(26) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(label, style: TextStyle(color: sel ? AppColors.blanc : AppColors.gris, fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400))))));
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.controller, required this.hint, required this.label, this.icon, this.keyboardType, this.obscure = false, this.suffix, this.validator});
  final TextEditingController controller; final String hint; final String label; final IconData? icon; final TextInputType? keyboardType; final bool obscure; final Widget? suffix; final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    return TextFormField(controller: controller, obscureText: obscure, keyboardType: keyboardType, validator: validator, style: const TextStyle(color: AppColors.blanc), decoration: InputDecoration(
      hintText: hint, labelText: label, labelStyle: const TextStyle(color: AppColors.gris, fontSize: 13), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.gris, size: 20) : null, suffixIcon: suffix, filled: true, fillColor: AppColors.surfaceAuth,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ));
  }
}
