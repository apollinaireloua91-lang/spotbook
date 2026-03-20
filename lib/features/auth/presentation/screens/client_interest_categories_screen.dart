import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/client_interest_categories_notifier.dart';

class _Category {
  const _Category({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

const _categories = [
  _Category(icon: Icons.content_cut, label: 'Hair & Beauty'),
  _Category(icon: Icons.self_improvement, label: 'Wellness & Yoga'),
  _Category(icon: Icons.theater_comedy, label: 'Event Planning'),
  _Category(icon: Icons.music_note, label: 'Entertainment'),
  _Category(icon: Icons.fitness_center, label: 'Training'),
  _Category(icon: Icons.camera_alt, label: 'Media & Photo'),
  _Category(icon: Icons.restaurant, label: 'Cooking'),
  _Category(icon: Icons.palette, label: 'Design'),
];

class ClientInterestCategoriesScreen extends ConsumerWidget {
  const ClientInterestCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(clientInterestCategoriesProvider);
    final notifier = ref.read(clientInterestCategoriesProvider.notifier);

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
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.blanc,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Step 1 of 3',
                    style: TextStyle(color: AppColors.gris, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: AppColors.surface,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.blanc),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What are you looking for?',
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select categories to personalise your feed.',
                  style: TextStyle(color: AppColors.gris, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = selected.contains(index);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.toggle(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blanc
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.blanc
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat.icon,
                            color: isSelected
                                ? AppColors.fond
                                : AppColors.blanc,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.fond
                                  : AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: SpotbookButton.primary(
                label: 'Continue',
                onPressed: selected.isNotEmpty
                    ? () {
                        HapticFeedback.mediumImpact();
                        context.go('/client/goals');
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.go('/client/goals'),
              child: const Text(
                'Skip for now',
                style: TextStyle(color: AppColors.gris, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
