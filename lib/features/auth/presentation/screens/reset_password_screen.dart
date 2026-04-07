import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).updatePassword(
            _passwordCtrl.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.violet.withAlpha(25),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.violet,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'New password',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a strong password for your account.',
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
                  ),
                  const SizedBox(height: 36),

                  // New password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure1,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc, fontSize: 15),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'Minimum 8 characters';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint: 'New password',
                      suffixIcon: _toggleIcon(_obscure1, () {
                        setState(() => _obscure1 = !_obscure1);
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm password
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure2,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc, fontSize: 15),
                    validator: (v) {
                      if (v != _passwordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint: 'Confirm password',
                      suffixIcon: _toggleIcon(_obscure2, () {
                        setState(() => _obscure2 = !_obscure2);
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SpotbookButton(
                    label: 'Update password',
                    variant: SpotbookButtonVariant.primary,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),

                  const SizedBox(height: 24),

                  // Back to login
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Back to sign in',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
      prefixIcon: const Icon(Icons.lock_outline_rounded,
          color: AppColors.gris, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.violet),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _toggleIcon(bool obscure, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.gris,
        size: 20,
      ),
    );
  }
}
