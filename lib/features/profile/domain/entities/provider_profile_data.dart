// Entités du domaine — couche pure, sans imports Flutter/Supabase.

// ─── ProviderSocialLink ───────────────────────────────────────────────────────

class ProviderSocialLink {
  const ProviderSocialLink({
    required this.platform,
    required this.handle,
    this.url,
    this.isLinked = false,
  });

  final String platform;
  final String handle;
  final String? url;
  final bool isLinked;
}

// ─── ProviderEntity ───────────────────────────────────────────────────────────

class ProviderEntity {
  const ProviderEntity({
    required this.id,
    required this.fullName,
    required this.username,
    this.bio,
    required this.profession,
    this.location,
    this.avatarUrl,
    this.coverUrl,
    this.isVerified = false,
    this.tiktokReach = 0,
    this.igPresence = 0,
    this.subscribersCount = 0,
    this.followersCount = 0,
    this.bookingsCompleted = 0,
    this.averageRating = 0.0,
    this.reviewsCount = 0,
    this.socialLinks = const [],
  });

  final String id;
  final String fullName;
  final String username;
  final String? bio;
  final String profession;
  final String? location;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isVerified;

  /// Reach TikTok (abonnés sur la plateforme liée).
  final int tiktokReach;

  /// Présence Instagram (abonnés sur la plateforme liée).
  final int igPresence;

  /// Abonnés Spotbook.
  final int subscribersCount;

  /// Followers (follows sur le profil).
  final int followersCount;

  final int bookingsCompleted;
  final double averageRating;
  final int reviewsCount;

  /// Handles réseaux (profil public client).
  final List<ProviderSocialLink> socialLinks;

  ProviderEntity copyWith({
    String? fullName,
    String? username,
    String? bio,
    String? profession,
    String? location,
    String? avatarUrl,
    String? coverUrl,
    int? followersCount,
    List<ProviderSocialLink>? socialLinks,
  }) =>
      ProviderEntity(
        id: id,
        fullName: fullName ?? this.fullName,
        username: username ?? this.username,
        bio: bio ?? this.bio,
        profession: profession ?? this.profession,
        location: location ?? this.location,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        coverUrl: coverUrl ?? this.coverUrl,
        isVerified: isVerified,
        tiktokReach: tiktokReach,
        igPresence: igPresence,
        subscribersCount: subscribersCount,
        followersCount: followersCount ?? this.followersCount,
        bookingsCompleted: bookingsCompleted,
        averageRating: averageRating,
        reviewsCount: reviewsCount,
        socialLinks: socialLinks ?? this.socialLinks,
      );

  factory ProviderEntity.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>? ?? {};
    final socials = (json['social_links'] as List<dynamic>?) ?? [];

    int tiktokReach = 0;
    int igPresence = 0;
    final linkList = <ProviderSocialLink>[];
    for (final s in socials) {
      if (s is! Map) continue;
      final m = Map<String, dynamic>.from(s);
      final platform = m['platform'] as String? ?? '';
      final count = m['followers_count'] as int? ?? 0;
      if (platform == 'tiktok') tiktokReach = count;
      if (platform == 'instagram') igPresence = count;
      final handle = (m['handle'] as String?)?.trim() ?? '';
      final url = (m['url'] as String?)?.trim();
      if (platform.isNotEmpty && handle.isNotEmpty) {
        linkList.add(ProviderSocialLink(
          platform: platform,
          handle: handle,
          url: url,
          isLinked: url != null && url.isNotEmpty,
        ));
      }
    }

    return ProviderEntity(
      id: json['id'] as String,
      fullName: user['full_name'] as String? ?? json['business_name'] as String? ?? '',
      username: user['username'] as String? ?? '',
      bio: json['description'] as String? ?? json['bio'] as String?,
      profession: json['category'] as String? ?? '',
      location: user['city'] as String?,
      avatarUrl: user['avatar_url'] as String?,
      coverUrl: user['cover_url'] as String?,
      isVerified: json['is_top_pro'] as bool? ?? false,
      tiktokReach: tiktokReach,
      igPresence: igPresence,
      subscribersCount: json['subscribers_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      bookingsCompleted: json['bookings_completed'] as int? ?? 0,
      averageRating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      socialLinks: linkList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'username': username,
        'bio': bio,
        'profession': profession,
        'location': location,
        'avatar_url': avatarUrl,
        'cover_url': coverUrl,
        'is_verified': isVerified,
        'tiktok_reach': tiktokReach,
        'ig_presence': igPresence,
        'subscribers_count': subscribersCount,
        'followers_count': followersCount,
        'bookings_completed': bookingsCompleted,
        'average_rating': averageRating,
        'reviews_count': reviewsCount,
        'social_links': socialLinks
            .map((e) => {'platform': e.platform, 'handle': e.handle})
            .toList(),
      };
}

// ─── ServiceEntity ────────────────────────────────────────────────────────────

class ServiceEntity {
  const ServiceEntity({
    required this.id,
    required this.name,
    this.description,
    this.durationMinutes = 60,
    required this.price,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool isActive;

  factory ServiceEntity.fromJson(Map<String, dynamic> json) => ServiceEntity(
        id: json['id'] as String,
        name: ServiceEntity._displayNameFromRow(json),
        description: json['description'] as String?,
        durationMinutes: json['duration_minutes'] as int? ?? 60,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  /// Bases distantes : `name` (schéma repo) ou `title` (variantes).
  static String _displayNameFromRow(Map<String, dynamic> json) {
    for (final key in ['name', 'title', 'service_name']) {
      final v = json[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'duration_minutes': durationMinutes,
        'price': price,
        'is_active': isActive,
      };
}

// ─── VideoEntity ──────────────────────────────────────────────────────────────

class VideoEntity {
  const VideoEntity({
    required this.id,
    this.thumbnailUrl,
    this.streamUrl,
    this.title,
    this.viewsCount = 0,
    this.status,
  });

  final String id;
  final String? thumbnailUrl;
  final String? streamUrl;
  final String? title;
  final int viewsCount;

  /// `processing`, `pending_review`, `approved`, `rejected`, `flagged` — hub pro.
  final String? status;

  factory VideoEntity.fromJson(Map<String, dynamic> json) => VideoEntity(
        id: json['id'] as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        streamUrl: json['stream_url'] as String?,
        title: json['title'] as String?,
        viewsCount: json['views_count'] as int? ?? 0,
        status: json['status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'thumbnail_url': thumbnailUrl,
        'stream_url': streamUrl,
        'title': title,
        'views_count': viewsCount,
        if (status != null) 'status': status,
      };
}

// ─── EventEntity ──────────────────────────────────────────────────────────────

class EventEntity {
  const EventEntity({
    required this.id,
    required this.title,
    this.eventDate,
    this.eventTime,
    this.venueName,
    this.maxAttendees = 0,
    this.ticketsSold = 0,
    this.coverUrl,
  });

  final String id;
  final String title;
  final DateTime? eventDate;
  final String? eventTime;
  final String? venueName;
  final int maxAttendees;
  final int ticketsSold;
  final String? coverUrl;

  factory EventEntity.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    if (json['event_date'] != null) {
      date = DateTime.tryParse(json['event_date'] as String);
    }

    String? time;
    if (date != null) {
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      time = '$h:$m';
    }

    return EventEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      eventDate: date,
      eventTime: time,
      venueName: json['location'] as String? ?? json['address'] as String?,
      maxAttendees: json['max_attendees'] as int? ?? 0,
      ticketsSold: json['tickets_sold'] as int? ?? 0,
      coverUrl: json['cover_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'event_date': eventDate?.toIso8601String(),
        'event_time': eventTime,
        'venue_name': venueName,
        'max_attendees': maxAttendees,
        'tickets_sold': ticketsSold,
        'cover_url': coverUrl,
      };
}

// ─── ProviderProfileData ──────────────────────────────────────────────────────

/// Agrégat retourné par [GetProviderProfile].
class ProviderProfileData {
  const ProviderProfileData({
    required this.provider,
    required this.services,
    required this.videos,
    required this.events,
  });

  final ProviderEntity provider;
  final List<ServiceEntity> services;
  final List<VideoEntity> videos;
  final List<EventEntity> events;

  ProviderProfileData copyWith({
    ProviderEntity? provider,
    List<ServiceEntity>? services,
    List<VideoEntity>? videos,
    List<EventEntity>? events,
  }) =>
      ProviderProfileData(
        provider: provider ?? this.provider,
        services: services ?? this.services,
        videos: videos ?? this.videos,
        events: events ?? this.events,
      );

  Map<String, dynamic> toJson() => {
        'provider': provider.toJson(),
        'services': services.map((s) => s.toJson()).toList(),
        'videos': videos.map((v) => v.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory ProviderProfileData.fromJson(Map<String, dynamic> json) =>
      ProviderProfileData(
        provider: ProviderEntity.fromJson(
            json['provider'] as Map<String, dynamic>),
        services: (json['services'] as List<dynamic>)
            .map((e) => ServiceEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        videos: (json['videos'] as List<dynamic>)
            .map((e) => VideoEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        events: (json['events'] as List<dynamic>)
            .map((e) => EventEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
