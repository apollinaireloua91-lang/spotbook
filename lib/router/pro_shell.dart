import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_colors.dart';

class ProShell extends StatelessWidget {
  const ProShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.fond,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.blanc,
          unselectedItemColor: AppColors.gris,
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Recherche',
            ),
            BottomNavigationBarItem(
              icon: _CameraTabIcon(),
              activeIcon: _CameraTabIcon(),
              label: 'Caméra',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'RDV',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Événements',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil Pro',
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraTabIcon extends StatelessWidget {
  const _CameraTabIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: const CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.blanc,
        child: Icon(Icons.videocam, color: AppColors.fond, size: 24),
      ),
    );
  }
}
