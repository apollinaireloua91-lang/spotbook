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
    return const Locale('fr');
  }

  Future<void> _hydrate() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final code = box.get(_key, defaultValue: 'fr') ?? 'fr';
      state = Locale(code == 'en' ? 'en' : 'fr');
    } catch (_) {
      state = const Locale('fr');
    }
  }

  Future<void> changeLocale(String languageCode) async {
    final locale = languageCode == 'en' ? const Locale('en') : const Locale('fr');
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, locale.languageCode);
    state = locale;
  }
}
