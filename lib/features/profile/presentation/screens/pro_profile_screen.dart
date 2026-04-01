import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../booking/presentation/screens/booking_bottom_sheet.dart';
import '../../../events/data/event_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/domain/video_model.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/pro_profile_content_widgets.dart';
import '../widgets/social_badge_widget.dart';

final proProfileProvider =
    FutureProvider.family<ProProfile?, String>((ref, proId) async {
  return ref.read(profileRepositoryProvider).getProProfile(proId);
});

final proProfileVideosProvider =
    FutureProvider.family<List<VideoModel>, String>((ref, proId) async {
  final list = await ref.read(videoRepositoryProvider).getProVideos(proId);
  return list.where((v) => v.status == 'approved').toList();
});

final proProfileServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, proId) async {
  return ref.read(bookingRepositoryProvider).getProServices(proId);
});

final proProfileEventsForProProvider =
    FutureProvider.family<List<EventModel>, String>((ref, proId) async {
  return ref.read(eventRepositoryProvider).getEventsByProId(proId);
});

class ProProfileScreen extends ConsumerWidget {
  const ProProfileScreen({super.key, required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(proProfileProvider(proId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.fond,
            appBar: AppBar(
              backgroundColor: AppColors.fond,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.blanc, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: Text(
                'Profil introuvable',
                style: TextStyle(color: AppColors.gris),
              ),
            ),
          );
        }
        return _ProProfileScaffold(profile: profile);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.blanc),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.blanc, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Erreur : $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _ProProfileScaffold extends ConsumerWidget {
  const _ProProfileScaffold({required this.profile});

  final ProProfile profile;

  void _openMoreMenu(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.flag_outlined, color: AppColors.blanc),
                title: const Text('Signaler',
                    style: TextStyle(color: AppColors.blanc)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showReportSheet(
                    context,
                    targetId: profile.id,
                    targetType: 'user',
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block, color: AppColors.error),
                title: const Text('Bloquer',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showBlockConfirmDialog(
                    context,
                    ref: ref,
                    userId: profile.id,
                    userName: profile.businessName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(profileRepositoryProvider).currentUserId;
    final isOwn = myId != null && myId == profile.id;
    final canPop = Navigator.of(context).canPop();

    final categoryCityParts = <String>[];
    if (profile.category.isNotEmpty) {
      categoryCityParts.add(profile.category);
    }
    if (profile.city != null && profile.city!.trim().isNotEmpty) {
      categoryCityParts.add(profile.city!.trim());
    }
    final categoryCity = categoryCityParts.join(' · ');

    final socialEligible = profile.socialConnections
        .where((c) => c.followersCount >= 10000)
        .toList();

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          return Scaffold(
            backgroundColor: AppColors.fond,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.blanc, size: 20),
                      onPressed: () => context.pop(),
                    )
                  : null,
              actions: [
                if (isOwn)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.blanc),
                    onPressed: () => context.push('/settings'),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppColors.blanc),
                    onPressed: () => _openMoreMenu(context, ref),
                  ),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180 + 40,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 180,
                                width: double.infinity,
                                color: AppColors.surface,
                                child: profile.coverUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: profile.coverUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 180,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: -40,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.blanc,
                                            width: 3,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: AppColors.surfaceAlt,
                                          backgroundImage:
                                              profile.avatarUrl != null
                                                  ? CachedNetworkImageProvider(
                                                      profile.avatarUrl!,
                                                    )
                                                  : null,
                                          child: profile.avatarUrl == null
                                              ? const Icon(Icons.person,
                                                  size: 40,
                                                  color: AppColors.gris)
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.blanc,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: AppColors.fond,
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
                        const SizedBox(height: 52),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                profile.businessName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.blanc,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (profile.isTopPro)
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
                          ),
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
                        if (categoryCity.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            categoryCity,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.gris,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.gris, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.rating.toStringAsFixed(1)} (${profile.reviewsCount} avis)',
                              style: const TextStyle(
                                color: AppColors.gris,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (socialEligible.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < socialEligible.length; i++) ...[
                                if (i > 0) const SizedBox(width: 16),
                                SocialBadgeWidget(
                                  platform: socialEligible[i].platform,
                                  followersCount: socialEligible[i].followersCount,
                                  compact: true,
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (profile.bio != null &&
                            profile.bio!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              profile.bio!.trim(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.blanc,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SpotbookButton.primary(
                                label: 'Book Appointment',
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  showBookingSheet(
                                    context,
                                    proId: profile.id,
                                    proProfile: profile,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              SpotbookButton.secondary(
                                label: 'Buy Event Ticket',
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  tabController.animateTo(2);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(height: 1, color: AppColors.border),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        indicatorColor: AppColors.blanc,
                        indicatorWeight: 2,
                        labelColor: AppColors.blanc,
                        unselectedLabelColor: AppColors.gris,
                        dividerColor: Colors.transparent,
                        tabs: const [
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
                  _ProVideosGrid(proId: profile.id),
                  _ProServicesList(
                    proId: profile.id,
                    proProfile: profile,
                  ),
                  _ProEventsList(proId: profile.id),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

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
    return ColoredBox(
      color: AppColors.fond,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}

class _ProVideosGrid extends ConsumerWidget {
  const _ProVideosGrid({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileVideosProvider(proId));

    return async.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(
            child: Text(
              'Aucune vidéo approuvée',
              style: TextStyle(color: AppColors.gris, fontSize: 14),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: videos.length,
          itemBuilder: (context, i) {
            return VideoThumbnailCard(video: videos[i]);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      ),
      error: (e, _) => Center(
        child: Text(
          'Erreur : $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _ProServicesList extends ConsumerWidget {
  const _ProServicesList({
    required this.proId,
    required this.proProfile,
  });

  final String proId;
  final ProProfile proProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileServicesProvider(proId));

    return async.when(
      data: (services) {
        if (services.isEmpty) {
          return const Center(
            child: Text(
              'Aucun service',
              style: TextStyle(color: AppColors.gris, fontSize: 14),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: services.length,
          itemBuilder: (context, i) {
            return ProServiceCard(
              service: services[i],
              proProfile: proProfile,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      ),
      error: (e, _) => Center(
        child: Text(
          'Erreur : $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _ProEventsList extends ConsumerWidget {
  const _ProEventsList({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileEventsForProProvider(proId));

    return async.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Text(
              'Aucun événement',
              style: TextStyle(color: AppColors.gris, fontSize: 14),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: events.length,
          itemBuilder: (context, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProEventProfileCard(event: events[i]),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      ),
      error: (e, _) => Center(
        child: Text(
          'Erreur : $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
