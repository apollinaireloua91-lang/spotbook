import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/video_model.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(supabase: Supabase.instance.client);
});

class VideoRepository {
  VideoRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;
  final _random = Random();

  String? get currentUserId => _supabase.auth.currentUser?.id;

  static const _selectWithPro =
      '*, users!pro_id(id, full_name, display_name, avatar_url, username, city, profiles_pro(id, business_name, category, city, rating_average, is_top_pro)), services(id, title, price, duration_minutes), events(id, title, event_date, location)';

  Future<List<VideoModel>> getScoredVideos({int limit = 10}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    // Phase 1 — round-trips indépendants lancés en parallèle : blocks (requis
    // pour filtrer la query videos), city de l'user courant (scoring), likes
    // existants (flag isLiked). Avant, ces 3 queries étaient séquentielles,
    // soit 3× la latence réseau avant même le fetch des vidéos — bug
    // « spinner figé » sur iPhone réseau lent (CA).
    //
    // NOTE : on ne passe pas par `Future.wait([...])` parce que les 3
    // opérations ont des types de retour hétérogènes (List<String>,
    // Map?, Set<String>) → `Future.wait` inférerait Future<dynamic>
    // ce qui plombe l'analyzer. On démarre chaque future sans await,
    // puis on les collecte — équivalent en parallélisme, typé proprement.
    final blocksFuture = _getBlockedProIds(uid);
    final userProfileFuture =
        _supabase.from('users').select('city').eq('id', uid).maybeSingle();
    final likedIdsFuture = _getLikedVideoIds(uid);

    final blockedIds = await blocksFuture;
    final userProfile = await userProfileFuture;
    final userCity = userProfile?['city'] as String?;
    final likedIds = await likedIdsFuture;

    // Phase 2 — la query videos dépend de blockedIds, donc on l'enchaîne
    // après Future.wait plutôt que de re-filtrer côté client (économie
    // de bande passante sur une liste de 50 vidéos).
    var query = _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved');
    if (blockedIds.isNotEmpty) {
      query = query.not('pro_id', 'in', blockedIds);
    }

    final data = await query.order('created_at', ascending: false).limit(50);

    final videos = (data as List)
        .map((json) => VideoModel.fromJson(json as Map<String, dynamic>,
            isLiked: likedIds.contains(json['id'])))
        .toList();

    final scored = videos.map((v) {
      double score = 0;
      if (userCity != null && v.proCity == userCity) score += 40;
      final age = DateTime.now().difference(v.createdAt);
      if (age.inHours < 24) {
        score += 30;
      } else if (age.inDays < 7) {
        score += 20;
      }
      score += _random.nextInt(11);
      return (video: v, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.video).toList();
  }

  Future<List<VideoModel>> getMoreVideos({
    required int offset,
    int limit = 10,
  }) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final blockedIds = await _getBlockedProIds(uid);
    final likedIds = await _getLikedVideoIds(uid);

    var query = _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved');
    if (blockedIds.isNotEmpty) {
      query = query.not('pro_id', 'in', blockedIds);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((json) => VideoModel.fromJson(json as Map<String, dynamic>,
            isLiked: likedIds.contains(json['id'])))
        .toList();
  }

  Future<void> likeVideo(String videoId) async {
    final uid = currentUserId;
    if (uid == null) return;
    // PostgREST n'autorise PAS d'espace après la virgule dans onConflict :
    // la chaîne est url-encodée telle quelle côté Supabase Dart, et un ` `
    // encodé devient `%20` → PostgREST cherche alors une colonne littérale
    // « ␣video_id » et répond 400. D'où le `like_failed` fantôme remonté
    // le 2026-04-21.
    await _supabase.from('video_likes').upsert({
      'user_id': uid,
      'video_id': videoId,
    }, onConflict: 'user_id,video_id');
  }

  Future<void> unlikeVideo(String videoId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _supabase
        .from('video_likes')
        .delete()
        .eq('user_id', uid)
        .eq('video_id', videoId);
  }

  Future<void> incrementViewCount(String videoId) async {
    try {
      await _supabase.rpc('increment_video_views', params: {'vid': videoId});
    } catch (_) {
      // Silently fail — non-critical
    }
  }

  Future<List<CommentModel>> getComments(String videoId) async {
    final data = await _supabase
        .from('video_comments')
        .select('*, users(full_name, avatar_url)')
        .eq('video_id', videoId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment(String videoId, String content) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    final data = await _supabase
        .from('video_comments')
        .insert({
          'video_id': videoId,
          'user_id': uid,
          'content': content,
        })
        .select('*, users(full_name, avatar_url)')
        .single();
    return CommentModel.fromJson(data);
  }

  Stream<List<CommentModel>> streamComments(String videoId) {
    return _supabase
        .from('video_comments')
        .stream(primaryKey: ['id'])
        .eq('video_id', videoId)
        .map((data) {
          final comments =
              data.map((json) => CommentModel.fromJson(json)).toList();
          comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return comments;
        });
  }

  Future<List<VideoModel>> getMyVideos() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('pro_id', uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<VideoModel>> getProVideos(String proId) async {
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('pro_id', proId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteVideo(String videoId) async {
    await _supabase.from('videos').delete().eq('id', videoId);
  }


  Future<List<VideoModel>> searchVideos(String query) async {
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved')
        .or('title.ilike.%$query%,category.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(20);
    return (data as List)
        .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<VideoModel>> getVideosByCategory(String category) async {
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved')
        .eq('category', category)
        .order('created_at', ascending: false)
        .limit(20);
    return (data as List)
        .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> _getBlockedProIds(String userId) async {
    final data = await _supabase
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', userId);
    return (data as List).map((e) => e['blocked_id'] as String).toList();
  }

  Future<Set<String>> _getLikedVideoIds(String userId) async {
    final data = await _supabase
        .from('video_likes')
        .select('video_id')
        .eq('user_id', userId);
    return (data as List).map((e) => e['video_id'] as String).toSet();
  }

  Future<void> saveVideo(String videoId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _supabase.from('post_saves').upsert({
      'user_id': uid,
      'post_id': videoId,
    }, onConflict: 'user_id,post_id');
  }

  Future<void> unsaveVideo(String videoId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _supabase
        .from('post_saves')
        .delete()
        .eq('user_id', uid)
        .eq('post_id', videoId);
  }

  Future<List<VideoModel>> getFollowingFeed({int limit = 10, int offset = 0}) async {
    final uid = currentUserId;
    if (uid == null) return [];
    final follows = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', uid);
    final proIds = (follows as List).map((e) => e['following_id'] as String).toList();
    if (proIds.isEmpty) return [];
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved')
        .inFilter('pro_id', proIds)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    final likedIds = await _getLikedVideoIds(uid);
    return (data as List)
        .map((json) => VideoModel.fromJson(json as Map<String, dynamic>,
            isLiked: likedIds.contains(json['id'])))
        .toList();
  }

  Future<List<VideoModel>> getDiscoverFeed({int limit = 10, int offset = 0}) async {
    return getMoreVideos(offset: offset, limit: limit);
  }

  Future<List<VideoModel>> getMyVideosWithInteractions() async {
    return getMyVideos();
  }

  Future<void> followPro(String proId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _supabase.from('follows').upsert({
      'follower_id': uid,
      'following_id': proId,
    }, onConflict: 'follower_id,following_id');
  }

  Future<void> unfollowPro(String proId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', proId);
  }
}
