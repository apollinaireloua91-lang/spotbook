import 'dart:ui';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../../shared/widgets/bookmark_bounce.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';
import 'comments_sheet.dart';
import 'like_animation.dart';
import 'share_bottom_sheet.dart';

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
    this.index,
    this.onToggleLike,
    this.onToggleSave,
    this.onToggleFollow,
    this.useLocalHeartAnimation = false,
    this.rightColumnOverride,
  });

  final VideoModel video;
  final bool isActive;
  final ValueChanged<bool> onLikeToggled;
  final int? index;
  final void Function(int index, bool liked)? onToggleLike;
  final void Function(int index, bool saved)? onToggleSave;
  final void Function(int index, bool followed)? onToggleFollow;
  final bool useLocalHeartAnimation;

  /// When provided, replaces the default right action column.
  /// Used by ProFeedScreen to show Pro-specific buttons (no Comment, enhanced Spotify).
  final Widget? rightColumnOverride;

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem> {
  BetterPlayerController? _controller;
  bool _viewCounted = false;
  bool _descriptionExpanded = false;

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
    final newLiked = !widget.video.isLiked;
    widget.onLikeToggled(newLiked);
    if (widget.onToggleLike != null && widget.index != null) {
      widget.onToggleLike!(widget.index!, newLiked);
    }
    if (newLiked) {
      AnalyticsService.instance.capture('video_liked', properties: {
        'video_id': widget.video.id,
        'pro_id': widget.video.proId,
      });
    }
  }

  void _toggleSave() {
    HapticFeedback.lightImpact();
    if (widget.onToggleSave != null && widget.index != null) {
      widget.onToggleSave!(widget.index!, !widget.video.isSaved);
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
                leading: const Icon(Icons.flag_outlined, color: AppColors.blanc),
                title: const Text('Report', style: TextStyle(color: AppColors.blanc)),
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
                title: const Text('Block this pro', style: TextStyle(color: AppColors.error)),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Video / Thumbnail ───
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

          // ─── Bottom gradient ───
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.overlayHeavy, Colors.transparent],
                ),
              ),
            ),
          ),

          // ─── Bottom overlay: Pro info + description + CTA ───
          Positioned(
            bottom: 90,
            left: 16,
            right: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pro avatar + name row
                GestureDetector(
                  onTap: () => context.push('/pro/${widget.video.proId}'),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.blanc.withAlpha(80),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceAlt,
                          backgroundImage: widget.video.proAvatarUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.video.proAvatarUrl!)
                              : null,
                          child: widget.video.proAvatarUrl == null
                              ? const Icon(Icons.person,
                                  size: 18, color: AppColors.gris)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.video.proName ?? 'Pro',
                          style: AppTypography.feedCaption(emphasized: true),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!(widget.video.isFollowed))
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (widget.onToggleFollow != null &&
                                widget.index != null) {
                              widget.onToggleFollow!(widget.index!, true);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.blanc.withAlpha(180)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                color: AppColors.blanc,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(color: AppColors.shadowTextLight, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Video title + description
                GestureDetector(
                  onTap: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: AppTypography.feedCaption(emphasized: true),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.video.description != null &&
                          widget.video.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.video.description!,
                          style: AppTypography.feedCaption(),
                          maxLines: _descriptionExpanded ? 6 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Spotify track
                if (widget.video.spotifyTrackTitle != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.music_note,
                          color: AppColors.blanc, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.video.spotifyTrackTitle} — ${widget.video.spotifyTrackArtist ?? ''}',
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 12,
                            shadows: [
                              Shadow(color: AppColors.overlayHeavy, blurRadius: 4),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // CTA strip — glassmorphism
                if (widget.video.serviceId != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xE61A1330), // rgba(26,19,48,0.9)
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.violet
                                .withAlpha(77), // rgba(108,62,244,0.3)
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.video.serviceName ?? 'Service',
                                    style: const TextStyle(
                                      color: AppColors.blanc,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.video.servicePrice != null)
                                    Text(
                                      '${widget.video.servicePrice!.toStringAsFixed(0)} \$',
                                      style: TextStyle(
                                        color: AppColors.blanc.withAlpha(180),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push(
                                  '/client/booking-flow/${widget.video.proId}?serviceId=${widget.video.serviceId}',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.violet,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: AppColors.blanc, size: 13),
                                    SizedBox(width: 5),
                                    Text(
                                      'Book',
                                      style: TextStyle(
                                        color: AppColors.blanc,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ─── Right side action buttons ───
          Positioned(
            bottom: 100,
            right: 12,
            child: widget.rightColumnOverride ??
                Column(
                  children: [
                    // Pro avatar (tap → profile)
                    GestureDetector(
                      onTap: () => context.push('/pro/${widget.video.proId}'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.blanc, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceAlt,
                          backgroundImage: widget.video.proAvatarUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.video.proAvatarUrl!)
                              : null,
                          child: widget.video.proAvatarUrl == null
                              ? const Icon(Icons.person,
                                  size: 20, color: AppColors.gris)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      icon: widget.video.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: _formatCount(widget.video.likesCount),
                      color: widget.video.isLiked
                          ? AppColors.rose
                          : AppColors.blanc,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: _formatCount(widget.video.commentsCount),
                      onTap: _openComments,
                    ),
                    const SizedBox(height: 18),
                    BookmarkBounce(
                      isSaved: widget.video.isSaved,
                      child: _ActionButton(
                        icon: widget.video.isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        label: widget.video.isSaved ? 'Saved' : 'Save',
                        color: widget.video.isSaved
                            ? AppColors.violet
                            : AppColors.blanc,
                        onTap: _toggleSave,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
                      icon: Icons.reply,
                      label: 'Share',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              ShareBottomSheet(videoId: widget.video.id),
                        );
                      },
                      mirrorIcon: true,
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
                      icon: Icons.more_horiz,
                      label: '',
                      onTap: _openModerationMenu,
                    ),
                  ],
                ),
          ),

          // ─── Double-tap like animation ───
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
