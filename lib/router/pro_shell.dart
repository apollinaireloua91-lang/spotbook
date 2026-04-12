import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/theme/app_colors.dart';

/// Pro Shell — 5 tabs:
///   Feed | Dashboard | Recherche | RDV | Profil
class ProShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final current = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 65 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: AppColors.fond,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 0 — Feed
            _ProNavItem(
              label: 'Feed',
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle_filled,
              selected: current == 0,
              onTap: () => _goBranch(0),
            ),
            // 1 — Dashboard
            _ProNavItem(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              selected: current == 1,
              onTap: () => _goBranch(1),
            ),
            // 2 — Recherche
            _ProNavItem(
              label: 'Recherche',
              icon: Icons.search_outlined,
              activeIcon: Icons.search,
              selected: current == 2,
              onTap: () => _goBranch(2),
            ),
            // 3 — RDV
            _ProNavItem(
              label: 'RDV',
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              selected: current == 3,
              onTap: () => _goBranch(3),
            ),
            // 4 — Profil
            _ProNavItem(
              label: 'Profil',
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              selected: current == 4,
              onTap: () => _goBranch(4),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Nav item — dot indicator + glow
// ═════════════════════════════════════════════════════════════════════════════

class _ProNavItem extends StatelessWidget {
  const _ProNavItem({
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
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? AppColors.violet : AppColors.grisInactif,
              size: 22,
            ),
            const SizedBox(height: 4),
            // Glow dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: selected ? 4 : 0,
              height: selected ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(150),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
