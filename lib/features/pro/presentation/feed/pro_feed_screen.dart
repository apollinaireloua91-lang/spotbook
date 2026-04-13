import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../feed/data/feed_play_state.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/presentation/widgets/video_feed_item.dart';
import '../../../notifications/data/notification_repository.dart';
import 'cubit/pro_feed_cubit.dart';
import 'widgets/post_left_column_pro.dart';
import 'widgets/post_right_column_pro.dart';
import 'widgets/pro_notif_sheets.dart';

/// Pro feed screen — mirrors the client feed structure.
///
/// Same premium glassmorphism top bar + persistent play/pause button.
/// Pro-specific: 4 notification buttons (bell, calendar, tickets, messages),
/// no Discover/Following tabs, no Comment button on videos.
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

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    return BlocProvider(
      create: (_) => ProFeedCubit(
        videoRepository: ref.read(videoRepositoryProvider),
        notificationRepository: ref.read(notificationRepositoryProvider),
      ),
      child: _ProFeedBody(pageController: _pageController),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FEED BODY — same layout as client FeedScreen
// ═════════════════════════════════════════════════════════════════════════════

class _ProFeedBody extends ConsumerWidget {
  const _ProFeedBody({required this.pageController});

  final PageController pageController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final isPlaying = ref.watch(feedPlayStateProvider);

    return BlocListener<ProFeedCubit, ProFeedState>(
      listenWhen: (p, c) => c.error != null && c.error != p.error,
      listener: (context, state) {
        final msg = state.error;
        if (msg == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg == 'like_failed'
                  ? 'Failed to update like'
                  : msg == 'save_failed'
                      ? 'Failed to update save'
                      : msg,
            ),
          ),
        );
        context.read<ProFeedCubit>().clearTransientError();
      },
      child: BlocBuilder<ProFeedCubit, ProFeedState>(
        builder: (context, state) {
          final cubit = context.read<ProFeedCubit>();
          final currentUid =
              Supabase.instance.client.auth.currentUser?.id;

          // ── Loading state ──
          if (state.isLoading) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.violet,
                  ),
                ),
              ),
            );
          }

          // ── Empty state ──
          if (state.videos.isEmpty) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.violet.withAlpha(20),
                        border: Border.all(
                          color: AppColors.violet.withAlpha(40),
                        ),
                      ),
                      child: Icon(Icons.play_circle_outline_rounded,
                          size: 40,
                          color: AppColors.violet.withAlpha(180)),
                    ),
                    const SizedBox(height: 20),
                    Text('Aucune vidéo',
                        style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                        'Les vidéos des professionnels\napparaîtront ici',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withAlpha(120),
                            fontSize: 14)),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: cubit.refresh,
                      child: Container(
                        width: 160,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientAccent,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppColors.primaryButtonShadow,
                        ),
                        child: Center(
                          child: Text('Actualiser',
                              style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Main feed ──
          return Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // ─── Video PageView ───
                PageView.builder(
                  controller: pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: state.videos.length,
                  onPageChanged: (i) {
                    cubit.setCurrentIndex(i);
                    ref.read(feedPlayStateProvider.notifier).set(true);
                  },
                  itemBuilder: (context, index) {
                    final video = state.videos[index];
                    final isOwnPost = video.proId == currentUid;
                    return VideoFeedItem(
                      video: video,
                      isActive: index == state.currentIndex,
                      onLikeToggled: (liked) =>
                          cubit.toggleLike(index, liked),
                      index: index,
                      useLocalHeartAnimation: true,
                      onToggleLike: cubit.toggleLike,
                      onToggleSave: cubit.toggleSave,
                      onToggleFollow: cubit.toggleFollow,
                      bottomOverlayOverride: PostLeftColumnPro(
                        video: video,
                        onBook: isOwnPost
                            ? null
                            : () =>
                                context.push('/pro/${video.proId}'),
                      ),
                      rightColumnOverride: PostRightColumnPro(
                        video: video,
                        onToggleLike: () =>
                            cubit.toggleLike(index, !video.isLiked),
                        onToggleSave: () =>
                            cubit.toggleSave(index, !video.isSaved),
                        onToggleFollow: () => cubit.toggleFollow(
                            index, !video.isFollowed),
                      ),
                    );
                  },
                ),

                // ─── Premium Top Bar — Glassmorphism (same as client feed) ───
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: EdgeInsets.only(
                            top: topPad + 10,
                            left: 16,
                            right: 16,
                            bottom: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(140),
                              Colors.black.withAlpha(40),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                        child: Row(
                          children: [
                            // Spotbook logo — premium with subtle glow
                            Text(
                              'Spotbook',
                              style: AppTypography.spotbookLogo(
                                      onVideoBackground: true)
                                  .copyWith(
                                fontSize: 20,
                                letterSpacing: -0.8,
                                shadows: [
                                  const Shadow(
                                    color: AppColors.shadowTextLight,
                                    blurRadius: 12,
                                    offset: Offset(0, 1),
                                  ),
                                  Shadow(
                                    color:
                                        AppColors.violet.withAlpha(40),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // ── 4 Pro notification buttons ──
                            BlocBuilder<ProFeedCubit, ProFeedState>(
                              buildWhen: (p, c) =>
                                  p.unreadNotif != c.unreadNotif ||
                                  p.unreadRdv != c.unreadRdv ||
                                  p.unreadTickets !=
                                      c.unreadTickets ||
                                  p.unreadMessages !=
                                      c.unreadMessages,
                              builder: (context, s) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ProNotifButton(
                                      icon: Icons
                                          .notifications_outlined,
                                      hasUnread:
                                          s.unreadNotif > 0,
                                      dotColor: AppColors.rose,
                                      onTap: () => _openSheet(
                                          context,
                                          const ProActivitySheet()),
                                    ),
                                    const SizedBox(width: 8),
                                    _ProNotifButton(
                                      icon: Icons
                                          .calendar_today_outlined,
                                      hasUnread: s.unreadRdv > 0,
                                      dotColor:
                                          AppColors.violetClair,
                                      onTap: () => _openSheet(
                                          context,
                                          const ProRdvSheet()),
                                    ),
                                    const SizedBox(width: 8),
                                    _ProNotifButton(
                                      icon: Icons
                                          .confirmation_number_outlined,
                                      hasUnread:
                                          s.unreadTickets > 0,
                                      dotColor: AppColors.rose,
                                      onTap: () => _openSheet(
                                          context,
                                          const ProTicketsSheet()),
                                    ),
                                    const SizedBox(width: 8),
                                    _ProNotifButton(
                                      icon: Icons
                                          .chat_bubble_outline_rounded,
                                      hasUnread:
                                          s.unreadMessages > 0,
                                      dotColor: AppColors.success,
                                      onTap: () => _openSheet(
                                          context,
                                          const ProMessagesSheet()),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Persistent Play/Pause — top left, below top bar ───
                Positioned(
                  top: topPad + 62,
                  left: 16,
                  child: _PremiumPlayPauseButton(
                    isPlaying: isPlaying,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(feedPlayStateProvider.notifier).toggle();
                    },
                  ),
                ),

                // ── Video progress indicator ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _PremiumVideoProgress(
                    currentIndex: state.currentIndex,
                    totalCount: state.videos.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PLAY/PAUSE BUTTON — persistent, glassmorphism (same as client feed)
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumPlayPauseButton extends StatefulWidget {
  const _PremiumPlayPauseButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  State<_PremiumPlayPauseButton> createState() =>
      _PremiumPlayPauseButtonState();
}

class _PremiumPlayPauseButtonState extends State<_PremiumPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = widget.isPlaying
              ? 0.6 + (_pulseController.value * 0.4)
              : 1.0;

          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? Colors.black
                          .withAlpha((60 * pulseValue).round())
                      : Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isPlaying
                        ? Colors.white.withAlpha(25)
                        : AppColors.violet.withAlpha(100),
                    width: widget.isPlaying ? 0.5 : 1.0,
                  ),
                  boxShadow: widget.isPlaying
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.violet.withAlpha(50),
                            blurRadius: 16,
                            spreadRadius: -2,
                          ),
                        ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(widget.isPlaying),
                    color: widget.isPlaying
                        ? Colors.white.withAlpha(200)
                        : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRO NOTIFICATION BUTTON — glassmorphism matching the top bar
// ═════════════════════════════════════════════════════════════════════════════

class _ProNotifButton extends StatelessWidget {
  const _ProNotifButton({
    required this.icon,
    required this.hasUnread,
    required this.dotColor,
    required this.onTap,
  });

  final IconData icon;
  final bool hasUnread;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(80),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withAlpha(120),
                            blurRadius: 6,
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
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VIDEO PROGRESS — thin gradient line at bottom
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumVideoProgress extends StatelessWidget {
  const _PremiumVideoProgress({
    required this.currentIndex,
    required this.totalCount,
  });

  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 1) return const SizedBox.shrink();

    final progress = (currentIndex + 1) / totalCount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 88, left: 16, right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: SizedBox(
            height: 3,
            child: Stack(
              children: [
                Container(color: Colors.white.withAlpha(20)),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientAccent,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet.withAlpha(80),
                          blurRadius: 6,
                          spreadRadius: -1,
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
    );
  }
}
