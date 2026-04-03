import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';
import '../../../events/data/event_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../../feed/data/video_repository.dart';
import '../../../feed/domain/video_model.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../widgets/pro_profile_content_widgets.dart';
import '../widgets/social_badge_widget.dart';
import '../widgets/social_link_sheets.dart';
import '../widgets/traiteur_soumission_sheet.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PRO SHELL PROFILE — Premium centered self-view
// ═════════════════════════════════════════════════════════════════════════════

// ─── Providers ────────────────────────────────────────────────────────────────

final _proSelfProfileProvider =
    FutureProvider.autoDispose<ProProfile?>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return null;
  return ref.read(profileRepositoryProvider).getProProfile(uid);
});

final _proSelfVideosProvider =
    FutureProvider.autoDispose<List<VideoModel>>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return [];
  final list = await ref.read(videoRepositoryProvider).getProVideos(uid);
  return list.where((v) => v.status == 'approved').toList();
});

final _proSelfServicesProvider =
    FutureProvider.autoDispose<List<ServiceModel>>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return [];
  return ref.read(bookingRepositoryProvider).getProServices(uid);
});

final _proSelfEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final uid = ref.read(profileRepositoryProvider).currentUserId;
  if (uid == null) return [];
  return ref.read(eventRepositoryProvider).getEventsByProId(uid);
});

class ProShellProfileScreen extends ConsumerWidget {
  const ProShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_proSelfProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: AppColors.fond,
            body: Center(
              child: Text('Not signed in',
                  style: TextStyle(color: AppColors.gris)),
            ),
          );
        }
        return _ProSelfProfileBody(profile: profile);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.violet),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE BODY
// ═════════════════════════════════════════════════════════════════════════════

class _ProSelfProfileBody extends ConsumerWidget {
  const _ProSelfProfileBody({required this.profile});

  final ProProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTraiteur = profile.category.toLowerCase().contains('traiteur');

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () async {
            ref.invalidate(_proSelfProfileProvider);
            ref.invalidate(_proSelfVideosProvider);
            ref.invalidate(_proSelfServicesProvider);
            ref.invalidate(_proSelfEventsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // ── Header ──
              _ProfileHeader(profile: profile),

              const SizedBox(height: 16),

              // ── Social Icons Row ──
              _SocialIconsRow(connections: profile.socialConnections),

              const SizedBox(height: 20),

              // ── Quick Actions ──
              _QuickActions(profile: profile),

              const SizedBox(height: 24),

              // ── Videos Section ──
              _SectionHeader(
                title: 'My videos',
                onSeeAll: () => context.push('/pro/feed'),
              ),
              const SizedBox(height: 10),
              _VideosRow(ref: ref),

              const SizedBox(height: 24),

              // ── Services Section ──
              _SectionHeader(
                title: 'My services',
                onSeeAll: () => context.push('/pro/services'),
              ),
              const SizedBox(height: 10),
              _ServicesList(ref: ref),

              // ── Traiteur Section (conditional) ──
              if (isTraiteur) ...[
                const SizedBox(height: 24),
                _TraiteurSection(
                  ref: ref,
                  proId: profile.id,
                  services:
                      ref.watch(_proSelfServicesProvider).asData?.value ?? [],
                ),
              ],

              const SizedBox(height: 24),

              // ── Events Section ──
              _SectionHeader(
                title: 'My events',
                onSeeAll: () => context.push('/pro/events'),
              ),
              const SizedBox(height: 10),
              _EventsList(ref: ref),

              const SizedBox(height: 32),

              // ── Settings Section ──
              const _InlineSettingsSection(),

              const SizedBox(height: 20),

              // ── Log Out Button ──
              const _LogOutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE HEADER — avatar 80px, name 22px UPPERCASE, badge, city
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.profile});

  final ProProfile profile;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final name = profile.businessName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Column(
      children: [
        // Settings gear top right
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/settings');
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blanc.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: AppColors.blanc, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Avatar 80px with violet border + breathing animation
        AnimatedBuilder(
          animation: _breathAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _breathAnim.value),
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.violet, width: 2.5),
              gradient: const LinearGradient(
                begin: Alignment(-0.5, -0.5),
                end: Alignment(0.5, 0.5),
                colors: [
                  AppColors.violetDarkGradient,
                  AppColors.violetDarkGradientEnd,
                ],
              ),
            ),
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    ),
                  )
                : Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blanc,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // Name — bold 22px UPPERCASE
        Text(
          name.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.blanc,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Category badge pill
        if (profile.category.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.violet.withAlpha(60),
                width: 0.5,
              ),
            ),
            child: Text(
              profile.category,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.violetClair,
              ),
            ),
          ),
        const SizedBox(height: 8),

        // City / location
        if (profile.city != null && profile.city!.trim().isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on,
                  size: 13, color: AppColors.gris),
              const SizedBox(width: 3),
              Text(
                profile.city!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.gris,
                ),
              ),
            ],
          ),

        // Rating
        if (profile.reviewsCount > 0) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.warning, size: 14),
              const SizedBox(width: 3),
              Text(
                '${profile.rating.toStringAsFixed(1)} (${profile.reviewsCount} reviews)',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.gris,
                ),
              ),
            ],
          ),
        ],

        // Bio
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            profile.bio!.trim(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.gris,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Edit Profile button — full width outline
        SpotbookButton.outlined(
          label: 'Edit Profile',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push('/edit-profile');
          },
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SOCIAL ICONS ROW — centered, real PNG assets
// ═════════════════════════════════════════════════════════════════════════════

class _SocialIconsRow extends StatelessWidget {
  const _SocialIconsRow({required this.connections});

  final List<SocialConnection> connections;

  void _onTapSocial(BuildContext context, SocialConnection conn) async {
    final info = platformInfoFor(conn.platform.toLowerCase());
    if (info == null) return;
    HapticFeedback.selectionClick();
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.fond,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialLinkBottomSheet(
        platform: info,
        currentUrl: conn.handle,
      ),
    );
  }

  void _onAddPlatform(BuildContext context) async {
    final existing = connections.map((c) => c.platform.toLowerCase()).toSet();
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<SocialPlatformInfo>(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddSocialPlatformSheet(alreadyAdded: existing),
    );
    if (picked != null && context.mounted) {
      await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.fond,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SocialLinkBottomSheet(platform: picked),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final conn in connections) ...[
            GestureDetector(
              onTap: () => _onTapSocial(context, conn),
              child: _SocialIconTile(
                platform: conn.platform,
                isLinked: true,
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Add platform button
          GestureDetector(
            onTap: () => _onAddPlatform(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.add,
                  color: AppColors.grisInactif, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIconTile extends StatelessWidget {
  const _SocialIconTile({
    required this.platform,
    required this.isLinked,
  });

  final String platform;
  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _buildBrandImage(),
          ),
        ),
        if (isLinked)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fond, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrandImage() {
    final info = platformInfoFor(platform.toLowerCase());
    if (info != null) {
      return SocialPlatformBrandIcon(
        platform: info,
        size: 24,
        brandAssetFit: BoxFit.contain,
      );
    }
    // Fallback to generic SocialIcon from social_badge_widget
    return SocialIcon(platform: platform, size: 24);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUICK ACTIONS — English labels
// ═════════════════════════════════════════════════════════════════════════════

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.profile});

  final ProProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionBtn(
          icon: Icons.design_services_outlined,
          label: 'Services',
          onTap: () => context.push('/pro/services'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.event_outlined,
          label: 'Events',
          onTap: () => context.push('/pro/events'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.bar_chart_rounded,
          label: 'Revenue',
          onTap: () => context.push('/pro/revenue'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.schedule_outlined,
          label: 'Availability',
          onTap: () => context.push('/pro/availability'),
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.violet, size: 20),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.gris,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION HEADER — English
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.blanc,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.violet,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VIDEOS ROW — horizontal scroll
// ═════════════════════════════════════════════════════════════════════════════

class _VideosRow extends StatelessWidget {
  const _VideosRow({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_proSelfVideosProvider);

    return async.when(
      data: (videos) {
        if (videos.isEmpty) {
          return _EmptySection(
            icon: Icons.videocam_outlined,
            text: 'No video yet',
            actionLabel: '+ Add a video',
            onAction: () => context.push('/pro/camera'),
          );
        }
        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == videos.length) {
                return _AddVideoCard(
                  onTap: () => context.push('/pro/camera'),
                );
              }
              return SizedBox(
                width: 100,
                child: VideoThumbnailCard(video: videos[i]),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AddVideoCard extends StatelessWidget {
  const _AddVideoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.grisInactif, size: 24),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.grisInactif,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICES LIST
// ═════════════════════════════════════════════════════════════════════════════

class _ServicesList extends StatelessWidget {
  const _ServicesList({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_proSelfServicesProvider);

    return async.when(
      data: (services) {
        if (services.isEmpty) {
          return _EmptySection(
            icon: Icons.design_services_outlined,
            text: 'No service yet',
            actionLabel: '+ Add a service',
            onAction: () => context.push('/pro/services'),
          );
        }
        return Column(
          children: [
            for (final s in services.take(3))
              _ProSelfServiceCard(service: s),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProSelfServiceCard extends StatelessWidget {
  const _ProSelfServiceCard({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.violetDarkGradientEnd,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.design_services_outlined,
                color: AppColors.violet, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${service.durationMinutes} min',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: AppColors.grisInactif,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${service.price.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.violet,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EVENTS LIST
// ═════════════════════════════════════════════════════════════════════════════

class _EventsList extends StatelessWidget {
  const _EventsList({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_proSelfEventsProvider);

    return async.when(
      data: (events) {
        if (events.isEmpty) {
          return _EmptySection(
            icon: Icons.event_outlined,
            text: 'No event yet',
            actionLabel: '+ Create an event',
            onAction: () => context.push('/pro/events'),
          );
        }
        return Column(
          children: [
            for (final e in events.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProSelfEventCard(event: e),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.violet)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProSelfEventCard extends StatelessWidget {
  const _ProSelfEventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.eventDate != null
        ? DateFormat.yMMMd('en_US').format(event.eventDate!)
        : '—';

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.rose.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event,
                  color: AppColors.rose, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blanc,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.gris,
                    ),
                  ),
                ],
              ),
            ),
            if (event.minPrice > 0)
              Text(
                '\$${event.minPrice.toStringAsFixed(0)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.violet,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRAITEUR SECTION — conditional, only for category == 'traiteur'
// ═════════════════════════════════════════════════════════════════════════════

class _TraiteurSection extends StatelessWidget {
  const _TraiteurSection({
    required this.ref,
    required this.proId,
    required this.services,
  });

  final WidgetRef ref;
  final String proId;
  final List<ServiceModel> services;

  @override
  Widget build(BuildContext context) {
    final allItems = <MenuItemModel>[];
    for (final s in services) {
      allItems.addAll(s.menuItems);
    }
    final traiteurServices =
        services.where((s) => s.isTraiteurService).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TraiteurBanner(),
        const SizedBox(height: 14),
        if (allItems.isNotEmpty) ...[
          const _SectionHeader(title: 'My menu'),
          const SizedBox(height: 10),
          _MenuGrid(items: allItems.take(4).toList()),
          const SizedBox(height: 14),
        ],
        if (traiteurServices.isNotEmpty) ...[
          const _SectionHeader(title: 'My packages'),
          const SizedBox(height: 10),
          for (final f in traiteurServices) _ForfaitCard(service: f),
          const SizedBox(height: 14),
        ],
        _SoumissionCTA(proId: proId),
      ],
    );
  }
}

class _TraiteurBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(0.5, 0.5),
          colors: [AppColors.catering, AppColors.cateringDark],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blanc.withAlpha(26),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catering Section',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blanc,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your menu, packages and quote requests',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.blanc.withAlpha(204),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});

  final List<MenuItemModel> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.1,
      children: items.map((item) => _MenuItemCard(item: item)).toList(),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.violet.withAlpha(40),
                  AppColors.rose.withAlpha(30),
                ],
              ),
            ),
            child: Center(
              child: Text(
                _getEmoji(item.name),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: GoogleFonts.dmSans(
                        fontSize: 8,
                        color: AppColors.grisInactif,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('poulet') || lower.contains('braise')) return '🍗';
    if (lower.contains('mafe') || lower.contains('curry')) return '🍛';
    if (lower.contains('thiebou') || lower.contains('riz')) return '🥘';
    if (lower.contains('suya') || lower.contains('viande')) return '🥩';
    if (lower.contains('poisson')) return '🐟';
    if (lower.contains('salade') || lower.contains('vege')) return '🥬';
    return '🍽️';
  }
}

class _ForfaitCard extends StatelessWidget {
  const _ForfaitCard({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                  ),
                ),
              ),
              Text(
                '\$${service.pricePerPerson?.toStringAsFixed(0) ?? service.price.toStringAsFixed(0)} /pers.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.catering,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (service.minPersons != null || service.maxPersons != null)
            Text(
              '${service.minPersons ?? 1} — ${service.maxPersons ?? '∞'} people',
              style: GoogleFonts.dmSans(
                fontSize: 8,
                color: AppColors.grisInactif,
              ),
            ),
          if (service.menuItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: service.menuItems.take(4).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.catering.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.catering.withAlpha(38),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      color: AppColors.cateringLight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoumissionCTA extends StatelessWidget {
  const _SoumissionCTA({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showTraiteurSoumissionSheet(context, proId: proId),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.5, -0.5),
            end: Alignment(0.5, 0.5),
            colors: [AppColors.catering, AppColors.cateringDark],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blanc.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.description_outlined,
                    color: AppColors.blanc, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quote requests',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blanc,
                    ),
                  ),
                  Text(
                    'Quotes in 24-48h · 30% deposit',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: AppColors.blanc.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.blanc, size: 14),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INLINE SETTINGS SECTION — clean, only essentials
// ═════════════════════════════════════════════════════════════════════════════

class _InlineSettingsSection extends StatelessWidget {
  const _InlineSettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () => context.push('/notification-settings'),
        ),
        _SettingsTile(
          icon: Icons.language_outlined,
          label: 'Language',
          onTap: () => context.push('/language-settings'),
        ),
        _SettingsTile(
          icon: Icons.star_outline,
          label: 'My Reviews',
          onTap: () => context.push('/review'),
        ),
        _SettingsTile(
          icon: Icons.account_balance_outlined,
          label: 'Stripe Connect',
          subtitle: 'Payment setup',
          onTap: () => context.push('/pro/stripe-connect'),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blanc, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.gris, size: 13),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOG OUT BUTTON — rose style, functional
// ═════════════════════════════════════════════════════════════════════════════

class _LogOutButton extends ConsumerWidget {
  const _LogOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Log out?',
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'You will be redirected to the login screen.',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmSans(color: AppColors.gris),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Log out',
                  style: GoogleFonts.dmSans(
                    color: AppColors.roseClair,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          await ref.read(authRepositoryProvider).signOut();
          if (context.mounted) context.go('/login');
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.rose.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Log out',
            style: GoogleFonts.dmSans(
              color: AppColors.roseClair,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.grisInactif, size: 28),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.gris,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.violet,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
