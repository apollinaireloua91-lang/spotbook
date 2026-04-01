import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/moderation_models.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(supabase: Supabase.instance.client);
});

class ModerationRepository {
  ModerationRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  // ─── Blocking ─────────────────────────────────────────────

  Future<List<BlockModel>> getBlockedUsers() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _supabase
        .from('blocks')
        .select('*, blocked_user:blocked_id(full_name, avatar_url)')
        .eq('blocker_id', uid)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => BlockModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> blockUser(String blockedId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    await _supabase.from('blocks').upsert({
      'blocker_id': uid,
      'blocked_id': blockedId,
    });
    await _supabase.from('audit_logs').insert({
      'user_id': uid,
      'action': 'user_blocked',
      'resource_type': 'user',
      'resource_id': blockedId,
      'metadata': {'blocked_id': blockedId},
    });
  }

  Future<void> unblockUser(String blockedId) async {
    final uid = _uid;
    if (uid == null) return;

    await _supabase
        .from('blocks')
        .delete()
        .eq('blocker_id', uid)
        .eq('blocked_id', blockedId);
  }

  Future<bool> isBlocked(String userId) async {
    final uid = _uid;
    if (uid == null) return false;

    final data = await _supabase
        .from('blocks')
        .select('id')
        .eq('blocker_id', uid)
        .eq('blocked_id', userId)
        .maybeSingle();

    return data != null;
  }

  // ─── Reporting ────────────────────────────────────────────

  Future<void> report({
    required String targetId,
    required String targetType,
    required String reason,
    String? details,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final row = <String, dynamic>{
      'reporter_id': uid,
      'target_id': targetId,
      'target_type': targetType,
      'reason': reason,
    };
    final d = details?.trim();
    if (d != null && d.isNotEmpty) {
      row['details'] = d.length > 2000 ? d.substring(0, 2000) : d;
    }

    await _supabase.from('reports').insert(row);
    await _supabase.from('audit_logs').insert({
      'user_id': uid,
      'action': 'user_reported',
      'resource_type': targetType,
      'resource_id': targetId,
      'metadata': {
        'reason': reason,
        if (d != null && d.isNotEmpty) 'has_details': true,
      },
    });
  }
}
