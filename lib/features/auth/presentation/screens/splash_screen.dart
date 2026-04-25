import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../../router/user_role_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/auth_repository.dart';

/// Même clé que côté `OnboardingScreen._complete()`. SharedPreferences
/// depuis la migration 2026-04-21, Hive comme fallback legacy.
const _onboardingSeenKey = 'onboarding_seen';

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
      // pour quelqu'un qui n'a jamais vu l'onboarding.
      //
      // Stockage du flag (depuis la migration 2026-04-21) :
      //   1. SharedPreferences (source de vérité, NSUserDefaults iOS /
      //      SharedPreferences Android). Purgé à la désinstallation.
      //   2. Hive box 'settings' → lecture fallback pour les users qui
      //      ont complété l'onboarding AVANT la migration : si Prefs est
      //      vide mais Hive dit vu, on propage vers Prefs et on évite de
      //      réafficher l'onboarding inutilement. Sinon (les deux vides)
      //      → vrai fresh install → onboarding.
      final prefs = await SharedPreferences.getInstance();
      bool onboardingSeen = prefs.getBool(_onboardingSeenKey) ?? false;
      if (!onboardingSeen) {
        final hiveSeen = Hive.box('settings')
            .get(_onboardingSeenKey, defaultValue: false) as bool;
        if (hiveSeen) {
          // Migration one-shot Hive → SharedPreferences.
          await prefs.setBool(_onboardingSeenKey, true);
          onboardingSeen = true;
        }
      }
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

      // Lecture AUTORITAIRE depuis public.users.role (et non
      // userMetadata['role'], qui est NULL pour les inscriptions Google/
      // Apple OAuth — cf. docs/AUTH_SECURITY_AUDIT.md bug 7a). Le résultat
      // est aussi pushé dans userRoleProvider pour que le router (qui doit
      // redirect en sync via refreshListenable) lise la même valeur.
      final role = await repo.fetchUserRoleAuthoritative();
      ref.read(userRoleProvider.notifier).setRole(role);

      if (!mounted) return;
      switch (role) {
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
