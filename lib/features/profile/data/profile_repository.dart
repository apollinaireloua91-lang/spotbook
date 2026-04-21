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

  Future<ClientProfile?> getClientProfile(String userId) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ClientProfile.fromJson(data);
  }

  Future<ProProfile?> getProProfile(String proId) async {
    final uid = currentUserId;

    // Fetch pro profile with user data (social_links queried separately — no FK from profiles_pro)
    final data = await _supabase
        .from('profiles_pro')
        .select('*, users(*)')
        .eq('id', proId)
        .maybeSingle();
    if (data == null) return null;

    // Social links live in a separate table keyed by user_id
    try {
      final socialLinksData = await _supabase
          .from('social_links')
          .select('*')
          .eq('user_id', proId);
      data['social_links'] = socialLinksData;
    } catch (_) {
      data['social_links'] = <Map<String, dynamic>>[];
    }

    bool isFollowed = false;
    if (uid != null) {
      try {
        final followData = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('follower_id', uid)
            .eq('following_id', proId)
            .maybeSingle();
        isFollowed = followData != null;
      } catch (_) {
        // follows query is non-critical for profile display
      }
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
      // Check if pro
      final role = _supabase.auth.currentUser?.userMetadata?['role'];
      if (role == 'pro') {
        await _supabase
            .from('profiles_pro')
            .update({'description': bio, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', uid);
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
    await _supabase.from('follows').upsert({
      'follower_id': uid,
      'following_id': targetId,
    }, onConflict: 'follower_id,following_id');
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

  Future<List<SocialConnection>> getSocialConnections() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await _supabase
        .from('social_links')
        .select()
        .eq('user_id', uid);
    return (data as List).map((e) => SocialConnection.fromJson(e)).toList();
  }

  Future<void> disconnectSocial(String platform) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase
        .from('social_links')
        .delete()
        .eq('user_id', uid)
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

  Future<void> saveSocialLink({
    required String platform,
    required String handle,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');
    await _supabase.from('social_links').upsert(
      {
        'user_id': uid,
        'platform': platform,
        'handle': handle,
        'followers_count': 0,
      },
      onConflict: 'user_id,platform',
    );
  }

  Future<List<Map<String, dynamic>>> getClientFavoritePros() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await _supabase
        .from('client_favorite_pros')
        .select('*, users!pro_id(id, full_name, display_name, avatar_url, profiles_pro(business_name, category, city, rating_average, is_top_pro))')
        .eq('client_id', uid);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getClientFavoriteVideos() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await _supabase
        .from('post_saves')
        .select('*, videos(*, users!pro_id(id, full_name, avatar_url, profiles_pro(business_name, category)))')
        .eq('user_id', uid);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<String>> getClientSocialLinkUrls() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await _supabase
        .from('social_links')
        .select('handle, platform')
        .eq('user_id', uid);
    return (data as List).map((e) => e['handle'] as String? ?? '').toList();
  }

  Future<int> countReviewsLeftByClient() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final data = await _supabase
        .from('reviews')
        .select('id')
        .eq('client_id', uid);
    return (data as List).length;
  }

  Future<int> countClientBookings() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final data = await _supabase
        .from('bookings')
        .select('id')
        .eq('client_id', uid);
    return (data as List).length;
  }

  Future<int> countFollowing() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final data = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', uid);
    return (data as List).length;
  }

  Future<int> countClientTickets() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    final data = await _supabase
        .from('tickets')
        .select('id')
        .eq('user_id', uid);
    return (data as List).length;
  }

  Future<List<Map<String, dynamic>>> getRecentClientHistory({int limit = 5}) async {
    final uid = currentUserId;
    if (uid == null) return [];
    final data = await _supabase
        .from('bookings')
        .select('*, services(name, title, price), pro:users!pro_id(full_name, display_name, avatar_url, profiles_pro(business_name, category))')
        .eq('client_id', uid)
        .inFilter('status', ['completed', 'cancelled_full_refund', 'cancelled_no_refund'])
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
