import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_colors.dart';
import '../shared/theme/app_typography.dart';

/// Shell prestataire — 5 onglets : Feed | Recherche | Caméra (central) | Agenda | Profil
class ProShell extends StatefulWidget {
  const ProShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ProShell> createState() => _ProShellState();
}

class _ProShellState extends State<ProShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant ProShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _previousIndex) {
      _previousIndex = newIndex;
      _fadeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _goBranch(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fond,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: _ProBottomBar(
        currentIndex: idx,
        onTap: _goBranch,
        onCameraTap: () => _showCreateSheet(context),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProCreateSheet(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BOTTOM NAV BAR — 5 slots with elevated central camera button
// ═════════════════════════════════════════════════════════════════════════════

class _ProBottomBar extends StatelessWidget {
  const _ProBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCameraTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 68 + bottomPad,
          decoration: BoxDecoration(
            color: AppColors.fond.withAlpha(242), // ~0.95
            border: const Border(
              top: BorderSide(color: AppColors.sheetSeparator, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  // Feed
                  Expanded(
                    child: _NavItem(
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view,
                      label: 'Feed',
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  // Recherche
                  Expanded(
                    child: _NavItem(
                      icon: Icons.search_outlined,
                      activeIcon: Icons.search,
                      label: 'Recherche',
                      selected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                  // Camera — elevated white circle
                  Expanded(child: _CameraButton(onTap: onCameraTap)),
                  // Agenda
                  Expanded(
                    child: _NavItem(
                      icon: Icons.calendar_today_outlined,
                      activeIcon: Icons.calendar_today,
                      label: 'Agenda',
                      selected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ),
                  // Profil
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Profil',
                      selected: currentIndex == 4,
                      onTap: () => onTap(4),
                    ),
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

// ── Central camera button with gradient + pulse glow ─────────────────────────

class _CameraButton extends StatefulWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CameraButton> createState() => _CameraButtonState();
}

class _CameraButtonState extends State<_CameraButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _tapCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.reverse(),
      onTapUp: (_) => _tapCtrl.forward(),
      onTapCancel: () => _tapCtrl.forward(),
      onTap: widget.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -8),
            child: ScaleTransition(
              scale: _tapCtrl,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientAccent,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet
                              .withAlpha((80 + 60 * _pulseAnim.value).toInt()),
                          blurRadius: 12 + 6 * _pulseAnim.value,
                          spreadRadius: 1 + 2 * _pulseAnim.value,
                        ),
                        BoxShadow(
                          color: AppColors.rose
                              .withAlpha((40 + 40 * _pulseAnim.value).toInt()),
                          blurRadius: 20 + 8 * _pulseAnim.value,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.blanc,
                      size: 26,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated nav item ────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _tapCtrl.reverse(),
      onTapUp: (_) => _tapCtrl.forward(),
      onTapCancel: () => _tapCtrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _tapCtrl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                widget.selected ? widget.activeIcon : widget.icon,
                key: ValueKey(widget.selected),
                color:
                    widget.selected ? AppColors.blanc : AppColors.grisInactif,
                size: widget.selected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color:
                    widget.selected ? AppColors.blanc : AppColors.grisInactif,
                fontSize: 10,
                fontWeight:
                    widget.selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRO CREATE SHEET — choose Video / Event / Service
// ═════════════════════════════════════════════════════════════════════════════

class _ProCreateSheet extends StatefulWidget {
  const _ProCreateSheet();

  @override
  State<_ProCreateSheet> createState() => _ProCreateSheetState();
}

class _ProCreateSheetState extends State<_ProCreateSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int index) {
    final start = (index * 0.15).clamp(0.0, 0.7);
    final end = (start + 0.5).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = <_CreateOptionData>[
      _CreateOptionData(
        Icons.videocam_rounded, 'Vidéo', AppColors.violet,
        () { context.pop(); context.push('/pro/camera'); },
      ),
      _CreateOptionData(
        Icons.qr_code_scanner_rounded, 'Scanner', AppColors.success,
        () { context.pop(); context.push('/pro/scanner'); },
      ),
      _CreateOptionData(
        Icons.celebration_rounded, 'Événement', AppColors.rose,
        () { context.pop(); context.push('/pro/events/create'); },
      ),
      _CreateOptionData(
        Icons.content_cut_rounded, 'Service', AppColors.violetClair,
        () { context.pop(); context.push('/pro/profile/services'); },
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Créer', style: AppTypography.sheetTitle),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < 2; i++)
                        _AnimatedCreateOption(
                          animation: _stagger(i),
                          data: options[i],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 2; i < 4; i++)
                        _AnimatedCreateOption(
                          animation: _stagger(i),
                          data: options[i],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CreateOptionData {
  const _CreateOptionData(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _AnimatedCreateOption extends StatefulWidget {
  const _AnimatedCreateOption({
    required this.animation,
    required this.data,
  });

  final Animation<double> animation;
  final _CreateOptionData data;

  @override
  State<_AnimatedCreateOption> createState() => _AnimatedCreateOptionState();
}

class _AnimatedCreateOptionState extends State<_AnimatedCreateOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return FadeTransition(
      opacity: widget.animation,
      child: ScaleTransition(
        scale: widget.animation,
        child: GestureDetector(
          onTapDown: (_) => _tapCtrl.reverse(),
          onTapUp: (_) => _tapCtrl.forward(),
          onTapCancel: () => _tapCtrl.forward(),
          onTap: () {
            HapticFeedback.lightImpact();
            d.onTap();
          },
          child: ScaleTransition(
            scale: _tapCtrl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: d.color.withAlpha(31),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: d.color.withAlpha(77), width: 1),
                  ),
                  child: Icon(d.icon, color: d.color, size: 30),
                ),
                const SizedBox(height: 10),
                Text(d.label, style: AppTypography.createSheetOptionLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
