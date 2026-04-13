import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/bookmark_bounce.dart';
import '../../../../feed/domain/video_model.dart';
import '../../../../feed/presentation/widgets/share_bottom_sheet.dart';

/// Right action column for the Pro feed — premium $20M design.
///
/// Order: Avatar → Like (with count) → Save (with count) → Share
/// NO comment button (exclusive to Client).
///
/// Design: 52px glassmorphism circles with animated neon borders,
/// gradient glow on active states, larger count labels.
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
        // ── Pro avatar (52px + gradient ring + follow badge) ──
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: SizedBox(
            width: 54,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient ring
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientAccent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(50),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    padding: const EdgeInsets.all(1.5),
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
                ),
                // "+" follow badge — elevated neon pill
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
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientAccent,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.violet.withAlpha(120),
                                blurRadius: 10,
                                spreadRadius: -2,
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
        const SizedBox(height: 22),

        // ── Like (with count) ──
        _PremiumActionButton(
          icon: video.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          label: _formatCount(video.likesCount),
          isActive: video.isLiked,
          activeColor: AppColors.rose,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleLike();
          },
        ),
        const SizedBox(height: 20),

        // ── Bookmark (BookmarkBounce) ──
        BookmarkBounce(
          isSaved: video.isSaved,
          child: _PremiumActionButton(
            icon: video.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            label: _formatCount(video.savesCount),
            isActive: video.isSaved,
            activeColor: AppColors.violetClair,
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleSave();
            },
          ),
        ),
        const SizedBox(height: 20),

        // ── Share ──
        _PremiumActionButton(
          icon: Icons.send_rounded,
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

/// 52px premium glassmorphism action button.
///
/// Design upgrades:
/// - 52px (was 50px) with rounded rect shape (radius 18) instead of circle
/// - Stronger backdrop blur (16σ) + richer glass tinting
/// - Active state: colored glass tint + animated glowing border + neon shadow
/// - Icon transitions with scale animation
/// - Bolder count labels with letter-spacing
class _PremiumActionButton extends StatelessWidget {
  const _PremiumActionButton({
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
              borderRadius: BorderRadius.circular(18),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withAlpha(60),
                        blurRadius: 18,
                        spreadRadius: -3,
                      ),
                      BoxShadow(
                        color: activeColor.withAlpha(25),
                        blurRadius: 30,
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 12,
                        spreadRadius: -3,
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor.withAlpha(25)
                        : Colors.black.withAlpha(110),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? activeColor.withAlpha(80)
                          : Colors.white.withAlpha(35),
                      width: isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Icon(
                        icon,
                        key: ValueKey('$icon-$isActive'),
                        color: isActive ? activeColor : Colors.white,
                        size: 26,
                        shadows: [
                          Shadow(
                            color: isActive
                                ? activeColor.withAlpha(100)
                                : Colors.black87,
                            blurRadius: isActive ? 12 : 6,
                          ),
                          const Shadow(color: Colors.black38, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
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
