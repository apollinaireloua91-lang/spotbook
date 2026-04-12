import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/theme/app_colors.dart';

/// Client Shell — 4 tabs, NO camera button:
///   Feed | Découvrir | Mes RDV | Profil
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
      bottomNavigationBar: Container(
        height: 65 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: AppColors.navBarBg,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ClientNavItem(
              label: 'Feed',
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle_filled,
              selected: idx == 0,
              onTap: () => _goBranch(0),
            ),
            _ClientNavItem(
              label: 'Découvrir',
              icon: Icons.search_outlined,
              activeIcon: Icons.search,
              selected: idx == 1,
              onTap: () => _goBranch(1),
            ),
            _ClientNavItem(
              label: 'Mes RDV',
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              selected: idx == 2,
              onTap: () => _goBranch(2),
            ),
            _ClientNavItem(
              label: 'Profil',
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              selected: idx == 3,
              onTap: () => _goBranch(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientNavItem extends StatelessWidget {
  const _ClientNavItem({
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
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.violet.withAlpha(20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? AppColors.violet : AppColors.grisInactif,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: selected ? AppColors.violet : AppColors.grisInactif,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
