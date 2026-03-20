import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/auth_repository.dart';
import '../../data/user_setup_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class _SignUpState {
  const _SignUpState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.step = 1,
    this.selectedRole = 'client',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.age = '',
    this.address = '',
    this.password = '',
  });

  final bool isLoading;
  final bool obscurePassword;
  final int step;
  final String selectedRole;
  final String fullName;
  final String email;
  final String phone;
  final String age;
  final String address;
  final String password;

  _SignUpState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    int? step,
    String? selectedRole,
    String? fullName,
    String? email,
    String? phone,
    String? age,
    String? address,
    String? password,
  }) =>
      _SignUpState(
        isLoading: isLoading ?? this.isLoading,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        step: step ?? this.step,
        selectedRole: selectedRole ?? this.selectedRole,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        age: age ?? this.age,
        address: address ?? this.address,
        password: password ?? this.password,
      );
}

class _SignUpNotifier extends Notifier<_SignUpState> {
  @override
  _SignUpState build() => const _SignUpState();

  void setRole(String role) => state = state.copyWith(selectedRole: role);
  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  void goStep(int step) => state = state.copyWith(step: step);
  void prevStep() {
    if (state.step > 1) state = state.copyWith(step: state.step - 1);
  }

  void saveStep1(String fullName) =>
      state = state.copyWith(fullName: fullName, step: 2);
  void saveStep2(String email) =>
      state = state.copyWith(email: email, step: 3);
  void saveStep3(String phone, String age) =>
      state = state.copyWith(phone: phone, age: age, step: 4);
  void saveStep4(String address) =>
      state = state.copyWith(address: address, step: 5);

  Future<void> signUp(String password) async {
    state = state.copyWith(isLoading: true, password: password);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            email: state.email,
            password: password,
            fullName: state.fullName,
            phone: state.phone,
            age: state.age,
            address: state.address,
            role: state.selectedRole,
          );
      await ref.read(userSetupRepositoryProvider).setupNewUser();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final _signUpProvider = NotifierProvider<_SignUpNotifier, _SignUpState>(
  _SignUpNotifier.new,
  isAutoDispose: true,
);

// ─── Screen ──────────────────────────────────────────────────────────────────

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.initialRole});
  final String? initialRole;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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
      Future.microtask(
        () => ref
            .read(_signUpProvider.notifier)
            .setRole(widget.initialRole!),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onContinue(int step) {
    HapticFeedback.selectionClick();
    final n = ref.read(_signUpProvider.notifier);
    switch (step) {
      case 1:
        if (_nameCtrl.text.trim().isEmpty) return;
        n.saveStep1(_nameCtrl.text.trim());
      case 2:
        final email = _emailCtrl.text.trim();
        if (email.isEmpty || !email.contains('@')) return;
        n.saveStep2(email);
      case 3:
        n.saveStep3(_phoneCtrl.text.trim(), _ageCtrl.text.trim());
      case 4:
        n.saveStep4(_addressCtrl.text.trim());
      case 5:
        _submit();
    }
  }

  Future<void> _submit() async {
    final pw = _passwordCtrl.text;
    if (pw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe: minimum 6 caractères'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await ref.read(_signUpProvider.notifier).signUp(pw);
      if (!mounted) return;
      context.go('/complete-profile');
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
    final s = ref.watch(_signUpProvider);
    final n = ref.read(_signUpProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: s.step == 1
                        ? () => context.go('/account-type')
                        : n.prevStep,
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.blanc,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Step ${s.step} of 5',
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.step / 5,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.blanc,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStepContent(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(_SignUpState s) {
    final loginLink = Center(
      child: GestureDetector(
        onTap: () => context.go('/login'),
        child: const Text(
          'Already have an account? Sign In',
          style: TextStyle(color: AppColors.blanc, fontSize: 14),
        ),
      ),
    );

    switch (s.step) {
      case 1:
        return _StepLayout(
          title: 'Create your account',
          subtitle: 'What is your full name?',
          buttonLabel: 'Continue',
          onContinue: () => _onContinue(1),
          isLoading: false,
          footer: loginLink,
          child: _SignUpField(
            controller: _nameCtrl,
            hint: 'Jane Doe',
            icon: Icons.person_outline,
          ),
        );
      case 2:
        return _StepLayout(
          title: 'Your email',
          subtitle: 'We will send your confirmation here',
          buttonLabel: 'Continue',
          onContinue: () => _onContinue(2),
          isLoading: false,
          footer: loginLink,
          child: _SignUpField(
            controller: _emailCtrl,
            hint: 'name@example.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
        );
      case 3:
        return _StepLayout(
          title: 'Contact info',
          subtitle: 'Phone and age (optional)',
          buttonLabel: 'Continue',
          onContinue: () => _onContinue(3),
          isLoading: false,
          footer: loginLink,
          child: Column(
            children: [
              _SignUpField(
                controller: _phoneCtrl,
                hint: '+1 (555) 000-0000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _SignUpField(
                controller: _ageCtrl,
                hint: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        );
      case 4:
        return _StepLayout(
          title: 'Your location',
          subtitle: 'City or address (optional)',
          buttonLabel: 'Continue',
          onContinue: () => _onContinue(4),
          isLoading: false,
          footer: loginLink,
          child: AddressAutocompleteField(
            controller: _addressCtrl,
            label: 'Location',
            hint: 'Montreal, QC',
            icon: Icons.pin_drop_outlined,
            fillColor: AppColors.surface,
          ),
        );
      case 5:
        return _StepLayout(
          title: 'Create a password',
          subtitle: 'Minimum 6 characters',
          buttonLabel: 'Create Account',
          onContinue: () => _onContinue(5),
          isLoading: s.isLoading,
          footer: loginLink,
          child: _SignUpField(
            controller: _passwordCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: s.obscurePassword,
            suffix: GestureDetector(
              onTap: ref.read(_signUpProvider.notifier).toggleObscure,
              child: Icon(
                s.obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.gris,
                size: 20,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Step layout ─────────────────────────────────────────────────────────────

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.buttonLabel,
    required this.onContinue,
    required this.isLoading,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String buttonLabel;
  final VoidCallback onContinue;
  final bool isLoading;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.gris, fontSize: 15),
        ),
        const SizedBox(height: 32),
        child,
        const SizedBox(height: 32),
        SpotbookButton.primary(
          label: buttonLabel,
          isLoading: isLoading,
          onPressed: isLoading ? null : onContinue,
        ),
        const SizedBox(height: 24),
        footer,
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────

class _SignUpField extends StatelessWidget {
  const _SignUpField({
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
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.gris, size: 20)
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blanc),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
