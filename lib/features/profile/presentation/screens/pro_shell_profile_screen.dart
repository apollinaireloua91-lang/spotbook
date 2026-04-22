import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/auth_required_redirect.dart';
import '../../../../shared/widgets/spotbook_snackbar.dart';
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
    // Light mode retiré (2026-04-21) — l'app est verrouillée dark, plus
    // besoin de rebuild sur toggle.
    final profileAsync = ref.watch(_proSelfProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          // Session absente OU ligne `users` manquante (cas Google OAuth
          // où setupNewUser a foiré) → on ne bloque pas l'user sur un
          // écran noir « Not signed in » sans CTA. La destination est
          // calculée par AuthRequiredRedirect selon l'état session.
          return const AuthRequiredRedirect();
        }
        return _ProSelfProfileBody(profile: profile);
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.violet),
        ),
      ),
      // Erreur fetch (réseau, RLS refusé, table manquante...) : on ne
      // laisse pas l'user sur un message d'erreur dead-end. Sentry a
      // déjà capturé via le pattern d'observabilité côté repository.
      error: (e, st) {
        if (kDebugMode) {
          debugPrint('ProShellProfileScreen error: $e\n$st');
        }
        return const AuthRequiredRedirect();
      },
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

  bool _isUploadingCover = false;

  Future<void> _pickAndUploadCover() async {
    if (_isUploadingCover) return;
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final bytes = await image.readAsBytes();
      final ext = image.path.split('.').last;
      final repo = ref.read(profileRepositoryProvider);
      await repo.uploadCover(bytes, ext);
      if (mounted) {
        ref.invalidate(_proSelfProfileProvider);
      }
    } catch (_) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        showSpotbookSnackBar(context,
            message: l.photoUploadError, type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

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
    final l = AppLocalizations.of(context)!;
    final profile = widget.profile;
    final isTraiteur = isCateringCategory(profile.category);

    const hPad = EdgeInsets.symmetric(horizontal: 20);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: RefreshIndicator(
        color: AppColors.violet,
        onRefresh: () async {
          ref.invalidate(_proSelfProfileProvider);
          ref.invalidate(_proSelfVideosProvider);
          ref.invalidate(_proSelfServicesProvider);
          ref.invalidate(_proSelfEventsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 120 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            // ── Hero: edge-to-edge cover + overlapping avatar ──
            _animated(
              0,
              _HeroCoverAvatar(
                profile: profile,
                isUploadingCover: _isUploadingCover,
                onChangeCover: _pickAndUploadCover,
              ),
            ),

            // ── Identity (name, badge, rating, bio, edit button) ──
            _animated(
              0,
              Padding(padding: hPad, child: _ProfileIdentity(profile: profile)),
            ),

            const SizedBox(height: 18),

            // ── Social Icons Row ──
            _animated(
              1,
              Padding(
                padding: hPad,
                child:
                    _SocialIconsRow(connections: profile.socialConnections),
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick Actions ──
            _animated(
              2,
              Padding(padding: hPad, child: _QuickActions(profile: profile)),
            ),

            const SizedBox(height: 28),

            // ── Videos Section ──
            _animated(
              3,
              Padding(
                padding: hPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: l.myVideosSection,
                      onSeeAll: () => context.push('/pro/feed'),
                    ),
                    const SizedBox(height: 10),
                    _VideosRow(ref: ref),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Services Section ──
            _animated(
              4,
              Padding(
                padding: hPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: l.myServicesSection,
                      onSeeAll: () => context.push('/pro/services'),
                    ),
                    const SizedBox(height: 10),
                    _ServicesList(ref: ref),
                  ],
                ),
              ),
            ),

            // ── Catering Section (conditional — Cuisine/Traiteur/Chef) ──
            if (isTraiteur) ...[
              const SizedBox(height: 24),
              Padding(padding: hPad, child: _CateringSection(proId: profile.id)),
            ],

            const SizedBox(height: 28),

            // ── Events Section ──
            _animated(
              5,
              Padding(
                padding: hPad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: l.myEventsSection,
                      onSeeAll: () => context.push('/pro/events'),
                    ),
                    const SizedBox(height: 10),
                    _EventsList(ref: ref),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Settings Section ──
            _animated(
              6,
              const Padding(padding: hPad, child: _InlineSettingsSection()),
            ),

            const SizedBox(height: 20),

            const Padding(padding: hPad, child: _LogOutButton()),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO COVER + AVATAR — edge-to-edge cover with overlapping animated avatar
// ═════════════════════════════════════════════════════════════════════════════

class _HeroCoverAvatar extends StatefulWidget {
  const _HeroCoverAvatar({
    required this.profile,
    required this.isUploadingCover,
    required this.onChangeCover,
  });

  final ProProfile profile;
  final bool isUploadingCover;
  final VoidCallback onChangeCover;

  @override
  State<_HeroCoverAvatar> createState() => _HeroCoverAvatarState();
}

class _HeroCoverAvatarState extends State<_HeroCoverAvatar>
    with SingleTickerProviderStateMixin {
  static const _coverHeight = 220.0;
  static const _avatarSize = 104.0;
  // Amount of avatar that overflows below the cover.
  static const _avatarOverflow = 56.0;

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
    ]).animate(CurvedAnimation(parent: _avatarCtrl, curve: Curves.easeInOut));
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

    return SizedBox(
      height: _coverHeight + _avatarOverflow,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Cover image or gradient fallback ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _coverHeight,
            child: _CoverContent(coverUrl: profile.coverUrl),
          ),

          // ── Bottom-to-fond gradient fade on cover ──
          Positioned(
            top: _coverHeight - 120,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.fond],
                  ),
                ),
              ),
            ),
          ),

          // ── Top overlay: camera (change cover) + settings ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _GlassIconButton(
                      icon: widget.isUploadingCover
                          ? Icons.hourglass_top_rounded
                          : Icons.photo_camera_outlined,
                      onTap: widget.isUploadingCover
                          ? null
                          : widget.onChangeCover,
                      showSpinner: widget.isUploadingCover,
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push('/settings');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Avatar, overlapping the cover bottom ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _avatarCtrl,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _avatarScale.value,
                    child: SizedBox(
                      width: _avatarSize + 6,
                      height: _avatarSize + 6,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating sweep-gradient ring
                          Transform.rotate(
                            angle: _ringRotation.value,
                            child: Container(
                              width: _avatarSize + 6,
                              height: _avatarSize + 6,
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
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.violet.withAlpha(80),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // fond gap ring
                          Container(
                            width: _avatarSize,
                            height: _avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.fond,
                            ),
                          ),
                          // Avatar content
                          Container(
                            width: _avatarSize - 6,
                            height: _avatarSize - 6,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProProfile profile, String initial) {
    final size = _avatarSize - 6;
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: profile.avatarUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, __) => _InitialCircle(initial: initial),
        errorWidget: (_, __, ___) => _InitialCircle(initial: initial),
      );
    }
    return _InitialCircle(initial: initial);
  }
}

class _CoverContent extends StatelessWidget {
  const _CoverContent({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => _CoverGradient(),
        errorWidget: (_, __, ___) => _CoverGradient(),
      );
    }
    return _CoverGradient();
  }
}

class _CoverGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withAlpha(150),
            AppColors.rose.withAlpha(90),
            AppColors.surfaceAlt,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Soft radial glow top-left for depth
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.violetClair.withAlpha(90),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.showSpinner = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(90),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(40),
                width: 0.5,
              ),
            ),
            child: Center(
              child: showSpinner
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
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
// PROFILE IDENTITY — name, username, badge, rating, bio, edit button
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.profile});

  final ProProfile profile;

  @override
  Widget build(BuildContext context) {
    final hasCategory = profile.category.isNotEmpty;
    final hasCity = profile.city != null && profile.city!.trim().isNotEmpty;
    final hasReviews = profile.reviewsCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),

        // ── Business name — oversized Sora display ──
        Text(
          profile.businessName,
          style: GoogleFonts.sora(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.blanc,
            letterSpacing: -0.8,
            height: 1.05,
          ),
          textAlign: TextAlign.center,
        ),

        // ── Handle ──
        if (profile.username != null && profile.username!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '@${profile.username}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.gris,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],

        // ── Category tag (hairline gradient outline) ──
        if (hasCategory) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.violet.withAlpha(200),
                  AppColors.rose.withAlpha(160),
                ],
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.fond,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.violetClair,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violetClair.withAlpha(160),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile.category.toUpperCase(),
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: AppColors.blanc,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ── Meta row — city · rating — caps-spaced editorial ──
        if (hasCity || hasReviews) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasCity) ...[
                Icon(Icons.place_outlined,
                    size: 13, color: AppColors.gris),
                const SizedBox(width: 4),
                Text(
                  profile.city!.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.gris,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
              if (hasCity && hasReviews) ...[
                const SizedBox(width: 10),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.grisInactif,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (hasReviews) ...[
                Icon(Icons.star_rounded,
                    size: 13, color: AppColors.starGold),
                const SizedBox(width: 4),
                Text(
                  profile.rating.toStringAsFixed(1),
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blanc,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${profile.reviewsCount})',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.gris,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ],

        // ── Bio — editorial italic pull quote ──
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Container(
                    width: 2,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientAccentVertical,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    profile.bio!.trim(),
                    textAlign: TextAlign.start,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.blanc.withAlpha(210),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      letterSpacing: 0.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ── Edit profile — editorial hairline CTA ──
        _ProEditProfilePill(
          label: AppLocalizations.of(context)!.editProfile,
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/edit-profile');
          },
        ),
      ],
    );
  }
}

// ─── Pro Edit-profile editorial CTA ────────────────────────────────────────────

class _ProEditProfilePill extends StatelessWidget {
  const _ProEditProfilePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.blanc.withAlpha(26),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withAlpha(20),
              blurRadius: 20,
              spreadRadius: -8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: LinearGradient(
                  colors: [
                    AppColors.violet.withAlpha(38),
                    AppColors.rose.withAlpha(20),
                  ],
                ),
                border: Border.all(
                  color: AppColors.violet.withAlpha(40),
                  width: 0.5,
                ),
              ),
              child: Icon(Icons.edit_outlined,
                  color: AppColors.violetClair, size: 13),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded,
                color: AppColors.gris, size: 14),
          ],
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
// QUICK ACTIONS
// ═════════════════════════════════════════════════════════════════════════════

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.profile});

  final ProProfile profile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        _QuickActionBtn(
          icon: Icons.design_services_outlined,
          label: l.servicesQuickAction,
          onTap: () => context.push('/pro/services'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.event_outlined,
          label: l.eventsQuickAction,
          onTap: () => context.push('/pro/events'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.bar_chart_rounded,
          label: l.revenueQuickAction,
          onTap: () => context.push('/pro/revenue'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.schedule_outlined,
          label: l.availabilityQuickAction,
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
// SECTION HEADER
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
                AppLocalizations.of(context)!.viewAll,
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
            text: AppLocalizations.of(context)!.noVideosAvailable,
            actionLabel: '+ ${AppLocalizations.of(context)!.addVideoAction}',
            onAction: () => _showVideoSourceSheet(context),
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
                  onTap: () => _showVideoSourceSheet(context),
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

  void _showVideoSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grisInactif,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.addVideoTitle,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blanc,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.videocam, color: AppColors.violet),
                title: Text(
                  AppLocalizations.of(context)!.recordVideo,
                  style: GoogleFonts.dmSans(color: AppColors.blanc),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.recordVideoSubtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/pro/camera');
                },
              ),
              ListTile(
                leading: Icon(Icons.upload_file, color: AppColors.violet),
                title: Text(
                  AppLocalizations.of(context)!.uploadVideo,
                  style: GoogleFonts.dmSans(color: AppColors.blanc),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.uploadVideoSubtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/upload-video');
                },
              ),
            ],
          ),
        ),
      ),
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
              AppLocalizations.of(context)!.addLabel2,
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
            text: AppLocalizations.of(context)!.noServicesLabel,
            actionLabel: '+ ${AppLocalizations.of(context)!.addServiceAction}',
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
            text: AppLocalizations.of(context)!.noEventsLabel,
            actionLabel: '+ ${AppLocalizations.of(context)!.createEventAction}',
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
        ? DateFormat.yMMMd('fr_FR').format(event.eventDate!)
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
        CateringBanner(
          subtitle: AppLocalizations.of(context)!.proShellCateringSubtitle,
        ),
        const SizedBox(height: 14),

        // ── Menu Items ──
        CateringSectionHeader(title: AppLocalizations.of(context)!.proShellMyMenu),
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
        CateringSectionHeader(title: AppLocalizations.of(context)!.proShellMyPackages),
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
          CateringSectionHeader(title: AppLocalizations.of(context)!.proShellGallery),
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
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.settings.toUpperCase(),
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
          label: l.notifications,
          onTap: () => context.push('/notification-settings'),
        ),
        _SettingsTile(
          icon: Icons.language_outlined,
          label: l.proShellLanguage,
          onTap: () => context.push('/language-settings'),
        ),
        _SettingsTile(
          icon: Icons.star_outline,
          label: l.proShellMyReviews,
          onTap: () => context.push('/review'),
        ),
        _SettingsTile(
          icon: Icons.account_balance_outlined,
          label: 'Stripe Connect',
          subtitle: l.proShellPaymentConfig,
          onTap: () => context.push('/pro/stripe-connect'),
        ),
        // _DarkModeTile retiré (2026-04-21) — light mode supprimé.
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
        final l = AppLocalizations.of(context)!;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l.logoutConfirmTitle,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              l.logoutConfirmMessage,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  l.cancel,
                  style: GoogleFonts.dmSans(color: AppColors.gris),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  l.logout,
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
                AppLocalizations.of(context)!.logout,
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
