import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

/// Barre de navigation basse du shell client (4 onglets, pas de caméra).
///
/// Chaque icône scale up quand sélectionnée + un point lumineux glisse
/// sous l'onglet actif (indicateur animé).
class ClientNavBar extends StatelessWidget {
  const ClientNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItemData>[
    _NavItemData(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Feed'),
    _NavItemData(Icons.search_outlined, Icons.search_rounded, 'Search'),
    _NavItemData(
        Icons.calendar_today_outlined, Icons.calendar_today, 'Bookings'),
    _NavItemData(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final idx = navigationShell.currentIndex;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 68 + bottomInset,
          decoration: BoxDecoration(
            color: AppColors.fond.withAlpha(230),
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Stack(
                children: [
                  // Sliding indicator dot
                  _SlidingIndicator(
                    currentIndex: idx,
                    itemCount: _items.length,
                  ),
                  // Nav items row
                  Row(
                    children: List.generate(_items.length, (i) {
                      return Expanded(
                        child: _AnimatedNavItem(
                          data: _items[i],
                          selected: idx == i,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            navigationShell.goBranch(
                              i,
                              initialLocation:
                                  i == navigationShell.currentIndex,
                            );
                          },
                        ),
                      );
                    }),
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

// ── Data model ───────────────────────────────────────────────────────────────

class _NavItemData {
  const _NavItemData(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ── Sliding indicator ────────────────────────────────────────────────────────

class _SlidingIndicator extends StatelessWidget {
  const _SlidingIndicator({
    required this.currentIndex,
    required this.itemCount,
  });

  final int currentIndex;
  final int itemCount;

  static const _kPillWidth = 32.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / itemCount;
        final left = itemWidth * currentIndex + (itemWidth - _kPillWidth) / 2;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          top: 0,
          left: left,
          child: Container(
            width: _kPillWidth,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: AppColors.gradientAccent,
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withAlpha(160),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.rose.withAlpha(60),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Animated nav item ────────────────────────────────────────────────────────

class _AnimatedNavItem extends StatefulWidget {
  const _AnimatedNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleCtrl.reverse();
  void _onTapUp(TapUpDetails _) => _scaleCtrl.forward();
  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                widget.selected ? widget.data.activeIcon : widget.data.icon,
                key: ValueKey(widget.selected),
                color: widget.selected ? AppColors.violet : AppColors.grisInactif,
                size: widget.selected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: widget.selected
                    ? AppColors.violet
                    : AppColors.grisInactif,
                fontSize: 10,
                fontWeight:
                    widget.selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: widget.selected ? 0.2 : 0,
              ),
              child: Text(widget.data.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
