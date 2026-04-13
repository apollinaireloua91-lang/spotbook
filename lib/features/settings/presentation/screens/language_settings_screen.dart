import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/locale/app_locale_notifier.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/spotbook_card.dart';

/// Sélection FR / EN — persistance via [AppLocaleNotifier] (Hive), appliquée à [MaterialApp.router].
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);

    Future<void> pick(String code) async {
      HapticFeedback.selectionClick();
      await ref.read(appLocaleProvider.notifier).changeLocale(code);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            l10n.settingsLanguageSavedSnack,
            style: TextStyle(color: AppColors.blanc),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l10n.cancel,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          l10n.settingsLanguageScreenTitle,
          style: AppTypography.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            l10n.settingsLanguageScreenSubtitle,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SpotbookCard.highlight(
            selected: locale.languageCode == 'fr',
            onTap: () => pick('fr'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.proSettingsLangFrench,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (locale.languageCode == 'fr')
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.violet,
                    size: 26,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SpotbookCard.highlight(
            selected: locale.languageCode == 'en',
            onTap: () => pick('en'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.proSettingsLangEnglish,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (locale.languageCode == 'en')
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.violet,
                    size: 26,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
