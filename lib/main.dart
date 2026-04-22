import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/widgets/spotbook_video_player.dart';
import 'shared/utils/secure_auth_storage.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Remonte une erreur vers Sentry si initialisé. Safe à appeler avant
/// SentryFlutter.init (no-op silencieux).
void _reportError(Object error, StackTrace stack) {
  try {
    Sentry.captureException(error, stackTrace: stack);
  } catch (_) {
    // Sentry pas encore init ou déjà teardown — on ignore.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Light mode — dark status bar icons on light background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // ── Secrets requis au démarrage ──────────────────────────────────────────
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL or SUPABASE_ANON_KEY is empty.\n'
      'Run with: flutter run --dart-define-from-file=.env.json',
    );
  }

  // Release builds MUST have Sentry DSN (monitoring obligatoire en prod).
  // En debug/profile, DSN vide = Sentry désactivé (dev local).
  if (kReleaseMode && sentryDsn.isEmpty) {
    throw StateError(
      'SENTRY_DSN must be provided via --dart-define in release builds. '
      'Monitoring crash est requis pour la production. Vérifier .env.json.',
    );
  }

  // Release builds MUST have Stripe publishable key.
  if (kReleaseMode && stripeKey.isEmpty) {
    throw StateError(
      'STRIPE_PUBLISHABLE_KEY is empty in release build — '
      'paiements désactivés. Vérifier .env.json.',
    );
  }

  // ── Bootstrap commun ─────────────────────────────────────────────────────
  // Tout ce qui peut throw pendant le bootstrap est placé dans cette closure
  // pour que Sentry (si init) capture les erreurs via son zone runner.
  Future<void> bootstrap() async {
    // Session persistée dans Keychain (iOS) / secure storage Keystore-backed
    // (Android) — pas en SharedPreferences clair. Voir secure_auth_storage.
    final persistSessionKey = supabasePersistSessionKeyFromUrl(supabaseUrl);

    // iOS Keychain SURVIT à la désinstallation de l'app (comportement Apple
    // voulu pour les password managers). Sans purge explicite, un user qui
    // réinstalle Spotbook voit sa session Supabase ressurgir sans passer par
    // /login — pire, un iPhone revendu peut auto-loguer le nouveau propriétaire.
    // `clearAuthKeychainIfFreshInstall` détecte l'install fraîche via un flag
    // SharedPreferences (lui-même wipé à l'uninstall) et purge la session
    // Keychain fantôme AVANT que Supabase ne l'hydrate.
    await clearAuthKeychainIfFreshInstall(
      persistSessionKey: persistSessionKey,
      onError: _reportError,
    );

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureAuthStorage(
          persistSessionKey: persistSessionKey,
          onError: _reportError,
        ),
        pkceAsyncStorage: SecurePkceStorage(),
      ),
    );

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      // Apple Pay requires a merchant identifier registered in Apple Dev Console
      // (Xcode capability "Apple Pay Payment Processing" must reference the same id).
      // Fourni via --dart-define, on retombe sur "merchant.com.spotbook.app" par défaut.
      const appleMerchantId = String.fromEnvironment(
        'STRIPE_APPLE_MERCHANT_ID',
        defaultValue: 'merchant.com.spotbook.app',
      );
      Stripe.merchantIdentifier = appleMerchantId;
      // Nécessaire pour les redirections 3DS/SCA après Apple/Google Pay.
      Stripe.urlScheme = 'spotbook';
      await Stripe.instance.applySettings();
    }

    await Hive.initFlutter();
    await Hive.openBox('settings');
    await Hive.openBox<String>('app_settings');

    await SpotbookVideoPlayer.initAudioState();

    runApp(const ProviderScope(child: SpotbookApp()));
  }

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.environment = kReleaseMode ? 'production' : 'development';
      },
      appRunner: bootstrap,
    );
  } else {
    await bootstrap();
  }
}
