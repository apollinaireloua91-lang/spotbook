import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../cubit/client_search_cubit.dart';
import 'event_search_card.dart';
import 'pro_list_card.dart';

final _clientTrendingPostsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('posts')
      .select('''
        id, title, thumbnail_url, views_count, likes_count, created_at,
        profiles_pro!pro_id(display_name, category)
      ''')
      .eq('status', 'approved')
      .order('created_at', ascending: false)
      .limit(12);
  return (data as List).cast<Map<String, dynamic>>();
});

class SearchListView extends StatefulWidget {
  const SearchListView({super.key});

  @override
  State<SearchListView> createState() => _SearchListViewState();
}

class _SearchListViewState extends State<SearchListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientSearchCubit, ClientSearchState>(
      builder: (context, state) {
        if (state.pros.isEmpty && state.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.grisInactif,
                ),
                const SizedBox(height: 12),
                Text(
                  'No results',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gris,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try another search or category',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.grisInactif,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          children: [
            // ── Section: Près de toi ──
            if (state.pros.isNotEmpty) ...[
              _SectionTitle(
                title: 'Near you \uD83D\uDCCD',
              ),
              const SizedBox(height: 8),
              ...List.generate(state.pros.length, (index) {
                final delay = (index * 0.08).clamp(0.0, 0.6);
                return _StaggeredItem(
                  animation: _staggerCtrl,
                  delay: delay,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ProListCard(
                      pro: state.pros[index],
                      onTap: () {
                        context
                            .read<ClientSearchCubit>()
                            .openDetailPanel(state.pros[index].id);
                      },
                    ),
                  ),
                );
              }),
            ],

            // ── Section: Événements à venir ──
            if (state.events.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'Upcoming events \uD83C\uDF89',
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return EventSearchCard(
                      event: state.events[index],
                      onTap: () => context.push(
                        '/event/${state.events[index].id}',
                      ),
                    );
                  },
                ),
              ),
            ],

            // ── Section: Videos ──
            const SizedBox(height: 20),
            const _ClientVideosSection(),
          ],
        );
      },
    );
  }
}

// ─── Videos Section (Riverpod Consumer inside Bloc tree) ────────────

class _ClientVideosSection extends ConsumerStatefulWidget {
  const _ClientVideosSection();

  @override
  ConsumerState<_ClientVideosSection> createState() =>
      _ClientVideosSectionState();
}

class _ClientVideosSectionState extends ConsumerState<_ClientVideosSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(_clientTrendingPostsProvider);

    posts.whenData((_) {
      if (!_staggerCtrl.isAnimating && _staggerCtrl.value == 0) {
        _staggerCtrl.forward();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: AppColors.violetClair, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Videos',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/client/feed'),
                child: Text(
                  'See all',
                  style: GoogleFonts.dmSans(
                    color: AppColors.violet,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: posts.when(
            loading: () => _buildShimmerGrid(),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load videos',
                  style:
                      GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return _buildVideoGrid(list);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 0.8),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        builder: (_, opacity, __) => AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 500),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid(List<Map<String, dynamic>> posts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final delay = index * 80;

        return AnimatedBuilder(
          animation: _staggerCtrl,
          builder: (context, child) {
            final progress = Curves.easeOutCubic.transform(
              ((_staggerCtrl.value * 1200 - delay) / 400).clamp(0.0, 1.0),
            );
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - progress)),
                child: Transform.scale(
                  scale: 0.85 + 0.15 * progress,
                  child: child,
                ),
              ),
            );
          },
          child: _ClientVideoCard(post: post),
        );
      },
    );
  }
}

// ── Single video card ──

class _ClientVideoCard extends StatelessWidget {
  const _ClientVideoCard({required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final thumb = post['thumbnail_url'] as String?;
    final title = post['title'] as String? ?? '';
    final views = post['views_count'] as int? ?? 0;
    final likes = post['likes_count'] as int? ?? 0;
    final pro = post['profiles_pro'] as Map<String, dynamic>?;
    final category = pro?['category'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/client/feed'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null && thumb.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceAlt,
                    child: Icon(Icons.videocam,
                        color: AppColors.grisInactif, size: 28),
                  ),
                )
              else
                Container(
                  color: AppColors.surfaceAlt,
                  child: Icon(Icons.videocam,
                      color: AppColors.grisInactif, size: 28),
                ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.overlayHeavy],
                    ),
                  ),
                ),
              ),

              // Play icon
              Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.textOnPrimary,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.play_arrow, color: AppColors.violet, size: 16),
                ),
              ),

              // Bottom info
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: AppColors.textOnVideo,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.visibility,
                            color: AppColors.textOnVideo, size: 10),
                        const SizedBox(width: 2),
                        Text(_formatCount(views),
                            style: GoogleFonts.dmSans(
                                color: AppColors.textOnVideo, fontSize: 9)),
                        const SizedBox(width: 6),
                        const Icon(Icons.favorite,
                            color: AppColors.textOnVideo, size: 10),
                        const SizedBox(width: 2),
                        Text(_formatCount(likes),
                            style: GoogleFonts.dmSans(
                                color: AppColors.textOnVideo, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),

              // Category badge
              if (category.isNotEmpty)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textOnPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
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

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ─── Section Title ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.blanc,
        ),
      ),
    );
  }
}

// ─── Staggered FadeSlideUp ───────────────────────────────────────────

class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({
    required this.animation,
    required this.delay,
    required this.child,
  });

  final AnimationController animation;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
