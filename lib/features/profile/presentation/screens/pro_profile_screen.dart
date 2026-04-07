import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../booking/presentation/screens/booking_bottom_sheet.dart';
import '../../../events/data/event_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/domain/video_model.dart';
import '../../../moderation/presentation/screens/report_sheet.dart';
import '../../../reviews/data/review_repository.dart';
import '../../../reviews/domain/review_model.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/pro_profile_content_widgets.dart';
import '../widgets/social_badge_widget.dart';
import '../widgets/traiteur_menu_tab.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final proProfileProvider =
    FutureProvider.family<ProProfile?, String>((ref, proId) async {
  return ref.read(profileRepositoryProvider).getProProfile(proId);
});

final proProfileVideosProvider =
    FutureProvider.family<List<VideoModel>, String>((ref, proId) async {
  final list = await ref.read(videoRepositoryProvider).getProVideos(proId);
  return list.where((v) => v.status == 'approved').toList();
});

final proProfileServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, proId) async {
  return ref.read(bookingRepositoryProvider).getProServices(proId);
});

final proProfileEventsForProProvider =
    FutureProvider.family<List<EventModel>, String>((ref, proId) async {
  return ref.read(eventRepositoryProvider).getEventsByProId(proId);
});

final proProfileReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, proId) async {
  return ref.read(reviewRepositoryProvider).getProReviews(proId);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class ProProfileScreen extends ConsumerWidget {
  const ProProfileScreen({super.key, required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(proProfileProvider(proId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.fond,
            appBar: AppBar(
              backgroundColor: AppColors.fond,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: _BackButton(),
            ),
            body: Center(
              child:
                  Text('Profile not found', style: GoogleFonts.dmSans(color: AppColors.gris)),
            ),
          );
        }
        return _PremiumProfileScaffold(profile: profile);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: _BackButton(),
        ),
        body: Center(
          child: Text('Erreur : $err',
              style: GoogleFonts.dmSans(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Back',
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
        ),
        onPressed: () => context.pop(),
      ),
    );
  }
}

// ─── Premium Profile Scaffold ────────────────────────────────────────────────

class _PremiumProfileScaffold extends ConsumerStatefulWidget {
  const _PremiumProfileScaffold({required this.profile});

  final ProProfile profile;

  @override
  ConsumerState<_PremiumProfileScaffold> createState() =>
      _PremiumProfileScaffoldState();
}

class _PremiumProfileScaffoldState
    extends ConsumerState<_PremiumProfileScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnimation;
  bool _isFollowed = false;

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.profile.isFollowedByMe;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _toggleFollow() {
    HapticFeedback.mediumImpact();
    setState(() => _isFollowed = !_isFollowed);
    final repo = ref.read(profileRepositoryProvider);
    if (_isFollowed) {
      repo.followUser(widget.profile.id);
    } else {
      repo.unfollowUser(widget.profile.id);
    }
  }

  void _openBooking() {
    HapticFeedback.mediumImpact();
    showBookingSheet(
      context,
      proId: widget.profile.id,
      proProfile: widget.profile,
    );
  }

  void _openMessage() {
    HapticFeedback.selectionClick();
    context.push('/chat/${widget.profile.id}', extra: {
      'otherUserName': widget.profile.businessName,
    });
  }

  void _openMoreMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gris.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.flag_outlined, color: AppColors.blanc),
                title: Text('Report',
                    style: GoogleFonts.dmSans(color: AppColors.blanc)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showReportSheet(context,
                      targetId: widget.profile.id, targetType: 'user');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block, color: AppColors.error),
                title: Text('Block',
                    style: GoogleFonts.dmSans(color: AppColors.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showBlockConfirmDialog(context,
                      ref: ref,
                      userId: widget.profile.id,
                      userName: widget.profile.businessName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final isTraiteur = p.category.toLowerCase().contains('traiteur');
    final tabCount = isTraiteur ? 5 : 4;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: AppColors.fond,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ─── Scrollable content ───
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // ─── Parallax cover + avatar header ───
                  SliverToBoxAdapter(
                    child: _buildHeader(p),
                  ),
                  // ─── Pinned tab bar ───
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PremiumTabBarDelegate(
                      TabBar(
                        indicatorColor: AppColors.violet,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: -4),
                        labelColor: AppColors.blanc,
                        unselectedLabelColor: AppColors.gris,
                        dividerColor: AppColors.border.withAlpha(80),
                        labelStyle: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                        unselectedLabelStyle: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                        tabs: [
                          const Tab(text: 'Videos'),
                          const Tab(text: 'Services'),
                          if (isTraiteur) const Tab(text: 'Menu'),
                          const Tab(text: 'Reviews'),
                          const Tab(text: 'Events'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Padding(
                padding: EdgeInsets.only(bottom: 72 + bottomPadding),
                child: TabBarView(
                  children: [
                    _ProVideosGrid(proId: p.id),
                    _PremiumServicesList(proId: p.id, proProfile: p),
                    if (isTraiteur) _TraiteurMenuWrapper(proId: p.id),
                    _PremiumReviewsList(
                      proId: p.id,
                      rating: p.rating,
                      reviewsCount: p.reviewsCount,
                    ),
                    _ProEventsList(proId: p.id),
                  ],
                ),
              ),
            ),

            // ─── Back + More buttons (floating) ───
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      _FloatingIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      _FloatingIconButton(
                        icon: Icons.share_outlined,
                        onTap: () {
                          HapticFeedback.selectionClick();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FloatingIconButton(
                        icon: Icons.more_horiz,
                        onTap: _openMoreMenu,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Persistent bottom booking bar ───
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _PersistentBookingBar(
                proName: p.businessName,
                onBook: _openBooking,
                bottomPadding: bottomPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProProfile p) {
    final categoryCityParts = <String>[];
    if (p.category.isNotEmpty) categoryCityParts.add(p.category);
    if (p.city != null && p.city!.trim().isNotEmpty) {
      categoryCityParts.add(p.city!.trim());
    }
    final categoryCity = categoryCityParts.join(' · ');

    return Column(
      children: [
        // ─── Cover image with gradient overlay ───
        SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover
              if (p.coverUrl != null)
                CachedNetworkImage(
                  imageUrl: p.coverUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.violet.withAlpha(60),
                        AppColors.rose.withAlpha(40),
                        AppColors.fond,
                      ],
                    ),
                  ),
                ),
              // Gradient overlay (bottom fade to fond)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 140,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.fond],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Avatar with animated gradient ring ───
        Transform.translate(
          offset: const Offset(0, -48),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet
                              .withAlpha((40 * _glowAnimation.value).round()),
                          blurRadius: 24 * _glowAnimation.value,
                          spreadRadius: 4 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.violet,
                        AppColors.rose,
                        AppColors.violetClair,
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.fond,
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.surfaceAlt,
                      backgroundImage: p.avatarUrl != null
                          ? CachedNetworkImageProvider(p.avatarUrl!)
                          : null,
                      child: p.avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 40, color: AppColors.gris)
                          : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ─── Name + Verified + TOP PRO ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        p.businessName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.violet,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.blanc,
                      ),
                    ),
                    if (p.isTopPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TOP PRO',
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ─── Category · City ───
              if (categoryCity.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  categoryCity,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
                ),
              ],

              const SizedBox(height: 14),

              // ─── Gold rating ───
              _GoldRating(rating: p.rating, reviewsCount: p.reviewsCount),

              const SizedBox(height: 16),

              // ─── Stats row ───
              _StatsRow(proId: p.id, reviewsCount: p.reviewsCount),

              // ─── Social links ───
              if (p.socialConnections.isNotEmpty) ...[
                const SizedBox(height: 16),
                SocialLinksRow(connections: p.socialConnections),
              ],

              // ─── Bio ───
              if (p.bio != null && p.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    p.bio!.trim(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc.withAlpha(200),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ─── Action buttons: Follow + Message + Book ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Follow
                    Expanded(
                      child: _ActionButton(
                        label: _isFollowed ? 'Following' : 'Follow',
                        icon: _isFollowed
                            ? Icons.check_rounded
                            : Icons.person_add_outlined,
                        isActive: _isFollowed,
                        onTap: _toggleFollow,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Message
                    Expanded(
                      child: _ActionButton(
                        label: 'Message',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: _openMessage,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Book (gradient)
                    Expanded(
                      flex: 2,
                      child: _BookButton(onTap: _openBooking),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Floating icon button (glass effect over cover) ──────────────────────────

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.fond.withAlpha(140),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blanc.withAlpha(20)),
            ),
            child: Icon(icon, color: AppColors.blanc, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Gold rating display ─────────────────────────────────────────────────────

class _GoldRating extends StatelessWidget {
  const _GoldRating({required this.rating, required this.reviewsCount});

  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final fill = (rating - i).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: _StarIcon(fill: fill),
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewsCount)',
          style: GoogleFonts.dmSans(
            color: AppColors.gris.withAlpha(180),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StarIcon extends StatelessWidget {
  const _StarIcon({required this.fill});

  final double fill;

  static const _gold = Color(0xFFFFB800);
  static const _empty = Color(0xFF3A3A4A);

  @override
  Widget build(BuildContext context) {
    if (fill >= 0.99) {
      return const Icon(Icons.star_rounded, color: _gold, size: 18);
    }
    if (fill <= 0.01) {
      return const Icon(Icons.star_rounded, color: _empty, size: 18);
    }
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) {
        return LinearGradient(
          stops: [fill, fill],
          colors: const [_gold, _empty],
        ).createShader(rect);
      },
      child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.proId, required this.reviewsCount});

  final String proId;
  final int reviewsCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(proProfileVideosProvider(proId));
    final videosCount = videosAsync.maybeWhen(
      data: (v) => v.length,
      orElse: () => 0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withAlpha(60)),
      ),
      child: Row(
        children: [
          _StatItem(value: '$videosCount', label: 'Videos'),
          _statDivider(),
          _StatItem(value: '$reviewsCount', label: 'Reviews'),
          _statDivider(),
          const _StatItem(value: '—', label: 'Bookings'),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border.withAlpha(60),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.gris.withAlpha(180),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action buttons ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.violet.withAlpha(25) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.violet : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.violet : AppColors.blanc,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isActive ? AppColors.violet : AppColors.blanc,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.gradientAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.blanc, size: 16),
            const SizedBox(width: 8),
            Text(
              'Book',
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Persistent bottom booking bar (Fresha-style) ────────────────────────────

class _PersistentBookingBar extends StatelessWidget {
  const _PersistentBookingBar({
    required this.proName,
    required this.onBook,
    required this.bottomPadding,
  });

  final String proName;
  final VoidCallback onBook;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding + 14),
          decoration: BoxDecoration(
            color: AppColors.fond.withAlpha(230),
            border: Border(
              top: BorderSide(color: AppColors.border.withAlpha(60)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      proName,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Available services',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onBook,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Book',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
}

// ─── Pinned tab bar delegate ─────────────────────────────────────────────────

class _PremiumTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PremiumTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.fond,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PremiumTabBarDelegate old) =>
      old._tabBar != _tabBar;
}

// ─── Videos grid tab ─────────────────────────────────────────────────────────

class _ProVideosGrid extends ConsumerWidget {
  const _ProVideosGrid({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileVideosProvider(proId));

    return async.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const _EmptyState(
              icon: Icons.videocam_outlined, text: 'No videos');
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: videos.length,
          itemBuilder: (_, i) => VideoThumbnailCard(video: videos[i]),
        );
      },
      loading: () => const SpotbookLoadingShimmer.card(itemCount: 4),
      error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(proProfileVideosProvider(proId))),
    );
  }
}

// ─── Premium services list (Fresha-style cards) ──────────────────────────────

class _PremiumServicesList extends ConsumerWidget {
  const _PremiumServicesList({
    required this.proId,
    required this.proProfile,
  });

  final String proId;
  final ProProfile proProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileServicesProvider(proId));

    return async.when(
      data: (services) {
        if (services.isEmpty) {
          return const _EmptyState(
              icon: Icons.design_services_outlined, text: 'No services');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: services.length,
          itemBuilder: (_, i) => _PremiumServiceCard(
            service: services[i],
            proProfile: proProfile,
          ),
        );
      },
      loading: () => const SpotbookLoadingShimmer.list(itemCount: 3),
      error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(proProfileServicesProvider(proId))),
    );
  }
}

class _PremiumServiceCard extends StatelessWidget {
  const _PremiumServiceCard({
    required this.service,
    required this.proProfile,
  });

  final ServiceModel service;
  final ProProfile proProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Service info (left)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.gris.withAlpha(150),
                        size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${service.durationMinutes} min',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${service.price.toStringAsFixed(0)} \$',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'dès',
                style: TextStyle(
                  color: AppColors.gris.withAlpha(130),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Book button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              showBookingSheet(
                context,
                proId: proProfile.id,
                proProfile: proProfile,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Book',
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium reviews list ────────────────────────────────────────────────────

class _PremiumReviewsList extends ConsumerWidget {
  const _PremiumReviewsList({
    required this.proId,
    required this.rating,
    required this.reviewsCount,
  });

  final String proId;
  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileReviewsProvider(proId));

    return async.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const _EmptyState(
              icon: Icons.rate_review_outlined, text: 'No reviews');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: reviews.length + 1,
          itemBuilder: (_, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _ReviewSummary(rating: rating, count: reviewsCount),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewCard(review: reviews[index - 1]),
            );
          },
        );
      },
      loading: () => const SpotbookLoadingShimmer.list(itemCount: 4),
      error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(proProfileReviewsProvider(proId))),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Big number + stars
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB800),
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                '$count avis',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          // Distribution bars
          Expanded(
            child: Column(
              children: [
                for (int stars = 5; stars >= 1; stars--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Text('$stars',
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris, fontSize: 11)),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB800), size: 11),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: review.clientAvatarUrl != null
                    ? CachedNetworkImageProvider(review.clientAvatarUrl!)
                    : null,
                child: review.clientAvatarUrl == null
                    ? const Icon(Icons.person, size: 14, color: AppColors.gris)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName ?? 'Client',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeAgo(review.createdAt),
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris.withAlpha(150),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB800),
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc.withAlpha(220),
                fontSize: 13,
                height: 1.45,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (review.serviceName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                review.serviceName!,
                style: GoogleFonts.dmSans(
                  color: AppColors.violetClair,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Traiteur menu wrapper ───────────────────────────────────────────────────

class _TraiteurMenuWrapper extends ConsumerWidget {
  const _TraiteurMenuWrapper({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(proProfileServicesProvider(proId));
    return servicesAsync.when(
      data: (services) => TraiteurMenuTab(services: services),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.violet)),
      error: (_, __) => Center(
        child:
            Text('Loading error', style: GoogleFonts.dmSans(color: AppColors.gris)),
      ),
    );
  }
}

// ─── Events list tab ─────────────────────────────────────────────────────────

class _ProEventsList extends ConsumerWidget {
  const _ProEventsList({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proProfileEventsForProProvider(proId));

    return async.when(
      data: (events) {
        if (events.isEmpty) {
          return const _EmptyState(
              icon: Icons.event_outlined, text: 'No events');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: events.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProEventProfileCard(event: events[i]),
          ),
        );
      },
      loading: () => const SpotbookLoadingShimmer.card(itemCount: 3),
      error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(proProfileEventsForProProvider(proId))),
    );
  }
}

// ─── Shared empty / error states ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violet.withAlpha(15),
            ),
            child: Icon(icon, size: 28, color: AppColors.violet),
          ),
          const SizedBox(height: 12),
          Text(text, style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text('Loading error',
              style: GoogleFonts.sora(color: AppColors.gris, fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.dmSans(
                color: AppColors.violet,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.violet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
