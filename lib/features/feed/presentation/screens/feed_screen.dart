import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../notifications/data/notification_notifier.dart';
import '../../data/feed_notifier.dart';
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
    final s = ref.watch(feedProvider);
    final n = ref.read(feedProvider.notifier);
    final topPad = MediaQuery.of(context).padding.top;

    if (s.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.blanc)),
      );
    }

    if (s.videos.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline,
                  size: 64, color: AppColors.gris.withAlpha(128)),
              const SizedBox(height: 16),
              const Text('No videos yet',
                  style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Videos from professionals will appear here',
                  style: TextStyle(color: AppColors.gris, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── Video PageView ───
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: s.videos.length,
            onPageChanged: n.setCurrentIndex,
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

          // ─── Top Bar Overlay ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: topPad + 8, left: 16, right: 16, bottom: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.overlayMedium,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Spotbook logo — white, DM Sans bold 19
                  Text('Spotbook',
                      style: AppTypography.spotbookLogo(
                              onVideoBackground: true)
                          .copyWith(fontSize: 19)),

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

                  // Bell notification icon — 34×34
                  _NotificationBell(onTap: () => context.push('/notifications')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Discover / Following tab pill ───────────────────────────────────────────

class _FeedTabPill extends StatelessWidget {
  const _FeedTabPill({required this.activeTab, required this.onTap});

  final FeedTab activeTab;
  final ValueChanged<FeedTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.blanc.withAlpha(15), // rgba(255,255,255,0.06)
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabItem(
            label: 'Discover',
            isActive: activeTab == FeedTab.discover,
            onTap: () => onTap(FeedTab.discover),
          ),
          _TabItem(
            label: 'Following',
            isActive: activeTab == FeedTab.following,
            onTap: () => onTap(FeedTab.following),
          ),
        ],
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.violet.withAlpha(128) // rgba(108,62,244,0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isActive
                ? AppColors.blanc
                : AppColors.blanc.withAlpha(115), // rgba(255,255,255,0.45)
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ─── Notification bell with unread dot ──────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotifCountProvider);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt.withAlpha(217), // rgba(22,22,31,0.85)
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: AppColors.blanc.withAlpha(26)), // rgba(255,255,255,0.1)
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.blanc,
                    size: 19,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.fond, width: 1),
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
