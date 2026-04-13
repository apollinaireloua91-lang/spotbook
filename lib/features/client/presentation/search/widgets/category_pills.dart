import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../features/auth/data/category_repository.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../cubit/client_search_cubit.dart';
import '../../../../../shared/theme/theme_mode_notifier.dart';
import '../models/search_models.dart';

class CategoryPills extends ConsumerWidget {
  const CategoryPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final asyncCats = ref.watch(proCategoriesProvider);
    final categories = asyncCats.when(
      data: (cats) => [
        const SearchCategory('all', 'All', ''),
        ...cats.map((c) => SearchCategory(c.label, c.label, c.emoji ?? '')),
      ],
      loading: () => kSearchCategoriesFallback,
      error: (_, __) => kSearchCategoriesFallback,
    );

    return BlocSelector<ClientSearchCubit, ClientSearchState, String>(
      selector: (s) => s.activeCategory,
      builder: (context, activeCategory) {
        return SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 5),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isActive = cat.key == activeCategory;
              return _CategoryPill(
                category: cat,
                isActive: isActive,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<ClientSearchCubit>().filterByCategory(cat.key);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryPill extends StatefulWidget {
  const _CategoryPill({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  final SearchCategory category;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_bounceCtrl);
  }

  @override
  void didUpdateWidget(covariant _CategoryPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final isActive = widget.isActive;
    final label = cat.emoji.isEmpty ? cat.label : '${cat.emoji} ${cat.label}';

    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.violet : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.violet
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.blanc : AppColors.grisInactif,
            ),
          ),
        ),
      ),
    );
  }
}
