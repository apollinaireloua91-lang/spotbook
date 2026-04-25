import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/auth_repository.dart';

// ─── State ───

class _ForgotPwState {
  const _ForgotPwState({this.isLoading = false, this.errorMessage});
  final bool isLoading;
  final String? errorMessage;

  _ForgotPwState copyWith({bool? isLoading, String? errorMessage, bool clearError = false}) =>
      _ForgotPwState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class _ForgotPwNotifier extends Notifier<_ForgotPwState> {
  @override
  _ForgotPwState build() => const _ForgotPwState();

  Future<bool> submit(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg.contains('rate')
            ? 'Trop de tentatives. Veuillez réessayer dans quelques minutes.'
            : 'Une erreur est survenue. Veuillez vérifier votre e-mail.',
      );
      return false;
    }
  }
}

final _forgotPwProvider =
    NotifierProvider<_ForgotPwNotifier, _ForgotPwState>(_ForgotPwNotifier.new);

// ─── Screen ───

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();
    final success =
        await ref.read(_forgotPwProvider.notifier).submit(_emailCtrl.text.trim());

    if (success && mounted) {
      context.go('/forgot-password-confirmation', extra: _emailCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(_forgotPwProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.a11yBack,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  l.authForgotPasswordTitle,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.authForgotPasswordSubtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return l.authEmailRequired;
                    // Validateur unifié avec sign-up : local@domain.tld minimum.
                    final emailRegex =
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                    if (!emailRegex.hasMatch(v)) {
                      return l.authEmailInvalid;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l.fieldEmail,
                    hintStyle: GoogleFonts.dmSans(
                        color: AppColors.gris, fontSize: 15),
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.gris, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.violet),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.error),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),

                if (s.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    s.errorMessage!,
                    style: GoogleFonts.dmSans(
                        color: AppColors.error, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit button
                SpotbookButton(
                  label: l.authResetPassword,
                  variant: SpotbookButtonVariant.primary,
                  isLoading: s.isLoading,
                  onPressed: s.isLoading ? null : _submit,
                ),

                const SizedBox(height: 32),

                // Back to login
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text.rich(
                        TextSpan(
                          text: l.authRememberPassword,
                          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
                          children: [
                            TextSpan(
                              text: l.login,
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
                ),
                const SizedBox(height: 16),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
