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
      '*, profiles_pro!inner(id, business_name, category, is_top_pro, users!inner(full_name, avatar_url, city), social_connections(platform, followers_count, handle))';

  Future<List<VideoModel>> getScoredVideos({int limit = 10}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final blockedIds = await _getBlockedProIds(uid);
    final userProfile = await _supabase
        .from('users')
        .select('city')
        .eq('id', uid)
        .maybeSingle();
    final userCity = userProfile?['city'] as String?;

    var query = _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved');
    if (blockedIds.isNotEmpty) {
      query = query.not('pro_id', 'in', blockedIds);
    }

    final data = await query.order('created_at', ascending: false).limit(50);
    final likedIds = await _getLikedVideoIds(uid);

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
    await _supabase.from('video_likes').insert({
      'user_id': uid,
      'video_id': videoId,
    });
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

  Future<Map<String, dynamic>> getCloudflareUploadUrl() async {
    final res = await _supabase.functions
        .invoke('generate-cloudflare-upload-url');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitForModeration({
    required String title,
    required String description,
    required String category,
    required double? duration,
    required String cloudflareId,
    required String streamUrl,
    required String thumbnailUrl,
    required List<String> hashtags,
  }) async {
    final res = await _supabase.functions.invoke(
      'moderate-video',
      body: {
        'title': title,
        'description': description,
        'category': category,
        'duration': duration,
        'cloudflare_id': cloudflareId,
        'stream_url': streamUrl,
        'thumbnail_url': thumbnailUrl,
        'hashtags': hashtags,
      },
    );
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Upload failed';
      throw Exception(err ?? 'Upload failed');
    }
    return res.data as Map<String, dynamic>;
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
    await _supabase.from('post_saves').insert({
      'user_id': uid,
      'post_id': videoId,
    });
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
    await _supabase.from('follows').insert({
      'follower_id': uid,
      'following_id': proId,
    });
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
