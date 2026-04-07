import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';

class _Goal {
  const _Goal({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;
}

const _goals = [
  _Goal(
    icon: Icons.trending_up,
    title: 'Discover trends',
    description: 'Explore the latest videos and trending styles',
  ),
  _Goal(
    icon: Icons.pin_drop,
    title: 'Book a nearby pro',
    description: 'Find and book a service near you',
  ),
  _Goal(
    icon: Icons.confirmation_number_outlined,
    title: 'Attend events',
    description: 'Buy tickets for upcoming events',
  ),
  _Goal(
    icon: Icons.attach_money,
    title: 'Compare prices',
    description: 'Find the best value for money',
  ),
];

class _GoalNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void select(int index) => state = index;
}

final _selectedGoalProvider = NotifierProvider<_GoalNotifier, int?>(
  _GoalNotifier.new,
  isAutoDispose: true,
);

class ClientInterestGoalsScreen extends ConsumerWidget {
  const ClientInterestGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(_selectedGoalProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            onPressed: () => context.go('/client/interests'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.violet.withAlpha(25),
                  ),
                  child: Text(
                    'STEP 2/3',
                    style: GoogleFonts.dmSans(
                      color: AppColors.violet,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.66,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'What is your goal?',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us what you\'re looking for to personalize your experience.',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Goals list
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(_selectedGoalProvider.notifier).select(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? AppColors.violet.withAlpha(25)
                                  : AppColors.surfaceAlt,
                            ),
                            child: Icon(
                              goal.icon,
                              color: isSelected
                                  ? AppColors.violet
                                  : AppColors.gris,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: GoogleFonts.sora(
                                    color: isSelected
                                        ? AppColors.blanc
                                        : AppColors.grisClair,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.description,
                                  style: GoogleFonts.dmSans(
                                    color: isSelected
                                        ? AppColors.gris
                                        : AppColors.grisInactif,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.violet,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: selectedIndex != null
                      ? AppColors.gradientAccent
                      : LinearGradient(colors: [
                          AppColors.violet.withAlpha(60),
                          AppColors.rose.withAlpha(60),
                        ]),
                ),
                child: ElevatedButton(
                  onPressed: selectedIndex != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          context.go('/client/location');
                        }
                      : null,
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
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/client/location'),
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
                ),
              ),
            ),
            SizedBox(height: bottomPadding + 16),
          ],
        ),
      ),
    );
  }
}
