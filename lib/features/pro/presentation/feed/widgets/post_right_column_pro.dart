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
/// Order: Avatar → Like (with count) → Save (with count) → Share
/// NO comment button (exclusive to Client).
///
/// Enhanced design: 50px circles, neon glow on active states,
/// stronger frosted glass, prominent count labels.
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
        // ── Pro avatar (50px + border + subtle glow) ──
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: SizedBox(
            width: 50,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.black38,
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: AppColors.violet.withAlpha(50),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surfaceAlt,
                    backgroundImage: video.proAvatarUrl != null
                        ? CachedNetworkImageProvider(video.proAvatarUrl!)
                        : null,
                    child: video.proAvatarUrl == null
                        ? Icon(Icons.person, size: 20, color: AppColors.gris)
                        : null,
                  ),
                ),
                // "+" follow badge — gradient accent
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
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientAccent,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.violet.withAlpha(100),
                                blurRadius: 8,
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Like (with count) ──
        _GlowActionButton(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(video.likesCount),
          isActive: video.isLiked,
          activeColor: AppColors.rose,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleLike();
          },
        ),
        const SizedBox(height: 18),

        // ── Bookmark (BookmarkBounce) ──
        BookmarkBounce(
          isSaved: video.isSaved,
          child: _GlowActionButton(
            icon: video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: _formatCount(video.savesCount),
            isActive: video.isSaved,
            activeColor: AppColors.violetClair,
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleSave();
            },
          ),
        ),
        const SizedBox(height: 18),

        // ── Share ──
        _GlowActionButton(
          icon: Icons.share_outlined,
          label: '',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => ShareBottomSheet(videoId: video.id),
            );
          },
        ),
      ],
    );
  }
}

/// 50px action button with enhanced frosted glass + neon glow on active state.
///
/// Improvements over the old _BlurActionButton:
/// - 50px (was 44px) — bigger touch target, more visual weight
/// - Stronger backdrop blur (14σ vs 10σ) + more opaque bg
/// - Active state: tinted glass + colored border + outer glow shadow
/// - Colored count label when active
class _GlowActionButton extends StatelessWidget {
  const _GlowActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withAlpha(70),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor.withAlpha(30)
                        : Colors.black.withAlpha(115),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? activeColor.withAlpha(90)
                          : Colors.white.withAlpha(45),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isActive ? activeColor : Colors.white,
                      size: 28,
                      shadows: [
                        Shadow(
                          color: isActive
                              ? activeColor.withAlpha(100)
                              : Colors.black87,
                          blurRadius: isActive ? 12 : 8,
                        ),
                        const Shadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(color: Colors.black87, blurRadius: 6),
                  Shadow(color: Colors.black54, blurRadius: 3),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
