import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';

class ClientProfileNotifier extends AsyncNotifier<ClientProfile?> {
  @override
  Future<ClientProfile?> build() async {
    final uid = ref.read(profileRepositoryProvider).currentUserId;
    if (uid == null) return null;
    return ref.read(profileRepositoryProvider).getClientProfile(uid);
  }
}

final clientProfileProvider =
    AsyncNotifierProvider<ClientProfileNotifier, ClientProfile?>(
  ClientProfileNotifier.new,
);

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clientProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
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
                'Non authentifié',
                style: TextStyle(color: AppColors.gris),
              ),
            );
          }
          return _ClientProfileBody(profile: profile);
        },
        loading: () => const _ClientProfileShimmer(),
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

class _ClientProfileBody extends ConsumerWidget {
  const _ClientProfileBody({required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnProfile =
        ref.read(profileRepositoryProvider).currentUserId == profile.id;

    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 176,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _CoverImage(url: profile.coverUrl),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.blanc,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.surfaceAlt,
                                backgroundImage: profile.avatarUrl != null
                                    ? CachedNetworkImageProvider(
                                        profile.avatarUrl!)
                                    : null,
                                child: profile.avatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 36,
                                        color: AppColors.gris,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.username != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (profile.city != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.gris,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.city!,
                          style: const TextStyle(
                            color: AppColors.gris,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isOwnProfile) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SpotbookButton.outlined(
                        label: 'Modifier le profil',
                        onPressed: () => context.push('/edit-profile'),
                      ),
                    ),
                  ],
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
                    Tab(text: 'Favoris'),
                    Tab(text: 'Historique'),
                    Tab(text: 'Billets'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: const TabBarView(
          children: [
            _EmptyTabPlaceholder(label: 'Favoris'),
            _EmptyTabPlaceholder(label: 'Historique'),
            _EmptyTabPlaceholder(label: 'Billets'),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
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

class _EmptyTabPlaceholder extends StatelessWidget {
  const _EmptyTabPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: const TextStyle(color: AppColors.gris)),
    );
  }
}

class _ClientProfileShimmer extends StatelessWidget {
  const _ClientProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView(
        children: [
          Container(height: 140, color: AppColors.surface),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceAlt,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 180,
              height: 18,
              color: AppColors.surfaceAlt,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 120,
              height: 14,
              color: AppColors.surfaceAlt,
            ),
          ),
        ],
      ),
    );
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
