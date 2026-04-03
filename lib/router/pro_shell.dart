import 'dart:math';
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
    final cameraActive = navigationShell.currentIndex == 2;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fond,
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.navBarBg,
              border: Border(
                top: BorderSide(color: AppColors.surface, width: 1),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              height: 66,
              child: Row(
                children: [
                  // ── Left: Feed + Recherche ──
                  _ProNavItem(
                    label: 'Feed',
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    selected: navigationShell.currentIndex == 0,
                    onTap: () => _goBranch(0),
                  ),
                  _ProNavItem(
                    label: 'Recherche',
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search,
                    selected: navigationShell.currentIndex == 1,
                    onTap: () => _goBranch(1),
                  ),
                  // ── Center: Camera FAB ──
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CameraFab(
                          isActive: cameraActive,
                          onTap: () => _goBranch(2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Caméra',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                cameraActive ? FontWeight.w600 : FontWeight.w400,
                            color:
                                cameraActive ? AppColors.blanc : AppColors.gris,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Right: RDV + Profil ──
                  _ProNavItem(
                    label: 'RDV',
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    selected: navigationShell.currentIndex == 3,
                    onTap: () => _goBranch(3),
                  ),
                  _ProNavItem(
                    label: 'Profil',
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    selected: navigationShell.currentIndex == 4,
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

/// Camera FAB — 48px white circle, surélevé -8px, spring scale + rotationZ.
class _CameraFab extends StatefulWidget {
  const _CameraFab({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_CameraFab> createState() => _CameraFabState();
}

class _CameraFabState extends State<_CameraFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Transform.rotate(
                angle: _rotation.value * (pi / 180),
                child: child,
              ),
            );
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blanc,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(77), // 0.3 opacity
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.isActive ? Icons.videocam : Icons.videocam_outlined,
              color: AppColors.fond,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nav item with micro-bounce animation on tap.
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
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
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
    final color = widget.selected ? AppColors.blanc : AppColors.gris;
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
              child: Icon(
                widget.selected ? widget.activeIcon : widget.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
