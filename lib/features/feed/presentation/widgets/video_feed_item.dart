import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../../profile/presentation/widgets/social_badge_widget.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';
import 'comments_sheet.dart';
import 'like_animation.dart';

class _ShowLikeAnimNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() {
    state = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      state = false;
    });
  }
}

final _showLikeAnimProvider = NotifierProvider<_ShowLikeAnimNotifier, bool>(
  _ShowLikeAnimNotifier.new,
  isAutoDispose: true,
);

class VideoFeedItem extends ConsumerStatefulWidget {
  const VideoFeedItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.onLikeToggled,
  });

  final VideoModel video;
  final bool isActive;
  final ValueChanged<bool> onLikeToggled;

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem> {
  BetterPlayerController? _controller;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.video.streamUrl == null) return;

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.video.streamUrl!,
      videoFormat: BetterPlayerVideoFormat.hls,
    );

    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: false,
        looping: true,
        fit: BoxFit.cover,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        aspectRatio: 9 / 16,
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  @override
  void didUpdateWidget(covariant VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      _countView();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  void _countView() {
    if (_viewCounted) return;
    _viewCounted = true;
    ref.read(videoRepositoryProvider).incrementViewCount(widget.video.id);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleLike() {
    HapticFeedback.mediumImpact();
    final repo = ref.read(videoRepositoryProvider);
    if (widget.video.isLiked) {
      repo.unlikeVideo(widget.video.id);
      widget.onLikeToggled(false);
    } else {
      repo.likeVideo(widget.video.id);
      widget.onLikeToggled(true);
      AnalyticsService.instance.capture('video_liked', properties: {
        'video_id': widget.video.id,
        'pro_id': widget.video.proId,
      });
    }
  }

  void _onDoubleTap() {
    if (!widget.video.isLiked) {
      _toggleLike();
    }
    ref.read(_showLikeAnimProvider.notifier).trigger();
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(videoId: widget.video.id),
    );
  }

  void _openModerationMenu() {
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined, color: AppColors.blanc),
                title: const Text('Signaler', style: TextStyle(color: AppColors.blanc)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showReportSheet(
                    context,
                    targetId: widget.video.id,
                    targetType: 'video',
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block, color: AppColors.error),
                title: const Text('Bloquer ce pro', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showBlockConfirmDialog(
                    context,
                    ref: ref,
                    userId: widget.video.proId,
                    userName: widget.video.proName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLikeAnim = ref.watch(_showLikeAnimProvider);

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -300) {
          context.push('/pro/${widget.video.proId}');
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null)
            BetterPlayer(controller: _controller!)
          else if (widget.video.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: AppColors.fond),
            )
          else
            Container(color: AppColors.fond),

          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/pro/${widget.video.proId}'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceAlt,
                        backgroundImage: widget.video.proAvatarUrl != null
                            ? CachedNetworkImageProvider(widget.video.proAvatarUrl!)
                            : null,
                        child: widget.video.proAvatarUrl == null
                            ? const Icon(Icons.person, size: 18, color: AppColors.gris)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.proName ?? 'Pro',
                              style: const TextStyle(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.video.socialConnections.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: widget.video.socialConnections
                                    .map((c) => SocialBadgeWidget(
                                          platform: c['platform'] as String,
                                          followersCount: c['followers_count'] as int,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.title,
                  style: const TextStyle(color: AppColors.blanc, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.video.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.video.hashtags.map((h) => '#$h').join(' '),
                    style: const TextStyle(color: AppColors.grisClair, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            bottom: 80,
            right: 12,
            child: Column(
              children: [
                _ActionButton(
                  icon: widget.video.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(widget.video.likesCount),
                  color: widget.video.isLiked ? AppColors.error : AppColors.blanc,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(widget.video.commentsCount),
                  onTap: _openComments,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.more_horiz,
                  label: 'Plus',
                  onTap: _openModerationMenu,
                ),
              ],
            ),
          ),

          if (showLikeAnim) const Center(child: LikeAnimation()),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.blanc,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.blanc, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
