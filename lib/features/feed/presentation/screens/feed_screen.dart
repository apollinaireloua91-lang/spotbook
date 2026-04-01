import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/feed_notifier.dart';
import '../widgets/client_feed_top_bar.dart';
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

    ref.listen<FeedState>(feedProvider, (previous, next) {
      if (previous?.activeTab != next.activeTab) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) return;
          if (next.videos.isNotEmpty) {
            _pageController.jumpToPage(0);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Feed content
          if (s.isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            )
          else if (s.videos.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    s.activeTab == FeedTab.following
                        ? Icons.person_add_outlined
                        : Icons.play_circle_outline,
                    size: 64,
                    color: AppColors.gris.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.activeTab == FeedTab.following
                        ? 'Aucun abonnement'
                        : 'Aucune vidéo',
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.activeTab == FeedTab.following
                        ? 'Suivez des pros pour voir leurs vidéos ici'
                        : 'Les vidéos des pros apparaîtront ici',
                    style: const TextStyle(
                      color: AppColors.gris,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
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
                );
              },
            ),

          // Top bar overlay
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClientFeedTopBar(),
          ),
        ],
      ),
    );
  }
}
