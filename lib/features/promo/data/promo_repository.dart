import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/promo_models.dart';

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  return PromoRepository(supabase: Supabase.instance.client);
});

class PromoRepository {
  PromoRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  // ─── Promo codes (Pro) ────────────────────────────────────

  Future<List<PromoCodeDetail>> getMyPromoCodes() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _supabase
        .from('promo_codes')
        .select()
        .eq('pro_id', uid)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => PromoCodeDetail.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPromoCode({
    required String code,
    required int discountPercent,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    await _supabase.from('promo_codes').insert({
      'pro_id': uid,
      'code': code.toUpperCase(),
      'discount_percent': discountPercent,
      'max_uses': maxUses,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': true,
    });
  }

  Future<void> deactivatePromoCode(String id) async {
    await _supabase
        .from('promo_codes')
        .update({'is_active': false})
        .eq('id', id);
  }

  // ─── Referrals ────────────────────────────────────────────

  Future<String> getReferralCode() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final user = await _supabase
        .from('users')
        .select('referral_code')
        .eq('id', uid)
        .single();

    String? code = user['referral_code'] as String?;
    if (code == null || code.isEmpty) {
      code = 'SPT-${uid.substring(0, 6).toUpperCase()}';
      await _supabase
          .from('users')
          .update({'referral_code': code})
          .eq('id', uid);
    }
    return code;
  }

  Future<int> getReferralCount() async {
    final uid = _uid;
    if (uid == null) return 0;

    final result = await _supabase
        .from('referrals')
        .select()
        .eq('referrer_id', uid)
        .count(CountOption.exact);

    return result.count;
  }

  Future<double> getTotalCredits() async {
    final uid = _uid;
    if (uid == null) return 0;

    final data = await _supabase
        .from('referrals')
        .select('credit_amount')
        .eq('referrer_id', uid)
        .eq('credited', true);

    final amounts = (data as List)
        .map((r) => (r['credit_amount'] as num).toDouble())
        .toList();

    if (amounts.isEmpty) return 0;
    return amounts.reduce((a, b) => a + b);
  }

  Future<List<ReferralModel>> getReferralHistory() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _supabase
        .from('referrals')
        .select()
        .eq('referrer_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
