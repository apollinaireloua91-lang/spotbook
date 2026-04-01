import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    await _supabase.from('users').insert({
      'id': user.id,
      'email': user.email,
      'full_name': meta['full_name'],
      'role': meta['role'],
      'avatar_url': meta['avatar_url'],
      'city': meta['address'],
      'country': countryCode,
      'currency': currency,
      'payment_provider': 'stripe',
    });

    // notification_preferences row is auto-created by DB trigger
    // (tr_ensure_notif_prefs in migration 027)
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
