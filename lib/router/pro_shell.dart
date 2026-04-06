import 'dart:ui';

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

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fond,
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.fond.withAlpha(230),
              border: Border(
                top: BorderSide(
                  color: AppColors.violet.withAlpha(20),
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              height: 68,
              child: Row(
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
          ),
        ),
      ),
    );
  }
}

/// Nav item with micro-bounce + gradient active dot indicator.
class _ProNavItem extends StatefulWidget {
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
  State<_ProNavItem> createState() => _ProNavItemState();
}

class _ProNavItemState extends State<_ProNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.12), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceCtrl.forward(from: 0);
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
              animation: _bounceScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceScale.value,
                  child: child,
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.selected ? widget.activeIcon : widget.icon,
                  key: ValueKey(widget.selected),
                  color: widget.selected ? AppColors.violet : AppColors.gris,
                  size: 23,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: widget.selected ? AppColors.violet : AppColors.gris,
                fontSize: 10,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: widget.selected ? 0.2 : 0,
              ),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Gradient dot indicator with glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: widget.selected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: widget.selected ? AppColors.gradientAccent : null,
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(120),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
