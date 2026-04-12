import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordConfirmationScreen extends ConsumerStatefulWidget {
  const ForgotPasswordConfirmationScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ForgotPasswordConfirmationScreen> createState() =>
      _ForgotPasswordConfirmationScreenState();
}

class _ForgotPasswordConfirmationScreenState
    extends ConsumerState<ForgotPasswordConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final email = widget.email;
    if (email == null || email.isEmpty) return;

    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.authResetLinkResent),
          backgroundColor: AppColors.violet,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated check icon
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.violet.withAlpha(25),
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.violet,
                    size: 44,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      l.authEmailSent,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.authCheckInbox,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.authCheckSpam,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: AppColors.grisInactif,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.email != null) ...[
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _isResending ? null : _resend,
                        child: Text(
                          _isResending
                              ? l.authResending
                              : l.authResendLink,
                          style: GoogleFonts.dmSans(
                            color: _isResending
                                ? AppColors.grisInactif
                                : AppColors.violetClair,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Back to login button
              FadeTransition(
                opacity: _fadeAnim,
                child: SpotbookButton(
                  label: l.authBackToLogin,
                  variant: SpotbookButtonVariant.primary,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/login');
                  },
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
