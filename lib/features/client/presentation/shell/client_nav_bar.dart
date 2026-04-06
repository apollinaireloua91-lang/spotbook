import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

/// Premium glassmorphism nav bar — 4 tabs, no camera.
/// Active: white icon + 4px gradient dot. Inactive: muted grey icon.
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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70 + bottomInset,
          decoration: BoxDecoration(
            color: AppColors.fond.withAlpha(235),
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  return Expanded(
                    child: _NavItem(
                      data: _items[i],
                      selected: idx == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        navigationShell.goBranch(
                          i,
                          initialLocation: i == navigationShell.currentIndex,
                        );
                      },
                    ),
                  );
                }),
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

// ── Nav item with dot indicator ─────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
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
            // Icon
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
                color: widget.selected ? AppColors.blanc : AppColors.grisInactif,
                size: widget.selected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            // Subtle label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: widget.selected
                    ? AppColors.blanc.withAlpha(179)
                    : AppColors.grisInactif,
                fontSize: 10,
                fontWeight:
                    widget.selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: widget.selected ? 0.2 : 0,
              ),
              child: Text(widget.data.label, maxLines: 1),
            ),
            const SizedBox(height: 4),
            // Dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: widget.selected ? 4 : 0,
              height: widget.selected ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected ? AppColors.blanc : Colors.transparent,
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: AppColors.blanc.withAlpha(100),
                          blurRadius: 6,
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
