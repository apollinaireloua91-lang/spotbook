import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';

class _RoleNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String role) => state = role;
}

final _selectedRoleProvider = NotifierProvider<_RoleNotifier, String?>(
  _RoleNotifier.new,
  isAutoDispose: true,
);

class AccountTypeSelectionScreen extends ConsumerWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.blanc,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'What are you?',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your account type to get started',
                style: TextStyle(color: AppColors.gris, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.person_outline,
                      title: 'Client',
                      subtitle: 'Book services & events',
                      isSelected: selected == 'client',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(_selectedRoleProvider.notifier)
                            .select('client');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.star_outline,
                      title: 'Professional',
                      subtitle: 'Offer your services',
                      isSelected: selected == 'pro',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(_selectedRoleProvider.notifier)
                            .select('pro');
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SpotbookButton.primary(
                label: 'Continue',
                onPressed: selected == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        context.go('/signup', extra: selected);
                      },
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(color: AppColors.blanc, fontSize: 14),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blanc : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.blanc,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
