import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_colors.dart';
import '../shared/theme/theme_mode_notifier.dart';

/// Pro Shell — 5 tabs with premium floating glassmorphism nav bar.
///
/// Feed | Dashboard | Recherche | RDV | Profil
class ProShell extends ConsumerWidget {
  const ProShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final current = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _PremiumProNavBar(
        currentIndex: current,
        bottomInset: bottomInset,
        onTap: _goBranch,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM FLOATING NAV BAR — 5 equal tabs
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumProNavBar extends StatelessWidget {
  const _PremiumProNavBar({
    required this.currentIndex,
    required this.bottomInset,
    required this.onTap,
  });

  final int currentIndex;
  final double bottomInset;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final totalBottom = bottomInset + 8;

    return Container(
      height: 80 + totalBottom,
      padding: EdgeInsets.only(bottom: totalBottom),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? Colors.black.withAlpha(180)
                    : Colors.white.withAlpha(210),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.isDark
                      ? Colors.white.withAlpha(18)
                      : Colors.black.withAlpha(8),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.isDark
                        ? AppColors.violet.withAlpha(20)
                        : Colors.black.withAlpha(15),
                    blurRadius: 30,
                    spreadRadius: -5,
                    offset: const Offset(0, 8),
                  ),
                  if (AppColors.isDark)
                    BoxShadow(
                      color: AppColors.violet.withAlpha(8),
                      blurRadius: 60,
                      spreadRadius: 0,
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 0 — Feed
                  _PremiumNavItem(
                    label: 'Feed',
                    icon: Icons.play_circle_outline_rounded,
                    activeIcon: Icons.play_circle_rounded,
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  // 1 — Dashboard
                  _PremiumNavItem(
                    label: 'Dashboard',
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  // 2 — Recherche
                  _PremiumNavItem(
                    label: 'Recherche',
                    icon: Icons.search_rounded,
                    activeIcon: Icons.search_rounded,
                    selected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  // 3 — RDV
                  _PremiumNavItem(
                    label: 'RDV',
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  // 4 — Profil
                  _PremiumNavItem(
                    label: 'Profil',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    selected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM NAV ITEM — animated gradient pill indicator
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumNavItem extends StatelessWidget {
  const _PremiumNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? AppColors.violet : AppColors.grisInactif,
                size: selected ? 26 : 23,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: selected ? 20 : 0,
              height: selected ? 3 : 0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: selected ? AppColors.gradientAccent : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(120),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.dmSans(
                color: selected ? AppColors.violet : AppColors.grisInactif,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: selected ? 0.3 : 0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
