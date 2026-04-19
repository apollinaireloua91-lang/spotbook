import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/payout_models.dart';

final payoutRepositoryProvider = Provider<PayoutRepository>((ref) {
  return PayoutRepository(supabase: Supabase.instance.client);
});

/// Repository for Pro payout preferences + instant payout requests.
///
/// Architecture notes:
///   - Reads (preferences, history) use RLS-scoped client as the caller.
///   - Writes to payout_requests are EXCLUSIVELY via edge function
///     `request-instant-payout` — never direct table writes. This prevents
///     double-spending race conditions.
class PayoutRepository {
  PayoutRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Load the Pro's payout preferences. Returns defaults if no row exists.
  Future<PayoutPreferences> loadPreferences() async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not authenticated');
    }
    final row = await _supabase
        .from('payout_preferences')
        .select()
        .eq('pro_id', uid)
        .maybeSingle();
    if (row == null) {
      return PayoutPreferences(proId: uid);
    }
    return PayoutPreferences.fromJson(row);
  }

  /// Upsert preferences (schedule + instant-enabled + min auto threshold).
  Future<PayoutPreferences> savePreferences(PayoutPreferences prefs) async {
    final row = await _supabase
        .from('payout_preferences')
        .upsert(prefs.toUpsertJson())
        .select()
        .single();
    return PayoutPreferences.fromJson(row);
  }

  /// List recent payout requests for the current Pro, newest first.
  Future<List<PayoutRequest>> listHistory({int limit = 50}) async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('payout_requests')
        .select()
        .eq('pro_id', uid)
        .order('requested_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => PayoutRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Trigger an instant (or standard) payout via the edge function.
  /// Returns the payout confirmation on success; throws with a typed code
  /// on Stripe / validation failures so the UI can show specific messaging.
  Future<Map<String, dynamic>> requestPayout({
    required int amountCents,
    PayoutMethod method = PayoutMethod.instant,
  }) async {
    final res = await _supabase.functions.invoke(
      'request-instant-payout',
      body: {
        'amountCents': amountCents,
        'method': method.name,
      },
    );

    if (res.status != 200) {
      final err = (res.data as Map?)?['error'] as String? ?? 'unknown_error';
      throw PayoutException(code: err, details: res.data as Map?);
    }
    return (res.data as Map).cast<String, dynamic>();
  }
}

/// Typed exception so the UI can map error codes to localized messages.
class PayoutException implements Exception {
  const PayoutException({required this.code, this.details});
  final String code;
  final Map<dynamic, dynamic>? details;

  String get userMessage {
    switch (code) {
      case 'stripe_connect_not_configured':
        return 'Configure d\'abord Stripe Connect pour être payé.';
      case 'insufficient_balance':
        return 'Solde insuffisant pour ce montant.';
      case 'no_instant_destination':
        return 'Ton compte n\'a pas de carte débit éligible aux virements instantanés. Utilise un virement standard ou ajoute une carte débit dans Stripe.';
      case 'amount_too_low':
        return 'Le montant minimum est de 1,00 \$.';
      case 'stripe_error':
        return 'Erreur Stripe. Réessaie dans un instant.';
      default:
        return 'Erreur inconnue. Réessaie plus tard.';
    }
  }

  @override
  String toString() => 'PayoutException($code): $userMessage';
}
