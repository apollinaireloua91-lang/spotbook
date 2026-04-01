import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/agent_debug_log.dart';
import '../../../shared/utils/cloudflare_stream_urls.dart';
import '../domain/video_model.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(supabase: Supabase.instance.client);
});

class VideoRepository {
  VideoRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// `videos.pro_id` référence `users.id` (FK `videos_pro_id_fkey`), pas `profiles_pro` — embed via `users` puis `profiles_pro`.
  /// `services` / `events` : colonnes `service_id` / `event_id` (migration 20260328130000).
  static const _selectWithPro =
      'id, pro_id, cloudflare_id, stream_url, thumbnail_url, title, description, hashtags, category, status, likes_count, comments_count, views_count, share_count, created_at, duration_seconds, service_id, event_id, spotify_track_title, spotify_track_artist, '
      'services(title, name, price), '
      'events(title, event_date, start_time, location), '
      'users!inner(id, full_name, avatar_url, city, profiles_pro(business_name, category, is_top_pro, social_connections(platform, followers_count, handle)))';

  /// Normalise `cloudflare_id`, dérive [stream_url] / [thumbnail_url] si absents.
  Map<String, dynamic> _enrichVideoRow(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    final id = cloudflareIdFromRow(m);
    if (id != null) {
      m['cloudflare_id'] = id;
    }
    final stream = m['stream_url'] as String?;
    if (stream == null || stream.isEmpty) {
      final derived = cloudflareManifestUrl(id);
      if (derived != null) m['stream_url'] = derived;
    }
    final thumb = m['thumbnail_url'] as String?;
    if (thumb == null || thumb.isEmpty) {
      final u = cloudflareThumbnailUrl(id);
      if (u != null) m['thumbnail_url'] = u;
    }
    return m;
  }

  /// Feed Découvrir : uniquement `approved` + `public`, pagination chronologique cohérente.
  Future<List<VideoModel>> getDiscoverFeed({
    int offset = 0,
    int limit = 10,
  }) async {
    final uid = currentUserId;

    final blockedIds =
        uid != null ? await _getBlockedProIds(uid) : <String>[];
    final likedIds =
        uid != null ? await _getLikedVideoIds(uid) : <String>{};
    final savedIds =
        uid != null ? await _getSavedVideoIds(uid) : <String>{};
    final followedIds =
        uid != null ? await _getFollowedProIds(uid) : <String>{};

    var query = _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved')
        .eq('visibility', 'public');
    if (blockedIds.isNotEmpty) {
      query = query.not('pro_id', 'in', blockedIds);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((raw) {
          final json = raw as Map<String, dynamic>;
          final m = _enrichVideoRow(json);
          return VideoModel.fromJson(
            m,
            isLiked: likedIds.contains(m['id'] as String),
            isSaved: savedIds.contains(m['id'] as String),
            isFollowed: followedIds.contains(m['pro_id'] as String),
          );
        })
        .toList();
  }

  Future<List<VideoModel>> getScoredVideos({int limit = 10}) =>
      getDiscoverFeed(offset: 0, limit: limit);

  Future<List<VideoModel>> getMoreVideos({
    required int offset,
    int limit = 10,
  }) =>
      getDiscoverFeed(offset: offset, limit: limit);

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
        .map((json) => VideoModel.fromJson(
              _enrichVideoRow(json as Map<String, dynamic>),
            ))
        .toList();
  }

  /// Même flux que [getMyVideos] + états like / favori pour l’utilisateur courant (aperçu stats).
  Future<List<VideoModel>> getMyVideosWithInteractions() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final likedIds = await _getLikedVideoIds(uid);
    final savedIds = await _getSavedVideoIds(uid);
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('pro_id', uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) {
          final m = json as Map<String, dynamic>;
          final id = m['id'] as String;
          return VideoModel.fromJson(
            _enrichVideoRow(m),
            isLiked: likedIds.contains(id),
            isSaved: savedIds.contains(id),
          );
        })
        .toList();
  }

  Future<List<VideoModel>> getProVideos(String proId) async {
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('pro_id', proId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => VideoModel.fromJson(
              _enrichVideoRow(json as Map<String, dynamic>),
            ))
        .toList();
  }

  Future<void> deleteVideo(String videoId) async {
    await _supabase.from('videos').delete().eq('id', videoId);
  }

  /// Edge Functions : toujours le singleton + JWT utilisateur explicite (évite tout cas limite sur [AuthHttpClient.putIfAbsent]).
  Future<FunctionResponse> _invokeAuthenticatedEdgeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final authClient = Supabase.instance.client;
    var session = authClient.auth.currentSession;
    if (session == null) {
      throw Exception('Session expirée — veuillez vous reconnecter');
    }
    if (session.isExpired) {
      final refreshed = await authClient.auth.refreshSession();
      session = refreshed.session;
      if (session == null) {
        throw Exception('Session expirée — veuillez vous reconnecter');
      }
    }
    final token = session.accessToken;
    if (token.isEmpty) {
      throw Exception('Session expirée — veuillez vous reconnecter');
    }
    try {
      final res = await authClient.functions.invoke(
        functionName,
        body: body,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      // #region agent log
      agentDebugLog(
        hypothesisId: 'post-fix',
        location: 'video_repository.dart:_invokeAuthenticatedEdgeFunction',
        message: 'Edge function OK',
        data: {
          'runId': 'post-fix-v2',
          'name': functionName,
          'status': res.status,
        },
      );
      // #endregion
      return res;
    } on FunctionException catch (e) {
      // #region agent log
      String? detailsError;
      final d = e.details;
      if (d is Map) {
        final m = Map<String, dynamic>.from(d);
        detailsError =
            m['error']?.toString() ?? m['message']?.toString() ?? m['msg']?.toString();
      } else if (d is String && d.isNotEmpty) {
        detailsError = d.length > 240 ? '${d.substring(0, 240)}…' : d;
      }
      agentDebugLog(
        hypothesisId: 'post-fix',
        location: 'video_repository.dart:_invokeAuthenticatedEdgeFunction',
        message: 'Edge function FunctionException',
        data: {
          'runId': 'post-fix-v2',
          'name': functionName,
          'status': e.status,
          'detailsType': e.details.runtimeType.toString(),
          'detailsError': detailsError ?? 'none',
        },
      );
      // #endregion
      rethrow;
    }
  }

  /// Réponse Edge = corps API Cloudflare v4 (`success`, `result.uploadURL`, `result.uid`).
  Future<Map<String, dynamic>> getCloudflareUploadUrl({
    int? fileSizeBytes,
    String? mimeType,
  }) async {
    final session = _supabase.auth.currentSession;
    final singleton = Supabase.instance.client;
    final fnHeaders = singleton.functions.headers;
    final preAuthKey = fnHeaders.keys
        .map((k) => k.toLowerCase())
        .contains('authorization');
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H1-H4',
      location: 'video_repository.dart:getCloudflareUploadUrl',
      message: 'SESSION CHECK avant functions.invoke (upload URL)',
      data: {
        'repoClientHash': identityHashCode(_supabase),
        'singletonClientHash': identityHashCode(singleton),
        'sameInstance': identical(_supabase, singleton),
        'hasSession': session != null,
        'sessionExpired': session?.isExpired,
        'accessTokenChars': session?.accessToken.length ?? 0,
        'functionsHeadersHasAuthorizationKey': preAuthKey,
      },
    );
    // #endregion
    if (session == null) {
      throw Exception('Session expirée — veuillez vous reconnecter');
    }
    final res = await _invokeAuthenticatedEdgeFunction(
      'generate-cloudflare-upload-url',
      body: {
        if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
        if (mimeType != null && mimeType.isNotEmpty) 'mimeType': mimeType,
      },
    );
    if (res.status != 200) {
      throw Exception(_functionsErrorMessage(res.data, fallback: 'Upload URL failed'));
    }
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid upload URL response');
    }
    final result = data['result'];
    if (result is! Map<String, dynamic>) {
      throw Exception(data['error']?.toString() ?? 'No Cloudflare result');
    }
    final uploadURL = result['uploadURL'] as String?;
    final uid = result['uid'] as String?;
    if (uploadURL == null || uid == null) {
      throw Exception('Missing uploadURL or uid in Cloudflare response');
    }
    return {
      'uploadURL': uploadURL,
      'videoId': uid,
    };
  }

  Future<Map<String, dynamic>> submitForModeration({
    required String title,
    required String description,
    required String category,
    required double? duration,
    required String cloudflareId,
    String thumbnailUrl = '',
    required List<String> hashtags,
    String? serviceId,
  }) async {
    final session = _supabase.auth.currentSession;
    final singleton = Supabase.instance.client;
    final fnHeaders = singleton.functions.headers;
    final preAuthKey = fnHeaders.keys
        .map((k) => k.toLowerCase())
        .contains('authorization');
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H1-H4',
      location: 'video_repository.dart:submitForModeration',
      message: 'SESSION CHECK avant functions.invoke (moderate)',
      data: {
        'repoClientHash': identityHashCode(_supabase),
        'singletonClientHash': identityHashCode(singleton),
        'sameInstance': identical(_supabase, singleton),
        'hasSession': session != null,
        'sessionExpired': session?.isExpired,
        'accessTokenChars': session?.accessToken.length ?? 0,
        'functionsHeadersHasAuthorizationKey': preAuthKey,
      },
    );
    // #endregion
    if (session == null) {
      throw Exception('Session expirée — veuillez vous reconnecter');
    }
    final res = await _invokeAuthenticatedEdgeFunction(
      'moderate-video',
      body: {
        'title': title,
        'description': description,
        'category': category,
        'duration': duration,
        'cloudflare_id': cloudflareId,
        'thumbnail_url': thumbnailUrl,
        'hashtags': hashtags,
        if (serviceId != null && serviceId.isNotEmpty) 'service_id': serviceId,
      },
    );
    if (res.status != 200) {
      throw Exception(_functionsErrorMessage(res.data, fallback: 'Publication échouée'));
    }
    return res.data as Map<String, dynamic>;
  }

  static String _functionsErrorMessage(dynamic data, {required String fallback}) {
    if (data is Map) {
      final e = data['error'] ?? data['message'];
      if (e != null && e.toString().trim().isNotEmpty) return e.toString();
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return fallback;
  }

  Future<List<VideoModel>> searchVideos(String query) async {
    // Sanitize query to prevent PostgREST filter injection
    final sanitized = query.replaceAll(RegExp(r'[,.()\[\]%\\]'), '');
    if (sanitized.trim().isEmpty) return [];
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved')
        .eq('visibility', 'public')
        .or('title.ilike.%$sanitized%,category.ilike.%$sanitized%')
        .order('created_at', ascending: false)
        .limit(20);
    return (data as List)
        .map((json) => VideoModel.fromJson(
              _enrichVideoRow(json as Map<String, dynamic>),
            ))
        .toList();
  }

  Future<List<VideoModel>> getVideosByCategory(String category) async {
    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved')
        .eq('visibility', 'public')
        .eq('category', category)
        .order('created_at', ascending: false)
        .limit(20);
    return (data as List)
        .map((json) => VideoModel.fromJson(
              _enrichVideoRow(json as Map<String, dynamic>),
            ))
        .toList();
  }

  /// Feed filtered to followed pros only.
  Future<List<VideoModel>> getFollowingFeed({int limit = 10, int offset = 0}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final followedIds = await _getFollowedProIds(uid);
    if (followedIds.isEmpty) return [];

    final likedIds = await _getLikedVideoIds(uid);
    final savedIds = await _getSavedVideoIds(uid);

    final data = await _supabase
        .from('videos')
        .select(_selectWithPro)
        .eq('status', 'approved')
        .eq('visibility', 'public')
        .inFilter('pro_id', followedIds.toList())
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((json) => VideoModel.fromJson(
              _enrichVideoRow(json as Map<String, dynamic>),
              isLiked: likedIds.contains(json['id']),
              isSaved: savedIds.contains(json['id']),
              isFollowed: true,
            ))
        .toList();
  }

  Future<void> saveVideo(String videoId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _supabase.from('favorites').insert({
      'user_id': uid,
      'video_id': videoId,
    });
  }

  Future<void> unsaveVideo(String videoId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', uid)
        .eq('video_id', videoId);
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

  Future<Set<String>> _getFollowedProIds(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return (data as List).map((e) => e['following_id'] as String).toSet();
  }

  Future<Set<String>> _getSavedVideoIds(String userId) async {
    final data = await _supabase
        .from('favorites')
        .select('video_id')
        .eq('user_id', userId);
    return (data as List).map((e) => e['video_id'] as String).toSet();
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
}
