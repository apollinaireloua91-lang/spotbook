import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/client/presentation/shell/client_nav_bar.dart';
import '../shared/theme/app_colors.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell>
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
  void didUpdateWidget(covariant ClientShell oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: widget.navigationShell,
      ),
      bottomNavigationBar:
          ClientNavBar(navigationShell: widget.navigationShell),
    );
  }
}
