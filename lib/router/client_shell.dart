import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_colors.dart';

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
    final fabActive = navigationShell.currentIndex == 2;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fond,
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -12),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            onPressed: () => _goBranch(2),
            backgroundColor: AppColors.blanc,
            foregroundColor: AppColors.fond,
            elevation: fabActive ? 6 : 3,
            shape: const CircleBorder(),
            child: Icon(
              fabActive ? Icons.calendar_today : Icons.calendar_today_outlined,
              size: 26,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.fond,
        elevation: 0,
        height: 56 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: _ClientNavItem(
                  label: 'Feed',
                  icon: Icons.play_circle_outline,
                  activeIcon: Icons.play_circle_filled,
                  selected: navigationShell.currentIndex == 0,
                  onTap: () => _goBranch(0),
                ),
              ),
              Expanded(
                child: _ClientNavItem(
                  label: 'Découvrir',
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  selected: navigationShell.currentIndex == 1,
                  onTap: () => _goBranch(1),
                ),
              ),
              SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Mes RDV',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            fabActive ? FontWeight.w600 : FontWeight.w400,
                        color: fabActive ? AppColors.blanc : AppColors.gris,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ClientNavItem(
                  label: 'Profil',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  selected: navigationShell.currentIndex == 3,
                  onTap: () => _goBranch(3),
                ),
              ),
            ],
          ),
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
    final color = selected ? AppColors.blanc : AppColors.gris;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
