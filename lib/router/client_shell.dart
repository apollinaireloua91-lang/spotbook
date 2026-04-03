import 'dart:ui';

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

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fond,
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.fond.withAlpha(242), // ~0.95 opacity
              border: const Border(
                top: BorderSide(color: AppColors.surface, width: 1),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _ClientNavItem(
                    label: 'Feed',
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view,
                    selected: navigationShell.currentIndex == 0,
                    onTap: () => _goBranch(0),
                  ),
                  _ClientNavItem(
                    label: 'Search',
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search,
                    selected: navigationShell.currentIndex == 1,
                    onTap: () => _goBranch(1),
                  ),
                  _ClientNavItem(
                    label: 'Bookings',
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    selected: navigationShell.currentIndex == 2,
                    onTap: () => _goBranch(2),
                  ),
                  _ClientNavItem(
                    label: 'Profile',
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    selected: navigationShell.currentIndex == 3,
                    onTap: () => _goBranch(3),
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

/// Nav item avec animation micro-bounce 1→1.15→1 au tap.
class _ClientNavItem extends StatefulWidget {
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
  State<_ClientNavItem> createState() => _ClientNavItemState();
}

class _ClientNavItemState extends State<_ClientNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) => Transform.scale(
                scale: _bounceAnimation.value,
                child: child,
              ),
              child: Icon(
                widget.selected ? widget.activeIcon : widget.icon,
                color:
                    widget.selected ? AppColors.blanc : AppColors.grisInactif,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: TextStyle(
                color:
                    widget.selected ? AppColors.blanc : AppColors.grisInactif,
                fontSize: 9,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
