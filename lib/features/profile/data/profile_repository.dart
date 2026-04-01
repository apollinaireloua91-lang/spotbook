import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase: Supabase.instance.client);
});

class ProfileRepository {
  ProfileRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<ClientProfile> getClientProfile(String userId) async {
    final data =
        await _supabase.from('users').select().eq('id', userId).maybeSingle();
    if (data != null) {
      return ClientProfile.fromJson(data);
    }
    // Ligne `users` absente (sync retardée) : repli sur la session Auth.
    final sessionUser = _supabase.auth.currentUser;
    if (sessionUser != null && sessionUser.id == userId) {
      final meta = sessionUser.userMetadata;
      final name = meta?['full_name'] as String? ??
          meta?['name'] as String? ??
          meta?['display_name'] as String? ??
          (sessionUser.email?.split('@').first ?? 'Utilisateur');
      return ClientProfile(
        id: sessionUser.id,
        fullName: name,
        email: sessionUser.email ?? '',
        avatarUrl: meta?['avatar_url'] as String? ?? meta?['picture'] as String?,
        username: meta?['username'] as String?,
        role: meta?['role'] as String? ?? 'client',
        createdAt: DateTime.tryParse(sessionUser.createdAt),
      );
    }
    throw Exception('Utilisateur introuvable');
  }

  Future<ProProfile> getProProfile(String proId) async {
    final uid = currentUserId;

    // Fetch pro profile with user data and social connections
    final data = await _supabase
        .from('profiles_pro')
        .select('*, users(*), social_connections(*)')
        .eq('id', proId)
        .single();

    bool isFollowed = false;
    if (uid != null) {
      final followData = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('follower_id', uid)
          .eq('following_id', proId)
          .maybeSingle();
      isFollowed = followData != null;
    }

    return ProProfile.fromJson(data, isFollowedByMe: isFollowed);
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? city,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final userUpdates = <String, dynamic>{};
    if (fullName != null) userUpdates['full_name'] = fullName;
    if (username != null) userUpdates['username'] = username;
    if (city != null) userUpdates['city'] = city;

    if (userUpdates.isNotEmpty) {
      userUpdates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('users').update(userUpdates).eq('id', uid);
    }

    if (bio != null) {
      final role = _supabase.auth.currentUser?.userMetadata?['role'];
      if (role == 'pro') {
        await _supabase.from('profiles_pro').update({
          'description': bio,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', uid);
      } else {
        await _supabase.from('users').update({'bio': bio}).eq('id', uid);
      }
    }
  }

  Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('avatars').uploadBinary(path, bytes);
    final url = _supabase.storage.from('avatars').getPublicUrl(path);

    await _supabase.from('users').update({'avatar_url': url}).eq('id', uid);
    return url;
  }

  Future<String> uploadCover(Uint8List bytes, String ext) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final path = '$uid/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('covers').uploadBinary(path, bytes);
    final url = _supabase.storage.from('covers').getPublicUrl(path);

    await _supabase.from('users').update({'cover_url': url}).eq('id', uid);
    return url;
  }

  Future<void> followUser(String targetId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase.from('follows').insert({
      'follower_id': uid,
      'following_id': targetId,
    });
  }

  Future<void> unfollowUser(String targetId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', targetId);
  }

  Future<bool> isFollowingPro(String proId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final row = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('follower_id', uid)
        .eq('following_id', proId)
        .maybeSingle();
    return row != null;
  }

  Future<List<SocialConnection>> getSocialConnections() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data =
        await _supabase.from('social_connections').select().eq('pro_id', uid);
    return (data as List).map((e) => SocialConnection.fromJson(e)).toList();
  }

  Future<void> disconnectSocial(String platform) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase
        .from('social_connections')
        .delete()
        .eq('pro_id', uid)
        .eq('platform', platform);
  }

  String? get currentUserRole =>
      _supabase.auth.currentUser?.userMetadata?['role'] as String?;

  Future<void> linkSocial(String platform) async {
    final res = await _supabase.functions
        .invoke('link-$platform', body: {'code': 'mock_code'});
    if (res.status != 200) {
      final err = res.data is Map ? res.data['error'] : 'Link failed';
      throw Exception(err ?? 'Link failed');
    }
  }

  /// Nombre d’avis laissés par ce client (table `reviews`).
  Future<int> countReviewsLeftByClient(String clientId) async {
    final data =
        await _supabase.from('reviews').select('id').eq('client_id', clientId);
    return (data as List).length;
  }

  /// Liens `social_links` (tiktok, facebook, snapchat, twitter) → URL.
  Future<Map<String, String>> getClientSocialLinkUrls(String userId) async {
    try {
      final data = await _supabase
          .from('social_links')
          .select('platform, url')
          .eq('user_id', userId);
      final map = <String, String>{};
      for (final row in data as List) {
        final m = row as Map<String, dynamic>;
        final p = m['platform'] as String?;
        final u = m['url'] as String?;
        if (p != null && u != null && u.isNotEmpty) map[p] = u;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<List<ClientFavoriteProItem>> getClientFavoritePros(
      String userId) async {
    final favData = await _supabase
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .eq('target_type', 'pro')
        .order('created_at', ascending: false);

    final rows = favData as List;
    if (rows.isEmpty) return [];

    final orderedIds = <String>[];
    for (final r in rows) {
      final id = (r as Map<String, dynamic>)['target_id'] as String;
      if (!orderedIds.contains(id)) orderedIds.add(id);
    }

    final prosData = await _supabase
        .from('profiles_pro')
        .select(
          'id, average_rating, review_count, business_name, users(full_name, avatar_url)',
        )
        .inFilter('id', orderedIds);

    final byId = <String, Map<String, dynamic>>{};
    for (final p in prosData as List) {
      final m = p as Map<String, dynamic>;
      byId[m['id'] as String] = m;
    }

    final out = <ClientFavoriteProItem>[];
    for (final id in orderedIds) {
      final m = byId[id];
      if (m == null) continue;
      final user = m['users'] as Map<String, dynamic>?;
      final name = user?['full_name'] as String? ??
          m['business_name'] as String? ??
          'Pro';
      final avatar = user?['avatar_url'] as String?;
      final rating = (m['average_rating'] as num?)?.toDouble() ?? 0;
      final reviewCount = m['review_count'] as int? ?? 0;
      out.add(ClientFavoriteProItem(
        proId: id,
        name: name,
        rating: rating,
        reviewCount: reviewCount,
        avatarUrl: avatar,
      ));
    }
    return out;
  }

  Future<List<ClientFavoriteVideoItem>> getClientFavoriteVideos(
    String userId,
  ) async {
    final favData = await _supabase
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .eq('target_type', 'video')
        .order('created_at', ascending: false);

    final rows = favData as List;
    if (rows.isEmpty) return [];

    final orderedIds = <String>[];
    for (final r in rows) {
      final id = (r as Map<String, dynamic>)['target_id'] as String;
      if (!orderedIds.contains(id)) orderedIds.add(id);
    }

    final videoData = await _supabase
        .from('videos')
        .select('id, title, thumbnail_url')
        .inFilter('id', orderedIds);

    final byId = <String, Map<String, dynamic>>{};
    for (final v in videoData as List) {
      final m = v as Map<String, dynamic>;
      byId[m['id'] as String] = m;
    }

    final out = <ClientFavoriteVideoItem>[];
    for (final id in orderedIds) {
      final m = byId[id];
      if (m == null) continue;
      out.add(ClientFavoriteVideoItem(
        videoId: id,
        title: m['title'] as String? ?? '',
        thumbnailUrl: m['thumbnail_url'] as String?,
        durationSeconds: null,
      ));
    }
    return out;
  }

  Future<void> removeFavoriteForUser({
    required String userId,
    required String targetId,
  }) async {
    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('target_id', targetId);
  }
}
