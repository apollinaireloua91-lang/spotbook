import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/social_badge_widget.dart';

final proProfileProvider = FutureProvider.family<ProProfile?, String>((ref, proId) async {
  return ref.read(profileRepositoryProvider).getProProfile(proId);
});

class ProProfileScreen extends ConsumerWidget {
  const ProProfileScreen({super.key, required this.proId});
  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(proProfileProvider(proId));

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Pro not found', style: TextStyle(color: AppColors.gris)),
            );
          }
          return _buildProfile(context, ref, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blanc)),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, ProProfile profile) {
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
                    height: 180 + 40, // Cover height + half avatar
                    child: Stack(
                      children: [
                        // Cover
                        Container(
                          height: 180,
                          width: double.infinity,
                          color: AppColors.surface,
                          child: profile.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: profile.coverUrl!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        // Back Button
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 16,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          right: 16,
                          child: Semantics(
                            label: 'Options profil',
                            child: IconButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                showModalBottomSheet(
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
                                            leading: const Icon(Icons.flag_outlined, color: AppColors.blanc),
                                            title: const Text('Signaler', style: TextStyle(color: AppColors.blanc)),
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
                                            title: const Text('Bloquer', style: TextStyle(color: AppColors.error)),
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
                              },
                              icon: const Icon(Icons.more_horiz, color: AppColors.blanc),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        // Avatar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.fond,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppColors.surfaceAlt,
                                    backgroundImage: profile.avatarUrl != null
                                        ? CachedNetworkImageProvider(profile.avatarUrl!)
                                        : null,
                                    child: profile.avatarUrl == null
                                        ? const Icon(Icons.person, size: 40, color: AppColors.gris)
                                        : null,
                                  ),
                                ),
                                // Verified Badge
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 12, color: AppColors.fondDark),
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
                  // Top Pro Badge
                  if (profile.isTopPro) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blanc,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TOP PRO',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Business Name
                  Text(
                    profile.businessName,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Username, Category, City
                  Text(
                    '${profile.username != null ? '@${profile.username} • ' : ''}${profile.category}${profile.city != null ? ' • ${profile.city}' : ''}',
                    style: const TextStyle(color: AppColors.gris, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.rating.toStringAsFixed(1)} (${profile.reviewsCount} avis)',
                        style: const TextStyle(color: AppColors.gris, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Social Badges
                  if (profile.socialConnections.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: profile.socialConnections
                          .map((conn) => SocialBadgeWidget(
                                platform: conn.platform,
                                followersCount: conn.followersCount,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Bio
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        profile.bio!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.blanc, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SpotbookButton.primary(
                          label: 'Book Appointment',
                          onPressed: () {},
                        ),
                        const SizedBox(height: 12),
                        SpotbookButton.secondary(
                          label: 'Buy Event Ticket',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border, height: 1),
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
                    Tab(text: 'Vidéos'),
                    Tab(text: 'Services'),
                    Tab(text: 'Événements'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: const TabBarView(
          children: [
            Center(child: Text('Vidéos (grille 2 cols)', style: TextStyle(color: AppColors.gris))),
            Center(child: Text('Services (liste)', style: TextStyle(color: AppColors.gris))),
            Center(child: Text('Événements (liste)', style: TextStyle(color: AppColors.gris))),
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
