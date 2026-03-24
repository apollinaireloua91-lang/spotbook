import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _controller.addStatusListener(_onAnimationDone);
  }

  Future<void> _onAnimationDone(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _redirect();
  }

  void _redirect() {
    final repo = ref.read(authRepositoryProvider);
    if (!repo.hasActiveSession) {
      context.go('/onboarding');
      return;
    }
    switch (repo.currentUserRole) {
      case 'client':
        context.go('/client');
      case 'pro':
        context.go('/pro');
      default:
        context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationDone);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Image.asset('assets/images/logo_white.png', width: 160),
        ),
      ),
    );
  }
}
