import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
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
import '../../../catering/data/catering_repository.dart';
import '../../../catering/domain/catering_models.dart';
import '../../../catering/presentation/widgets/catering_section_widgets.dart';
import '../../../catering/presentation/widgets/catering_add_sheets.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PRO SHELL PROFILE — Premium centered self-view
// ═════════════════════════════════════════════════════════════════════════════

// ─── Providers ────────────────────────────────────────────────────────────────

final _proSelfProfileProvider =
    FutureProvider.autoDispose<ProProfile?>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  final uid = repo.currentUserId;
  if (uid == null) return null;

  // Try fetching the full pro profile
  final profile = await repo.getProProfile(uid);
  if (profile != null) return profile;

  // No profiles_pro row — build a minimal profile from the users table
  // so the screen can still render (newly converted Pro accounts).
  final userData = await repo.getClientProfile(uid);
  if (userData == null) return null;

  return ProProfile(
    id: uid,
    businessName: userData.fullName,
    category: '',
    username: userData.username,
    avatarUrl: userData.avatarUrl,
    bio: '',
    city: userData.city,
    socialConnections: const [],
    isFollowedByMe: false,
  );
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
    // Watch theme mode so the entire subtree rebuilds when dark mode toggles,
    // re-evaluating all AppColors.xxx getters with the updated brightness.
    ref.watch(themeModeProvider);

    final profileAsync = ref.watch(_proSelfProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.fond,
            body: Center(
              child: Text('Not signed in',
                  style: TextStyle(color: AppColors.gris)),
            ),
          );
        }
        return _ProSelfProfileBody(profile: profile);
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.violet),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Text('Error: $e',
              style: TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE BODY
// ═════════════════════════════════════════════════════════════════════════════

class _ProSelfProfileBody extends ConsumerStatefulWidget {
  const _ProSelfProfileBody({required this.profile});

  final ProProfile profile;

  @override
  ConsumerState<_ProSelfProfileBody> createState() =>
      _ProSelfProfileBodyState();
}

class _ProSelfProfileBodyState extends ConsumerState<_ProSelfProfileBody>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  static const _sectionCount = 7;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnims = List.generate(_sectionCount, (i) {
      final start = (i * 0.1).clamp(0.0, 0.7);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_sectionCount, (i) {
      final start = (i * 0.1).clamp(0.0, 0.7);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    final i = index.clamp(0, _sectionCount - 1);
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(
        position: _slideAnims[i],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isTraiteur = isCateringCategory(profile.category);

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
              _animated(0, _ProfileHeader(profile: profile)),

              const SizedBox(height: 16),

              // ── Social Icons Row ──
              _animated(1, _SocialIconsRow(connections: profile.socialConnections)),

              const SizedBox(height: 20),

              // ── Quick Actions ──
              _animated(2, _QuickActions(profile: profile)),

              const SizedBox(height: 28),

              // ── Videos Section ──
              _animated(3, Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'My videos',
                    onSeeAll: () => context.push('/pro/feed'),
                  ),
                  const SizedBox(height: 10),
                  _VideosRow(ref: ref),
                ],
              )),

              const SizedBox(height: 28),

              // ── Services Section ──
              _animated(4, Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'My services',
                    onSeeAll: () => context.push('/pro/services'),
                  ),
                  const SizedBox(height: 10),
                  _ServicesList(ref: ref),
                ],
              )),

              // ── Catering Section (conditional — Cuisine/Traiteur/Chef) ──
              if (isTraiteur) ...[
                const SizedBox(height: 24),
                _CateringSection(proId: profile.id),
              ],

              const SizedBox(height: 28),

              // ── Events Section ──
              _animated(5, Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'My events',
                    onSeeAll: () => context.push('/pro/events'),
                  ),
                  const SizedBox(height: 10),
                  _EventsList(ref: ref),
                ],
              )),

              const SizedBox(height: 32),

              // ── Settings Section ──
              _animated(6, const _InlineSettingsSection()),

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
  late final AnimationController _avatarCtrl;
  late final Animation<double> _avatarScale;
  late final Animation<double> _ringRotation;

  @override
  void initState() {
    super.initState();
    _avatarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _avatarScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _avatarCtrl,
      curve: Curves.easeInOut,
    ));
    _ringRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _avatarCtrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _avatarCtrl.dispose();
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.settings_outlined,
                  color: AppColors.gris, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Avatar 96px with animated gradient ring
        AnimatedBuilder(
          animation: _avatarCtrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _avatarScale.value,
              child: SizedBox(
                width: 102,
                height: 102,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating gradient ring
                    Transform.rotate(
                      angle: _ringRotation.value,
                      child: Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.violet,
                              AppColors.rose,
                              AppColors.violet.withAlpha(80),
                              AppColors.violet,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // White gap ring
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.fond,
                      ),
                    ),
                    // Avatar circle
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      child: ClipOval(
                        child: _buildAvatar(profile, initial),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        // Name — Sora bold, proper case
        Text(
          name,
          style: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.blanc,
            letterSpacing: -0.5,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),

        // Username handle
        if (profile.username != null && profile.username!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@${profile.username}',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.gris,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 10),

        // Category badge + location in a row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (profile.category.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.category,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.violet,
                  ),
                ),
              ),
            if (profile.category.isNotEmpty &&
                profile.city != null &&
                profile.city!.trim().isNotEmpty)
              const SizedBox(width: 8),
            if (profile.city != null && profile.city!.trim().isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.gris.withAlpha(180)),
                  const SizedBox(width: 2),
                  Text(
                    profile.city!,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.gris,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Rating
        if (profile.reviewsCount > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (i) {
                final filled = i < profile.rating.round();
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? AppColors.starGold : AppColors.grisInactif,
                  size: 16,
                );
              }),
              const SizedBox(width: 6),
              Text(
                '${profile.rating.toStringAsFixed(1)} (${profile.reviewsCount})',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.gris,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],

        // Bio
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            profile.bio!.trim(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.gris,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 18),

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

  Widget _buildAvatar(ProProfile profile, String initial) {
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: profile.avatarUrl!,
        fit: BoxFit.cover,
        width: 90,
        height: 90,
        placeholder: (_, __) => _InitialCircle(initial: initial),
        errorWidget: (_, __, ___) => _InitialCircle(initial: initial),
      );
    }
    return _InitialCircle(initial: initial);
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.sora(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.violet,
          ),
        ),
      ),
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
              child: Icon(Icons.add,
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

class _QuickActionBtn extends StatefulWidget {
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickActionBtn> createState() => _QuickActionBtnState();
}

class _QuickActionBtnState extends State<_QuickActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _tiltAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _tiltAnim = Tween<double>(begin: 0, end: 0.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(_tiltAnim.value),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.violet.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: AppColors.violet, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.gris,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.blanc,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'See all',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.violet,
                  fontWeight: FontWeight.w600,
                ),
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
      loading: () => SizedBox(
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
            Icon(Icons.add, color: AppColors.grisInactif, size: 24),
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
      loading: () => SizedBox(
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.fond,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.design_services_outlined,
                color: AppColors.violet, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blanc,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMinutes} min',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.gris,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '\$${service.price.toStringAsFixed(0)}',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.violet,
              ),
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
      loading: () => SizedBox(
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date badge instead of generic icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.gradientAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.eventDate != null
                        ? DateFormat.d().format(event.eventDate!)
                        : '—',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    event.eventDate != null
                        ? DateFormat.MMM().format(event.eventDate!).toUpperCase()
                        : '',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary.withAlpha(200),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blanc,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateStr,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.gris,
                    ),
                  ),
                ],
              ),
            ),
            if (event.minPrice > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${event.minPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.violet,
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
// CATERING SECTION — conditional, for Cuisine/Traiteur/Chef Pros
// Uses catering_menu_items, catering_forfaits, catering_gallery tables
// ═════════════════════════════════════════════════════════════════════════════

class _CateringSection extends ConsumerWidget {
  const _CateringSection({required this.proId});

  final String proId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(cateringMenuProvider(proId));
    final forfaitsAsync = ref.watch(cateringForfaitsProvider(proId));
    final galleryAsync = ref.watch(cateringGalleryProvider(proId));

    final menuItems = menuAsync.asData?.value ?? [];
    final forfaits = forfaitsAsync.asData?.value ?? [];
    final gallery = galleryAsync.asData?.value ?? [];

    void refreshAll() {
      ref.invalidate(cateringMenuProvider(proId));
      ref.invalidate(cateringForfaitsProvider(proId));
      ref.invalidate(cateringGalleryProvider(proId));
    }

    final repo = ref.read(cateringRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CateringBanner(
          subtitle: 'Manage your menu, packages and quote requests',
        ),
        const SizedBox(height: 14),

        // ── Menu Items ──
        const CateringSectionHeader(title: 'MY MENU'),
        const SizedBox(height: 10),
        CateringMenuGrid(
          items: menuItems,
          onAddTap: () => showAddDishSheet(
            context,
            repo: repo,
            proId: proId,
            onDone: refreshAll,
          ),
        ),
        const SizedBox(height: 14),

        // ── Packages ──
        const CateringSectionHeader(title: 'MY PACKAGES'),
        const SizedBox(height: 10),
        CateringForfaitList(
          forfaits: forfaits,
          onAddTap: () => showAddPackageSheet(
            context,
            repo: repo,
            proId: proId,
            onDone: refreshAll,
          ),
        ),
        const SizedBox(height: 14),

        // ── Gallery ──
        if (gallery.isNotEmpty) ...[
          const CateringSectionHeader(title: 'GALLERY'),
          const SizedBox(height: 10),
          CateringGalleryRow(items: gallery),
          const SizedBox(height: 14),
        ],

        // ── Quote CTA ──
        CateringRequestQuoteCTA(
          onTap: () => showTraiteurSoumissionSheet(context, proId: proId),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INLINE SETTINGS SECTION — clean, only essentials
// ═════════════════════════════════════════════════════════════════════════════

class _InlineSettingsSection extends ConsumerWidget {
  const _InlineSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: GoogleFonts.sora(
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
        _DarkModeTile(
          isDark: isDark,
          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ],
    );
  }
}

class _DarkModeTile extends StatelessWidget {
  const _DarkModeTile({required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: AppColors.blanc,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dark Mode',
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child: Switch.adaptive(
              value: isDark,
              onChanged: onChanged,
              activeTrackColor: AppColors.violet,
            ),
          ),
        ],
      ),
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
        decoration: BoxDecoration(
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
            Icon(Icons.arrow_forward_ios,
                color: AppColors.gris, size: 13),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOG OUT BUTTON — red destructive style, functional
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
          builder: (ctx) => AlertDialog(
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
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmSans(color: AppColors.gris),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Log out',
                  style: GoogleFonts.dmSans(
                    color: AppColors.logout,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          try {
            await ref.read(authRepositoryProvider).signOut();
          } catch (e) {
            debugPrint('[pro_profile] signOut error ignored: $e');
          }
          if (context.mounted) context.go('/login');
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.logout.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.logout.withAlpha(60),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.logout,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Log out',
                style: GoogleFonts.dmSans(
                  color: AppColors.logout,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.grisInactif.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.grisInactif, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.gris,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.violet,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
