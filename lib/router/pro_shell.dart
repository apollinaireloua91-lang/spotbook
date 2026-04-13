import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_colors.dart';

/// Pro Shell — 5 tabs with premium floating glassmorphism nav bar.
///
/// Feed | Dashboard | ✦ Camera (elevated) | RDV | Profil
///
/// The camera button floats above the bar with a neon-glow gradient ring,
/// giving the nav bar a distinctive $20M+ app feel.
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
    final current = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _PremiumProNavBar(
        currentIndex: current,
        bottomInset: bottomInset,
        onTap: _goBranch,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM FLOATING NAV BAR
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumProNavBar extends StatelessWidget {
  const _PremiumProNavBar({
    required this.currentIndex,
    required this.bottomInset,
    required this.onTap,
  });

  final int currentIndex;
  final double bottomInset;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Extra bottom padding: safe area + breathing room
    final totalBottom = bottomInset + 8;

    return Container(
      height: 80 + totalBottom,
      padding: EdgeInsets.only(bottom: totalBottom),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Floating glass bar ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.isDark
                        ? Colors.black.withAlpha(180)
                        : Colors.white.withAlpha(210),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.isDark
                          ? Colors.white.withAlpha(18)
                          : Colors.black.withAlpha(8),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.isDark
                            ? AppColors.violet.withAlpha(20)
                            : Colors.black.withAlpha(15),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, 8),
                      ),
                      if (AppColors.isDark)
                        BoxShadow(
                          color: AppColors.violet.withAlpha(8),
                          blurRadius: 60,
                          spreadRadius: 0,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 0 — Feed
                      _PremiumNavItem(
                        label: 'Feed',
                        icon: Icons.play_circle_outline_rounded,
                        activeIcon: Icons.play_circle_rounded,
                        selected: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      // 1 — Dashboard
                      _PremiumNavItem(
                        label: 'Dashboard',
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view_rounded,
                        selected: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                      // 2 — Camera (spacer — the actual button floats above)
                      const SizedBox(width: 72),
                      // 3 — RDV
                      _PremiumNavItem(
                        label: 'Agenda',
                        icon: Icons.calendar_today_outlined,
                        activeIcon: Icons.calendar_today_rounded,
                        selected: currentIndex == 3,
                        onTap: () => onTap(3),
                      ),
                      // 4 — Profil
                      _PremiumNavItem(
                        label: 'Profil',
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        selected: currentIndex == 4,
                        onTap: () => onTap(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Elevated camera button — floats above the bar ──
          Positioned(
            bottom: 22,
            child: _ElevatedCameraButton(
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM NAV ITEM — animated gradient pill indicator
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumNavItem extends StatelessWidget {
  const _PremiumNavItem({
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animated size/color
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? AppColors.violet : AppColors.grisInactif,
                size: selected ? 26 : 23,
              ),
            ),
            const SizedBox(height: 4),
            // Animated gradient pill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: selected ? 20 : 0,
              height: selected ? 3 : 0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: selected ? AppColors.gradientAccent : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(120),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ]
                    : [],
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
                letterSpacing: selected ? 0.3 : 0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ELEVATED CAMERA BUTTON — neon glow + gradient ring + scale animation
// ═════════════════════════════════════════════════════════════════════════════

class _ElevatedCameraButton extends StatefulWidget {
  const _ElevatedCameraButton({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ElevatedCameraButton> createState() => _ElevatedCameraButtonState();
}

class _ElevatedCameraButtonState extends State<_ElevatedCameraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientAccent,
              boxShadow: [
                // Neon outer glow — pulses
                BoxShadow(
                  color: AppColors.violet
                      .withAlpha((60 * _glowAnim.value).round()),
                  blurRadius: 24 * _glowAnim.value,
                  spreadRadius: 2,
                ),
                // Deep shadow for depth
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.isDark
                    ? Colors.white.withAlpha(30)
                    : Colors.white.withAlpha(180),
                width: 2,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                widget.isSelected
                    ? Icons.close_rounded
                    : Icons.videocam_rounded,
                key: ValueKey(widget.isSelected),
                color: Colors.white,
                size: 26,
                shadows: const [
                  Shadow(color: Colors.black38, blurRadius: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
