import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persistance Hive + mise à jour immédiate de l’UI (équivalent demandé : LocaleCubit).
final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

class AppLocaleNotifier extends Notifier<Locale> {
  static const _boxName = 'app_settings';
  static const _key = 'locale';

  bool _scheduled = false;

  @override
  Locale build() {
    if (!_scheduled) {
      _scheduled = true;
      Future<void>.microtask(_hydrate);
    }
    // Français = défaut produit (CLAUDE.md). On ne laisse JAMAIS l'app démarrer
    // en anglais sur un iPhone dont la langue système est EN — Spotbook est
    // une app francophone-first (FR/CA/CI). L'utilisateur peut basculer EN
    // via les paramètres, ce choix est persisté dans Hive et ré-appliqué
    // au prochain lancement via _hydrate().
    return const Locale('fr');
  }

  Future<void> _hydrate() async {
    try {
      final box = Hive.box<String>(_boxName);
      final code = box.get(_key, defaultValue: 'fr') ?? 'fr';
      state = Locale(code == 'en' ? 'en' : 'fr');
    } catch (_) {
      state = const Locale('fr');
    }
  }

  Future<void> changeLocale(String languageCode) async {
    final locale = languageCode == 'en' ? const Locale('en') : const Locale('fr');
    final box = Hive.box<String>(_boxName);
    await box.put(_key, locale.languageCode);
    state = locale;
  }
}
