import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/soumission_model.dart';

part 'soumission_repository.g.dart';

class SoumissionRepository {
  SoumissionRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all soumissions for the current Pro, newest first.
  Future<List<Soumission>> fetchMySoumissions() async {
    final rows = await _client
        .from('soumissions')
        .select()
        .eq('pro_id', _uid)
        .order('created_at', ascending: false);
    return rows.map((r) => Soumission.fromJson(r)).toList();
  }

  /// Fetch a single soumission by ID.
  Future<Soumission> fetchById(String id) async {
    final row =
        await _client.from('soumissions').select().eq('id', id).single();
    return Soumission.fromJson(row);
  }

  /// Fetch soumission by share token (for client view).
  Future<Soumission> fetchByShareToken(String token) async {
    final row = await _client
        .from('soumissions')
        .select()
        .eq('share_token', token)
        .single();
    return Soumission.fromJson(row);
  }

  /// Create a new soumission (draft).
  Future<Soumission> create({
    required String title,
    String? description,
    String? serviceId,
    required List<SoumissionLineItem> lineItems,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    DateTime? validUntil,
    String? notes,
  }) async {
    final subtotal =
        lineItems.fold<int>(0, (sum, item) => sum + item.totalCents);
    // TPS + TVQ for Quebec (14.975%) — round to nearest cent
    final tax = (subtotal * 0.14975).round();
    final total = subtotal + tax;

    final row = await _client
        .from('soumissions')
        .insert({
          'pro_id': _uid,
          'title': title,
          'description': description,
          'service_id': serviceId,
          'line_items': lineItems.map((e) => e.toJson()).toList(),
          'subtotal_cents': subtotal,
          'tax_cents': tax,
          'total_cents': total,
          'client_name': clientName,
          'client_email': clientEmail,
          'client_phone': clientPhone,
          'valid_until': validUntil?.toIso8601String(),
          'notes': notes,
        })
        .select()
        .single();
    return Soumission.fromJson(row);
  }

  /// Update status (e.g., draft → sent).
  Future<void> updateStatus(String id, String newStatus) async {
    await _client
        .from('soumissions')
        .update({'status': newStatus}).eq('id', id);
  }

  /// Delete a draft soumission.
  Future<void> deleteDraft(String id) async {
    await _client.from('soumissions').delete().eq('id', id);
  }
}

@riverpod
SoumissionRepository soumissionRepository(Ref ref) {
  return SoumissionRepository(Supabase.instance.client);
}

@riverpod
Future<List<Soumission>> mySoumissions(Ref ref) {
  return ref.watch(soumissionRepositoryProvider).fetchMySoumissions();
}
