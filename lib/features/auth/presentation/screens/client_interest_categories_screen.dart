import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/category_repository.dart';
import '../../data/client_interest_categories_notifier.dart';

class ClientInterestCategoriesScreen extends ConsumerWidget {
  const ClientInterestCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(clientInterestCategoriesProvider);
    final notifier = ref.read(clientInterestCategoriesProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final asyncCats = ref.watch(proCategoriesProvider);
    final categories = asyncCats.when(
      data: (cats) => cats,
      loading: () => <ProCategory>[],
      error: (_, __) => <ProCategory>[],
    );

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.blanc,
            size: 20,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.violet.withAlpha(25),
                  ),
                  child: const Text(
                    'ÉTAPE 1/3',
                    style: TextStyle(
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
                value: 0.33,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              "Qu'est-ce qui vous intéresse ?",
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sélectionnez les catégories qui vous intéressent pour personnaliser votre feed.',
              style: TextStyle(
                color: AppColors.gris,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Grid
            Expanded(
              child: asyncCats.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.violet),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'Failed to load categories',
                    style: TextStyle(color: AppColors.gris),
                  ),
                ),
                data: (_) => GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
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
                            ? AppColors.violet.withAlpha(15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.violet
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat.emoji ?? '',
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.blanc
                                        : AppColors.grisClair,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
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
            ),
            const SizedBox(height: 12),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: selected.isNotEmpty
                      ? AppColors.gradientAccent
                      : LinearGradient(colors: [
                          AppColors.violet.withAlpha(60),
                          AppColors.rose.withAlpha(60),
                        ]),
                ),
                child: ElevatedButton(
                  onPressed: selected.isNotEmpty
                      ? () {
                          HapticFeedback.mediumImpact();
                          context.go('/client/goals');
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
                  child: const Text(
                    'Continuer',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/client/goals'),
                child: const Text(
                  'Passer pour le moment',
                  style: TextStyle(color: AppColors.gris, fontSize: 14),
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
