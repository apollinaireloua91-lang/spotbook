import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/favorite_model.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(supabase: Supabase.instance.client);
});

class FavoriteRepository {
  FavoriteRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<List<FavoriteModel>> getFavorites(String type) async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _supabase
        .from('favorites')
        .select()
        .eq('user_id', uid)
        .eq('target_type', type)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isFavorite(String targetId) async {
    final uid = _uid;
    if (uid == null) return false;

    final data = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', uid)
        .eq('target_id', targetId)
        .maybeSingle();

    return data != null;
  }

  Future<void> addFavorite({
    required String targetId,
    required String targetType,
    String? targetName,
    String? targetImageUrl,
    String? targetSubtitle,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    await _supabase.from('favorites').upsert({
      'user_id': uid,
      'target_id': targetId,
      'target_type': targetType,
      'target_name': targetName,
      'target_image_url': targetImageUrl,
      'target_subtitle': targetSubtitle,
    });
  }

  Future<void> removeFavorite(String targetId) async {
    final uid = _uid;
    if (uid == null) return;

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', uid)
        .eq('target_id', targetId);
  }

  Future<Set<String>> getFavoriteIds() async {
    final uid = _uid;
    if (uid == null) return {};

    final data = await _supabase
        .from('favorites')
        .select('target_id')
        .eq('user_id', uid);

    return (data as List)
        .map((json) => json['target_id'] as String)
        .toSet();
  }
}
