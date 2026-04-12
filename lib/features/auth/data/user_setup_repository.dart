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
