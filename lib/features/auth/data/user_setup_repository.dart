import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Même pattern d'observabilité que les autres entrées critiques
/// (feed_notifier, pos_notifier) — on ne laisse jamais un upsert auth
/// foirer en silence, sinon on se retrouve avec une session valide mais
/// zéro profil en DB → écran profil vide inexplicable.
void _reportSetupError(String where, Object e, StackTrace st) {
  if (kDebugMode) {
    debugPrint('UserSetupRepository.$where failed: $e\n$st');
  }
  try {
    Sentry.captureException(e, stackTrace: st);
  } catch (_) {
    // Sentry pas initialisé (dev sans DSN) — on ignore.
  }
}

final userSetupRepositoryProvider = Provider<UserSetupRepository>((ref) {
  return UserSetupRepository(supabase: Supabase.instance.client);
});

class UserSetupRepository {
  UserSetupRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  static const _currencyMap = {
    'CA': 'CAD',
    'FR': 'EUR',
    'US': 'USD',
    'CI': 'XOF',
  };

  Future<void> setupNewUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final existing = await _supabase
        .from('users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) return;

    String countryCode = 'CA';
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final resolved = await _resolveCountry();
        if (resolved != null) countryCode = resolved;
      }
    } catch (_) {
      // Fallback to CA
    }

    final currency = _currencyMap[countryCode] ?? 'CAD';
    final meta = user.userMetadata ?? {};

    try {
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': meta['full_name'],
        'phone': meta['phone'],
        'age': meta['age'],
        'address': meta['address'],
        'city': meta['city'],
        if (meta['latitude'] != null) 'latitude': meta['latitude'],
        if (meta['longitude'] != null) 'longitude': meta['longitude'],
        'role': meta['role'],
        'avatar_url': meta['avatar_url'],
        'country': countryCode,
        'currency': currency,
        'payment_provider': 'stripe',
      }, onConflict: 'id');
    } catch (e, st) {
      // Rethrow : sans la ligne `users` on ne peut rien afficher en aval
      // (profile screen vide, role null, loop infini sur /select-account-type).
      // Le caller (login_screen) attrape et affiche une erreur.
      _reportSetupError('users.upsert', e, st);
      rethrow;
    }

    try {
      await _supabase.from('notification_preferences').upsert({
        'user_id': user.id,
        'push_enabled': true,
        'email_enabled': true,
        'booking_reminders': true,
        'new_messages': true,
        'promotions': false,
        'new_followers': true,
        'booking_updates': true,
        'event_updates': true,
      }, onConflict: 'user_id');
    } catch (e, st) {
      // Non bloquant : les prefs notifications peuvent être créées plus
      // tard (first push token register / écran Notifications). On log et
      // on continue sinon un blip réseau ici casserait tout le login.
      _reportSetupError('notification_preferences.upsert', e, st);
    }
  }

  /// Creates a `profiles_pro` row so the Edge Function recognises this user
  /// as a provider (required for video upload, etc.).
  Future<void> createProProfile({
    required String businessName,
    required String category,
    required String city,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('profiles_pro').upsert({
      'id': user.id,
      'business_name': businessName,
      'category': category,
      'city': city,
    });
  }

  Future<String?> _resolveCountry() async {
    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return null;
    } catch (_) {
      return null;
    }
  }
}
