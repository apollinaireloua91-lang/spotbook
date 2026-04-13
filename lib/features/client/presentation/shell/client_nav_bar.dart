import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';

/// Premium client nav bar — 4 tabs, no camera, glassmorphism.
/// Active: violet icon in glowing pill + bold label. Inactive: muted grey.
class ClientNavBar extends StatelessWidget {
  const ClientNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItemData>[
    _NavItemData(
        Icons.play_circle_outline_rounded, Icons.play_circle_rounded, 'Feed'),
    _NavItemData(
        Icons.search_rounded, Icons.search_rounded, 'Recherche'),
    _NavItemData(
        Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Mes RDV'),
    _NavItemData(
        Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final idx = navigationShell.currentIndex;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 72 + bottomInset,
          decoration: BoxDecoration(
            color: AppColors.glass,
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
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

// ── Nav item with premium pill indicator ─────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in animated pill container
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 16 : 12,
              vertical: selected ? 7 : 6,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.violet.withAlpha(22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(
                      color: AppColors.violet.withAlpha(30),
                      width: 0.5,
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(20),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                selected ? data.activeIcon : data.icon,
                key: ValueKey(selected),
                color: selected ? AppColors.violet : AppColors.grisInactif,
                size: selected ? 23 : 21,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: GoogleFonts.dmSans(
              color: selected ? AppColors.violet : AppColors.grisInactif,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: selected ? 0.1 : 0,
            ),
            child: Text(data.label, maxLines: 1),
          ),
        ],
      ),
    );
  }
}
