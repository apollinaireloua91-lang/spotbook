import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../catering/data/catering_repository.dart';
import '../../../catering/domain/catering_models.dart';
import '../../../catering/presentation/widgets/catering_section_widgets.dart';
import '../../../reviews/domain/review_model.dart';
import '../../domain/entities/provider_profile_data.dart';
import '../bloc/public_provider_profile_bloc.dart';
import '../widgets/share_profile_modal.dart';
import '../widgets/social_badge_widget.dart';
import '../widgets/traiteur_soumission_sheet.dart';

/// Pro public profile seen by clients — premium design with social links,
/// video grid, services, reviews, and events tabs.
class ProviderPublicProfileClientViewScreen extends StatefulWidget {
  const ProviderPublicProfileClientViewScreen({super.key});

  @override
  State<ProviderPublicProfileClientViewScreen> createState() =>
      _ProviderPublicProfileClientViewScreenState();
}

class _ProviderPublicProfileClientViewScreenState
    extends State<ProviderPublicProfileClientViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static String _shareUrl(String providerId) =>
      'https://spotbook.app/client/provider/$providerId';

  Future<void> _openSocial(ProviderSocialLink link) async {
    final uri = _socialUri(link.platform, link.handle);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Uri? _socialUri(String platform, String handle) {
    final h = handle.replaceFirst(RegExp(r'^@'), '');
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Uri.parse('https://www.tiktok.com/@$h');
      case 'instagram':
        return Uri.parse('https://www.instagram.com/$h/');
      case 'youtube':
        return Uri.parse('https://www.youtube.com/@$h');
      case 'snapchat':
        return Uri.parse('https://www.snapchat.com/add/$h');
      case 'twitter':
      case 'x':
        return Uri.parse('https://twitter.com/$h');
      case 'facebook':
        return Uri.parse('https://www.facebook.com/$h');
      default:
        return null;
    }
  }

  ServiceEntity? _firstActiveService(PublicProviderProfileReady s) {
    for (final x in s.data.services) {
      if (x.isActive) return x;
    }
    return null;
  }

  Future<void> _onBook(
      BuildContext context, PublicProviderProfileReady s) async {
    HapticFeedback.mediumImpact();
    final svc = _firstActiveService(s);
    final pid = s.data.provider.id;
    if (svc == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'No bookable services at this time.',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      context.push('/client/booking-flow/$pid?serviceId=${svc.id}');
    }
  }

  Future<void> _onMessage(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final bloc = context.read<PublicProviderProfileBloc>();
    final s = bloc.state;
    if (s is! PublicProviderProfileReady) return;
    final convId = await bloc.ensureConversationAndGetId();
    if (!context.mounted) return;
    if (convId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'Sign in to send a message.',
            style: TextStyle(color: AppColors.blanc),
          ),
        ),
      );
      return;
    }
    context.push(
      '/chat/$convId',
      extra: <String, String>{
        'otherUserName': s.data.provider.fullName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PublicProviderProfileBloc, PublicProviderProfileState>(
      listenWhen: (p, c) =>
          (p is PublicProviderProfileReady) !=
              (c is PublicProviderProfileReady) ||
          c is PublicProviderProfileFailure,
      listener: (context, state) {
        if (state is PublicProviderProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surface,
              content: Text(
                state.message,
                style: const TextStyle(color: AppColors.blanc),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.fond,
          body: switch (state) {
            PublicProviderProfileLoading() => const Center(
                child: SpotbookLoadingShimmer.profile(),
              ),
            PublicProviderProfileFailure(:final message) => SafeArea(
                child: Column(
                  children: [
                    // Back button row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.blanc, size: 20),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: AppColors.gris),
                              ),
                              const SizedBox(height: 16),
                              _PillButton(
                                label: 'Retry',
                                color: AppColors.violet,
                                onTap: () {
                                  final bloc = context
                                      .read<PublicProviderProfileBloc>();
                                  final id = bloc.providerId;
                                  if (id != null && id.isNotEmpty) {
                                    bloc.add(
                                        PublicProviderProfileStarted(id));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            PublicProviderProfileReady() => _ReadyBody(
                state: state,
                tabController: _tabController,
                onOpenSocial: _openSocial,
                onBook: () => _onBook(context, state),
                onMessage: () => _onMessage(context),
                onShare: () {
                  HapticFeedback.lightImpact();
                  final p = state.data.provider;
                  showShareProfileModal(
                    context: context,
                    profileUrl: _shareUrl(p.id),
                    displayName: p.fullName,
                    avatarUrl: p.avatarUrl,
                  );
                },
                onVideoTap: (v) {
                  HapticFeedback.lightImpact();
                  context.push('/client/profile-video', extra: v);
                },
              ),
          },
        );
      },
    );
  }
}

// ─── Ready Body (NestedScrollView + pinned tabs) ────────────────────────────

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.state,
    required this.tabController,
    required this.onOpenSocial,
    required this.onBook,
    required this.onMessage,
    required this.onShare,
    required this.onVideoTap,
  });

  final PublicProviderProfileReady state;
  final TabController tabController;
  final Future<void> Function(ProviderSocialLink) onOpenSocial;
  final VoidCallback onBook;
  final VoidCallback onMessage;
  final VoidCallback onShare;
  final void Function(VideoEntity) onVideoTap;

  @override
  Widget build(BuildContext context) {
    final p = state.data.provider;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // ── Header content ──
        SliverToBoxAdapter(
          child: Column(
            children: [
              // 1. COVER IMAGE with gradient + overlay buttons
              _CoverSection(provider: p, onShare: onShare),

              // Avatar + info (shifted up to overlap cover)
              Transform.translate(
                offset: const Offset(0, -44),
                child: Column(
                  children: [
                    // ── GRADIENT RING AVATAR ──
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.gradientAccent,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.fond,
                        ),
                        child: SpotbookAvatar(
                          imageUrl: p.avatarUrl,
                          name: p.fullName,
                          radius: 40,
                          isVerified: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── NAME + VERIFIED BADGE ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              p.fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.blanc,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (p.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                color: AppColors.violet, size: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ── CATEGORY · LOCATION ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        [
                          if (p.profession.isNotEmpty) p.profession,
                          if (p.location != null && p.location!.isNotEmpty)
                            p.location!,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.gris,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── RATING BADGE ──
                    _RatingBadge(
                      rating: p.averageRating,
                      reviewsCount: p.reviewsCount,
                    ),
                    const SizedBox(height: 20),

                    // ── STATS ROW ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _StatsRow(
                        followers: p.followersCount,
                        bookings: p.bookingsCompleted,
                        videos: state.data.videos.length,
                      ),
                    ),

                    // ── BIO ──
                    if (p.bio != null && p.bio!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          p.bio!.trim(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.grisClair,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    // ── SOCIAL ICONS ROW ──
                    if (p.socialLinks.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0;
                                i < p.socialLinks.length;
                                i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onOpenSocial(p.socialLinks[i]);
                                },
                                child: SocialIcon(
                                  platform: p.socialLinks[i].platform,
                                  size: 40,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── FOLLOW BUTTON ──
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _FollowButton(),
                    ),
                    const SizedBox(height: 12),

                    // 2. ACTION BUTTONS — side-by-side (Marketplace style)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Message',
                              color: AppColors.surface,
                              textColor: AppColors.blanc,
                              icon: Icons.chat_bubble_outline_rounded,
                              borderColor: AppColors.border,
                              onTap: onMessage,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Book',
                              color: AppColors.violet,
                              icon: Icons.calendar_today_rounded,
                              onTap: onBook,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── CATERING SECTION (conditional — Cuisine/Traiteur/Chef) ──
        if (isCateringCategory(p.profession))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _ClientCateringSection(proId: p.id),
            ),
          ),

        // ── PINNED TAB BAR ──
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(tabController),
        ),
      ],
      body: TabBarView(
        controller: tabController,
        children: [
          _VideosTab(
            videos: state.data.videos,
            onVideoTap: onVideoTap,
          ),
          _ServicesTab(
            providerId: p.id,
            services: state.data.services,
          ),
          _ReviewsTab(
            reviews: state.reviews,
            averageRating: p.averageRating,
            reviewsCount: p.reviewsCount,
          ),
          _EventsTab(events: state.data.events),
        ],
      ),
    );
  }
}

// ─── Cover Section ──────────────────────────────────────────────────────────

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.provider, required this.onShare});

  final ProviderEntity provider;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image or gradient fallback
          if (provider.coverUrl != null && provider.coverUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: provider.coverUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A1A50), Color(0xFF1A1030)],
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A1A50), Color(0xFF1A1030)],
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A1A50), Color(0xFF1A1030)],
                ),
              ),
            ),

          // Bottom gradient fade to fond
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.fond],
                ),
              ),
            ),
          ),

          // Back + Share buttons
          Positioned(
            top: topPad + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                _CircleIconButton(
                  icon: Icons.ios_share,
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circle Icon Button (overlay on cover) ──────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.fond.withAlpha(180),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withAlpha(80)),
        ),
        child: Icon(icon, color: AppColors.blanc, size: 18),
      ),
    );
  }
}

// ─── Rating Badge ───────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.reviewsCount});

  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0 && reviewsCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Text(
          'New',
          style: TextStyle(
            color: AppColors.gris,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.starGold, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($reviewsCount ${reviewsCount == 1 ? 'review' : 'reviews'})',
            style: const TextStyle(color: AppColors.gris, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.followers,
    required this.bookings,
    required this.videos,
  });

  final int followers;
  final int bookings;
  final int videos;

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
              child: _StatCell(value: _fmt(followers), label: 'Followers')),
          Container(width: 1, height: 28, color: AppColors.border),
          Expanded(
              child: _StatCell(value: _fmt(bookings), label: 'Bookings')),
          Container(width: 1, height: 28, color: AppColors.border),
          Expanded(child: _StatCell(value: _fmt(videos), label: 'Videos')),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gris,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Follow Button ──────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  const _FollowButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PublicProviderProfileBloc, PublicProviderProfileState>(
      buildWhen: (p, c) {
        if (c is! PublicProviderProfileReady ||
            p is! PublicProviderProfileReady) {
          return true;
        }
        return p.isFollowedByMe != c.isFollowedByMe ||
            p.followBusy != c.followBusy;
      },
      builder: (context, s) {
        if (s is! PublicProviderProfileReady) return const SizedBox.shrink();
        final authId = Supabase.instance.client.auth.currentUser?.id;
        if (authId == null) {
          return _ActionButton(
            label: 'Sign in to follow',
            color: AppColors.surfaceAlt,
            textColor: AppColors.gris,
            borderColor: AppColors.border,
            onTap: () => context.push('/auth/login'),
          );
        }
        if (authId == s.data.provider.id) return const SizedBox.shrink();

        final followed = s.isFollowedByMe;
        final busy = s.followBusy;

        return GestureDetector(
          onTap: busy
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  context
                      .read<PublicProviderProfileBloc>()
                      .add(const PublicProviderProfileToggleFollow());
                },
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              color: followed ? AppColors.surfaceAlt : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.blanc,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          followed
                              ? Icons.check_rounded
                              : Icons.person_add_outlined,
                          color:
                              followed ? AppColors.gris : AppColors.blanc,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          followed ? 'Following' : 'Follow',
                          style: TextStyle(
                            color:
                                followed ? AppColors.gris : AppColors.blanc,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Action Button (Book / Message) ─────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = AppColors.blanc,
    this.icon,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border:
              borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small pill button (for retry, etc.) ────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Pinned Tab Bar Delegate ────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.controller);

  final TabController controller;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.fond,
      child: TabBar(
        controller: controller,
        labelColor: AppColors.blanc,
        unselectedLabelColor: AppColors.gris,
        indicatorColor: AppColors.violet,
        indicatorWeight: 2.5,
        dividerColor: AppColors.border,
        dividerHeight: 0.5,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        tabs: const [
          Tab(text: 'VIDEOS'),
          Tab(text: 'SERVICES'),
          Tab(text: 'REVIEWS'),
          Tab(text: 'EVENTS'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller;
}

// ─── Videos Tab (2-column grid) ─────────────────────────────────────────────

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.videos, required this.onVideoTap});

  final List<VideoEntity> videos;
  final void Function(VideoEntity) onVideoTap;

  static String _fmtViews(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined,
                color: AppColors.gris, size: 48),
            SizedBox(height: 12),
            Text('No videos yet',
                style: TextStyle(color: AppColors.gris, fontSize: 15)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        final v = videos[i];
        return GestureDetector(
          onTap: () => onVideoTap(v),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail
                if (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: v.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const SpotbookLoadingShimmer.card(itemCount: 1),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceAlt),
                  )
                else
                  Container(
                    color: AppColors.surfaceAlt,
                    child: const Icon(Icons.play_circle_outline,
                        color: AppColors.gris, size: 40),
                  ),

                // Bottom gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                ),

                // Play icon center
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blanc.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.blanc, size: 28),
                  ),
                ),

                // Views badge bottom-left
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.fond.withAlpha(180),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow,
                            color: AppColors.blanc, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          _fmtViews(v.viewsCount),
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Services Tab ───────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({required this.providerId, required this.services});

  final String providerId;
  final List<ServiceEntity> services;

  @override
  Widget build(BuildContext context) {
    final active = services.where((s) => s.isActive).toList();
    if (active.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.design_services_outlined,
                color: AppColors.gris, size: 48),
            SizedBox(height: 12),
            Text('No services available',
                style: TextStyle(color: AppColors.gris, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: active.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = active[i];
        final price =
            NumberFormat.currency(symbol: r'$', decimalDigits: 0)
                .format(s.price);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Service icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.spa_outlined,
                    color: AppColors.violetClair, size: 22),
              ),
              const SizedBox(width: 14),
              // Name + duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            color: AppColors.gris, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${s.durationMinutes} min',
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price + Book
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.violetClair,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push(
                        '/client/booking-flow/$providerId?serviceId=${s.id}',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.violet,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Book',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Reviews Tab ────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({
    required this.reviews,
    required this.averageRating,
    required this.reviewsCount,
  });

  final List<ReviewModel> reviews;
  final double averageRating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined,
                color: AppColors.gris, size: 48),
            SizedBox(height: 12),
            Text('No reviews yet',
                style: TextStyle(color: AppColors.gris, fontSize: 15)),
          ],
        ),
      );
    }
    final fmt = DateFormat.yMMMd('en');
    // +1 for the summary header
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: reviews.length + 1,
      itemBuilder: (context, i) {
        // Rating summary header
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (si) {
                        return Icon(
                          si < averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.starGold,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$reviewsCount ${reviewsCount == 1 ? 'review' : 'reviews'}',
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final r = reviews[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpotbookAvatar(
                  imageUrl: r.clientAvatarUrl,
                  name: r.clientName ?? 'Client',
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.clientName ?? 'Client',
                              style: const TextStyle(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            fmt.format(r.createdAt),
                            style: const TextStyle(
                                color: AppColors.gris, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (si) {
                          return Icon(
                            si < r.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.starGold,
                            size: 14,
                          );
                        }),
                      ),
                      if (r.serviceName != null &&
                          r.serviceName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.serviceName!.trim(),
                          style: const TextStyle(
                            color: AppColors.violetClair,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (r.comment != null &&
                          r.comment!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.comment!.trim(),
                          style: const TextStyle(
                            color: AppColors.grisClair,
                            fontSize: 13,
                            height: 1.4,
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
      },
    );
  }
}

// ─── Events Tab (gradient cards) ────────────────────────────────────────────

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.events});

  final List<EventEntity> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, color: AppColors.gris, size: 48),
            SizedBox(height: 12),
            Text('No upcoming events',
                style: TextStyle(color: AppColors.gris, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final e = events[i];
        final remaining = (e.maxAttendees - e.ticketsSold).clamp(0, 999999);
        final hasDate = e.eventDate != null;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/event/${e.id}');
          },
          child: Container(
            height: 170,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient
                if (e.coverUrl != null && e.coverUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: e.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceAlt),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceAlt),
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.violet, AppColors.rose],
                      ),
                    ),
                  ),

                // Gradient overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(200),
                      ],
                    ),
                  ),
                ),

                // Date badge top-left
                if (hasDate)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.fond.withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.d().format(e.eventDate!),
                            style: const TextStyle(
                              color: AppColors.blanc,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormat.MMM()
                                .format(e.eventDate!)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.violetClair,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Tickets remaining badge top-right
                if (remaining > 0 && e.maxAttendees > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.success.withAlpha(60)),
                      ),
                      child: Text(
                        '$remaining left',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Bottom info + Buy button
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (e.venueName != null &&
                          e.venueName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: AppColors.grisClair),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                e.venueName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.grisClair,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (e.eventTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 13, color: AppColors.grisClair),
                            const SizedBox(width: 4),
                            Text(
                              e.eventTime!,
                              style: const TextStyle(
                                color: AppColors.grisClair,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.violet,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Buy ticket',
                            style: TextStyle(
                              color: AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CLIENT CATERING SECTION — shows menu, packages, gallery, quote CTA
// ═════════════════════════════════════════════════════════════════════════════

class _ClientCateringSection extends StatefulWidget {
  const _ClientCateringSection({required this.proId});

  final String proId;

  @override
  State<_ClientCateringSection> createState() => _ClientCateringSectionState();
}

class _ClientCateringSectionState extends State<_ClientCateringSection> {
  late final CateringRepository _repo;
  List<CateringMenuItem> _menuItems = [];
  List<CateringForfait> _forfaits = [];
  List<CateringGalleryItem> _gallery = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = CateringRepository(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repo.getMenuItems(widget.proId),
        _repo.getForfaits(widget.proId),
        _repo.getGallery(widget.proId),
      ]);
      if (mounted) {
        setState(() {
          _menuItems = results[0] as List<CateringMenuItem>;
          _forfaits = results[1] as List<CateringForfait>;
          _gallery = results[2] as List<CateringGalleryItem>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppColors.catering,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // Don't show section if Pro has no catering content at all
    if (_menuItems.isEmpty && _forfaits.isEmpty && _gallery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CateringBanner(),
        const SizedBox(height: 14),

        // ── Menu Items ──
        if (_menuItems.isNotEmpty) ...[
          const CateringSectionHeader(title: 'MENU'),
          const SizedBox(height: 10),
          CateringMenuGrid(items: _menuItems),
          const SizedBox(height: 14),
        ],

        // ── Packages ──
        if (_forfaits.isNotEmpty) ...[
          const CateringSectionHeader(title: 'PACKAGES'),
          const SizedBox(height: 10),
          CateringForfaitList(forfaits: _forfaits),
          const SizedBox(height: 14),
        ],

        // ── Gallery ──
        if (_gallery.isNotEmpty) ...[
          const CateringSectionHeader(title: 'GALLERY'),
          const SizedBox(height: 10),
          CateringGalleryRow(items: _gallery),
          const SizedBox(height: 14),
        ],

        // ── Request Quote CTA ──
        CateringRequestQuoteCTA(
          onTap: () => showTraiteurSoumissionSheet(
            context,
            proId: widget.proId,
          ),
        ),
      ],
    );
  }
}
