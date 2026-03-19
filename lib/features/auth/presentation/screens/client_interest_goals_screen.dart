import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

class _Goal {
  const _Goal({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;
}

const _goals = [
  _Goal(icon: Icons.trending_up, title: 'Discover new trends', description: 'Explore the latest videos and styles'),
  _Goal(icon: Icons.pin_drop, title: 'Book a nearby pro', description: 'Find and schedule professional services'),
  _Goal(icon: Icons.confirmation_number, title: 'Attend local events', description: 'Get tickets for upcoming gatherings'),
  _Goal(icon: Icons.attach_money, title: 'Compare service prices', description: 'Find the best value for your needs'),
];

class _GoalNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void select(int index) => state = index;
}

final _selectedGoalProvider = NotifierProvider<_GoalNotifier, int?>(_GoalNotifier.new, isAutoDispose: true);

class ClientInterestGoalsScreen extends ConsumerWidget {
  const ClientInterestGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(_selectedGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.fondDark,
      appBar: AppBar(
        backgroundColor: AppColors.fondDark,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: const Text('Onboarding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.accent.withAlpha(26)),
                child: const Text('STEP 2 OF 2', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
              const Spacer(),
              const Text('90%', style: TextStyle(color: AppColors.gris, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(value: 0.9, backgroundColor: AppColors.surfaceAuth, valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent), minHeight: 4)),
            const SizedBox(height: 24),
            const Text("What's your goal today?", style: TextStyle(color: AppColors.blanc, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tell us what you\'re looking for so we can tailor your experience and find the best matches.', style: TextStyle(color: AppColors.gris, fontSize: 14)),
            const SizedBox(height: 24),
            Expanded(child: ListView.separated(
              itemCount: _goals.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => ref.read(_selectedGoalProvider.notifier).select(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceAuth, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? AppColors.accent : Colors.transparent, width: 2)),
                    child: Row(children: [
                      Icon(goal.icon, color: isSelected ? AppColors.accent : AppColors.blanc, size: 28),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(goal.title, style: const TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(goal.description, style: const TextStyle(color: AppColors.gris, fontSize: 13)),
                      ])),
                      if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent, size: 24),
                    ]),
                  ),
                );
              },
            )),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: selectedIndex != null ? () => context.go('/client/location') : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.fondDark, disabledBackgroundColor: AppColors.accent.withAlpha(77), disabledForegroundColor: AppColors.fondDark.withAlpha(128), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Finish Setup ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
