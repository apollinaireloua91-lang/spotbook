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
        height: 68,
        decoration: const BoxDecoration(
          color: AppColors.fond,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Tabs 0, 1, 2 (Feed, Search, Camera)
            Expanded(
              child: _buildNav(
                context,
                tabs: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dynamic_feed_outlined),
                    activeIcon: Icon(Icons.dynamic_feed),
                    label: 'Feed',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_outlined),
                    activeIcon: Icon(Icons.search),
                    label: 'Recherche',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.videocam_outlined),
                    activeIcon: Icon(Icons.videocam),
                    label: 'Caméra',
                  ),
                ],
                startIndex: 0,
              ),
            ),
            // 1px vertical divider between tab 3 and 4
            Container(
              width: 1,
              height: 40,
              color: AppColors.border,
            ),
            // Tabs 3, 4, 5 (Bookings, Events, Profile)
            Expanded(
              child: _buildNav(
                context,
                tabs: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today),
                    label: 'RDV',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.confirmation_number_outlined),
                    activeIcon: Icon(Icons.confirmation_number),
                    label: 'Événements',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil Pro',
                  ),
                ],
                startIndex: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNav(
    BuildContext context, {
    required List<BottomNavigationBarItem> tabs,
    required int startIndex,
  }) {
    final currentIndex = navigationShell.currentIndex;
    final relativeIndex = currentIndex - startIndex;
    final isInGroup = relativeIndex >= 0 && relativeIndex < tabs.length;

    return BottomNavigationBar(
      backgroundColor: AppColors.fond,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.blanc,
      unselectedItemColor: AppColors.gris,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      currentIndex: isInGroup ? relativeIndex : 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: (relIdx) {
        final globalIdx = startIndex + relIdx;
        HapticFeedback.selectionClick();
        navigationShell.goBranch(
          globalIdx,
          initialLocation: globalIdx == currentIndex,
        );
      },
      items: tabs
          .asMap()
          .map((i, tab) {
            final isSelected = isInGroup && i == relativeIndex;
            return MapEntry(
              i,
              BottomNavigationBarItem(
                icon: isSelected ? tab.activeIcon : tab.icon,
                activeIcon: tab.activeIcon,
                label: tab.label,
              ),
            );
          })
          .values
          .toList(),
    );
  }
}
