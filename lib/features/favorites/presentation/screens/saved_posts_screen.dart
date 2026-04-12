import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/cloudflare_stream_urls.dart';
import '../../data/favorite_repository.dart';
import '../../domain/favorite_model.dart';

/// Saved videos / posts screen — shows a grid of videos the client saved.
class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  List<FavoriteModel>? _savedVideos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(favoriteRepositoryProvider);
    final videos = await repo.getFavorites('video');
    if (mounted) {
      setState(() {
        _savedVideos = videos;
        _isLoading = false;
      });
    }
  }

  Future<void> _unsave(FavoriteModel fav) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Retirer des favoris ?',
            style: GoogleFonts.sora(color: AppColors.blanc)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Non', style: GoogleFonts.dmSans(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Oui', style: GoogleFonts.dmSans(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(favoriteRepositoryProvider);
    await repo.removeFavorite(fav.targetId);
    setState(() => _savedVideos?.remove(fav));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text('Posts sauvegardés',
            style:
                GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildShimmer()
          : _savedVideos == null || _savedVideos!.isEmpty
              ? _buildEmpty()
              : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _savedVideos!.length,
      itemBuilder: (context, index) {
        final fav = _savedVideos![index];
        // Try to get thumbnail from image URL (may be a cloudflare thumbnail)
        // or from the targetId (cloudflare video ID)
        final thumbnailUrl = fav.targetImageUrl ??
            cloudflareThumbnailUrl(fav.targetId);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to the video — targetId is the video ID
            context.push('/client/profile-video', extra: {'videoId': fav.targetId});
          },
          onLongPress: () => _unsave(fav),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: Icon(Icons.videocam_off,
                        color: AppColors.gris, size: 24),
                  ),
                )
              else
                Container(
                  color: AppColors.surface,
                  child: Icon(Icons.videocam,
                      color: AppColors.gris, size: 24),
                ),
              // Title overlay at bottom
              if (fav.targetName != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.overlayPicker, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      fav.targetName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              // Bookmark icon
              Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.bookmark,
                    color: AppColors.blanc, size: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border,
              color: AppColors.gris.withValues(alpha: 0.5), size: 56),
          const SizedBox(height: 12),
          Text(
            'Aucun post sauvegardé',
            style: GoogleFonts.sora(color: AppColors.gris, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Appuyez sur le signet pour sauvegarder des vidéos',
            style: GoogleFonts.dmSans(color: AppColors.grisInactif, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 9 / 16,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => Container(color: AppColors.surface),
      ),
    );
  }
}
