import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/auth_repository.dart';
import '../../data/user_setup_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _loaderOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo: fade in + scale 0.8→1.0 (0% → 40%)
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Tagline: fade + slide up (30% → 65%)
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Loader: fade in (55% → 80%)
    _loaderOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _controller.addStatusListener(_onAnimationDone);
  }

  Future<void> _onAnimationDone(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await _redirect();
  }

  Future<void> _redirect() async {
    final repo = ref.read(authRepositoryProvider);
    if (!repo.hasActiveSession) {
      context.go('/onboarding');
      return;
    }

    // Ensure users row exists (handles Google OAuth first-time login)
    try {
      await ref.read(userSetupRepositoryProvider).setupNewUser();
    } catch (e) {
      debugPrint('[splash] setupNewUser ignored: $e');
    }

    if (!mounted) return;

    // Re-read profile from DB to get actual role
    final profile = await repo.getUserProfile();
    if (!mounted) return;

    final role = profile?['role'] as String?;
    switch (role) {
      case 'client':
        context.go('/client');
      case 'pro':
        context.go('/pro');
      default:
        context.go('/complete-profile');
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.1,
            colors: [
              AppColors.violet.withAlpha(65),
              AppColors.fond,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo animé (fade + scale) avec halo ambiant
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Halo violet derrière le logo
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.violet.withAlpha(45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/logo_white.png',
                          width: 160,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline animée (fade + slide up)
                Opacity(
                  opacity: _taglineOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _taglineSlide.value),
                    child: const Text(
                      'Réserve. Découvre. Vibre.',
                      style: TextStyle(
                        color: AppColors.grisClair,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Loader animé
                Opacity(
                  opacity: _loaderOpacity.value,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.violetClair,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
