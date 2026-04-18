import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/service_addon_models.dart';

final serviceAddonRepositoryProvider = Provider<ServiceAddonRepository>((ref) {
  return ServiceAddonRepository(supabase: Supabase.instance.client);
});

/// Repository for managing service add-ons (Pro-owned catalog of paid extras).
///
/// Architectural notes:
///   - Pro-side CRUD: authorized via RLS (pro_id = auth.uid()).
///   - Client-side reads: public read is restricted to `is_active = true` rows
///     via RLS, so `listForService` automatically returns only visible add-ons
///     when called by a client.
class ServiceAddonRepository {
  ServiceAddonRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// List add-ons attached to a service. Orders by `sort_order` for stable UI.
  Future<List<ServiceAddon>> listForService(String serviceId) async {
    final rows = await _supabase
        .from('service_addons')
        .select()
        .eq('service_id', serviceId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    return (rows as List)
        .map((r) => ServiceAddon.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// List ALL add-ons for a Pro across all their services.
  /// Includes inactive ones (useful for Pro's management view).
  Future<List<ServiceAddon>> listAllForPro() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('service_addons')
        .select()
        .eq('pro_id', uid)
        .order('service_id')
        .order('sort_order');
    return (rows as List)
        .map((r) => ServiceAddon.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceAddon> create(ServiceAddon draft) async {
    final row = await _supabase
        .from('service_addons')
        .insert(draft.toInsertJson())
        .select()
        .single();
    return ServiceAddon.fromJson(row);
  }

  Future<ServiceAddon> update(ServiceAddon addon) async {
    final row = await _supabase
        .from('service_addons')
        .update(addon.toUpdateJson())
        .eq('id', addon.id)
        .select()
        .single();
    return ServiceAddon.fromJson(row);
  }

  Future<void> delete(String addonId) async {
    await _supabase.from('service_addons').delete().eq('id', addonId);
  }

  /// Soft-toggle visibility without deleting historical references.
  Future<void> setActive(String addonId, bool isActive) async {
    await _supabase
        .from('service_addons')
        .update({'is_active': isActive})
        .eq('id', addonId);
  }

  /// Bulk reorder — updates `sort_order` in a single round-trip via upsert.
  /// Pass addons in the desired display order.
  Future<void> reorder(List<ServiceAddon> ordered) async {
    if (ordered.isEmpty) return;
    // Upsert on PK with updated sort_order — RLS still applies.
    final payload = <Map<String, dynamic>>[];
    for (var i = 0; i < ordered.length; i++) {
      payload.add({
        'id': ordered[i].id,
        'sort_order': i,
      });
    }
    await _supabase.from('service_addons').upsert(payload);
  }
}
