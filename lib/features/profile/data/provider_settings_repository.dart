import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final providerSettingsRepositoryProvider = Provider<ProviderSettingsRepository>(
  (ref) => ProviderSettingsRepository(Supabase.instance.client),
);

class ProSettingsSnapshot {
  const ProSettingsSnapshot({
    required this.email,
    required this.phone,
    required this.cancellationPolicy,
    required this.minAdvanceHours,
    required this.minGapMinutes,
    required this.maxBookingsPerDay,
    required this.isPublic,
    required this.searchVisible,
    required this.stripeOnboarded,
    required this.stripeAccountId,
    required this.kycStatus,
    this.stripePayoutLast4,
  });

  final String email;
  final String? phone;
  final String cancellationPolicy;
  final int minAdvanceHours;
  final int minGapMinutes;
  final int maxBookingsPerDay;
  final bool isPublic;
  final bool searchVisible;
  final bool stripeOnboarded;
  final String? stripeAccountId;
  final String? kycStatus;
  final String? stripePayoutLast4;
}

class ProviderSettingsRepository {
  ProviderSettingsRepository(this._client);

  final SupabaseClient _client;

  String? get _proId => _client.auth.currentUser?.id;

  Future<ProSettingsSnapshot> fetchSnapshot() async {
    final uid = _proId;
    if (uid == null) {
      throw Exception('Non authentifié');
    }
    final user = _client.auth.currentUser;
    final email = user?.email ?? '';

    final proRes = await _client
        .from('profiles_pro')
        .select(
          'tel, stripe_account_id, stripe_onboarded, kyc_status, is_public, search_visible, stripe_payout_last4',
        )
        .eq('id', uid)
        .maybeSingle();

    Map<String, dynamic> settingsRow = {};
    final settingsRes = await _client
        .from('provider_settings')
        .select()
        .eq('pro_id', uid)
        .maybeSingle();
    if (settingsRes != null) {
      settingsRow = Map<String, dynamic>.from(settingsRes);
    }

    return ProSettingsSnapshot(
      email: email,
      phone: proRes?['tel'] as String?,
      cancellationPolicy: (settingsRow['cancellation_policy'] as String?) ?? 'flexible',
      minAdvanceHours: (settingsRow['min_advance_hours'] as int?) ?? 24,
      minGapMinutes: (settingsRow['min_gap_minutes'] as int?) ?? 0,
      maxBookingsPerDay: (settingsRow['max_bookings_per_day'] as int?) ?? 10,
      isPublic: proRes?['is_public'] as bool? ?? true,
      searchVisible: proRes?['search_visible'] as bool? ?? true,
      stripeOnboarded: proRes?['stripe_onboarded'] as bool? ?? false,
      stripeAccountId: proRes?['stripe_account_id'] as String?,
      kycStatus: proRes?['kyc_status'] as String?,
      stripePayoutLast4: proRes?['stripe_payout_last4'] as String?,
    );
  }

  Future<void> upsertProviderSettings(Map<String, dynamic> patch) async {
    final uid = _proId;
    if (uid == null) throw Exception('Non authentifié');
    await _client.from('provider_settings').upsert({
      'pro_id': uid,
      ...patch,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateProfilePro(Map<String, dynamic> patch) async {
    final uid = _proId;
    if (uid == null) throw Exception('Non authentifié');
    await _client.from('profiles_pro').update(patch).eq('id', uid);
  }

  Future<void> updatePhone(String tel) async {
    await updateProfilePro({'tel': tel});
  }

  /// Retourne une URL d’onboarding si l’Edge Function existe ; sinon null.
  Future<String?> fetchStripeConnectOnboardingUrl() async {
    try {
      final res = await _client.functions.invoke(
        'stripe-connect-onboarding',
        body: const <String, dynamic>{},
      );
      if (res.status == 200 && res.data is Map) {
        final url = (res.data as Map)['url'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (_) {
      // Fonction absente ou erreur réseau — fallback navigation interne
    }
    return null;
  }
}
