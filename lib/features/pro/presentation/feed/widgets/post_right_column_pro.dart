import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../../../../../shared/widgets/bookmark_bounce.dart';
import '../../../../feed/domain/video_model.dart';
import '../../../../feed/presentation/widgets/share_bottom_sheet.dart';
import '../../../../feed/presentation/widgets/spotify_music_sheet.dart';
import '../../../../moderation/presentation/screens/report_sheet.dart';

/// Right action column for the Pro feed.
/// Order: Avatar → Like → Save → Share → Spotify → More
/// NO comment button (exclusive to Client).
class PostRightColumnPro extends StatelessWidget {
  const PostRightColumnPro({
    super.key,
    required this.video,
    required this.onToggleLike,
    required this.onToggleSave,
    this.onToggleFollow,
  });

  final VideoModel video;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback? onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Pro avatar ──
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blanc, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceAlt,
              backgroundImage: video.proAvatarUrl != null
                  ? CachedNetworkImageProvider(video.proAvatarUrl!)
                  : null,
              child: video.proAvatarUrl == null
                  ? const Icon(Icons.person, size: 20, color: AppColors.gris)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Like ──
        _ActionButton(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(video.likesCount),
          color: video.isLiked ? AppColors.rose : AppColors.blanc,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleLike();
          },
        ),
        const SizedBox(height: 18),

        // ── Save (BookmarkBounce) ──
        BookmarkBounce(
          isSaved: video.isSaved,
          child: _ActionButton(
            icon: video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: video.isSaved ? 'Sauvé' : 'Sauver',
            color: video.isSaved ? AppColors.warning : AppColors.blanc,
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleSave();
            },
          ),
        ),
        const SizedBox(height: 18),

        // ── Share ──
        _ActionButton(
          icon: Icons.reply,
          label: 'Partager',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => ShareBottomSheet(videoId: video.id),
            );
          },
          mirrorIcon: true,
        ),
        const SizedBox(height: 18),

        // ── Spotify (enhanced Pro style) ──
        _SpotifyActionButton(
          onTap: () => showSpotifyMusicSheet(context: context),
        ),
        const SizedBox(height: 18),

        // ── More (moderation) ──
        _ActionButton(
          icon: Icons.more_horiz,
          label: '',
          onTap: () => _openModerationMenu(context),
        ),
      ],
    );
  }

  void _openModerationMenu(BuildContext context) {
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
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                    targetId: video.id,
                    targetType: 'video',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// Enhanced Spotify button with green styling.
class _SpotifyActionButton extends StatelessWidget {
  const _SpotifyActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.spotifyGreen.withAlpha(31), // rgba(30,215,96,0.12)
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.spotifyGreen.withAlpha(89), // rgba(30,215,96,0.35)
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.music_note,
                color: AppColors.spotifyGreen,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Musique',
            style: TextStyle(
              color: AppColors.spotifyGreen,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(
                  color: AppColors.overlayHeavy,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.blanc,
    this.mirrorIcon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool mirrorIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blanc.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: mirrorIcon
                  ? Transform.flip(
                      flipX: true,
                      child: Icon(icon, color: color, size: 24),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(label, style: AppTypography.feedActionCount),
          ],
        ],
      ),
    );
  }
}
