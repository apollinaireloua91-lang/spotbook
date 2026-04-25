import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../notifications/data/notification_notifier.dart';
import '../../data/feed_notifier.dart';
import '../../data/feed_play_state.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../widgets/video_feed_item.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final s = ref.watch(feedProvider);
    final n = ref.read(feedProvider.notifier);
    final topPad = MediaQuery.of(context).padding.top;
    final isPlaying = ref.watch(feedPlayStateProvider);

    // Transient error SnackBar (like/save/follow failures). On lit
    // uniquement la transition null → non-null pour éviter de reshowing
    // le même SnackBar à chaque rebuild.
    ref.listen<FeedState>(feedProvider, (prev, next) {
      final err = next.transientError;
      if (err == null || err == prev?.transientError) return;
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final text = switch (err) {
        'like_failed' => l.feedLikeFailed,
        'save_failed' => l.feedSaveFailed,
        'follow_failed' => l.feedFollowFailed,
        _ => err,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      ref.read(feedProvider.notifier).clearTransientError();
    });

    if (s.isLoading) {
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

    // Écran d'erreur dédié — distinct de l'empty state pour que l'utilisateur
    // ait une affordance de retry. L'auto-retry silencieux (1×) a déjà eu
    // lieu dans FeedNotifier._loadInitial avant d'arriver ici.
    if (s.loadError != null) {
      final l = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 38,
                    color: AppColors.violet.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.feedLoadError,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(200),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF700B97), Color(0xFF8E05C2)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(80),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        n.retryLoad();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        child: Text(
                          l.feedRetry,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (s.videos.isEmpty) {
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
                    size: 40, color: AppColors.violet.withAlpha(180)),
              ),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.feedEmptyTitle,
                  style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.feedEmptySubtitle,
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withAlpha(120), fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── Video PageView ───
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: s.videos.length,
            onPageChanged: (i) {
              n.setCurrentIndex(i);
              ref.read(feedPlayStateProvider.notifier).set(true);
            },
            itemBuilder: (context, index) {
              return VideoFeedItem(
                video: s.videos[index],
                isActive: index == s.currentIndex,
                index: index,
                onLikeToggled: (liked) => n.toggleLike(index, liked),
                onToggleLike: n.toggleLike,
                onToggleSave: n.toggleSave,
                onToggleFollow: n.toggleFollow,
              );
            },
          ),

          // ─── Premium Top Bar — Glassmorphism ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                      top: topPad + 10, left: 16, right: 16, bottom: 14),
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
                      Text('Spotbook',
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
                                color: AppColors.violet.withAlpha(40),
                                blurRadius: 24,
                              ),
                            ],
                          )),

                      const Spacer(),

                      // Discover / Following pill tabs
                      _FeedTabPill(
                        activeTab: s.activeTab,
                        onTap: (tab) {
                          HapticFeedback.lightImpact();
                          n.switchTab(tab);
                        },
                      ),

                      const Spacer(),

                      // Bell notification icon — frosted glass
                      _NotificationBell(
                          onTap: () => context.push('/notifications')),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Persistent Play/Pause Control — Always visible ───
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
        ],
      ),
    );
  }
}

// ─── Premium Play/Pause Button — Persistent, always visible ─────────────────

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
                      ? Colors.black.withAlpha((60 * pulseValue).round())
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
                  transitionBuilder: (child, animation) => ScaleTransition(
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

// ─── Discover / Following tab pill — Premium glass variant ──────────────────

class _FeedTabPill extends StatelessWidget {
  const _FeedTabPill({required this.activeTab, required this.onTap});

  final FeedTab activeTab;
  final ValueChanged<FeedTab> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(80),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TabItem(
                label: AppLocalizations.of(context)!.feedDiscover,
                isActive: activeTab == FeedTab.discover,
                onTap: () => onTap(FeedTab.discover),
              ),
              _TabItem(
                label: AppLocalizations.of(context)!.feedFollowing,
                isActive: activeTab == FeedTab.following,
                onTap: () => onTap(FeedTab.following),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isActive
              ? Border.all(color: Colors.white.withAlpha(10))
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: GoogleFonts.dmSans(
            color: isActive ? Colors.white : Colors.white.withAlpha(120),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: isActive ? 0.2 : 0,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ─── Notification bell — Premium frosted glass with glow dot ────────────────

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotifCountProvider);

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
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rose.withAlpha(120),
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
