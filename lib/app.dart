import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

import 'router/app_router.dart';
import 'shared/theme/app_theme.dart';

class SpotbookApp extends StatelessWidget {
  const SpotbookApp({super.key});

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
