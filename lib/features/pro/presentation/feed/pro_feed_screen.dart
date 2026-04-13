import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/presentation/widgets/video_feed_item.dart';
import '../../../notifications/data/notification_repository.dart';
import 'cubit/pro_feed_cubit.dart';
import 'widgets/post_left_column_pro.dart';
import 'widgets/post_right_column_pro.dart';
import 'widgets/pro_top_bar.dart';

/// Pro feed screen — TikTok-style vertical video feed.
///
/// Key differences from ClientFeedScreen:
/// - No tabs (Découvrir / Abonnements) — shows all approved videos
/// - ProTopBar with 4 notification buttons (bell, calendar, tickets, messages)
/// - Right column: Like + Save + Share + Spotify (NO Comment button)
/// - Premium play/pause controls always visible on screen
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
    return BlocProvider(
      create: (context) => ProFeedCubit(
        videoRepository: ref.read(videoRepositoryProvider),
        notificationRepository: ref.read(notificationRepositoryProvider),
      ),
      child: _ProFeedBody(pageController: _pageController),
    );
  }
}

class _ProFeedBody extends StatelessWidget {
  const _ProFeedBody({required this.pageController});

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
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
          return Scaffold(
            backgroundColor: AppColors.fond,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // ── Content ──
                if (state.isLoading)
                  const SpotbookLoadingShimmer.feed()
                else if (state.videos.isEmpty)
                  _ProFeedEmptyState(onRetry: cubit.refresh)
                else
                  RefreshIndicator(
                    onRefresh: cubit.refresh,
                    color: AppColors.violet,
                    backgroundColor: AppColors.surface,
                    child: PageView.builder(
                      controller: pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: state.videos.length,
                      onPageChanged: cubit.setCurrentIndex,
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
                          // Pro feed: left column with Book CTA (hidden on own posts)
                          bottomOverlayOverride: PostLeftColumnPro(
                            video: video,
                            onBook: isOwnPost
                                ? null
                                : () => context
                                    .push('/pro/${video.proId}'),
                          ),
                          // Pro feed: enhanced right column without Comment button
                          rightColumnOverride: PostRightColumnPro(
                            video: video,
                            onToggleLike: () =>
                                cubit.toggleLike(index, !video.isLiked),
                            onToggleSave: () =>
                                cubit.toggleSave(index, !video.isSaved),
                            onToggleFollow: () =>
                                cubit.toggleFollow(
                                    index, !video.isFollowed),
                          ),
                        );
                      },
                    ),
                  ),

                // ── Top bar (always on top) ──
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ProTopBar(),
                ),

                // ── Video progress indicator — thin premium line ──
                if (!state.isLoading && state.videos.isNotEmpty)
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
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM VIDEO PROGRESS — thin gradient line at bottom
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
                // Track
                Container(
                  color: Colors.white.withAlpha(20),
                ),
                // Progress
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

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATE — premium design
// ═════════════════════════════════════════════════════════════════════════════

class _ProFeedEmptyState extends StatelessWidget {
  const _ProFeedEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium icon container with gradient ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.violet.withAlpha(30),
                    AppColors.violet.withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.violet.withAlpha(40),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.play_circle_rounded,
                size: 52,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Aucune vidéo',
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Les vidéos des professionnels\napparaîtront ici',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Premium gradient button
            GestureDetector(
              onTap: onRetry,
              child: Container(
                width: 180,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.primaryButtonShadow,
                ),
                child: Center(
                  child: Text(
                    'Actualiser',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
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
