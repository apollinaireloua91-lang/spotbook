import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
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
        const SizedBox(height: 16),
        // Like
        _AnimatedActionButton(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(video.likesCount),
          color: video.isLiked ? AppColors.rose : AppColors.blanc,
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleLike();
          },
          animate: video.isLiked,
        ),
        const SizedBox(height: 16),
        // Comment — CLIENT EXCLUSIVE
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(video.commentsCount),
          onTap: onCommentTap,
        ),
        const SizedBox(height: 16),
        // Save/Bookmark
        _AnimatedActionButton(
          icon: video.isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: _formatCount(video.savesCount),
          color: video.isSaved ? AppColors.violet : AppColors.blanc,
          onTap: () {
            HapticFeedback.lightImpact();
            onToggleSave();
          },
          animate: video.isSaved,
        ),
        const SizedBox(height: 16),
        // Share
        _ActionButton(
          icon: Icons.reply,
          label: 'Partager',
          onTap: onShareTap,
          mirrorIcon: true,
        ),
        // Music indicator (conditional)
        if (video.spotifyTrackTitle != null) ...[
          const SizedBox(height: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(51),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.violet.withAlpha(102)),
            ),
            child: const Icon(
              Icons.music_note,
              color: AppColors.blanc,
              size: 20,
            ),
          ),
        ],
      ],
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

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
                border: Border.all(color: AppColors.blanc, width: 2),
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
                              color: AppColors.blanc,
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
                          color: AppColors.blanc,
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
                      color: AppColors.blanc,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.mirrorIcon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool mirrorIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                      child: Icon(icon, color: AppColors.blanc, size: 22),
                    )
                  : Icon(icon, color: AppColors.blanc, size: 22),
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

class _AnimatedActionButton extends StatefulWidget {
  const _AnimatedActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.animate,
    this.color = AppColors.blanc,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool animate;

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
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
  void didUpdateWidget(covariant _AnimatedActionButton oldWidget) {
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
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.blanc.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
          ),
          if (widget.label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.label, style: AppTypography.feedActionCount),
          ],
        ],
      ),
    );
  }
}
