import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../auth/data/category_repository.dart';
import '../../data/discover_notifier.dart';
import '../../domain/provider_search_result.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../domain/video_model.dart';

/// Fallback categories when Supabase data hasn't loaded yet.
const _fallbackCategories = [
  'All', 'Hairdressing', 'Barber', 'Aesthetics', 'Massage',
  'Fitness', 'Photography', 'Music / DJ', 'Tattoo',
  'Fashion', 'Cooking', 'Coaching',
];

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    ref.read(discoverProvider.notifier).setShowHistory(_focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openFilters() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _FiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(discoverProvider);
    final n = ref.read(discoverProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Search bar + filter ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      onChanged: n.onSearchChanged,
                      onSubmitted: (v) {
                        _focusNode.unfocus();
                        n.search(v);
                        AnalyticsService.instance.capture(
                          'search_performed',
                          properties: {
                            'query_length': v.length,
                            'source': 'submit',
                          },
                        );
                      },
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: l.searchProfessionalHint,
                        hintStyle: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.gris,
                          size: 20,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchCtrl,
                          builder: (_, value, __) => value.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: AppColors.gris,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    n.search('');
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openFilters,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: AppColors.blanc,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Search history dropdown ───
            if (s.showHistory && s.searchHistory.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent searches',
                            style: GoogleFonts.dmSans(
                              color: AppColors.gris,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: n.clearHistory,
                            child: Text(
                              'Clear',
                              style: GoogleFonts.dmSans(
                                color: AppColors.violet,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...s.searchHistory.map(
                      (query) => ListTile(
                        leading: Icon(
                          Icons.history,
                          color: AppColors.gris,
                          size: 18,
                        ),
                        title: Text(
                          query,
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontSize: 14,
                          ),
                        ),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        onTap: () {
                          _searchCtrl.text = query;
                          _focusNode.unfocus();
                          n.search(query);
                          AnalyticsService.instance.capture(
                            'search_performed',
                            properties: {
                              'query_length': query.length,
                              'source': 'history',
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ─── Category chips ───
            Consumer(
              builder: (context, cRef, _) {
                final asyncCats = cRef.watch(proCategoriesProvider);
                final categories = asyncCats.when(
                  data: (cats) => ['All', ...cats.map((c) => c.label)],
                  loading: () => _fallbackCategories,
                  error: (_, __) => _fallbackCategories,
                );
                return SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final label = categories[index];
                  final dbCat = label;
                  final selected = s.selectedCategory == dbCat;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      n.setCategory(dbCat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            selected ? AppColors.gradientAccent : null,
                        color: selected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                          color: selected
                              ? AppColors.blanc
                              : AppColors.gris,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
              },
            ),

            const SizedBox(height: 16),

            // ─── Content area ───
            Expanded(
              child: s.isLoading
                  ? const _ShimmerGrid()
                  : s.hasError
                      ? _ErrorState(
                          onRetry: () => n.reloadWithFilters(),
                        )
                      : _buildResults(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(DiscoverState s) {
    final hasProviders = s.nearbyProviders.isNotEmpty;
    final hasVideos = s.results != null && s.results!.isNotEmpty;

    if (!hasProviders && !hasVideos) {
      return _EmptyState(
        hasQuery: s.activeQuery != null && s.activeQuery!.isNotEmpty,
      );
    }

    // Default: show videos grid (all pro videos)
    // When searching: show providers on top + videos below
    if (hasProviders && s.activeQuery != null) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pros',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ProviderCard(provider: s.nearbyProviders[i]),
                childCount: s.nearbyProviders.length.clamp(0, 4),
              ),
            ),
          ),
          if (hasVideos) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Vidéos',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _VideoCard(video: s.results![i]),
                  childCount: s.results!.length,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Default: videos grid (all pro published videos)
    return _VideosGrid(videos: s.results ?? []);
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});
  final ProviderSearchResult provider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pro/${provider.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.violet.withAlpha(80),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: provider.avatarUrl != null
                    ? CachedNetworkImageProvider(provider.avatarUrl!)
                    : null,
                child: provider.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 28,
                        color: AppColors.gris,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                provider.displayName,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Category badge
            if (provider.category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.category!,
                  style: GoogleFonts.dmSans(
                    color: AppColors.violetClair,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            // Bottom row: rating + distance/price
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.averageRating != null &&
                      provider.averageRating! > 0) ...[
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.warning,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      provider.averageRating!.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (provider.reviewCount != null &&
                        provider.reviewCount! > 0) ...[
                      const SizedBox(width: 2),
                      Text(
                        '(${provider.reviewCount})',
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                  if (provider.distanceKm != null) ...[
                    if (provider.averageRating != null &&
                        provider.averageRating! > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: TextStyle(color: AppColors.gris),
                        ),
                      ),
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.gris,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${provider.distanceKm!.toStringAsFixed(1)} km',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (provider.minPrice != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '·',
                        style: TextStyle(color: AppColors.gris),
                      ),
                    ),
                    Text(
                      'from \$${provider.minPrice!.toStringAsFixed(0)}',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Videos grid (fallback) ──────────────────────────────────────────────────

class _VideosGrid extends StatelessWidget {
  const _VideosGrid({required this.videos});
  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: videos.length,
      itemBuilder: (_, index) => _VideoCard(video: videos[index]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});
  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pro/${video.proId}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: video.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.surfaceAlt),
                      )
                    : Container(
                        color: AppColors.surfaceAlt,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: AppColors.gris,
                            size: 32,
                          ),
                        ),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.surfaceAlt,
                        backgroundImage: video.proAvatarUrl != null
                            ? CachedNetworkImageProvider(
                                video.proAvatarUrl!)
                            : null,
                        child: video.proAvatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 12,
                                color: AppColors.gris,
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          video.proName ?? 'Pro',
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.title,
                    style: GoogleFonts.dmSans(
                      color: AppColors.grisClair,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet.withAlpha(25),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasQuery
                  ? 'Aucun résultat'
                  : 'Aucun professionnel trouvé',
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try different keywords\nor adjust your filters'
                  : 'Discover the best\nprofessionals near you soon',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withAlpha(25),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection\nand try again',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

// ─── Shimmer grid ────────────────────────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceAlt,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filters sheet ───────────────────────────────────────────────────────────

class _FiltersSheet extends ConsumerWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(discoverProvider);
    final n = ref.read(discoverProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Filters',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distance max',
                  style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                ),
                Text(
                  '${s.maxDistance.toInt()} km',
                  style: GoogleFonts.dmSans(
                    color: AppColors.violet,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.violet,
                inactiveTrackColor: AppColors.surfaceAlt,
                thumbColor: AppColors.violet,
                overlayColor: AppColors.violet.withAlpha(30),
              ),
              child: Slider(
                value: s.maxDistance,
                min: 1,
                max: 100,
                onChanged: n.setDistance,
              ),
            ),
            const SizedBox(height: 12),

            // Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Minimum rating',
                  style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.minRating.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        color: AppColors.violet,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.violet,
                inactiveTrackColor: AppColors.surfaceAlt,
                thumbColor: AppColors.violet,
                overlayColor: AppColors.violet.withAlpha(30),
              ),
              child: Slider(
                value: s.minRating,
                min: 0,
                max: 5,
                divisions: 10,
                onChanged: n.setRating,
              ),
            ),
            const SizedBox(height: 12),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Max price',
                  style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                ),
                Text(
                  '${s.maxPrice.toInt()} \$',
                  style: GoogleFonts.dmSans(
                    color: AppColors.violet,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.violet,
                inactiveTrackColor: AppColors.surfaceAlt,
                thumbColor: AppColors.violet,
                overlayColor: AppColors.violet.withAlpha(30),
              ),
              child: Slider(
                value: s.maxPrice,
                min: 10,
                max: 500,
                onChanged: n.setPrice,
              ),
            ),
            const SizedBox(height: 12),

            // Available today
            SwitchListTile(
              title: Text(
                'Available today',
                style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
              ),
              value: s.availableToday,
              activeTrackColor: AppColors.violet.withAlpha(128),
              activeThumbColor: AppColors.violet,
              inactiveTrackColor: AppColors.surfaceAlt,
              contentPadding: EdgeInsets.zero,
              onChanged: n.setAvailableToday,
            ),
            const SizedBox(height: 20),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  n.reloadWithFilters();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: AppColors.blanc,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply filters',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
