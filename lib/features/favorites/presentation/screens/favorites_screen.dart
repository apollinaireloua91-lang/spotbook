import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/favorite_notifier.dart';
import '../../domain/favorite_model.dart';
import '../widgets/favorite_heart_button.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          leading: Semantics(
            label: 'Back',
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.pop();
              },
            ),
          ),
          title: const Text('Favorites',
              style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.blanc,
            labelColor: AppColors.blanc,
            unselectedLabelColor: AppColors.gris,
            tabs: [
              Tab(text: 'Pros'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: state.isLoading
            ? _buildShimmer()
            : TabBarView(
                children: [
                  _FavoritesList(
                    favorites: state.proFavorites,
                    emptyIcon: Icons.person_outline,
                    emptyLabel: 'No favorite pros',
                    onTap: (fav) => context.push('/pro/${fav.targetId}'),
                  ),
                  _FavoritesList(
                    favorites: state.eventFavorites,
                    emptyIcon: Icons.event_outlined,
                    emptyLabel: 'No favorite events',
                    onTap: (fav) => context.push('/event/${fav.targetId}'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({
    required this.favorites,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.onTap,
  });

  final List<FavoriteModel> favorites;
  final IconData emptyIcon;
  final String emptyLabel;
  final void Function(FavoriteModel) onTap;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, color: AppColors.gris, size: 48),
            const SizedBox(height: 12),
            Text(emptyLabel, style: const TextStyle(color: AppColors.gris, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final fav = favorites[index];
        return _FavoriteCard(favorite: fav, onTap: () => onTap(fav));
      },
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.favorite, required this.onTap});
  final FavoriteModel favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: favorite.targetImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: favorite.targetImageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.surfaceAlt,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.person, color: AppColors.gris, size: 20),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.person, color: AppColors.gris, size: 20),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.targetName ?? 'Unnamed',
                    style: const TextStyle(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (favorite.targetSubtitle != null)
                    Text(
                      favorite.targetSubtitle!,
                      style: const TextStyle(color: AppColors.gris, fontSize: 13),
                    ),
                ],
              ),
            ),
            FavoriteHeartButton(
              targetId: favorite.targetId,
              targetType: favorite.targetType,
              targetName: favorite.targetName,
              targetImageUrl: favorite.targetImageUrl,
              targetSubtitle: favorite.targetSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}
