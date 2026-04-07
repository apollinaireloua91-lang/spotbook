import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
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
          const SnackBar(content: Text('Search error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          prefixIcon: const Icon(Icons.search,
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
              const SliverFillRemaining(
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
              // ── Tendances (hashtags) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trending',
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _TrendingHashtags(),
                    ],
                  ),
                ),
              ),

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

              // ── Inspirations (posts viraux) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Inspirations',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _InspirationGrid()),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRENDING HASHTAGS — horizontal scroll pills
// ═════════════════════════════════════════════════════════════════════════════

class _TrendingHashtags extends StatelessWidget {
  const _TrendingHashtags();

  static const _hashtags = [
    '#barbier', '#nailart', '#coach', '#fade', '#mtl',
    '#beaute', '#tatouage', '#photoshoot', '#fitness', '#makeup',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _hashtags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: AppColors.violet.withAlpha(77), // ~0.3
                width: 1,
              ),
            ),
            child: Text(
              _hashtags[i],
              style: GoogleFonts.dmSans(
                color: AppColors.violetClair,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
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
          return const SizedBox(
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
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.fond,
                  backgroundImage: pro.avatarUrl != null
                      ? CachedNetworkImageProvider(pro.avatarUrl!)
                      : null,
                  child: pro.avatarUrl == null
                      ? Text(
                          pro.displayName[0].toUpperCase(),
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
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
                    const Icon(Icons.star, color: AppColors.warning, size: 12),
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
// INSPIRATION GRID — 3 columns, thumbnail posts
// ═════════════════════════════════════════════════════════════════════════════

class _InspirationGrid extends ConsumerWidget {
  const _InspirationGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(_trendingPostsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: posts.when(
        loading: () => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.75,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          ),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load inspirations', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13)),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No inspirations yet', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13)),
              ),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.75,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final post = list[i];
              final thumb = post['thumbnail_url'] as String?;
              return GestureDetector(
                onTap: () => context.push('/pro/feed'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumb != null
                      ? CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.surface))
                      : Container(
                          color: AppColors.surface,
                          child: Icon(Icons.play_arrow_rounded, color: AppColors.gris.withAlpha(77), size: 28),
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

final _trendingPostsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('posts')
      .select('id, thumbnail_url')
      .eq('status', 'approved')
      .order('created_at', ascending: false)
      .limit(9);
  return (data as List).cast<Map<String, dynamic>>();
});

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
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceAlt,
              backgroundImage: result.avatarUrl != null
                  ? CachedNetworkImageProvider(result.avatarUrl!)
                  : null,
              child: result.avatarUrl == null
                  ? Text(
                      result.displayName[0].toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
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
              const Icon(Icons.star, color: AppColors.warning, size: 14),
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
