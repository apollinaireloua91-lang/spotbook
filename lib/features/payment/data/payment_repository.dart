import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(supabase: Supabase.instance.client);
});

class PaymentRepository {
  PaymentRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  /// Calls stripe-create-intent edge function to get a clientSecret
  /// for the booking's deposit PaymentIntent.
  Future<String> createPaymentIntent(String bookingId) async {
    await _supabase.auth.refreshSession();
    final res = await _supabase.functions.invoke(
      'stripe-create-intent',
      body: {'bookingId': bookingId, 'payment_type': 'deposit'},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Paiement échoué';
      throw Exception(err ?? 'Paiement échoué');
    }
    final data = res.data as Map<String, dynamic>;
    final clientSecret = data['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('Aucun client_secret reçu');
    }
    return clientSecret;
  }

  /// Calls stripe-connect-onboarding edge function to get the Stripe
  /// Account Link URL for Express onboarding.
  ///
  /// [country] is ISO 3166-1 alpha-2 (CA/FR/US). Required on first onboarding
  /// because Stripe Express country is immutable after account creation.
  Future<String> createStripeConnectLink({String? country}) async {
    await _supabase.auth.refreshSession();

    final res = await _supabase.functions.invoke(
      'stripe-connect-onboarding',
      body: country != null && country.isNotEmpty ? {'country': country} : {},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Stripe Connect failed';
      throw Exception(err ?? 'Stripe Connect failed');
    }
    final data = res.data as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('No onboarding URL returned');
    }
    return url;
  }

  /// Calls stripe-connect-dashboard to get the pro's Stripe status + URL.
  /// Returns {status, detailsSubmitted, chargesEnabled, payoutsEnabled, url}.
  Future<Map<String, dynamic>> getStripeConnectStatus() async {
    await _supabase.auth.refreshSession();

    final res = await _supabase.functions.invoke(
      'stripe-connect-dashboard',
      body: {},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Failed to fetch status';
      throw Exception(err ?? 'Failed to fetch status');
    }
    return res.data as Map<String, dynamic>;
  }

  /// Calls stripe-create-catering-intent edge function to get a clientSecret
  /// for the catering deposit PaymentIntent (30% of total estimate).
  Future<String> createCateringPaymentIntent(String submissionId) async {
    await _supabase.auth.refreshSession();
    final res = await _supabase.functions.invoke(
      'stripe-create-catering-intent',
      body: {'submissionId': submissionId},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Paiement échoué';
      throw Exception(err ?? 'Paiement échoué');
    }
    final data = res.data as Map<String, dynamic>;
    final clientSecret = data['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('Aucun client_secret reçu');
    }
    return clientSecret;
  }
}
