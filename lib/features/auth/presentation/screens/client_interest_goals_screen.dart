import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';

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
    title: 'Découvrir les tendances',
    description: 'Explorez les dernières vidéos et styles',
  ),
  _Goal(
    icon: Icons.pin_drop,
    title: 'Réserver un pro à proximité',
    description: 'Trouvez et planifiez des services professionnels',
  ),
  _Goal(
    icon: Icons.confirmation_number,
    title: 'Participer à des événements',
    description: 'Obtenez des billets pour les événements à venir',
  ),
  _Goal(
    icon: Icons.attach_money,
    title: 'Comparer les prix',
    description: 'Trouvez le meilleur rapport qualité-prix',
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
                    'Étape 2 sur 3',
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
                  value: 0.66,
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
                  'Quel est votre objectif ?',
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
                  'Dites-nous ce que vous recherchez pour personnaliser votre expérience.',
                  style: TextStyle(color: AppColors.gris, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(_selectedGoalProvider.notifier)
                          .select(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Icon(
                            goal.icon,
                            color: isSelected
                                ? AppColors.fond
                                : AppColors.blanc,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.fond
                                        : AppColors.blanc,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.description,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.fond
                                        : AppColors.gris,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.fond,
                              size: 24,
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
                label: 'Continuer',
                onPressed: selectedIndex != null
                    ? () {
                        HapticFeedback.mediumImpact();
                        context.go('/client/location');
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
