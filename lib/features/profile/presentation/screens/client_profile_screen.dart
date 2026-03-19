import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Not authenticated', style: TextStyle(color: AppColors.gris)),
            );
          }
          return _buildProfile(context, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blanc)),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, ClientProfile profile) {
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Cover & Avatar
                  SizedBox(
                    height: 140 + 36, // Cover height + half avatar
                    child: Stack(
                      children: [
                        // Cover
                        Container(
                          height: 140,
                          width: double.infinity,
                          color: AppColors.surface,
                          child: profile.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: profile.coverUrl!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        // Actions (Settings)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          right: 16,
                          child: IconButton(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings, color: AppColors.blanc),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                        // Avatar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.fond,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.surfaceAlt,
                                backgroundImage: profile.avatarUrl != null
                                    ? CachedNetworkImageProvider(profile.avatarUrl!)
                                    : null,
                                child: profile.avatarUrl == null
                                    ? const Icon(Icons.person, size: 36, color: AppColors.gris)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info
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
                      style: const TextStyle(color: AppColors.gris, fontSize: 14),
                    ),
                  ],
                  if (profile.city != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.city!,
                      style: const TextStyle(color: AppColors.gris, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Edit Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SpotbookButton.outlined(
                      label: 'Modifier le profil',
                      onPressed: () {
                        // TODO: Navigate to Edit Profile
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFF2A2A2A), height: 1),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                const TabBar(
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.blanc,
                  unselectedLabelColor: AppColors.gris,
                  tabs: [
                    Tab(text: 'Favoris'),
                    Tab(text: 'Historique RDV'),
                    Tab(text: 'Mes Billets'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: const TabBarView(
          children: [
            Center(child: Text('Favoris', style: TextStyle(color: AppColors.gris))),
            Center(child: Text('Historique RDV', style: TextStyle(color: AppColors.gris))),
            Center(child: Text('Mes Billets', style: TextStyle(color: AppColors.gris))),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.fond,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
