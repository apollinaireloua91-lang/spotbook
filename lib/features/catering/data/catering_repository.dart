import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/catering_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CATERING REPOSITORY — queries catering_* Supabase tables
// ═════════════════════════════════════════════════════════════════════════════

final cateringRepositoryProvider = Provider<CateringRepository>((ref) {
  return CateringRepository(Supabase.instance.client);
});

class CateringRepository {
  const CateringRepository(this._client);

  final SupabaseClient _client;

  // ── Menu Items ───────────────────────────────────────────────────────────

  Future<List<CateringMenuItem>> getMenuItems(String proId) async {
    final data = await _client
        .from('catering_menu_items')
        .select('*')
        .eq('pro_id', proId)
        .eq('is_active', true)
        .order('sort_order');
    return (data as List)
        .map((e) => CateringMenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addMenuItem({
    required String proId,
    required String name,
    String? description,
    double? pricePerPerson,
    String? emoji,
  }) async {
    await _client.from('catering_menu_items').insert({
      'pro_id': proId,
      'name': name,
      'description': description,
      'price_per_person': pricePerPerson,
      'emoji': emoji,
      'is_active': true,
    });
  }

  // ── Forfaits / Packages ──────────────────────────────────────────────────

  Future<List<CateringForfait>> getForfaits(String proId) async {
    final data = await _client
        .from('catering_forfaits')
        .select('*')
        .eq('pro_id', proId)
        .eq('is_active', true)
        .order('sort_order');
    return (data as List)
        .map((e) => CateringForfait.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addForfait({
    required String proId,
    required String name,
    required double pricePerPerson,
    String? description,
    List<String> inclusions = const [],
    int? minGuests,
    int? maxGuests,
  }) async {
    await _client.from('catering_forfaits').insert({
      'pro_id': proId,
      'name': name,
      'price_per_person': pricePerPerson,
      'description': description,
      'inclusions': inclusions,
      'min_guests': minGuests,
      'max_guests': maxGuests,
      'is_active': true,
    });
  }

  // ── Gallery ──────────────────────────────────────────────────────────────

  Future<List<CateringGalleryItem>> getGallery(String proId) async {
    final data = await _client
        .from('catering_gallery')
        .select('*')
        .eq('pro_id', proId)
        .order('sort_order');
    return (data as List)
        .map((e) => CateringGalleryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Submissions ──────────────────────────────────────────────────────────

  Future<void> submitQuote({
    required String proId,
    required String clientId,
    required String eventType,
    required int guestCount,
    required DateTime eventDate,
    required String eventTime,
    required String location,
    String? forfaitId,
    String? forfaitName,
    double? budget,
    List<String> dietaryPrefs = const [],
    String? notes,
    required double estimatedTotal,
    required double depositAmount,
  }) async {
    await _client.from('catering_submissions').insert({
      'pro_id': proId,
      'client_id': clientId,
      'event_type': eventType,
      'guest_count': guestCount,
      'event_date': eventDate.toIso8601String(),
      'event_time': eventTime,
      'location': location,
      'forfait_id': forfaitId,
      'forfait_name': forfaitName,
      'budget': budget,
      'dietary_prefs': dietaryPrefs,
      'notes': notes,
      'estimated_total': estimatedTotal,
      'deposit_amount': depositAmount,
      'deposit_percentage': 30,
      'status': 'pending',
    });
  }
}

// ── Riverpod Providers for data queries ──────────────────────────────────────

final cateringMenuProvider =
    FutureProvider.autoDispose.family<List<CateringMenuItem>, String>(
  (ref, proId) => ref.read(cateringRepositoryProvider).getMenuItems(proId),
);

final cateringForfaitsProvider =
    FutureProvider.autoDispose.family<List<CateringForfait>, String>(
  (ref, proId) => ref.read(cateringRepositoryProvider).getForfaits(proId),
);

final cateringGalleryProvider =
    FutureProvider.autoDispose.family<List<CateringGalleryItem>, String>(
  (ref, proId) => ref.read(cateringRepositoryProvider).getGallery(proId),
);
