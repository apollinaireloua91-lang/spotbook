import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../data/auth_repository.dart';
import '../../data/category_repository.dart';
import '../../data/user_setup_repository.dart';

// ─── State ───

class _SignUpState {
  const _SignUpState({
    this.currentStep = 0,
    this.isLoading = false,
    this.obscurePassword = true,
    this.obscureConfirm = true,
    this.selectedCategories = const {},
    this.avatarBytes,
  });

  final int currentStep;
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirm;
  final Set<int> selectedCategories;
  final List<int>? avatarBytes;

  _SignUpState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? obscurePassword,
    bool? obscureConfirm,
    Set<int>? selectedCategories,
    List<int>? avatarBytes,
    bool clearAvatar = false,
  }) =>
      _SignUpState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        obscureConfirm: obscureConfirm ?? this.obscureConfirm,
        selectedCategories: selectedCategories ?? this.selectedCategories,
        avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
      );
}

class _SignUpNotifier extends Notifier<_SignUpState> {
  @override
  _SignUpState build() => const _SignUpState();

  void setStep(int step) => state = state.copyWith(currentStep: step);
  void toggleObscurePassword() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
  void toggleObscureConfirm() =>
      state = state.copyWith(obscureConfirm: !state.obscureConfirm);

  void toggleCategory(int index) {
    final cats = Set<int>.from(state.selectedCategories);
    if (cats.contains(index)) {
      cats.remove(index);
    } else {
      cats.add(index);
    }
    state = state.copyWith(selectedCategories: cats);
  }

  Future<void> signUp({
    required String role,
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String phone,
    required String businessName,
    String address = '',
    String city = '',
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            age: '',
            address: address,
            city: city,
            latitude: latitude,
            longitude: longitude,
            role: role,
          );
      final setupRepo = ref.read(userSetupRepositoryProvider);
      await setupRepo.setupNewUser();

      // Pro signup: create profiles_pro so Edge Functions recognise this user
      if (role == 'pro' && businessName.isNotEmpty) {
        String category = 'Other';
        final cats = ref.read(proCategoriesProvider).value;
        if (cats != null && state.selectedCategories.isNotEmpty) {
          final idx = state.selectedCategories.first;
          if (idx >= 0 && idx < cats.length) {
            category = cats[idx].label;
          }
        }
        await setupRepo.createProProfile(
          businessName: businessName,
          category: category,
          city: city,
        );
      }

      await AnalyticsService.instance.capture('signup_completed', properties: {
        'role': role,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<String?> signInWithGoogle(String role) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
      // Set role for Google sign-in users
      await repo.updateUserRole(role);
      final setupRepo = ref.read(userSetupRepositoryProvider);
      await setupRepo.setupNewUser();

      // Pro Google sign-in: create minimal profiles_pro row
      if (role == 'pro') {
        final user = repo.currentUser;
        final name = user?.userMetadata?['full_name'] as String? ?? 'My Business';
        await setupRepo.createProProfile(
          businessName: name,
          category: 'Other',
          city: '',
        );
      }

      final profile = await repo.getUserProfile();
      state = state.copyWith(isLoading: false);
      return profile?['role'] as String?;
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

// ─── Screen ───

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, required this.role});
  final String role;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _pageController = PageController();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Place details from Google Places autocomplete
  String _city = '';
  double? _latitude;
  double? _longitude;

  bool get _isClient => widget.role == 'client';
  int get _totalSteps => _isClient ? 3 : 4;

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _businessCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(_signUpProvider.notifier).setStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextStep() {
    final current = ref.read(_signUpProvider).currentStep;
    if (current == 0) {
      if (!_step1Key.currentState!.validate()) return;
      if (_passwordCtrl.text != _confirmCtrl.text) {
        _showError('Passwords do not match.');
        return;
      }
    } else if (current == 1) {
      if (!_step2Key.currentState!.validate()) return;
    }
    HapticFeedback.selectionClick();
    _goToStep(current + 1);
  }

  void _prevStep() {
    final current = ref.read(_signUpProvider).currentStep;
    if (current > 0) {
      HapticFeedback.selectionClick();
      _goToStep(current - 1);
    } else {
      context.go('/select-account-type');
    }
  }

  Future<void> _submit() async {
    try {
      await ref.read(_signUpProvider.notifier).signUp(
            role: widget.role,
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            businessName: _businessCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            city: _city,
            latitude: _latitude,
            longitude: _longitude,
          );
      if (!mounted) return;
      _navigateToHome();
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await ref.read(_signUpProvider.notifier).signInWithGoogle(widget.role);
      if (!mounted) return;
      _navigateToHome();
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('cancel')) _showError(msg);
    }
  }

  void _navigateToHome() {
    if (_isClient) {
      context.go('/client/interests');
    } else {
      context.go('/pro/dashboard');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_signUpProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back + step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  Semantics(
                    label: 'Back',
                    child: IconButton(
                      onPressed: _prevStep,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Step ${s.currentStep + 1}/$_totalSteps',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: LinearProgressIndicator(
                    value: (s.currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.surface,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.violet),
                    minHeight: 4,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) =>
                    ref.read(_signUpProvider.notifier).setStep(i),
                children: _buildSteps(s),
              ),
            ),

            // Bottom link
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: GoogleFonts.dmSans(
                          color: AppColors.violetClair,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSteps(_SignUpState s) {
    if (_isClient) {
      return [
        _Step1EmailPassword(
          formKey: _step1Key,
          emailCtrl: _emailCtrl,
          passwordCtrl: _passwordCtrl,
          confirmCtrl: _confirmCtrl,
          obscurePassword: s.obscurePassword,
          obscureConfirm: s.obscureConfirm,
          onTogglePassword:
              ref.read(_signUpProvider.notifier).toggleObscurePassword,
          onToggleConfirm:
              ref.read(_signUpProvider.notifier).toggleObscureConfirm,
          onNext: _nextStep,
          onGoogleSignIn: _signInWithGoogle,
          isLoading: s.isLoading,
        ),
        _Step2ClientProfile(
          formKey: _step2Key,
          nameCtrl: _nameCtrl,
          usernameCtrl: _usernameCtrl,
          addressCtrl: _addressCtrl,
          onPlaceSelected: (details) {
            _city = details.city;
            _latitude = details.latitude;
            _longitude = details.longitude;
          },
          onNext: _nextStep,
        ),
        _Step3Categories(
          title: 'What are you interested in?',
          subtitle:
              'Select categories to personalize your feed.',
          selectedCategories: s.selectedCategories,
          onToggle: ref.read(_signUpProvider.notifier).toggleCategory,
          onSubmit: _submit,
          isLoading: s.isLoading,
          buttonLabel: 'Create my account',
        ),
      ];
    } else {
      return [
        _Step1EmailPassword(
          formKey: _step1Key,
          emailCtrl: _emailCtrl,
          passwordCtrl: _passwordCtrl,
          confirmCtrl: _confirmCtrl,
          obscurePassword: s.obscurePassword,
          obscureConfirm: s.obscureConfirm,
          onTogglePassword:
              ref.read(_signUpProvider.notifier).toggleObscurePassword,
          onToggleConfirm:
              ref.read(_signUpProvider.notifier).toggleObscureConfirm,
          onNext: _nextStep,
          onGoogleSignIn: _signInWithGoogle,
          isLoading: s.isLoading,
        ),
        _Step2ProProfile(
          formKey: _step2Key,
          nameCtrl: _nameCtrl,
          businessCtrl: _businessCtrl,
          phoneCtrl: _phoneCtrl,
          addressCtrl: _addressCtrl,
          onPlaceSelected: (details) {
            _city = details.city;
            _latitude = details.latitude;
            _longitude = details.longitude;
          },
          onNext: _nextStep,
        ),
        _Step3Categories(
          title: 'What services do you offer?',
          subtitle:
              'Select the categories of your services.',
          selectedCategories: s.selectedCategories,
          onToggle: ref.read(_signUpProvider.notifier).toggleCategory,
          onSubmit: _nextStep,
          isLoading: false,
          buttonLabel: 'Next',
        ),
        _Step4ProPhoto(
          onSubmit: _submit,
          onSkip: _submit,
          isLoading: s.isLoading,
        ),
      ];
    }
  }
}

// ─── Step 1: Email + Password (shared) ───

class _Step1EmailPassword extends StatelessWidget {
  const _Step1EmailPassword({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onNext,
    required this.onGoogleSignIn,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onNext;
  final VoidCallback onGoogleSignIn;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text(
              'Create your account',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join the Spotbook community.',
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
            ),
            const SizedBox(height: 28),

            // Google button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: isLoading ? null : onGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.blanc,
                  foregroundColor: AppColors.fond,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata_rounded,
                        size: 24, color: AppColors.fond),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Google',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fond,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Apple button (iOS only)
            if (Platform.isIOS)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Apple Sign In — coming soon (v1.1)'),
                              backgroundColor: AppColors.surface,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.blanc,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple_rounded,
                          size: 24, color: AppColors.blanc),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Apple',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blanc,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (Platform.isIOS) const SizedBox(height: 12),
            const SizedBox(height: 12),

            // Divider
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: AppColors.gris.withAlpha(50), height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: GoogleFonts.dmSans(
                        color: AppColors.gris.withAlpha(180), fontSize: 13),
                  ),
                ),
                Expanded(
                    child: Divider(
                        color: AppColors.gris.withAlpha(50), height: 1)),
              ],
            ),
            const SizedBox(height: 24),

            _SignUpField(
              controller: emailCtrl,
              label: 'Email address',
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _SignUpField(
              controller: passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              suffix: GestureDetector(
                onTap: onTogglePassword,
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.gris,
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) return 'Min. 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _SignUpField(
              controller: confirmCtrl,
              label: 'Confirm password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscureConfirm,
              textInputAction: TextInputAction.done,
              suffix: GestureDetector(
                onTap: onToggleConfirm,
                child: Icon(
                  obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.gris,
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                return null;
              },
            ),
            const SizedBox(height: 28),
            _StepButton(label: 'Next', onPressed: onNext),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2 Client: Name + Username ───

class _Step2ClientProfile extends StatelessWidget {
  const _Step2ClientProfile({
    required this.formKey,
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.addressCtrl,
    required this.onPlaceSelected,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController addressCtrl;
  final ValueChanged<PlaceDetails> onPlaceSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text(
              'Your information',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to be known?',
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
            ),
            const SizedBox(height: 28),
            _SignUpField(
              controller: nameCtrl,
              label: 'Full name',
              hint: 'John Doe',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _SignUpField(
              controller: usernameCtrl,
              label: 'Username',
              hint: '@johndoe',
              icon: Icons.alternate_email_rounded,
              textInputAction: TextInputAction.done,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AddressAutocompleteField(
              controller: addressCtrl,
              label: 'Address',
              hint: 'Start typing your address...',
              icon: Icons.location_on_outlined,
              fillColor: AppColors.surface,
              onPlaceSelected: onPlaceSelected,
            ),
            const SizedBox(height: 28),
            _StepButton(label: 'Next', onPressed: onNext),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2 Pro: Name + Business + Phone ───

class _Step2ProProfile extends StatelessWidget {
  const _Step2ProProfile({
    required this.formKey,
    required this.nameCtrl,
    required this.businessCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.onPlaceSelected,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController businessCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final ValueChanged<PlaceDetails> onPlaceSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text(
              'Your Pro profile',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Introduce yourself to your future clients.',
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
            ),
            const SizedBox(height: 28),
            _SignUpField(
              controller: nameCtrl,
              label: 'Full name',
              hint: 'John Doe',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _SignUpField(
              controller: businessCtrl,
              label: 'Business name',
              hint: 'Doe Studio',
              icon: Icons.store_outlined,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _SignUpField(
              controller: phoneCtrl,
              label: 'Phone number',
              hint: '+1 (555) 000-0000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AddressAutocompleteField(
              controller: addressCtrl,
              label: 'Business address',
              hint: 'Start typing your address…',
              icon: Icons.location_on_outlined,
              fillColor: AppColors.surfaceAuth,
              onPlaceSelected: onPlaceSelected,
            ),
            const SizedBox(height: 28),
            _StepButton(label: 'Next', onPressed: onNext),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Categories grid (shared) ───

class _Step3Categories extends ConsumerWidget {
  const _Step3Categories({
    required this.title,
    required this.subtitle,
    required this.selectedCategories,
    required this.onToggle,
    required this.onSubmit,
    required this.isLoading,
    required this.buttonLabel,
  });

  final String title;
  final String subtitle;
  final Set<int> selectedCategories;
  final ValueChanged<int> onToggle;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String buttonLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(proCategoriesProvider);
    final categories = asyncCats.when(
      data: (cats) => cats,
      loading: () => <ProCategory>[],
      error: (_, __) => <ProCategory>[],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            title,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategories.contains(index);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.violet.withAlpha(15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.violet : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (cat.emoji != null && cat.emoji!.isNotEmpty)
                                Text(
                                  cat.emoji!,
                                  style: const TextStyle(fontSize: 26),
                                )
                              else
                                Icon(
                                  cat.icon,
                                  color: isSelected
                                      ? AppColors.violet
                                      : AppColors.gris,
                                  size: 28,
                                ),
                              const SizedBox(height: 6),
                              Text(
                                cat.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: isSelected
                                      ? AppColors.blanc
                                      : AppColors.grisClair,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.violet,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _StepButton(
            label: buttonLabel,
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Step 4 Pro: Profile photo ───

class _Step4ProPhoto extends StatefulWidget {
  const _Step4ProPhoto({
    required this.onSubmit,
    required this.onSkip,
    required this.isLoading,
  });

  final VoidCallback onSubmit;
  final VoidCallback onSkip;
  final bool isLoading;

  @override
  State<_Step4ProPhoto> createState() => _Step4ProPhotoState();
}

class _Step4ProPhotoState extends State<_Step4ProPhoto> {
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            'Profile photo',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo to build trust with your clients.',
            style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
          ),
          const SizedBox(height: 40),

          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: _pickedImage != null
                            ? AppColors.violet
                            : AppColors.border,
                        width: 2,
                      ),
                      image: _pickedImage != null
                          ? DecorationImage(
                              image: FileImage(File(_pickedImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _pickedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.gris, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                'Add',
                                style: GoogleFonts.dmSans(
                                    color: AppColors.gris, fontSize: 13),
                              ),
                            ],
                          )
                        : null,
                  ),
                  if (_pickedImage != null)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.violet,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: AppColors.blanc,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          _StepButton(
            label: 'Create my account',
            onPressed: widget.onSubmit,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: widget.onSkip,
              child: Text(
                'Skip for now',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───

class _SignUpField extends StatelessWidget {
  const _SignUpField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.grisClair,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction: textInputAction ?? TextInputAction.next,
          style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 16),
          cursorColor: AppColors.violet,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.dmSans(color: AppColors.gris.withAlpha(130), fontSize: 16),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.gris, size: 20)
                : null,
            suffixIcon: suffix,
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
              borderSide: BorderSide(color: AppColors.violet),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.gradientAccent,
        ),
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.blanc,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: AppColors.blanc.withAlpha(100),
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
                    color: AppColors.blanc,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
