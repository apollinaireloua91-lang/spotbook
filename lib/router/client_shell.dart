import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/theme/app_colors.dart';

/// Client Shell — 4 tabs, NO camera button:
///   Feed | Découvrir | Mes RDV | Profil
///
/// Premium glassmorphism nav bar with animated pill indicator.
class ClientShell extends StatelessWidget {
  const ClientShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final idx = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 72 + bottomInset,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: AppColors.glass,
              border: Border(
                top: BorderSide(
                  color: AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PremiumNavItem(
                  label: 'Feed',
                  icon: Icons.play_circle_outline_rounded,
                  activeIcon: Icons.play_circle_rounded,
                  selected: idx == 0,
                  onTap: () => _goBranch(0),
                ),
                _PremiumNavItem(
                  label: 'Découvrir',
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  selected: idx == 1,
                  onTap: () => _goBranch(1),
                ),
                _PremiumNavItem(
                  label: 'Mes RDV',
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  selected: idx == 2,
                  onTap: () => _goBranch(2),
                ),
                _PremiumNavItem(
                  label: 'Profil',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  selected: idx == 3,
                  onTap: () => _goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active: icon inside a glowing pill container
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 16 : 12,
                vertical: selected ? 7 : 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.violet.withAlpha(22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: selected
                    ? Border.all(
                        color: AppColors.violet.withAlpha(30),
                        width: 0.5,
                      )
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(20),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  color: selected ? AppColors.violet : AppColors.grisInactif,
                  size: selected ? 23 : 21,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.dmSans(
                color: selected ? AppColors.violet : AppColors.grisInactif,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: selected ? 0.1 : 0,
              ),
              child: Text(label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
