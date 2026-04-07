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
      body: {'bookingId': bookingId},
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Payment failed';
      throw Exception(err ?? 'Payment failed');
    }
    final data = res.data as Map<String, dynamic>;
    final clientSecret = data['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('No client secret returned');
    }
    return clientSecret;
  }

  /// Calls stripe-connect-onboarding edge function to get the Stripe
  /// Account Link URL for Express onboarding.
  Future<String> createStripeConnectLink() async {
    // Force-refresh the session so the JWT is fresh for the gateway.
    await _supabase.auth.refreshSession();

    final res = await _supabase.functions.invoke(
      'stripe-connect-onboarding',
      method: HttpMethod.post,
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

  /// Creates a Stripe Checkout session for Pro Premium subscription.
  Future<String> createProSubscription() async {
    await _supabase.auth.refreshSession();
    final res = await _supabase.functions.invoke('create-pro-subscription');
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Subscription failed';
      throw Exception(err ?? 'Subscription failed');
    }
    final data = res.data as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('No checkout URL returned');
    }
    return url;
  }
}
