import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../feed/domain/video_model.dart';

class ClientRightColumn extends StatelessWidget {
  const ClientRightColumn({
    super.key,
    required this.video,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onToggleFollow,
    required this.onCommentTap,
    required this.onShareTap,
  });

  final VideoModel video;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onToggleFollow;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pro avatar + follow badge
        _ProAvatarWithFollow(
          proId: video.proId,
          avatarUrl: video.proAvatarUrl,
          proName: video.proName,
          isFollowed: video.isFollowed,
          onFollowTap: onToggleFollow,
        ),
        const SizedBox(height: 20),
        // Like — heart icon only
        _AnimatedActionIcon(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          color: video.isLiked ? AppColors.rose : AppColors.textOnVideo,
          count: video.likesCount,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleLike();
          },
          animate: video.isLiked,
        ),
        const SizedBox(height: 16),
        // Comment — CLIENT EXCLUSIVE
        _ActionIcon(
          icon: Icons.chat_bubble_outline,
          color: AppColors.textOnVideo,
          count: video.commentsCount,
          onTap: onCommentTap,
        ),
        const SizedBox(height: 16),
        // Save/Bookmark — NO label
        _AnimatedActionIcon(
          icon: video.isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: video.isSaved ? AppColors.violet : AppColors.textOnVideo,
          count: null,
          onTap: () {
            HapticFeedback.lightImpact();
            onToggleSave();
          },
          animate: video.isSaved,
        ),
        const SizedBox(height: 16),
        // Share — flipped reply icon, NO label
        _ActionIcon(
          icon: Icons.reply,
          color: AppColors.textOnVideo,
          onTap: onShareTap,
          flipHorizontal: true,
        ),
        // Music indicator (conditional)
        if (video.spotifyTrackTitle != null) ...[
          const SizedBox(height: 16),
          _SpinningMusicDisc(),
        ],
      ],
    );
  }
}

// ── Naked action icon + optional count ──────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.count,
    this.flipHorizontal = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? count;
  final bool flipHorizontal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          flipHorizontal
              ? Transform.flip(
                  flipX: true,
                  child: Icon(icon, color: color, size: 28),
                )
              : Icon(
                  icon,
                  color: color,
                  size: 28,
                  shadows: const [
                    Shadow(
                      color: AppColors.overlayHeavy,
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
          if (count != null && count! > 0) ...[
            const SizedBox(height: 2),
            Text(
              _formatCount(count!),
              style: const TextStyle(
                color: AppColors.textOnVideo,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: AppColors.overlayHeavy,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated action icon (like/save bounce) ─────────────────────────────────

class _AnimatedActionIcon extends StatefulWidget {
  const _AnimatedActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.animate,
    this.count,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool animate;
  final int? count;

  @override
  State<_AnimatedActionIcon> createState() => _AnimatedActionIconState();
}

class _AnimatedActionIconState extends State<_AnimatedActionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _AnimatedActionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (context, child) {
              return Transform.scale(scale: _scale.value, child: child);
            },
            child: Icon(
              widget.icon,
              color: widget.color,
              size: 28,
              shadows: const [
                Shadow(
                  color: AppColors.overlayHeavy,
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          if (widget.count != null && widget.count! > 0) ...[
            const SizedBox(height: 2),
            Text(
              _formatCount(widget.count!),
              style: const TextStyle(
                color: AppColors.textOnVideo,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: AppColors.overlayHeavy,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pro avatar with follow badge ────────────────────────────────────────────

class _ProAvatarWithFollow extends StatefulWidget {
  const _ProAvatarWithFollow({
    required this.proId,
    required this.avatarUrl,
    required this.proName,
    required this.isFollowed,
    required this.onFollowTap,
  });

  final String proId;
  final String? avatarUrl;
  final String? proName;
  final bool isFollowed;
  final VoidCallback onFollowTap;

  @override
  State<_ProAvatarWithFollow> createState() => _ProAvatarWithFollowState();
}

class _ProAvatarWithFollowState extends State<_ProAvatarWithFollow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _badgeCtrl;
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _ProAvatarWithFollow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFollowed != oldWidget.isFollowed) {
      _badgeCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.proName ?? 'P').isNotEmpty
        ? (widget.proName ?? 'P')[0].toUpperCase()
        : 'P';

    return GestureDetector(
      onTap: () => context.push('/pro/${widget.proId}'),
      child: SizedBox(
        width: 52,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textOnVideo, width: 2),
                gradient: AppColors.gradientAccent,
              ),
              child: widget.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.textOnVideo,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.textOnVideo,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            // Follow badge
            Positioned(
              bottom: 0,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onFollowTap();
                },
                child: AnimatedBuilder(
                  animation: _badgeScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _badgeScale.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: widget.isFollowed
                          ? AppColors.success
                          : AppColors.violet,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.fond, width: 1.5),
                    ),
                    child: Icon(
                      widget.isFollowed ? Icons.check : Icons.add,
                      color: AppColors.textOnVideo,
                      size: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Spinning music disc ─────────────────────────────────────────────────────

class _SpinningMusicDisc extends StatefulWidget {
  @override
  State<_SpinningMusicDisc> createState() => _SpinningMusicDiscState();
}

class _SpinningMusicDiscState extends State<_SpinningMusicDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spinCtrl,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradientAccent,
          border: Border.all(color: AppColors.textOnVideo.withAlpha(51), width: 2),
        ),
        child: const Center(
          child: Icon(Icons.music_note, color: AppColors.textOnVideo, size: 16),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return count.toString();
}
