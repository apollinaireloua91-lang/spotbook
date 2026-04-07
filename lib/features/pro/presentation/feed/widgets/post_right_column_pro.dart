import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/bookmark_bounce.dart';
import '../../../../feed/domain/video_model.dart';
import '../../../../feed/presentation/widgets/share_bottom_sheet.dart';
import '../../../../moderation/presentation/screens/report_sheet.dart';

/// Right action column for the Pro feed.
/// Order: Avatar → Like → Save → Share → Spotify → More
/// NO comment button (exclusive to Client).
///
/// Spec: 46px circles, 20px gaps, backdrop blur(8px), border rgba(255,255,255,0.12).
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
        // ── Pro avatar (46px + 2px border) ──
        GestureDetector(
          onTap: () => context.push('/pro/${video.proId}'),
          child: SizedBox(
            width: 46,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 21,
                    backgroundColor: AppColors.surfaceAlt,
                    backgroundImage: video.proAvatarUrl != null
                        ? CachedNetworkImageProvider(video.proAvatarUrl!)
                        : null,
                    child: video.proAvatarUrl == null
                        ? const Icon(Icons.person,
                            size: 20, color: AppColors.gris)
                        : null,
                  ),
                ),
                // "+" follow badge — violet
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
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF043603),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
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

        // ── Like ──
        _BlurActionButton(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          iconSize: 28,
          label: '',
          color: video.isLiked ? Colors.red : Colors.white,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleLike();
          },
        ),
        const SizedBox(height: 20),

        // ── Save (BookmarkBounce) ──
        BookmarkBounce(
          isSaved: video.isSaved,
          child: _BlurActionButton(
            icon: video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            iconSize: 26,
            label: '',
            color: video.isSaved ? const Color(0xFF043603) : Colors.white,
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleSave();
            },
          ),
        ),
        const SizedBox(height: 20),

        // ── Share ──
        _BlurActionButton(
          icon: Icons.reply,
          iconSize: 24,
          label: '',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => ShareBottomSheet(videoId: video.id),
            );
          },
          mirrorIcon: true,
        ),
        const SizedBox(height: 20),

        // ── More (moderation) ──
        _BlurActionButton(
          icon: Icons.more_horiz,
          iconSize: 22,
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
                title: const Text('Report',
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
}

/// 46px action button with backdrop blur.
class _BlurActionButton extends StatelessWidget {
  const _BlurActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 24,
    this.color = Colors.white,
    this.mirrorIcon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;
  final Color color;
  final bool mirrorIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(89),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(31),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: mirrorIcon
                      ? Transform.flip(
                          flipX: true,
                          child: Icon(icon, color: color, size: iconSize,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                          ),
                        )
                      : Icon(icon, color: color, size: iconSize,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
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
