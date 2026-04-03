import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _controller.addStatusListener(_onAnimDone);
  }

  Future<void> _onAnimDone(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _redirect();
  }

  Future<void> _redirect() async {
    try {
      final repo = ref.read(authRepositoryProvider);

      if (!repo.hasActiveSession) {
        // Use the already-opened untyped box from main.dart
        final box = Hive.box('settings');
        final seen = box.get('onboarding_seen', defaultValue: false) == true;
        if (!mounted) return;
        context.go(seen ? '/login' : '/onboarding');
        return;
      }

      if (!mounted) return;
      switch (repo.currentUserRole) {
        case 'client':
          context.go('/client/feed');
        case 'pro':
          context.go('/pro/dashboard');
        default:
          context.go('/select-account-type');
      }
    } catch (e) {
      debugPrint('Splash redirect error: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimDone);
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
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
            ),
          ),
        ),
      ),
    );
  }
}
