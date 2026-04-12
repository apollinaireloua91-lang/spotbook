import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';

class _RoleNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String role) => state = role;
}

final _selectedRoleProvider =
    NotifierProvider<_RoleNotifier, String?>(_RoleNotifier.new);

class AccountTypeSelectionScreen extends ConsumerWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(_selectedRoleProvider);

    void confirm() {
      if (selectedRole == null) return;
      HapticFeedback.mediumImpact();
      context.go('/signup/$selectedRole');
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              Text(
                'Welcome to\nSpotbook',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How would you like to use the app?',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
              ),
              const SizedBox(height: 40),

              // Client card
              _RoleCard(
                icon: Icons.explore_outlined,
                title: 'Client',
                subtitle: 'I\'m looking for professionals',
                description: 'Discover, book, attend',
                isSelected: selectedRole == 'client',
                gradientColors: [AppColors.violet, AppColors.violetClair],
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(_selectedRoleProvider.notifier).select('client');
                },
              ),
              const SizedBox(height: 16),

              // Pro card
              _RoleCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Professional',
                subtitle: 'I offer my services',
                description: 'Publish, manage, earn',
                isSelected: selectedRole == 'pro',
                gradientColors: [AppColors.rose, AppColors.roseClair],
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(_selectedRoleProvider.notifier).select('pro');
                },
              ),

              const Spacer(),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: selectedRole != null
                        ? AppColors.gradientAccent
                        : LinearGradient(colors: [
                            AppColors.violet.withAlpha(60),
                            AppColors.rose.withAlpha(60),
                          ]),
                  ),
                  child: ElevatedButton(
                    onPressed: selectedRole != null ? confirm : null,
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
                    child: Text(
                      'Continue',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Already have an account link
              Center(
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isSelected,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? gradientColors[0].withAlpha(12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? gradientColors[0] : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withAlpha(25),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected ? null : AppColors.surfaceAlt,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.blanc : AppColors.gris,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      color:
                          isSelected ? AppColors.blanc : AppColors.grisClair,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      color: isSelected
                          ? AppColors.gris
                          : AppColors.grisInactif,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.dmSans(
                      color: isSelected
                          ? AppColors.gris.withAlpha(180)
                          : AppColors.grisInactif.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: gradientColors[0],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
