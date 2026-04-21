import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/realtime/realtime_bootstrap.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'shared/locale/app_locale_notifier.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';
import 'shared/utils/analytics_service.dart';

class SpotbookApp extends ConsumerStatefulWidget {
  const SpotbookApp({super.key});

  @override
  ConsumerState<SpotbookApp> createState() => _SpotbookAppState();
}

class _SpotbookAppState extends ConsumerState<SpotbookApp> {
  bool _bootstrapped = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        appRouter.go('/reset-password');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    Future.microtask(() async {
      await AnalyticsService.instance.initializeIfConsented();
      await AnalyticsService.instance.capture('app_opened');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep realtime alive for the entire app session
    ref.watch(realtimeBootstrapProvider);

    final locale = ref.watch(appLocaleProvider);
    // Le light mode a été retiré (2026-04-21). On force dark partout :
    //   - AppColors.brightness pilote la palette runtime (AppColors.fond,
    //     AppColors.blanc, etc.) — verrouillé sur Brightness.dark.
    //   - themeMode côté MaterialApp est fixé à ThemeMode.dark pour que les
    //     widgets Material (AppBar, CupertinoAlertDialog, etc.) ne tentent
    //     pas de basculer selon la préférence système.
    // Voir `theme_mode_notifier.dart` pour la migration du flag Hive.
    AppColors.brightness = Brightness.dark;

    return MaterialApp.router(
      title: 'Spotbook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
