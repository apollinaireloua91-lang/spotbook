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
              fabActive ? Icons.videocam : Icons.videocam_outlined,
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
                child: _ProNavItem(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  selected: navigationShell.currentIndex == 0,
                  onTap: () => _goBranch(0),
                ),
              ),
              Expanded(
                child: _ProNavItem(
                  label: 'Recherche',
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
                      'Caméra',
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
                child: _ProNavItem(
                  label: 'RDV',
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  selected: navigationShell.currentIndex == 3,
                  onTap: () => _goBranch(3),
                ),
              ),
              Expanded(
                child: _ProNavItem(
                  label: 'Événements',
                  icon: Icons.event_outlined,
                  activeIcon: Icons.event,
                  selected: navigationShell.currentIndex == 4,
                  onTap: () => _goBranch(4),
                ),
              ),
              Expanded(
                child: _ProNavItem(
                  label: 'Profil Pro',
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront,
                  selected: navigationShell.currentIndex == 5,
                  onTap: () => _goBranch(5),
                ),
              ),
            ],
          ),
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
    final color = selected ? AppColors.blanc : AppColors.gris;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
