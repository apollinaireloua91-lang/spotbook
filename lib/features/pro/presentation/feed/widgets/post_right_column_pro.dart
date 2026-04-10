import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/bookmark_bounce.dart';
import '../../../../feed/domain/video_model.dart';
import '../../../../feed/presentation/widgets/share_bottom_sheet.dart';

/// Right action column for the Pro feed.
/// Order: Avatar → Like (with count) → Save → Share → More
/// NO comment button (exclusive to Client).
///
/// Spec: 44px circles, 18px gaps, backdrop blur(10px), frosted glass.
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

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    if (count == 0) return '';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Pro avatar (44px + 2px border) ──
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: SizedBox(
            width: 44,
            height: 54,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceAlt,
                    backgroundImage: video.proAvatarUrl != null
                        ? CachedNetworkImageProvider(video.proAvatarUrl!)
                        : null,
                    child: video.proAvatarUrl == null
                        ? Icon(Icons.person,
                            size: 18, color: AppColors.gris)
                        : null,
                  ),
                ),
                // "+" follow badge
                if (!video.isFollowed)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onToggleFollow?.call();
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.black, size: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ── Like (with count) ──
        _BlurActionButton(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          iconSize: 28,
          label: _formatCount(video.likesCount),
          color: video.isLiked ? Colors.red : Colors.white,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleLike();
          },
        ),
        const SizedBox(height: 18),

        // ── Bookmark (BookmarkBounce) ──
        BookmarkBounce(
          isSaved: video.isSaved,
          child: _BlurActionButton(
            icon: video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            iconSize: 28,
            label: _formatCount(video.savesCount),
            color: video.isSaved ? Colors.white : Colors.white,
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleSave();
            },
          ),
        ),
        const SizedBox(height: 18),

        // ── Share ──
        _BlurActionButton(
          icon: Icons.share_outlined,
          iconSize: 28,
          label: '',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => ShareBottomSheet(videoId: video.id),
            );
          },
        ),
        // More menu removed — clean 4-action layout
      ],
    );
  }

}

/// 44px action button with frosted glass backdrop blur.
class _BlurActionButton extends StatelessWidget {
  const _BlurActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 28,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(25),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: iconSize,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            )),
          ],
        ],
      ),
    );
  }
}
