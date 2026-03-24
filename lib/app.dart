import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';

import 'router/app_router.dart';
import 'shared/locale/app_locale_notifier.dart';
import 'shared/theme/app_theme.dart';
import 'shared/utils/analytics_service.dart';

class SpotbookApp extends ConsumerStatefulWidget {
  const SpotbookApp({super.key});

  @override
  ConsumerState<SpotbookApp> createState() => _SpotbookAppState();
}

class _SpotbookAppState extends ConsumerState<SpotbookApp> {
  bool _bootstrapped = false;

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
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'Spotbook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
