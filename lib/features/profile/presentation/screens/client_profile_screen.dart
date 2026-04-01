import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../booking/data/booking_notifier.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../events/data/event_notifier.dart';
import '../../../favorites/data/favorite_notifier.dart';
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
    final uid = ref.watch(profileRepositoryProvider).currentUserId;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.blanc),
            onPressed: () => context.push('/settings'),
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
          final isOwn = uid != null && profile.id == uid;
          return _ClientProfileBody(profile: profile, isOwnProfile: isOwn);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blanc),
        ),
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

class _ClientProfileBody extends StatelessWidget {
  const _ClientProfileBody({
    required this.profile,
    required this.isOwnProfile,
  });

  final ClientProfile profile;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 140 + 36,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          color: AppColors.surface,
                          child: profile.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: profile.coverUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 140,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: -36,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.blanc,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.surfaceAlt,
                                backgroundImage: profile.avatarUrl != null
                                    ? CachedNetworkImageProvider(
                                        profile.avatarUrl!,
                                      )
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    profile.fullName,
                    textAlign: TextAlign.center,
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
                  if (profile.city != null && profile.city!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${profile.city}',
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
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
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),
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
            _ClientFavoritesTab(),
            _ClientHistoryTab(),
            _ClientTicketsTab(),
          ],
        ),
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

bool _isHistoryBooking(BookingModel b) {
  if (b.isPast || b.isCancelled) return true;
  final raw = b.slotDate;
  if (raw == null || raw.isEmpty) return false;
  final d = DateTime.tryParse(raw);
  if (d == null) return false;
  return !d.isAfter(DateTime.now());
}

class _ClientFavoritesTab extends ConsumerWidget {
  const _ClientFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesListProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      );
    }

    final items = [...state.proFavorites, ...state.eventFavorites];
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Aucun favori pour le moment',
          style: TextStyle(color: AppColors.gris, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final fav = items[i];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            fav.targetName ?? 'Favori',
            style: const TextStyle(color: AppColors.blanc, fontSize: 15),
          ),
          subtitle: Text(
            fav.targetType == 'pro' ? 'Pro' : 'Événement',
            style: const TextStyle(color: AppColors.gris, fontSize: 12),
          ),
          onTap: () {
            if (fav.targetType == 'pro') {
              context.push('/pro/${fav.targetId}');
            } else {
              context.push('/event/${fav.targetId}');
            }
          },
        );
      },
    );
  }
}

class _ClientHistoryTab extends ConsumerWidget {
  const _ClientHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientBookingsProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      );
    }

    final past = state.bookings.where(_isHistoryBooking).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (past.isEmpty) {
      return const Center(
        child: Text(
          'Aucun historique de rendez-vous',
          style: TextStyle(color: AppColors.gris, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: past.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = past[i];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            b.serviceName ?? 'Service',
            style: const TextStyle(color: AppColors.blanc, fontSize: 15),
          ),
          subtitle: Text(
            b.proName ?? '',
            style: const TextStyle(color: AppColors.gris, fontSize: 12),
          ),
        );
      },
    );
  }
}

class _ClientTicketsTab extends ConsumerWidget {
  const _ClientTicketsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userTicketsProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      );
    }

    if (state.tickets.isEmpty) {
      return const Center(
        child: Text(
          'Aucun billet',
          style: TextStyle(color: AppColors.gris, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: state.tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = state.tickets[i];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            t.eventTitle ?? 'Événement',
            style: const TextStyle(color: AppColors.blanc, fontSize: 15),
          ),
          subtitle: Text(
            t.ticketTypeName ?? '',
            style: const TextStyle(color: AppColors.gris, fontSize: 12),
          ),
          onTap: () => context.push('/ticket-detail', extra: t),
        );
      },
    );
  }
}
