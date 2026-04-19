import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/quick_reply_models.dart';

final quickReplyRepositoryProvider = Provider<QuickReplyRepository>((ref) {
  return QuickReplyRepository(supabase: Supabase.instance.client);
});

/// Data access for chat quick replies.
///
/// Reads `quick_reply_templates` (global, per category+audience) and
/// `pro_quick_replies` (per pro). RLS ensures the latter is only
/// visible/mutable by its owner.
class QuickReplyRepository {
  QuickReplyRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Default templates seeded for a given pro category + audience.
  ///
  /// Returns an empty list if the slug has no seeded templates — the caller
  /// can then retry with the `'autre'` fallback slug.
  Future<List<QuickReplyTemplate>> fetchTemplates({
    required String categorySlug,
    required String audience,
  }) async {
    final data = await _supabase
        .from('quick_reply_templates')
        .select()
        .eq('category_slug', categorySlug)
        .eq('audience', audience)
        .order('sort_order', ascending: true);

    return (data as List)
        .map((row) => QuickReplyTemplate.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Seeds 3 defaults for this pro on their first-ever access (idempotent
  /// server-side via `quick_replies_seeded_at` marker).
  ///
  /// Silently swallows errors — seeding is a nice-to-have, not a blocker for
  /// viewing the empty list.
  Future<void> seedMyRepliesIfNeeded() async {
    if (_uid == null) return;
    try {
      await _supabase.rpc('seed_my_quick_replies');
    } catch (_) {
      // Non-fatal: the pro will just see an empty list + "Add a reply" CTA.
    }
  }

  /// The current pro's own custom quick replies (ordered by sort_order).
  ///
  /// Triggers first-access seeding before returning — new pros will see 3
  /// editable defaults on their first open; subsequent calls are cheap (the
  /// RPC short-circuits on the marker).
  Future<List<ProQuickReply>> fetchMyCustomReplies() async {
    final uid = _uid;
    if (uid == null) return [];

    await seedMyRepliesIfNeeded();

    final data = await _supabase
        .from('pro_quick_replies')
        .select()
        .eq('pro_id', uid)
        .order('sort_order', ascending: true);

    return (data as List)
        .map((row) => ProQuickReply.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ProQuickReply> createCustomReply(String text) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw Exception('Text must be 1–200 characters');
    }

    // Next sort_order = current max + 1.
    final maxRow = await _supabase
        .from('pro_quick_replies')
        .select('sort_order')
        .eq('pro_id', uid)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    final nextOrder = ((maxRow?['sort_order'] as num?)?.toInt() ?? 0) + 1;

    final data = await _supabase
        .from('pro_quick_replies')
        .insert({
          'pro_id': uid,
          'text': trimmed,
          'sort_order': nextOrder,
          'is_enabled': true,
        })
        .select()
        .single();

    return ProQuickReply.fromJson(data);
  }

  Future<ProQuickReply> updateCustomReply({
    required String id,
    String? text,
    bool? isEnabled,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{};
    if (text != null) {
      final trimmed = text.trim();
      if (trimmed.isEmpty || trimmed.length > 200) {
        throw Exception('Text must be 1–200 characters');
      }
      payload['text'] = trimmed;
    }
    if (isEnabled != null) payload['is_enabled'] = isEnabled;
    if (payload.isEmpty) throw Exception('Nothing to update');

    final data = await _supabase
        .from('pro_quick_replies')
        .update(payload)
        .eq('id', id)
        .eq('pro_id', uid)
        .select()
        .single();

    return ProQuickReply.fromJson(data);
  }

  Future<void> deleteCustomReply(String id) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase
        .from('pro_quick_replies')
        .delete()
        .eq('id', id)
        .eq('pro_id', uid);
  }

  /// Bulk-persists the order after a drag-and-drop reorder.
  /// Updates are serialized to keep RLS happy (one row per call).
  Future<void> reorderCustomReplies(List<String> orderedIds) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    for (var i = 0; i < orderedIds.length; i++) {
      await _supabase
          .from('pro_quick_replies')
          .update({'sort_order': i + 1})
          .eq('id', orderedIds[i])
          .eq('pro_id', uid);
    }
  }
}
