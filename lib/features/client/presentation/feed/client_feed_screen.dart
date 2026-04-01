import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../feed/data/feed_notifier.dart';
import '../../../feed/presentation/widgets/video_feed_item.dart';
import 'cubit/client_feed_cubit.dart';
import 'widgets/client_top_bar.dart';

/// Feed client plein écran (PageView vertical) — piloté par [ClientFeedCubit].
class ClientFeedScreen extends StatefulWidget {
  const ClientFeedScreen({super.key});

  @override
  State<ClientFeedScreen> createState() => _ClientFeedScreenState();
}

class _ClientFeedScreenState extends State<ClientFeedScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientFeedCubit, ClientFeedState>(
      listenWhen: (p, c) => c.error != null && c.error != p.error,
      listener: (context, state) {
        final msg = state.error;
        if (msg == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg == 'like_failed'
                  ? 'Impossible de mettre à jour le like'
                  : msg == 'save_failed'
                      ? 'Impossible de mettre à jour le favori'
                      : msg,
            ),
          ),
        );
        context.read<ClientFeedCubit>().clearTransientError();
      },
      child: BlocConsumer<ClientFeedCubit, ClientFeedState>(
        listenWhen: (p, c) =>
            p.activeTab != c.activeTab ||
            (p.videos.isNotEmpty && c.videos.isEmpty && c.isLoading),
        listener: (context, state) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        },
        builder: (context, state) {
          final cubit = context.read<ClientFeedCubit>();
          return Scaffold(
            backgroundColor: AppColors.fond,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                if (state.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.violet),
                  )
                else if (state.videos.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.violet.withAlpha(25),
                            ),
                            child: Icon(
                              state.activeTab == FeedTab.following
                                  ? Icons.person_add_rounded
                                  : Icons.play_circle_rounded,
                              size: 48,
                              color: AppColors.violet,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            state.activeTab == FeedTab.following
                                ? 'Aucun abonnement'
                                : 'Aucune vidéo pour le moment',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.blanc,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.activeTab == FeedTab.following
                                ? 'Abonnez-vous à des professionnels\npour retrouver leurs vidéos ici'
                                : 'Découvrez bientôt les créations\ndes meilleurs pros près de chez vous',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.gris,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          if (state.activeTab == FeedTab.following) ...[
                            const SizedBox(height: 28),
                            SizedBox(
                              width: 200,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () =>
                                    cubit.switchTab(FeedTab.discover),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.violet,
                                  foregroundColor: AppColors.blanc,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Découvrir des pros',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (state.error != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Une erreur est survenue',
                              style: TextStyle(
                                color: AppColors.error.withAlpha(180),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => cubit.switchTab(state.activeTab),
                              child: const Text(
                                'Réessayer',
                                style: TextStyle(
                                  color: AppColors.violet,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.violet,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: state.videos.length,
                    onPageChanged: cubit.setCurrentIndex,
                    itemBuilder: (context, index) {
                      return VideoFeedItem(
                        video: state.videos[index],
                        isActive: index == state.currentIndex,
                        onLikeToggled: (liked) => cubit.toggleLike(index, liked),
                        index: index,
                        useLocalHeartAnimation: true,
                        onToggleLike: (i, l) => cubit.toggleLike(i, l),
                        onToggleSave: (i, s) => cubit.toggleSave(i, s),
                        onToggleFollow: (i, f) => cubit.toggleFollow(i, f),
                      );
                    },
                  ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClientTopBar(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
