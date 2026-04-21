import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Le light mode a été retiré de l'app (2026-04-21). Ce notifier ne contrôle
// plus qu'un seul état (`ThemeMode.dark`) et conserve son API publique
// (`toggle`, `isDark`) pour éviter de casser les call sites existants —
// le toggle devient un no-op silencieux. Toute UI permettant de basculer
// a été retirée des écrans de profil.
//
// Pourquoi dark-only : direction design — « le dark est plus cool et plus
// attirant », confirmé par Papy. Si un jour on revient sur un toggle, il
// suffit de rétablir la lecture Hive et de réactiver le branchement UI.

const _boxName = 'settings';
const _key = 'theme_mode';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Migration one-shot : on normalise la valeur persistée à 'dark'.
    // Ça évite qu'une ancienne valeur 'light' ne réapparaisse si on
    // revenait à la lecture Hive plus tard. Coût négligeable, Hive est
    // déjà ouvert à ce stade (main.dart L109).
    final box = Hive.box(_boxName);
    if (box.get(_key) != 'dark') {
      box.put(_key, 'dark');
    }
    return ThemeMode.dark;
  }

  /// No-op — le light mode n'est plus supporté. Conservé pour la compat API.
  void toggle() {
    // Intentionnel : on ne modifie plus l'état.
  }

  bool get isDark => true;
}
