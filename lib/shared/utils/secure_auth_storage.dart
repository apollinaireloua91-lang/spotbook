// ════════════════════════════════════════════════════════════════════════════
// secure_auth_storage.dart
// ────────────────────────────────────────────────────────────────────────────
// Le défaut de supabase_flutter persiste la session dans SharedPreferences
// (UserDefaults iOS, SharedPreferences Android en clair). Un device jailbreaké
// ou branché en ADB peut exfiltrer le refresh_token et impersonner l'user.
//
// Cet adapter force la persistance dans :
//   - iOS      : Keychain (Data Protection: first_unlock_this_device)
//   - Android  : flutter_secure_storage v10+ (ciphers AES Keystore-backed)
//
// Les deux sont liés au device : une restauration depuis iCloud/Google Drive
// n'importe pas la session. Couplé avec allowBackup="false" côté Android et
// `first_unlock_this_device` iOS, le token reste inaccessible même si le
// backup device-to-device est compromis.
//
// Migration (one-shot, idempotente) : à la première init, on lit l'ancienne
// session depuis SharedPreferences (clé "sb-<ref>-auth-token") et on la
// re-persiste dans Keychain/Keystore, puis on purge la copie clair. Un flag
// dédié stocké en Keychain (`_migrationCompleted`) évite de rejouer la
// migration à chaque launch (utile quand l'user logout puis relogin).
// Pas de re-login forcé pour l'user existant.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Options par défaut ─────────────────────────────────────────────────────
const IOSOptions _defaultIosOpts = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
);

const FlutterSecureStorage _defaultSecureStorage = FlutterSecureStorage(
  iOptions: _defaultIosOpts,
);

/// Flag Keychain indiquant que la migration SharedPreferences → secure a
/// été tentée au moins une fois avec succès. Évite de re-scanner
/// SharedPreferences à chaque boot.
const String _migrationCompletedKey = 'spotbook_auth_migration_done_v1';

/// Flag SharedPreferences (UserDefaults iOS / SharedPreferences Android)
/// indiquant que l'app a déjà été bootée une fois sur ce device.
///
/// Utilisé pour détecter une (ré)installation : iOS conserve le Keychain
/// entre les installs (comportement documenté Apple, pour préserver les
/// creds des password managers). Résultat : un iPhone revendu / rendu qui
/// avait Spotbook installé peut auto-logger le prochain user qui réinstalle.
/// SharedPreferences est wipé à la désinstallation → son absence = install
/// fraîche → purger la session Keychain laissée par l'installation précédente.
const String _freshInstallFlagKey = 'spotbook_install_marker_v1';

/// Nombre de tentatives max pour un write secure storage.
const int _writeRetryAttempts = 2;

/// Signature d'un callback optionnel pour remonter les erreurs (Sentry).
typedef ErrorReporter = void Function(Object error, StackTrace stack);

// ── Interface minimale pour tester ─────────────────────────────────────────
/// Abstraction testable au-dessus de FlutterSecureStorage. La prod utilise
/// [FlutterSecureStorageAdapter]. Les tests injectent un fake in-memory.
abstract class SecureKeyValueStore {
  Future<bool> containsKey({required String key});
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureStorageAdapter implements SecureKeyValueStore {
  const FlutterSecureStorageAdapter([
    this._storage = _defaultSecureStorage,
  ]);
  final FlutterSecureStorage _storage;

  @override
  Future<bool> containsKey({required String key}) =>
      _storage.containsKey(key: key);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

// ── Adapters Supabase ──────────────────────────────────────────────────────

/// Adapter `LocalStorage` (session auth JSON) backed by Keychain/Keystore.
class SecureAuthStorage extends LocalStorage {
  SecureAuthStorage({
    required this.persistSessionKey,
    SecureKeyValueStore? secureStorage,
    Future<SharedPreferences> Function()? sharedPrefsLoader,
    ErrorReporter? onError,
  })  : _secure = secureStorage ?? const FlutterSecureStorageAdapter(),
        _prefsLoader = sharedPrefsLoader ?? SharedPreferences.getInstance,
        _onError = onError;

  final String persistSessionKey;
  final SecureKeyValueStore _secure;
  final Future<SharedPreferences> Function() _prefsLoader;
  final ErrorReporter? _onError;

  @override
  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _migrateFromSharedPreferences();
  }

  /// Migration one-shot SharedPreferences → secure storage.
  ///
  /// Contrats :
  /// - Ne throw JAMAIS. Un échec catastrophique logue via [ErrorReporter] et
  ///   laisse l'user se re-loguer (dégât acceptable, rare).
  /// - Idempotente : flag `_migrationCompletedKey` posé en Keychain après
  ///   le premier passage réussi (ou no-op).
  /// - Si le write secure échoue, on retry [_writeRetryAttempts] fois puis on
  ///   abandonne sans effacer la copie SharedPreferences — l'user garde sa
  ///   session au prochain launch via l'ancien storage (Supabase fallback).
  @visibleForTesting
  Future<void> migrateForTesting() => _migrateFromSharedPreferences();

  Future<void> _migrateFromSharedPreferences() async {
    try {
      // Short-circuit si déjà fait. Flag dédié (pas la clé session) :
      // logout efface la session mais pas le flag, donc pas de re-scan.
      if (await _secure.containsKey(key: _migrationCompletedKey)) {
        return;
      }

      String? legacy;
      try {
        final prefs = await _prefsLoader();
        legacy = prefs.getString(persistSessionKey);
      } catch (error, stack) {
        // Lecture SharedPreferences cassée : on log, on marque la migration
        // comme faite (pour ne pas boucler), et l'user se relogue.
        _onError?.call(error, stack);
        await _tryMarkMigrationDone();
        return;
      }

      // Pas de legacy session → nouvel user ou migration déjà propre.
      if (legacy == null || legacy.isEmpty) {
        await _tryMarkMigrationDone();
        return;
      }

      // Write secure avec retry : les opérations Keychain peuvent échouer
      // ponctuellement (device verrouillé pendant un reboot warm).
      final written = await _writeWithRetry(
        key: persistSessionKey,
        value: legacy,
      );

      if (!written) {
        // Write impossible après retries → on laisse la copie SharedPreferences
        // intacte, Supabase retombera dessus via le prochain boot. Pas de
        // flag "migration done" pour qu'on retente plus tard.
        return;
      }

      // Purge la copie clair seulement après un write secure confirmé.
      try {
        final prefs = await _prefsLoader();
        await prefs.remove(persistSessionKey);
      } catch (error, stack) {
        // Pas fatal — la session secure est écrite, la copie clair survit
        // jusqu'au prochain boot. On log pour visibilité.
        _onError?.call(error, stack);
      }

      await _tryMarkMigrationDone();
    } catch (error, stack) {
      // Catch-all défensif : aucune exception ne doit remonter.
      _onError?.call(error, stack);
    }
  }

  Future<bool> _writeWithRetry({
    required String key,
    required String value,
  }) async {
    for (var attempt = 0; attempt < _writeRetryAttempts; attempt++) {
      try {
        await _secure.write(key: key, value: value);
        return true;
      } catch (error, stack) {
        final isLastAttempt = attempt == _writeRetryAttempts - 1;
        if (isLastAttempt) {
          _onError?.call(error, stack);
        }
      }
    }
    return false;
  }

  Future<void> _tryMarkMigrationDone() async {
    try {
      await _secure.write(key: _migrationCompletedKey, value: '1');
    } catch (error, stack) {
      // Flag non-posé → la migration sera re-tentée au prochain boot. Le
      // coût est une lecture SharedPreferences en plus, pas de corruption.
      _onError?.call(error, stack);
    }
  }

  @override
  Future<bool> hasAccessToken() =>
      _secure.containsKey(key: persistSessionKey);

  @override
  Future<String?> accessToken() => _secure.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _secure.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secure.write(key: persistSessionKey, value: persistSessionString);
}

/// Adapter `GotrueAsyncStorage` (stockage PKCE code_verifier) backed by
/// Keychain/Keystore. Le code_verifier est éphémère (1 seul tour du flux
/// OAuth) mais il protège contre l'interception du code d'autorisation, donc
/// il doit également être à l'abri d'un attaquant ayant un accès fichier.
class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage({SecureKeyValueStore? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorageAdapter();

  final SecureKeyValueStore _secure;

  @override
  Future<String?> getItem({required String key}) => _secure.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _secure.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) => _secure.delete(key: key);
}

/// Dérive la clé de session par défaut utilisée par supabase_flutter :
/// `sb-<project-ref>-auth-token`. On respecte le même format pour que la
/// migration fonctionne sans intervention manuelle.
String supabasePersistSessionKeyFromUrl(String supabaseUrl) {
  final host = Uri.parse(supabaseUrl).host;
  final projectRef = host.split('.').first;
  return 'sb-$projectRef-auth-token';
}

/// Purge la session Keychain/Keystore à la première installation de l'app
/// sur un device.
///
/// CONTEXTE — Le Keychain iOS survit à la désinstallation d'une app (c'est
/// voulu par Apple pour les password managers). Notre adapter
/// [SecureAuthStorage] y stocke le refresh_token Supabase avec
/// `first_unlock_this_device` → un user qui désinstalle + réinstalle voit
/// sa session ressurgir sans jamais repasser par /login. Pire : un iPhone
/// revendu ou rendu peut auto-logger le nouveau propriétaire.
///
/// MÉCANIQUE — SharedPreferences (UserDefaults iOS / xml Android) EST wipé
/// à la désinstallation. On pose un flag [_freshInstallFlagKey] dedans la
/// première fois qu'on boote avec succès. Si à un boot suivant ce flag est
/// absent, c'est qu'on vient d'être (ré)installé → purger le Keychain avant
/// que Supabase.initialize() ne rehydrate la session fantôme.
///
/// APPEL — AVANT `Supabase.initialize` dans `main()`. Idempotente (no-op
/// si le flag est déjà posé). Ne throw jamais.
///
/// On purge :
///   - la clé session Supabase (`persistSessionKey`)
///   - le flag de migration SharedPreferences→Keychain (pour forcer un
///     re-scan propre si l'user re-logue plus tard)
Future<void> clearAuthKeychainIfFreshInstall({
  required String persistSessionKey,
  SecureKeyValueStore? secureStorage,
  Future<SharedPreferences> Function()? sharedPrefsLoader,
  ErrorReporter? onError,
}) async {
  final secure = secureStorage ?? const FlutterSecureStorageAdapter();
  final loadPrefs = sharedPrefsLoader ?? SharedPreferences.getInstance;

  try {
    final prefs = await loadPrefs();
    if (prefs.getBool(_freshInstallFlagKey) == true) {
      return; // Pas une install fraîche
    }

    // Install fraîche (ou première exécution après update apportant ce code).
    // On efface explicitement les clés qu'on POSSÈDE — pas un delete_all qui
    // toucherait des entrées d'autres bundles/apps sur le même Keychain
    // access group.
    try {
      await secure.delete(key: persistSessionKey);
    } catch (error, stack) {
      onError?.call(error, stack);
    }
    try {
      await secure.delete(key: _migrationCompletedKey);
    } catch (error, stack) {
      onError?.call(error, stack);
    }

    // Poser le marqueur APRÈS la purge. Si la purge crash, on retentera au
    // prochain boot. L'utilisateur verra une session fantôme une seule fois
    // pire cas, pas indéfiniment.
    await prefs.setBool(_freshInstallFlagKey, true);
  } catch (error, stack) {
    onError?.call(error, stack);
  }
}
