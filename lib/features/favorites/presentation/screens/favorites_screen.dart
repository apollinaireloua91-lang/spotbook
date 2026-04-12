import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: Semantics(
            label: 'Back',
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    color: AppColors.blanc, size: 16),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.pop();
              },
            ),
          ),
          title: Text(
            'Favorites',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.textOnPrimary,
                unselectedLabelColor: AppColors.gris,
                labelStyle: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Pros'),
                  Tab(text: 'Events'),
                ],
              ),
            ),
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
                    emptySubLabel: 'Pros you save will appear here.',
                    onTap: (fav) => context.push('/pro/${fav.targetId}'),
                  ),
                  _FavoritesList(
                    favorites: state.eventFavorites,
                    emptyIcon: Icons.event_outlined,
                    emptyLabel: 'No favorite events',
                    emptySubLabel: 'Events you save will appear here.',
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
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
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

// ═════════════════════════════════════════════════════════════════════════════
// FAVORITES LIST
// ═════════════════════════════════════════════════════════════════════════════

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({
    required this.favorites,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.emptySubLabel,
    required this.onTap,
  });

  final List<FavoriteModel> favorites;
  final IconData emptyIcon;
  final String emptyLabel;
  final String emptySubLabel;
  final void Function(FavoriteModel) onTap;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(10),
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon, color: AppColors.violet, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              emptyLabel,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubLabel,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final fav = favorites[index];
        return _FavoriteCard(favorite: fav, onTap: () => onTap(fav));
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FAVORITE CARD
// ═════════════════════════════════════════════════════════════════════════════

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.favorite, required this.onTap});
  final FavoriteModel favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
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
                      errorWidget: (_, __, ___) => _fallbackAvatar(),
                    )
                  : _fallbackAvatar(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.targetName ?? 'Unnamed',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (favorite.targetSubtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      favorite.targetSubtitle!,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
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

  Widget _fallbackAvatar() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.surfaceAlt,
      child:
          Icon(Icons.person, color: AppColors.gris, size: 20),
    );
  }
}
