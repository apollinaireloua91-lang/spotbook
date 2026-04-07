import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_colors.dart';

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
    final currentIndex = navigationShell.currentIndex;
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 65 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
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
            _ProNavItem(
              label: 'Feed',
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle_filled,
              selected: currentIndex == 0,
              onTap: () => _goBranch(0),
            ),
            _ProNavItem(
              label: 'Dashboard',
              icon: Icons.space_dashboard_outlined,
              activeIcon: Icons.space_dashboard,
              selected: currentIndex == 1,
              onTap: () => _goBranch(1),
            ),
            _ProNavItem(
              label: 'Search',
              icon: Icons.search_outlined,
              activeIcon: Icons.search,
              selected: currentIndex == 2,
              onTap: () => _goBranch(2),
            ),
            _ProNavItem(
              label: 'RDV',
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              selected: currentIndex == 3,
              onTap: () => _goBranch(3),
            ),
            _ProNavItem(
              label: 'Profile',
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              selected: currentIndex == 4,
              onTap: () => _goBranch(4),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final primary = Theme.of(context).colorScheme.primary;

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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? primary.withAlpha(20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? primary : AppColors.grisInactif,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? primary : AppColors.grisInactif,
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
