import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_mode_notifier.dart';
import '../cubit/client_search_cubit.dart';
import '../models/search_models.dart';

// ── Trending videos from all pros ──
final _clientTrendingVideosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('videos')
      .select('''
        id, title, thumbnail_url, cloudflare_thumbnail_url, views_count, likes_count, created_at,
        users!pro_id(full_name, avatar_url, profiles_pro(business_name, category))
      ''')
      .eq('status', 'approved')
      .order('created_at', ascending: false)
      .limit(12);
  return (data as List).cast<Map<String, dynamic>>();
});

// ── Trending events (active + future) ──
final _clientTrendingEventsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('events')
      .select('''
        id, title, event_date, start_time, location, cover_url, total_capacity,
        users!pro_id(full_name, avatar_url, profiles_pro(business_name)),
        ticket_types(price, quantity, sold_count)
      ''')
      .eq('is_active', true)
      .gte('event_date', DateTime.now().toIso8601String().split('T').first)
      .order('event_date', ascending: true)
      .limit(10);
  return (data as List).cast<Map<String, dynamic>>();
});

class SearchListView extends StatelessWidget {
  const SearchListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientSearchCubit, ClientSearchState>(
      builder: (context, state) {
        final hasSearchResults = state.pros.isNotEmpty || state.events.isNotEmpty;
        final isSearching = state.query.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          children: [
            // ── Section: Pros près de toi (horizontal scroll) ──
            if (state.pros.isNotEmpty) ...[
              const _SectionTitle(title: 'Près de toi'),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.pros.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final pro = state.pros[index];
                    return _HorizontalProCard(
                      pro: pro,
                      onTap: () {
                        context
                            .read<ClientSearchCubit>()
                            .openDetailPanel(pro.id);
                      },
                    );
                  },
                ),
              ),
            ],

            // ── Empty search state ──
            if (isSearching && !hasSearchResults)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: AppColors.grisInactif),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun résultat',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gris,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Essaie une autre recherche ou catégorie',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.grisInactif,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Section: Événements tendance ──
            const SizedBox(height: 20),
            const _TrendingEventsSection(),

            // ── Section: Vidéos ──
            const SizedBox(height: 20),
            const _ClientVideosSection(),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRENDING EVENTS SECTION — horizontal cards with cover images
// ═════════════════════════════════════════════════════════════════════════════

class _TrendingEventsSection extends ConsumerWidget {
  const _TrendingEventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final events = ref.watch(_clientTrendingEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: AppColors.rose, size: 18),
              const SizedBox(width: 8),
              Text(
                'Événements tendance',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: events.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 240,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
              ),
            ),
            error: (_, __) => Center(
              child: Text(
                'Impossible de charger les événements',
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Aucun événement à venir',
                      style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _TrendingEventCard(event: list[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingEventCard extends StatelessWidget {
  const _TrendingEventCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final title = event['title'] as String? ?? '';
    final dateStr = event['event_date'] as String? ?? '';
    final location = event['location'] as String? ?? '';
    final coverUrl = event['cover_url'] as String?;
    final eventId = event['id'] as String;
    final user = event['users'] as Map<String, dynamic>?;
    final proName = user?['full_name'] as String? ?? '';
    final ticketTypes = event['ticket_types'] as List? ?? [];

    // Calculate lowest price
    double? lowestPrice;
    for (final tt in ticketTypes) {
      final price = (tt['price'] as num?)?.toDouble();
      if (price != null && (lowestPrice == null || price < lowestPrice)) {
        lowestPrice = price;
      }
    }

    // Format date
    String formattedDate = dateStr;
    try {
      final dt = DateTime.parse(dateStr);
      formattedDate = DateFormat('d MMM yyyy', 'fr_FR').format(dt);
    } catch (_) {}

    return GestureDetector(
      onTap: () => context.push('/event/$eventId'),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or gradient
            SizedBox(
              height: 100,
              width: double.infinity,
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(gradient: AppColors.gradientAccent),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(gradient: AppColors.gradientAccent),
                      child: Center(
                        child: Icon(Icons.event, color: Colors.white.withAlpha(100), size: 32),
                      ),
                    ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 10, color: AppColors.gris),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on_outlined, size: 10, color: AppColors.gris),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (proName.isNotEmpty)
                          Expanded(
                            child: Text(
                              proName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: AppColors.violetClair,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (lowestPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.violet.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Dès ${lowestPrice.toInt()}\$',
                              style: GoogleFonts.dmSans(
                                color: AppColors.violet,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VIDEOS SECTION — grid of all pro videos
// ═════════════════════════════════════════════════════════════════════════════

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
    ref.watch(themeModeProvider);
    final videos = ref.watch(_clientTrendingVideosProvider);

    videos.whenData((_) {
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
                    'Vidéos',
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
                  'Voir tout',
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
          child: videos.when(
            loading: () => _buildShimmerGrid(),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger les vidéos',
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
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

  Widget _buildVideoGrid(List<Map<String, dynamic>> videos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
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
          child: _ClientVideoCard(video: video),
        );
      },
    );
  }
}

// ── Single video card ──

class _ClientVideoCard extends StatelessWidget {
  const _ClientVideoCard({required this.video});

  final Map<String, dynamic> video;

  @override
  Widget build(BuildContext context) {
    final thumb = (video['cloudflare_thumbnail_url'] as String?)
        ?? (video['thumbnail_url'] as String?);
    final title = video['title'] as String? ?? '';
    final views = video['views_count'] as int? ?? 0;
    final likes = video['likes_count'] as int? ?? 0;
    final user = video['users'] as Map<String, dynamic>?;
    final profilesPro = user?['profiles_pro'] as Map<String, dynamic>?;
    final category = profilesPro?['category'] as String? ?? '';

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

// ═════════════════════════════════════════════════════════════════════════════
// HORIZONTAL PRO CARD — used in "Près de toi" scroll
// ═════════════════════════════════════════════════════════════════════════════

class _HorizontalProCard extends StatelessWidget {
  const _HorizontalProCard({required this.pro, required this.onTap});

  final ProSearchResult pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final catColor = categoryColor(pro.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Top: avatar on gradient background ──
            Container(
              height: 84,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [catColor.withAlpha(50), catColor.withAlpha(20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [catColor, catColor.withAlpha(160)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: pro.avatarUrl != null && pro.avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: pro.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 50,
                                height: 50,
                                placeholder: (_, __) => _ProCardInitial(name: pro.name),
                                errorWidget: (_, __, ___) => _ProCardInitial(name: pro.name),
                              ),
                            )
                          : _ProCardInitial(name: pro.name),
                    ),
                    if (pro.online)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Bottom: name, category, rating, distance ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  children: [
                    Text(
                      pro.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${categoryEmoji(pro.category)} ${pro.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\u2B50 ${pro.rating}',
                          style: GoogleFonts.dmSans(
                            color: AppColors.ratingAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pro.distKm} km',
                          style: GoogleFonts.dmSans(
                            color: AppColors.violet,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProCardInitial extends StatelessWidget {
  const _ProCardInitial({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.sora(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

