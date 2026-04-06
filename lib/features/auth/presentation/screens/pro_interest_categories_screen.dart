import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/category_repository.dart';

class _ProInterestNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int index) {
    final copy = Set<int>.from(state);
    if (copy.contains(index)) {
      copy.remove(index);
    } else {
      copy.add(index);
    }
    state = copy;
  }
}

final _proInterestProvider =
    NotifierProvider<_ProInterestNotifier, Set<int>>(
  _ProInterestNotifier.new,
  isAutoDispose: true,
);

class ProInterestCategoriesScreen extends ConsumerWidget {
  const ProInterestCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_proInterestProvider);
    final notifier = ref.read(_proInterestProvider.notifier);
    final categoriesAsync = ref.watch(proCategoriesProvider);
    final categories = categoriesAsync.when(
      data: (cats) => cats,
      loading: () => <ProCategory>[],
      error: (_, __) => <ProCategory>[],
    );
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
            const Text(
              'What do you do?',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your areas of expertise so clients can easily find you.',
              style: TextStyle(
                color: AppColors.gris,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Grid
            Expanded(
              child: GridView.builder(
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
                          color:
                              isSelected ? AppColors.violet : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat.icon,
                                  color: isSelected
                                      ? AppColors.violet
                                      : AppColors.gris,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
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
            const SizedBox(height: 12),

            // Continue
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
                          context.go('/pro/dashboard');
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
                    'Continue',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
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
