import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

import 'router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/utils/analytics_service.dart';

class SpotbookApp extends StatefulWidget {
  const SpotbookApp({super.key});

  @override
  State<SpotbookApp> createState() => _SpotbookAppState();
}

class _SpotbookAppState extends State<SpotbookApp> {
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
    return MaterialApp.router(
      title: 'Spotbook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
