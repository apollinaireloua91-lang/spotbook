import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../booking/presentation/screens/booking_bottom_sheet.dart';
import '../../../events/data/event_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/domain/video_model.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../../reviews/data/review_repository.dart';
import '../../../reviews/domain/review_model.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/pro_profile_content_widgets.dart';
import '../widgets/social_badge_widget.dart';
import '../widgets/traiteur_menu_tab.dart';

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

final proProfileReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, proId) async {
  return ref.read(reviewRepositoryProvider).getProReviews(proId);
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
                'Profile not found',
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
                title: const Text('Report',
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
                title: const Text('Block',
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

    final isTraiteur =
        profile.category.toLowerCase().contains('traiteur');
    final tabCount = isTraiteur ? 5 : 4;

    return DefaultTabController(
      length: tabCount,
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
                        if (profile.socialConnections.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SocialLinksRow(
                              connections: profile.socialConnections),
                        ],
                        if (socialEligible.isNotEmpty) ...[
                          const SizedBox(height: 10),
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
                                label: 'Réserver un RDV',
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
                                label: 'Acheter un billet',
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  tabController.animateTo(3);
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
                        indicatorColor: AppColors.violet,
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: AppColors.blanc,
                        unselectedLabelColor: AppColors.gris,
                        dividerColor: AppColors.border,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                        tabs: [
                          const Tab(text: 'Vidéos'),
                          const Tab(text: 'Services'),
                          if (isTraiteur) const Tab(text: 'Menu'),
                          const Tab(text: 'Avis'),
                          const Tab(text: 'Events'),
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
                  if (isTraiteur)
                    _TraiteurMenuWrapper(proId: profile.id),
                  _ProReviewsList(
                    proId: profile.id,
                    rating: profile.rating,
                    reviewsCount: profile.reviewsCount,
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
          return const _ProTabEmpty(
            icon: Icons.videocam_outlined,
            text: 'No videos',
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
          itemBuilder: (_, i) => VideoThumbnailCard(video: videos[i]),
        );
      },
      loading: () => const SpotbookLoadingShimmer.card(itemCount: 4),
      error: (e, _) => _ProTabError(onRetry: () => ref.invalidate(proProfileVideosProvider(proId))),
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
          return const _ProTabEmpty(
            icon: Icons.design_services_outlined,
            text: 'No services',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: services.length,
          itemBuilder: (_, i) => ProServiceCard(
            service: services[i],
            proProfile: proProfile,
          ),
        );
      },
      loading: () => const SpotbookLoadingShimmer.list(itemCount: 3),
      error: (e, _) => _ProTabError(onRetry: () => ref.invalidate(proProfileServicesProvider(proId))),
    );
  }
}

// ─── Reviews tab ─────────────────────────────────────────────────────────────

class _ProReviewsList extends ConsumerWidget {
  const _ProReviewsList({
    required this.proId,
    required this.rating,
    required this.reviewsCount,
  });

  final String proId;
  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileReviewsProvider(proId));

    return async.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const _ProTabEmpty(
            icon: Icons.rate_review_outlined,
            text: 'No reviews yet',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: reviews.length + 1,
          itemBuilder: (_, index) {
            // Summary header
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _ReviewSummary(
                  rating: rating,
                  count: reviewsCount,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: reviews[index - 1]),
            );
          },
        );
      },
      loading: () => const SpotbookLoadingShimmer.list(itemCount: 4),
      error: (e, _) => _ProTabError(onRetry: () => ref.invalidate(proProfileReviewsProvider(proId))),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$count avis',
                style: const TextStyle(
                  color: AppColors.gris,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                for (int stars = 5; stars >= 1; stars--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '$stars',
                          style: const TextStyle(
                            color: AppColors.gris,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: review.clientAvatarUrl != null
                    ? CachedNetworkImageProvider(review.clientAvatarUrl!)
                    : null,
                child: review.clientAvatarUrl == null
                    ? const Icon(Icons.person, size: 14, color: AppColors.gris)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName ?? 'Client',
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeAgo(review.createdAt),
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null &&
              review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 13,
                height: 1.45,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (review.serviceName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                review.serviceName!,
                style: const TextStyle(
                  color: AppColors.violetClair,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _TraiteurMenuWrapper extends ConsumerWidget {
  const _TraiteurMenuWrapper({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(proProfileServicesProvider(proId));
    return servicesAsync.when(
      data: (services) => TraiteurMenuTab(services: services),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      ),
      error: (_, __) => const Center(
        child: Text('Loading error',
            style: TextStyle(color: AppColors.gris)),
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
          return const _ProTabEmpty(
            icon: Icons.event_outlined,
            text: 'No events',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: events.length,
          itemBuilder: (_, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProEventProfileCard(event: events[i]),
            );
          },
        );
      },
      loading: () => const SpotbookLoadingShimmer.card(itemCount: 3),
      error: (e, _) => _ProTabError(onRetry: () => ref.invalidate(proProfileEventsForProProvider(proId))),
    );
  }
}

// ─── Shared empty / error states ─────────────────────────────────────────────

class _ProTabEmpty extends StatelessWidget {
  const _ProTabEmpty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violet.withAlpha(20),
            ),
            child: Icon(icon, size: 28, color: AppColors.violet),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(color: AppColors.gris, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ProTabError extends StatelessWidget {
  const _ProTabError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Loading error',
            style: TextStyle(color: AppColors.gris, fontSize: 14),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Réessayer',
              style: TextStyle(
                color: AppColors.violet,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.violet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
