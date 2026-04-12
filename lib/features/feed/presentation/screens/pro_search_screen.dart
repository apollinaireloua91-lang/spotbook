import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/discover_search_repository.dart';
import '../../domain/provider_search_result.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PRO SEARCH SCREEN — Explorer (trending, pros nearby, events, inspirations)
// ═════════════════════════════════════════════════════════════════════════════

class ProSearchScreen extends ConsumerStatefulWidget {
  const ProSearchScreen({super.key});

  @override
  ConsumerState<ProSearchScreen> createState() => _ProSearchScreenState();
}

class _ProSearchScreenState extends ConsumerState<ProSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<ProviderSearchResult> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(discoverSearchRepositoryProvider);
      final results = await repo.getAllProviders();
      // Client-side filter by name/category
      final q = query.toLowerCase();
      setState(() {
        _results = results
            .where((r) =>
                r.displayName.toLowerCase().contains(q) ||
                (r.category?.toLowerCase().contains(q) ?? false))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Search error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.explore_rounded,
                          color: AppColors.violetClair,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Explorer',
                          style: AppTypography.proHubTitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.dmSans(
                            color: AppColors.blanc, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search pros, hashtags...',
                          hintStyle: GoogleFonts.dmSans(
                              color: AppColors.gris.withAlpha(153)),
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.gris, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: _onSearch,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search results ──
            if (_isSearching)
              SliverFillRemaining(
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.violet),
                ),
              )
            else if (_results.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _ProSearchCard(result: _results[i]),
                ),
              )
            else ...[
              // ── Pros populaires près de toi ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Text(
                    'Popular pros near you',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _PopularProsSection(ref: ref),
              ),

              // ── Événements tendance ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Text(
                    'Trending events',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _TrendingEventsSection()),

              // ── Videos ──
              const SliverToBoxAdapter(child: _InspirationsSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// POPULAR PROS NEARBY — horizontal grid
// ═════════════════════════════════════════════════════════════════════════════

class _PopularProsSection extends StatelessWidget {
  const _PopularProsSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProviderSearchResult>>(
      future: ref.read(discoverSearchRepositoryProvider).getAllProviders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            ),
          );
        }
        final pros = (snapshot.data ?? []).take(10).toList();
        if (pros.isEmpty) {
          return SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'No pros nearby',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
              ),
            ),
          );
        }
        return SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            scrollDirection: Axis.horizontal,
            itemCount: pros.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ProPopularCard(pro: pros[i]),
          ),
        );
      },
    );
  }
}

class _ProPopularCard extends StatelessWidget {
  const _ProPopularCard({required this.pro});

  final ProviderSearchResult pro;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/provider/${pro.id}'),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cover gradient
            Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(
                  colors: [
                    AppColors.violet.withAlpha(102),
                    AppColors.rose.withAlpha(77),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: pro.avatarUrl == null
                        ? LinearGradient(
                            colors: [
                              AppColors.violet,
                              AppColors.violet.withAlpha(153),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: pro.avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: pro.avatarUrl!,
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                          ),
                        )
                      : Center(
                          child: Text(
                            pro.displayName[0].toUpperCase(),
                            style: GoogleFonts.sora(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                pro.displayName,
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            if (pro.category != null)
              Text(
                pro.category!,
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const Spacer(),
            if (pro.averageRating != null && pro.averageRating! > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      pro.averageRating!.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRENDING EVENTS — horizontal cards
// ═════════════════════════════════════════════════════════════════════════════

class _TrendingEventsSection extends ConsumerWidget {
  const _TrendingEventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(_trendingEventsProvider);
    return SizedBox(
      height: 130,
      child: events.when(
        loading: () => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    'No upcoming events',
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = list[i];
              return GestureDetector(
                onTap: () => context.push('/event/${e['id']}'),
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        e['title'] as String? ?? '',
                        style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e['event_date'] as String? ?? '',
                        style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _trendingEventsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('events')
      .select('id, title, event_date')
      .eq('is_active', true)
      .gte('event_date', DateTime.now().toIso8601String())
      .order('event_date', ascending: true)
      .limit(10);
  return (data as List).cast<Map<String, dynamic>>();
});

// ═════════════════════════════════════════════════════════════════════════════
// INSPIRATIONS SECTION — Real videos from Spotbook with animations
// ═════════════════════════════════════════════════════════════════════════════

final _trendingPostsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
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

class _InspirationsSection extends ConsumerStatefulWidget {
  const _InspirationsSection();

  @override
  ConsumerState<_InspirationsSection> createState() => _InspirationsSectionState();
}

class _InspirationsSectionState extends ConsumerState<_InspirationsSection>
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
    final posts = ref.watch(_trendingPostsProvider);

    // Start animation when data arrives
    posts.whenData((_) {
      if (!_staggerCtrl.isAnimating && _staggerCtrl.value == 0) {
        _staggerCtrl.forward();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.violetClair, size: 18),
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
                onTap: () => context.push('/pro/feed'),
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

        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: posts.when(
            loading: () => _buildShimmerGrid(),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load videos',
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return _buildEmptyState();
              }
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
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.video_library_outlined, size: 48,
                color: AppColors.grisInactif),
            const SizedBox(height: 12),
            Text('No videos yet',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Be the first to post!',
                style: GoogleFonts.dmSans(
                    color: AppColors.violet, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
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
          child: _InspirationVideoCard(post: post),
        );
      },
    );
  }
}

// ── Single inspiration video card ──
class _InspirationVideoCard extends StatelessWidget {
  const _InspirationVideoCard({required this.post});

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
      onTap: () => context.push('/pro/feed'),
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
              // Thumbnail
              if (thumb != null && thumb.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceAlt,
                    child: Icon(Icons.videocam, color: AppColors.grisInactif, size: 28),
                  ),
                )
              else
                Container(
                  color: AppColors.surfaceAlt,
                  child: Icon(Icons.videocam, color: AppColors.grisInactif, size: 28),
                ),

              // Gradient overlay at bottom
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
                  child: Icon(Icons.play_arrow, color: AppColors.violet, size: 16),
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
                        const Icon(Icons.visibility, color: AppColors.textOnVideo, size: 10),
                        const SizedBox(width: 2),
                        Text(_formatCount(views),
                            style: GoogleFonts.dmSans(color: AppColors.textOnVideo, fontSize: 9)),
                        const SizedBox(width: 6),
                        const Icon(Icons.favorite, color: AppColors.textOnVideo, size: 10),
                        const SizedBox(width: 2),
                        Text(_formatCount(likes),
                            style: GoogleFonts.dmSans(color: AppColors.textOnVideo, fontSize: 9)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ── Shimmer loading card ──
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
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
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRO SEARCH CARD — result item
// ═════════════════════════════════════════════════════════════════════════════

class _ProSearchCard extends StatelessWidget {
  const _ProSearchCard({required this.result});

  final ProviderSearchResult result;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/provider/${result.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: result.avatarUrl == null
                    ? LinearGradient(
                        colors: [
                          AppColors.violet,
                          AppColors.violet.withAlpha(153),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: result.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: result.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      ),
                    )
                  : Center(
                      child: Text(
                        result.displayName[0].toUpperCase(),
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (result.category != null) result.category!,
                      if (result.city != null) result.city!,
                    ].join(' · '),
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (result.averageRating != null && result.averageRating! > 0) ...[
              Icon(Icons.star, color: AppColors.warning, size: 14),
              const SizedBox(width: 2),
              Text(
                result.averageRating!.toStringAsFixed(1),
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
