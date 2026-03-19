import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

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

class ClientInterestCategoriesScreen extends StatefulWidget {
  const ClientInterestCategoriesScreen({super.key});

  @override
  State<ClientInterestCategoriesScreen> createState() =>
      _ClientInterestCategoriesScreenState();
}

class _ClientInterestCategoriesScreenState
    extends State<ClientInterestCategoriesScreen> {
  final _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondDark,
      appBar: AppBar(
        backgroundColor: AppColors.fondDark,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        title: const Text(
          'Onboarding',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Step badge + progress
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.accent.withAlpha(26),
                    ),
                    child: const Text(
                      'STEP 1 OF 3',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '33% Complete',
                    style: TextStyle(color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: AppColors.surfaceAuth,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'What are you looking for?',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the categories that interest you to personalize your feed and discover top professionals.',
                style: TextStyle(color: AppColors.gris, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selected.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(index);
                          } else {
                            _selected.add(index);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAuth,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(cat.icon,
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.blanc,
                                      size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.blanc,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle,
                                    color: AppColors.accent, size: 20),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected.isNotEmpty
                      ? () => context.go('/client/goals')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.fondDark,
                    disabledBackgroundColor: AppColors.accent.withAlpha(77),
                    disabledForegroundColor: AppColors.fondDark.withAlpha(128),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue →',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/client/goals'),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.gris, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
