import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../events/data/event_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/domain/video_model.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/social_badge_widget.dart';

final proProfileProvider =
    FutureProvider.family<ProProfile?, String>((ref, proId) async {
  return ref.read(profileRepositoryProvider).getProProfile(proId);
});

final proApprovedVideosProvider =
    FutureProvider.family<List<VideoModel>, String>((ref, proId) async {
  final videos = await ref.read(videoRepositoryProvider).getProVideos(proId);
  return videos.where((v) => v.status == 'approved').toList();
});

final proServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, proId) async {
  return ref.read(bookingRepositoryProvider).getProServices(proId);
});

final proEventsProvider =
    FutureProvider.family<List<EventModel>, String>((ref, proId) async {
  final events = await ref.read(eventRepositoryProvider).getEvents();
  return events.where((e) => e.proId == proId).toList();
});

class ProProfileScreen extends ConsumerWidget {
  const ProProfileScreen({super.key, required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(proProfileProvider(proId));

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, color: AppColors.blanc),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'Pro introuvable',
                style: TextStyle(color: AppColors.gris),
              ),
            );
          }
          return _ProfileContent(profile: profile);
        },
        loading: () => const _ProProfileShimmer(),
        error: (err, _) => Center(
          child: Text(
            'Erreur : $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final ProProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(proApprovedVideosProvider(profile.id));
    final servicesAsync = ref.watch(proServicesProvider(profile.id));
    final eventsAsync = ref.watch(proEventsProvider(profile.id));
    final visibleSocials = profile.socialConnections
        .where((c) => c.followersCount >= 10000)
        .toList();

    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _CoverImage(url: profile.coverUrl),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.blanc,
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppColors.surfaceAlt,
                                    backgroundImage: profile.avatarUrl != null
                                        ? CachedNetworkImageProvider(
                                            profile.avatarUrl!)
                                        : null,
                                    child: profile.avatarUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: AppColors.gris,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: AppColors.blanc,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: AppColors.fond,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.businessName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (profile.isTopPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blanc,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TOP PRO',
                            style: TextStyle(
                              color: AppColors.fond,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (profile.username != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '@${profile.username}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _categoryAndCity(profile),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u2B50 ${profile.rating.toStringAsFixed(1)} (${profile.reviewsCount} avis)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 13,
                    ),
                  ),
                  if (visibleSocials.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 24,
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: visibleSocials.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (_, index) {
                          final social = visibleSocials[index];
                          return SocialBadgeWidget(
                            platform: social.platform,
                            followersCount: social.followersCount,
                          );
                        },
                      ),
                    ),
                  ],
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        profile.bio!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SpotbookButton.primary(
                      label: 'Book Appointment',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SpotbookButton.secondary(
                      label: 'Buy Event Ticket',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: AppColors.border),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                const TabBar(
                  indicatorColor: AppColors.blanc,
                  labelColor: AppColors.blanc,
                  unselectedLabelColor: AppColors.gris,
                  indicatorWeight: 2,
                  tabs: [
                    Tab(text: 'Vidéos'),
                    Tab(text: 'Services'),
                    Tab(text: 'Événements'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            videosAsync.when(
              data: (videos) => _VideosTab(videos: videos),
              loading: () => const _GridShimmer(),
              error: (err, _) => _ErrorPlaceholder(message: '$err'),
            ),
            servicesAsync.when(
              data: (services) =>
                  _ServicesTab(profile: profile, services: services),
              loading: () => const _ListShimmer(),
              error: (err, _) => _ErrorPlaceholder(message: '$err'),
            ),
            eventsAsync.when(
              data: (events) => _EventsTab(events: events),
              loading: () => const _ListShimmer(),
              error: (err, _) => _ErrorPlaceholder(message: '$err'),
            ),
          ],
        ),
      ),
    );
  }

  static String _categoryAndCity(ProProfile profile) {
    if (profile.city == null || profile.city!.isEmpty) return profile.category;
    return '${profile.category} \u2022 ${profile.city}';
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: AppColors.surface,
                highlightColor: AppColors.surfaceAlt,
                child: Container(color: AppColors.surface),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surface,
                child: const Icon(
                  Icons.image_not_supported,
                  color: AppColors.blanc,
                ),
              ),
            )
          : Container(color: AppColors.surface),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.videos});

  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const _EmptyPlaceholder(message: 'Aucune vidéo approuvée');
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (video.thumbnailUrl != null)
                        CachedNetworkImage(
                          imageUrl: video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.surface,
                            highlightColor: AppColors.surfaceAlt,
                            child: Container(color: AppColors.surface),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.blanc,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.surfaceAlt,
                          child: const Icon(
                            Icons.videocam,
                            color: AppColors.gris,
                          ),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fond,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(video.durationSeconds),
                            style: const TextStyle(
                              color: AppColors.blanc,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatDuration(double? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return '--:--';
    final total = durationSeconds.round();
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({required this.profile, required this.services});

  final ProProfile profile;
  final List<ServiceModel> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const _EmptyPlaceholder(message: 'Aucun service disponible');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final service = services[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${service.durationMinutes} min \u2022 ${_formatPrice(service.price)}',
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: SpotbookButton.outlined(
                  label: 'Réserver',
                  onPressed: () => context.push('/pro/${profile.id}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return '\$${price.toStringAsFixed(0)}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.events});

  final List<EventModel> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyPlaceholder(message: 'Aucun événement actif');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: event.coverUrl == null
                      ? Container(
                          color: AppColors.surfaceAlt,
                          child: const Icon(
                            Icons.event,
                            color: AppColors.gris,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: event.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.surface,
                            highlightColor: AppColors.surfaceAlt,
                            child: Container(color: AppColors.surface),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceAlt,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.blanc,
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(event.eventDate)} \u2022 ${_formatPrice(event.minPrice)}',
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Date à confirmer';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static String _formatPrice(double price) {
    if (price <= 0) return 'Prix à confirmer';
    if (price == price.roundToDouble()) {
      return '\$${price.toStringAsFixed(0)}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.fond, child: _tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ListShimmer extends StatelessWidget {
  const _ListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ProProfileShimmer extends StatelessWidget {
  const _ProProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView(
        children: [
          Container(height: 180, color: AppColors.surface),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 200,
              height: 20,
              color: AppColors.surfaceAlt,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 140,
              height: 14,
              color: AppColors.surfaceAlt,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: AppColors.gris)),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}
