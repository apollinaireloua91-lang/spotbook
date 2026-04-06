import 'dart:ui';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_bottom_sheet.dart';
import '../../data/pro_feed_notifier.dart';
import '../../data/pro_feed_repository.dart';
import '../../data/pro_own_feed_notifier.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';
import '../widgets/like_animation.dart';
import '../widgets/spotify_music_sheet.dart';

// ─── Double-tap heart animation (overlay ~600ms, spec TikTok) ─────────

class _DoubleTapHeartNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() {
    state = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      state = false;
    });
  }
}

final _doubleTapHeartProvider =
    NotifierProvider<_DoubleTapHeartNotifier, bool>(
  _DoubleTapHeartNotifier.new,
);

// ═════════════════════════════════════════════════════════════════════
// PRO FEED SCREEN — TikTok-style full-screen vertical swipe
// ═════════════════════════════════════════════════════════════════════

class ProFeedScreen extends ConsumerStatefulWidget {
  const ProFeedScreen({super.key});

  @override
  ConsumerState<ProFeedScreen> createState() => _ProFeedScreenState();
}

class _ProFeedScreenState extends ConsumerState<ProFeedScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(proOwnFeedProvider.notifier).setCurrentIndex(index);
  }

  void _toggleLike(VideoModel video, int index) {
    HapticFeedback.mediumImpact();
    final liked = !video.isLiked;
    ref.read(proOwnFeedProvider.notifier).toggleLike(index, liked);
  }

  void _toggleSave(VideoModel video, int index) {
    HapticFeedback.lightImpact();
    final saved = !video.isSaved;
    ref.read(proOwnFeedProvider.notifier).toggleSave(index, saved);
  }

  void _onDoubleTap(VideoModel video, int index) {
    if (!video.isLiked) {
      _toggleLike(video, index);
    }
    ref.read(_doubleTapHeartProvider.notifier).trigger();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(proOwnFeedProvider);
    final badges = ref.watch(proFeedBadgesProvider);
    final showHeart = ref.watch(_doubleTapHeartProvider);

    if (feed.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.blanc),
        ),
      );
    }

    if (feed.videos.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.fond,
        extendBodyBehindAppBar: true,
        body: _emptyFeedPreview(context, badges),
      );
    }

    final currentIndex = feed.currentIndex.clamp(0, feed.videos.length - 1);
    final currentVideo = feed.videos[currentIndex];

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // ── PageView (full-screen video / thumbnail) ──────────
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: feed.videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final video = feed.videos[index];
              return GestureDetector(
                onDoubleTap: () => _onDoubleTap(video, index),
                onHorizontalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < -300) {
                    context.push('/pro/profile');
                  }
                },
                child: _PostBackground(
                  video: video,
                  isActive: index == currentIndex,
                ),
              );
            },
          ),

          // ── Top bar overlay (fixed) ───────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _ProTopBar(
                badges: badges,
                onNotificationsTap: () =>
                    _showNotificationsSheet(context),
                onBookingsTap: () => _showBookingsSheet(context),
                onTicketsTap: () => _showTicketSalesSheet(context),
                onMessagesTap: () => _showMessagesSheet(context),
              ),
            ),
          ),

          // ── Right column (centrée verticalement, au-dessus de la nav) ─
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 72),
                child: _RightColumn(
                  video: currentVideo,
                  onLike: () => _toggleLike(currentVideo, currentIndex),
                  onSave: () => _toggleSave(currentVideo, currentIndex),
                  onShare: () => _showShareSheet(context, currentVideo),
                  onSpotify: () => _showSpotifySheet(context),
                ),
              ),
            ),
          ),

          // ── Left column (name, caption, CTA) ──────────────────
          Positioned(
            left: 16,
            right: 80,
            bottom: 88,
            child: _LeftColumn(video: currentVideo),
          ),

          // ── Double-tap heart animation ────────────────────────
          if (showHeart) const Center(child: LikeAnimation()),
        ],
      ),
    );
  }

  // ─── Sheet openers ────────────────────────────────────────────────

  void _showNotificationsSheet(BuildContext context) {
    showSpotbookBottomSheet(
      context: context,
      title: 'Activity on my posts',
      child: const _NotificationsSheetContent(),
    );
  }

  void _showBookingsSheet(BuildContext context) {
    showSpotbookBottomSheet(
      context: context,
      title: 'Bookings & Appointments',
      child: const _BookingsSheetContent(),
    );
  }

  void _showTicketSalesSheet(BuildContext context) {
    showSpotbookBottomSheet(
      context: context,
      title: 'Tickets sold',
      child: const _TicketSalesSheetContent(),
    );
  }

  void _showMessagesSheet(BuildContext context) {
    showSpotbookBottomSheet(
      context: context,
      title: 'Client messages',
      child: const _MessagesSheetContent(),
    );
  }

  void _showShareSheet(BuildContext context, VideoModel video) {
    showSpotbookBottomSheet(
      context: context,
      title: 'Share',
      child: _ShareSheetContent(video: video),
    );
  }

  void _showSpotifySheet(BuildContext context) {
    showSpotifyMusicSheet(context: context);
  }

  /// Même structure que le feed avec vidéos : barre du haut + colonne droite + texte, sans contenu média.
  Widget _emptyFeedPreview(BuildContext context, ProFeedBadges badges) {
    void demoAction() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceAlt,
          content: Text(
            'These buttons will be active once a video is published.',
            style: TextStyle(color: AppColors.blanc, fontSize: 13),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surfaceAlt,
                AppColors.fond,
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _ProTopBar(
              badges: badges,
              onNotificationsTap: () => _showNotificationsSheet(context),
              onBookingsTap: () => _showBookingsSheet(context),
              onTicketsTap: () => _showTicketSalesSheet(context),
              onMessagesTap: () => _showMessagesSheet(context),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 72),
              child: _EmptyFeedSideActions(
                onProfileTap: () => context.push('/pro/profile'),
                onDemoInteractionTap: demoAction,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 88,
          bottom: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ton feed pro',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only your published (approved) videos scroll here — just like for clients on your profile. Top: notifications, appointments, tickets, messages; right: interactions.',
                style: TextStyle(
                  color: AppColors.gris.withValues(alpha: 0.95),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: AppColors.blanc,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/pro/camera');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_rounded,
                            color: AppColors.fond, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Create a video',
                          style: TextStyle(
                            color: AppColors.fond,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// POST BACKGROUND — video player / thumbnail per page
// ═════════════════════════════════════════════════════════════════════

class _PostBackground extends ConsumerStatefulWidget {
  const _PostBackground({required this.video, required this.isActive});

  final VideoModel video;
  final bool isActive;

  @override
  ConsumerState<_PostBackground> createState() => _PostBackgroundState();
}

class _PostBackgroundState extends ConsumerState<_PostBackground> {
  BetterPlayerController? _controller;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.video.streamUrl == null) return;
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
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.video.streamUrl!,
        videoFormat: BetterPlayerVideoFormat.hls,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _PostBackground oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video or thumbnail
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

        // Dégradé bas : #0D0D14 depuis ~45 % de la hauteur du bandeau
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 360,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.fond,
                  AppColors.fond.withValues(alpha: 0.65),
                  Colors.transparent,
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// EMPTY FEED — colonne droite (aperçu des interactions)
// ═════════════════════════════════════════════════════════════════════

class _EmptyFeedSideActions extends StatelessWidget {
  const _EmptyFeedSideActions({
    required this.onProfileTap,
    required this.onDemoInteractionTap,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onDemoInteractionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blanc, width: 2),
                ),
                child: SpotbookAvatar(
                  imageUrl: null,
                  name: 'Pro',
                  radius: 22,
                ),
              ),
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.fond, width: 1.5),
                    ),
                    child: const Icon(Icons.add,
                        size: 14, color: AppColors.blanc),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onDemoInteractionTap,
          child: _RightColButton(
            icon: Icons.favorite_border,
            color: AppColors.blanc,
            label: '0',
            iconSize: 34,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onDemoInteractionTap,
          child: _RightColButton(
            icon: Icons.bookmark_border,
            color: AppColors.blanc,
            label: '0',
            iconSize: 32,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onDemoInteractionTap,
          child: _RightColButton(
            icon: Icons.ios_share,
            label: 'Share',
            iconSize: 30,
          ),
        ),
        const SizedBox(height: 20),
        _SpotifyButton(onTap: onDemoInteractionTap),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// TOP BAR (glass overlay)
// ═════════════════════════════════════════════════════════════════════

class _ProTopBar extends StatelessWidget {
  const _ProTopBar({
    required this.badges,
    required this.onNotificationsTap,
    required this.onBookingsTap,
    required this.onTicketsTap,
    required this.onMessagesTap,
  });

  final ProFeedBadges badges;
  final VoidCallback onNotificationsTap;
  final VoidCallback onBookingsTap;
  final VoidCallback onTicketsTap;
  final VoidCallback onMessagesTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 22,
                color: AppColors.blanc.withAlpha(235),
                shadows: const [
                  Shadow(color: AppColors.shadowDark, blurRadius: 8),
                ],
              ),
              const SizedBox(width: 5),
              Text(
                'Spotbook',
                style: AppTypography.spotbookLogo(onVideoBackground: true),
              ),
            ],
          ),
          const Spacer(),
          _BadgeButton(
            icon: Icons.notifications_outlined,
            hasUnread: badges.notifications > 0,
            badgeColor: AppColors.rose,
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 8),
          _BadgeButton(
            icon: Icons.calendar_today_outlined,
            hasUnread: badges.bookings > 0,
            badgeColor: AppColors.violet,
            onTap: onBookingsTap,
          ),
          const SizedBox(width: 8),
          _BadgeButton(
            icon: Icons.confirmation_number_outlined,
            hasUnread: badges.tickets > 0,
            badgeColor: AppColors.rose,
            onTap: onTicketsTap,
          ),
          const SizedBox(width: 8),
          _BadgeButton(
            icon: Icons.chat_bubble_outline,
            hasUnread: badges.messages > 0,
            badgeColor: AppColors.success,
            onTap: onMessagesTap,
          ),
        ],
      ),
    );
  }
}

class _BadgeButton extends StatelessWidget {
  const _BadgeButton({
    required this.icon,
    required this.onTap,
    this.hasUnread = false,
    this.badgeColor = AppColors.rose,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasUnread;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt.withAlpha(224),
                    border: Border.all(color: AppColors.blanc.withAlpha(45)),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.overlayMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.blanc, size: 20,
                      shadows: const [
                        Shadow(color: AppColors.shadowDark, blurRadius: 6),
                      ]),
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.fond, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// RIGHT COLUMN (avatar, like, save, share, spotify)
// ═════════════════════════════════════════════════════════════════════

/// Animation scale 1 → 1.4 → 1.0 (~200ms) au tap (spec J'aime / Favoris).
class _ScalePulse extends StatefulWidget {
  const _ScalePulse({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScalePulse> createState() => _ScalePulseState();
}

class _ScalePulseState extends State<_ScalePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.4)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.4, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 50,
    ),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onTap();
    await _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({
    required this.video,
    required this.onLike,
    required this.onSave,
    required this.onShare,
    required this.onSpotify,
  });

  final VideoModel video;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onSpotify;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push('/pro/profile'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blanc, width: 2),
                ),
                child: SpotbookAvatar(
                  imageUrl: video.proAvatarUrl,
                  name: video.proName,
                  radius: 22,
                ),
              ),
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.fond, width: 1.5),
                    ),
                    child: const Icon(Icons.add,
                        size: 14, color: AppColors.blanc),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _ScalePulse(
          onTap: onLike,
          child: _RightColButton(
            icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
            color: video.isLiked ? AppColors.rose : AppColors.blanc,
            label: _formatCount(video.likesCount),
            iconSize: 34,
          ),
        ),
        const SizedBox(height: 20),

        _ScalePulse(
          onTap: () {
            HapticFeedback.selectionClick();
            onSave();
          },
          child: _RightColButton(
            icon: video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: video.isSaved ? AppColors.violet : AppColors.blanc,
            label: _formatCount(video.savesCount),
            iconSize: 32,
          ),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: onShare,
          child: _RightColButton(
            icon: Icons.ios_share,
            label: 'Share',
            iconSize: 30,
          ),
        ),
        const SizedBox(height: 20),

        _SpotifyButton(onTap: onSpotify),
      ],
    );
  }
}

class _RightColButton extends StatelessWidget {
  const _RightColButton({
    required this.icon,
    required this.label,
    this.color = AppColors.blanc,
    this.iconSize = 32,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.overlayMedium,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blanc.withAlpha(50)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.overlayMedium,
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: iconSize,
                  shadows: const [
                    Shadow(color: AppColors.shadowDark, blurRadius: 8),
                  ]),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: AppColors.shadowDark, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

class _SpotifyButton extends StatelessWidget {
  const _SpotifyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.spotifyGreen.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.spotifyGreen.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.overlayMedium,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note,
                  color: AppColors.spotifyGreen,
                  size: 30,
                  shadows: [Shadow(color: AppColors.shadowDark, blurRadius: 8)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Musique',
            style: TextStyle(
              color: AppColors.spotifyGreen,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: AppColors.shadowDark, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// LEFT COLUMN (name, caption, hashtags, CTA strip)
// ═════════════════════════════════════════════════════════════════════

class _LeftColumn extends StatefulWidget {
  const _LeftColumn({required this.video});

  final VideoModel video;

  @override
  State<_LeftColumn> createState() => _LeftColumnState();
}

class _LeftColumnState extends State<_LeftColumn> {
  bool _captionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final caption = video.description?.trim().isNotEmpty == true
        ? video.description!.trim()
        : video.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                video.proName ?? 'Pro',
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  shadows: [Shadow(color: AppColors.shadowDark, blurRadius: 6)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (video.proCategory != null || video.category != null) ...[
              const SizedBox(width: 8),
              _CategoryBadge(
                  label: video.proCategory ?? video.category ?? ''),
            ],
          ],
        ),
        const SizedBox(height: 6),

        if (caption.isNotEmpty) ...[
          Text(
            caption,
            style: const TextStyle(
              color: AppColors.grisClair,
              fontSize: 12,
              height: 1.45,
              shadows: [Shadow(color: AppColors.shadowDark, blurRadius: 4)],
            ),
            maxLines: _captionExpanded ? 8 : 2,
            overflow: _captionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (caption.length > 80 || caption.split('\n').length > 2)
            GestureDetector(
              onTap: () =>
                  setState(() => _captionExpanded = !_captionExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _captionExpanded ? 'show less' : 'show more',
                  style: const TextStyle(
                    color: AppColors.violet,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],

        if (video.hashtags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                for (final h in video.hashtags)
                  TextSpan(
                    text: '#$h ',
                    style: const TextStyle(
                      color: AppColors.violet,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: AppColors.shadowDark, blurRadius: 4)],
                    ),
                  ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        if (_showServiceCta(video) || _showEventCta(video)) ...[
          const SizedBox(height: 10),
          if (_showEventCta(video))
            _EventCtaStrip(video: video)
          else
            _ServiceCtaStrip(video: video),
        ],
      ],
    );
  }

  bool _showEventCta(VideoModel v) =>
      v.eventId != null && v.eventId!.isNotEmpty;

  bool _showServiceCta(VideoModel v) =>
      !_showEventCta(v) &&
      ((v.serviceId != null && v.serviceId!.isNotEmpty) ||
          v.category != null);
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.violetClair,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ServiceCtaStrip extends StatelessWidget {
  const _ServiceCtaStrip({required this.video});

  final VideoModel video;

  String get _name =>
      video.serviceName ?? video.category ?? 'Service';

  String get _priceLine {
    if (video.servicePrice != null) {
      return '${video.servicePrice!.toStringAsFixed(0)} \$';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ctaServiceStripBg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.violet.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (_priceLine.isNotEmpty) _priceLine,
                    video.serviceNextSlot ?? 'Available on request',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.gris, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () =>
                  context.push('/client/booking-flow/${video.proId}'),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  'Book',
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCtaStrip extends StatelessWidget {
  const _EventCtaStrip({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final title = video.eventName ?? 'Event';
    String dateStr = '';
    if (video.eventDate != null) {
      try {
        final parsed = DateTime.parse(video.eventDate!);
        dateStr = '${parsed.day}/${parsed.month}';
      } catch (_) {
        dateStr = video.eventDate!;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ctaEventStripBg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.rose.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: const TextStyle(color: AppColors.gris, fontSize: 10),
                  ),
              ],
            ),
          ),
          Material(
            color: AppColors.rose,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => context.push(
                '/client/ticket-purchase/${video.eventId}',
              ),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  'Acheter',
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// SHARE SHEET
// ═════════════════════════════════════════════════════════════════════

class _ShareSheetContent extends StatelessWidget {
  const _ShareSheetContent({required this.video});

  final VideoModel video;

  static const _contactNames = ['Alex', 'Sam', 'Léa', 'Tom', 'Nina'];

  @override
  Widget build(BuildContext context) {
    final link = 'https://spotbook.app/v/${video.id}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Send to',
          style: TextStyle(
            color: AppColors.gris,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _contactNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final name = _contactNames[i];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.grisClair,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Share on',
          style: TextStyle(
            color: AppColors.gris,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ShareBrandTile(
                bg: AppColors.brandTikTok,
                label: 'TikTok',
                icon: Icons.music_note,
                onTap: () => SharePlus.instance.share(
                  ShareParams(text: link),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShareBrandTile(
                bg: AppColors.rose,
                label: 'Instagram',
                icon: Icons.camera_alt_outlined,
                onTap: () => SharePlus.instance.share(
                  ShareParams(text: link),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ShareBrandTile(
                bg: AppColors.brandWhatsApp,
                label: 'WhatsApp',
                icon: Icons.chat,
                onTap: () => SharePlus.instance.share(
                  ShareParams(text: link),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShareBrandTile(
                bg: AppColors.surface,
                label: 'Copier lien',
                icon: Icons.link,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.surfaceAlt,
                        content: Text(
                          'Link copied',
                          style: TextStyle(color: AppColors.blanc),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareBrandTile extends StatelessWidget {
  const _ShareBrandTile({
    required this.bg,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final Color bg;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.blanc, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// BOTTOM SHEETS — NOTIFICATIONS
// ═════════════════════════════════════════════════════════════════════

class _NotificationsSheetContent extends ConsumerWidget {
  const _NotificationsSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          ref.read(proFeedRepositoryProvider).fetchNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SheetLoader();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _SheetEmpty(message: 'No notifications');
        }
        return _SheetList(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final type = item['type'] as String? ?? '';
            final isRead = item['is_read'] as bool? ?? true;
            return _NotifItem(
              icon: _notifIcon(type),
              title:
                  item['title'] as String? ?? 'Notification',
              subtitle: item['body'] as String? ?? '',
              timestamp: timeAgo(
                  DateTime.parse(item['created_at'] as String)),
              isUnread: !isRead,
            );
          },
        );
      },
    );
  }

  IconData _notifIcon(String type) {
    return switch (type) {
      'like' => Icons.favorite,
      'comment' => Icons.chat_bubble,
      'follow' => Icons.person_add,
      'booking' => Icons.calendar_today,
      _ => Icons.notifications,
    };
  }
}

// ═════════════════════════════════════════════════════════════════════
// BOTTOM SHEETS — BOOKINGS
// ═════════════════════════════════════════════════════════════════════

class _BookingsSheetContent extends ConsumerWidget {
  const _BookingsSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(proFeedRepositoryProvider).fetchBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SheetLoader();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _SheetEmpty(message: 'No bookings');
        }
        return _SheetList(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final status = item['status'] as String? ?? '';
            final service =
                item['services'] as Map<String, dynamic>?;
            final serviceTitle = service?['title'] as String? ??
                service?['name'] as String?;
            return _NotifItem(
              icon: _bookingIcon(status),
              iconColor: _bookingColor(status),
              title: serviceTitle ?? 'Booking',
              subtitle: _bookingLabel(status),
              timestamp: timeAgo(
                  DateTime.parse(item['created_at'] as String)),
            );
          },
        );
      },
    );
  }

  IconData _bookingIcon(String status) {
    return switch (status) {
      'confirmed' => Icons.check_circle,
      'pending' => Icons.schedule,
      'pending_payment' => Icons.schedule,
      'cancelled' => Icons.cancel,
      'rescheduled' => Icons.update,
      _ => Icons.calendar_today,
    };
  }

  Color _bookingColor(String status) {
    return switch (status) {
      'confirmed' => AppColors.success,
      'pending' => AppColors.warning,
      'pending_payment' => AppColors.warning,
      'cancelled' => AppColors.error,
      _ => AppColors.blanc,
    };
  }

  String _bookingLabel(String status) {
    return switch (status) {
      'confirmed' => 'Confirmed',
      'pending' => 'Pending',
      'pending_payment' => 'Pending',
      'cancelled' => 'Cancelled',
      'rescheduled' => 'Rescheduled',
      _ => status,
    };
  }
}

// ═════════════════════════════════════════════════════════════════════
// BOTTOM SHEETS — TICKET SALES
// ═════════════════════════════════════════════════════════════════════

class _TicketSalesSheetContent extends ConsumerWidget {
  const _TicketSalesSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          ref.read(proFeedRepositoryProvider).fetchTicketSales(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SheetLoader();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _SheetEmpty(message: 'No tickets sold');
        }
        return _SheetList(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final event =
                item['events'] as Map<String, dynamic>?;
            return _NotifItem(
              icon: Icons.confirmation_number,
              title: event?['title'] as String? ??
                  'Ticket sold',
              subtitle: 'Ticket purchased',
              timestamp: timeAgo(DateTime.parse(
                  item['purchased_at'] as String)),
            );
          },
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// BOTTOM SHEETS — MESSAGES
// ═════════════════════════════════════════════════════════════════════

class _MessagesSheetContent extends ConsumerWidget {
  const _MessagesSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(proFeedRepositoryProvider).fetchMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SheetLoader();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _SheetEmpty(message: 'No messages');
        }
        return _SheetList(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isRead = item['is_read'] as bool? ?? true;
            return _NotifItem(
              icon: Icons.chat_bubble,
              iconColor:
                  isRead ? AppColors.gris : AppColors.success,
              title:
                  item['sender_name'] as String? ?? 'Client',
              subtitle: item['body'] as String? ?? '',
              timestamp: timeAgo(
                  DateTime.parse(item['created_at'] as String)),
              isUnread: !isRead,
            );
          },
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// SHARED BOTTOM SHEET WIDGETS
// ═════════════════════════════════════════════════════════════════════

class _SheetLoader extends StatelessWidget {
  const _SheetLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.blanc),
      ),
    );
  }
}

class _SheetEmpty extends StatelessWidget {
  const _SheetEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(message,
            style:
                const TextStyle(color: AppColors.gris, fontSize: 14)),
      ),
    );
  }
}

class _SheetList extends StatelessWidget {
  const _SheetList({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            const Divider(color: AppColors.sheetSeparator, height: 1),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  const _NotifItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.iconColor = AppColors.blanc,
    this.isUnread = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String timestamp;
  final Color iconColor;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 13,
                    fontWeight: isUnread
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.gris, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timestamp,
                  style: const TextStyle(
                      color: AppColors.gris, fontSize: 10)),
              if (isUnread) ...[
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.blanc,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// HELPERS
// ═════════════════════════════════════════════════════════════════════

// timeAgo() is now imported from shared/utils/time_ago.dart

String _formatCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}
