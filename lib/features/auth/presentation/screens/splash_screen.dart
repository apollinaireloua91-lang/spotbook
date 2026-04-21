import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset(
      'assets/video/splash_animation.mp4',
    );

    try {
      await _controller.initialize();
      _controller.setLooping(false);
      _controller.setVolume(0);

      if (!mounted) return;
      setState(() => _initialized = true);

      _controller.addListener(_onVideoProgress);
      _controller.play();
    } catch (e) {
      debugPrint('Splash video init error: $e');
      // Video failed — navigate immediately
      _navigateNext();
    }

    // Safety timeout — navigate after 5s even if video hasn't finished
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted) _navigateNext();
    });
  }

  void _onVideoProgress() {
    final value = _controller.value;
    if (value.position >= value.duration && value.duration > Duration.zero) {
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    try {
      // Onboarding gate — doit être checké AVANT la session. Sur iOS, le
      // token Supabase est persisté dans le Keychain et survit à la
      // désinstallation, donc `hasActiveSession` peut être `true` même
      // pour quelqu'un qui n'a jamais vu l'onboarding. Hive, lui, vit dans
      // le container de l'app et est correctement wipé à la désinstallation.
      // `OnboardingScreen._complete()` écrit `onboarding_seen = true` sur
      // skip ET completion — symétrie assurée.
      final settings = Hive.box('settings');
      final onboardingSeen =
          settings.get('onboarding_seen', defaultValue: false) as bool;
      if (!onboardingSeen) {
        if (!mounted) return;
        context.go('/onboarding');
        return;
      }

      final repo = ref.read(authRepositoryProvider);

      if (!repo.hasActiveSession) {
        if (!mounted) return;
        context.go('/login');
        return;
      }

      if (!mounted) return;
      switch (repo.currentUserRole) {
        case 'client':
          context.go('/client/feed');
        case 'pro':
          context.go('/pro/feed');
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
    _controller.removeListener(_onVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Center(
        child: _initialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
