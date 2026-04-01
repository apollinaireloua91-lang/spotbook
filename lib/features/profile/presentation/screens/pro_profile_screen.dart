import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_avatar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../chat/data/chat_repository.dart';
import '../../data/profile_repository.dart';
import '../../domain/entities/provider_profile_data.dart';
import '../notifiers/provider_profile_notifier.dart';
import '../widgets/share_profile_modal.dart';
import '../widgets/social_link_sheets.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PRO PROFILE SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class ProProfileScreen extends ConsumerStatefulWidget {
  const ProProfileScreen({
    super.key,
    required this.proId,
    this.showOwnerTools = true,
  });

  final String proId;

  /// `false` = vu par un client : même mise en page sans calendrier, scan QR, ni événements pro.
  final bool showOwnerTools;

  @override
  ConsumerState<ProProfileScreen> createState() => _ProProfileScreenState();
}

class _ProProfileScreenState extends ConsumerState<ProProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerProfileNotifierProvider.notifier).load(
            widget.proId,
            isOwnerView: widget.showOwnerTools,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(providerProfileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      bottomNavigationBar: widget.showOwnerTools
          ? null
          : switch (profileState) {
              ProviderProfileLoaded(:final data) =>
                _buildGuestBottomBar(context, data),
              _ => null,
            },
      body: switch (profileState) {
        ProviderProfileInitial() ||
        ProviderProfileLoading() =>
          _ProfileShimmerLayout(),
        ProviderProfileLoaded(:final data) => _ProfileBody(
            data: data,
            showOwnerTools: widget.showOwnerTools,
          ),
        ProviderProfileError(:final failure) => _ErrorView(
            message: failure.message,
            onRetry: () => ref.read(providerProfileNotifierProvider.notifier).load(
                  widget.proId,
                  isOwnerView: widget.showOwnerTools,
                ),
          ),
      },
    );
  }

  Widget _buildGuestBottomBar(BuildContext context, ProviderProfileData data) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: SpotbookButton.primary(
                label: 'Réserver',
                onPressed: () => _onGuestReserve(context, data),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SpotbookButton.outlined(
                label: 'Message',
                onPressed: () => _onGuestMessage(context, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onGuestReserve(BuildContext context, ProviderProfileData data) {
    HapticFeedback.mediumImpact();
    ServiceEntity? svc;
    for (final x in data.services) {
      if (x.isActive) {
        svc = x;
        break;
      }
    }
    final pid = data.provider.id;
    if (svc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'Aucun service réservable pour le moment.',
            style: TextStyle(color: AppColors.blanc),
          ),
        ),
      );
      return;
    }
    context.push('/client/booking-flow/$pid?serviceId=${svc.id}');
  }

  Future<void> _onGuestMessage(
    BuildContext context,
    ProviderProfileData data,
  ) async {
    HapticFeedback.mediumImpact();
    final repo = ref.read(chatRepositoryProvider);
    final uid = repo.currentUserId;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Connecte-toi pour envoyer un message.',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
      return;
    }
    try {
      final conv = await repo.getOrCreateConversation(
        clientId: uid,
        proId: data.provider.id,
      );
      if (!context.mounted) return;
      context.push(
        '/client/messages/${conv.id}',
        extra: <String, String>{'otherUserName': data.provider.fullName},
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Impossible d’ouvrir la conversation.',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    }
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────────────

class _ProfileShimmerLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: SpotbookLoadingShimmer.profile());
  }
}

// ─── Error ───────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gris, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Réessayer',
                style: TextStyle(color: AppColors.blanc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BODY
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({
    required this.data,
    required this.showOwnerTools,
  });

  final ProviderProfileData data;
  final bool showOwnerTools;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  static const double _hPad = 20;
  static const double _sectionGap = 28;

  /// Tracks which social platforms the pro has linked (local UI state).
  late Set<String> _linkedPlatforms;

  /// The platforms shown on the profile grid.
  late List<String> _visiblePlatforms;

  bool _followed = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _linkedPlatforms = widget.data.provider.socialLinks
        .where((l) => l.isLinked)
        .map((l) => l.platform)
        .toSet();

    // Default visible: backend + réseaux courants (logos dans assets/social/).
    final fromBackend =
        widget.data.provider.socialLinks.map((l) => l.platform).toSet();
    _visiblePlatforms = {
      ...fromBackend,
      'tiktok',
      'instagram',
      'snapchat',
      'twitter',
    }.toList();

    if (!widget.showOwnerTools) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowState());
    }
  }

  Future<void> _loadFollowState() async {
    final repo = ref.read(profileRepositoryProvider);
    final v = await repo.isFollowingPro(widget.data.provider.id);
    if (!mounted) return;
    setState(() => _followed = v);
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final repo = ref.read(profileRepositoryProvider);
    final pid = widget.data.provider.id;
    final was = _followed;
    setState(() {
      _followBusy = true;
      _followed = !was;
    });
    try {
      if (!was) {
        await repo.followUser(pid);
      } else {
        await repo.unfollowUser(pid);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _followed = was);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Action impossible pour le moment.',
              style: TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // ── 1. Header ──
                _buildAvatar(widget.data.provider),
                const SizedBox(height: 16),
                _buildName(widget.data.provider),
                const SizedBox(height: 8),
                _buildProfessionLocation(widget.data.provider),

                if (!widget.showOwnerTools) ...[
                  const SizedBox(height: 20),
                  _buildGuestFollowButton(),
                ],

                // ── 2. Bio / présentation (profiles_pro.description) ──
                const SizedBox(height: _sectionGap),
                _buildBioSection(context, widget.data.provider),

                // ── 3. Quick Actions + scanner (propriétaire) ──
                if (widget.showOwnerTools) ...[
                  const SizedBox(height: _sectionGap),
                  _buildQuickActions(context),
                  const SizedBox(height: 14),
                  SpotbookButton.outlined(
                    label: 'Scanner un billet (QR)',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push('/pro/scanner');
                    },
                  ),
                ],

                // ── 4. Services & tarifs (même source que « Services & tarifs ») ──
                const SizedBox(height: _sectionGap),
                _buildServices(context, widget.data.services),

                // ── 5. Vidéos ──
                const SizedBox(height: _sectionGap),
                _buildVideos(
                  context,
                  widget.data.videos,
                  showOwnerTools: widget.showOwnerTools,
                ),

                // ── 6. Réseaux sociaux ──
                const SizedBox(height: _sectionGap),
                _buildSocialLinks(),

                // ── 7. Événements (pro connecté) ──
                if (widget.showOwnerTools) ...[
                  const SizedBox(height: _sectionGap),
                  _buildEvents(context, widget.data.events),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    final pid = widget.data.provider.id;
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      automaticallyImplyLeading: false,
      leading: !widget.showOwnerTools
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc),
              onPressed: () => context.pop(),
            )
          : null,
      actions: [
        if (!widget.showOwnerTools)
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppColors.blanc),
            onPressed: () {
              HapticFeedback.lightImpact();
              showShareProfileModal(
                context: context,
                profileUrl: 'https://spotbook.app/client/provider/$pid',
                displayName: widget.data.provider.fullName,
                avatarUrl: widget.data.provider.avatarUrl,
              );
            },
          ),
        if (widget.showOwnerTools)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.blanc),
            onPressed: () => context.push('/pro/profile/settings'),
          ),
      ],
    );
  }

  Widget _buildGuestFollowButton() {
    return SizedBox(
      width: double.infinity,
      child: SpotbookButton.outlined(
        label: _followed ? 'Suivi(e)' : 'Suivre',
        icon: _followed ? Icons.check_rounded : Icons.person_add_outlined,
        isLoading: _followBusy,
        onPressed: _toggleFollow,
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────

  Widget _buildAvatar(ProviderEntity p) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.blanc, width: 2),
        ),
      ),
      child: SpotbookAvatar(
        imageUrl: p.avatarUrl,
        name: p.fullName,
        radius: 48,
        isVerified: p.isVerified,
      ),
    );
  }

  // ── Name ───────────────────────────────────────────────────────────────────

  Widget _buildName(ProviderEntity p) {
    return Text(
      p.fullName.toUpperCase(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.blanc,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Profession + Location ──────────────────────────────────────────────────

  Widget _buildProfessionLocation(ProviderEntity p) {
    return Column(
      children: [
        if (p.profession.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.blanc,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.profession,
              style: const TextStyle(
                color: AppColors.fond,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (p.location != null && p.location!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.gris, size: 14),
              const SizedBox(width: 3),
              Text(
                p.location!,
                style: const TextStyle(color: AppColors.gris, fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _reloadProviderProfile() async {
    await ref.read(providerProfileNotifierProvider.notifier).load(
          widget.data.provider.id,
          isOwnerView: widget.showOwnerTools,
        );
  }

  /// Texte `description` côté Supabase (`profiles_pro`) — visible client & pro.
  Widget _buildBioSection(BuildContext context, ProviderEntity p) {
    final bio = p.bio?.trim();
    if (bio != null && bio.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'PRÉSENTATION'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(
              bio,
              style: const TextStyle(
                color: AppColors.grisClair,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          if (widget.showOwnerTools) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await context.push('/pro/profile/edit');
                  if (context.mounted) await _reloadProviderProfile();
                },
                child: const Text(
                  'Modifier',
                  style: TextStyle(color: AppColors.violetClair, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      );
    }
    if (widget.showOwnerTools) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'PRÉSENTATION'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Text(
              'Ajoute une description : elle apparaît ici et sur ton profil vu par les clients.',
              style: TextStyle(color: AppColors.gris, fontSize: 13, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          SpotbookButton.outlined(
            label: 'Rédiger ma présentation',
            icon: Icons.edit_outlined,
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await context.push('/pro/profile/edit');
              if (context.mounted) await _reloadProviderProfile();
            },
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. SOCIAL LINKS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'MES RÉSEAUX SOCIAUX'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            ..._visiblePlatforms.map((key) {
              final info = platformInfoFor(key);
              if (info == null) return const SizedBox.shrink();
              final isLinked = _linkedPlatforms.contains(key);
              return _SocialIconTile(
                info: info,
                isLinked: isLinked,
                onTap: () => _onSocialTap(info),
              );
            }),
            if (widget.showOwnerTools) _AddTile(onTap: _onAddSocialTap),
          ],
        ),
      ],
    );
  }

  Future<void> _onSocialTap(SocialPlatformInfo info) async {
    if (!widget.showOwnerTools) {
      await _openGuestSocialLink(info);
      return;
    }

    final existingLink = widget.data.provider.socialLinks
        .where((l) => l.platform == info.key)
        .firstOrNull;

    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialLinkBottomSheet(
        platform: info,
        currentUrl: existingLink?.url,
      ),
    );

    if (url != null && mounted) {
      setState(() => _linkedPlatforms.add(info.key));
      ref
          .read(providerProfileNotifierProvider.notifier)
          .saveSocialLink(platform: info.key, url: url);
    }
  }

  Future<void> _openGuestSocialLink(SocialPlatformInfo info) async {
    final match = widget.data.provider.socialLinks
        .where((l) => l.platform == info.key)
        .firstOrNull;
    if (match == null || !match.isLinked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Aucun lien ${info.label} renseigné.',
              style: const TextStyle(color: AppColors.blanc),
            ),
          ),
        );
      }
      return;
    }
    final raw = match.url?.trim();
    if (raw != null && raw.isNotEmpty) {
      final u = Uri.tryParse(raw);
      if (u != null && await canLaunchUrl(u)) {
        await launchUrl(u, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'Lien non disponible.',
            style: TextStyle(color: AppColors.blanc),
          ),
        ),
      );
    }
  }

  Future<void> _onAddSocialTap() async {
    final selected = await showModalBottomSheet<SocialPlatformInfo>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddSocialPlatformSheet(
        alreadyAdded: _visiblePlatforms.toSet(),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _visiblePlatforms.add(selected.key));
      // Immediately open the link sheet for the newly added platform.
      _onSocialTap(selected);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. QUICK ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'QUICK ACTIONS'),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'CALENDRIER\n/ DISPOS',
                  onTap: () => context.push('/pro/profile/availability'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'CRÉER\nÉVÉNEMENT',
                  onTap: () => context.push('/pro/events/create'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. MES VIDÉOS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildVideos(
    BuildContext context,
    List<VideoEntity> videos, {
    required bool showOwnerTools,
  }) {
    if (!showOwnerTools && videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          label: showOwnerTools ? 'MES VIDÉOS (TON COMPTE)' : 'VIDÉOS',
        ),
        const SizedBox(height: 12),
        if (showOwnerTools && videos.isEmpty) ...[
          _VideoFeedPreviewPlaceholder(
            onOpenCamera: () => context.push('/pro/camera'),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.isEmpty ? 1 : videos.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (videos.isEmpty) {
                return _DashedAddButton(
                  width: 100,
                  height: 160,
                  label: '+ Ajouter\nune vidéo',
                  onTap: () => context.push('/pro/camera'),
                );
              }
              if (i < videos.length) {
                return _VideoThumbnail(
                  video: videos[i],
                  showStatusBadge: showOwnerTools,
                );
              }
              return _DashedAddButton(
                width: 100,
                height: 160,
                label: '+ Ajouter\nune vidéo',
                onTap: () => context.push('/pro/camera'),
              );
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. MES SERVICES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildServices(BuildContext context, List<ServiceEntity> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionLabel(label: 'SERVICES & TARIFS')),
            if (widget.showOwnerTools)
              TextButton(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await context.push('/pro/profile/services');
                  if (context.mounted) await _reloadProviderProfile();
                },
                child: const Text(
                  'Gérer',
                  style: TextStyle(color: AppColors.violetClair, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: services.length + (widget.showOwnerTools ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            if (i < services.length) {
              return _ServiceCard(service: services[i]);
            }
            return _DashedAddButton(
              height: 64,
              label: '+ Ajouter un service',
              onTap: () async {
                HapticFeedback.mediumImpact();
                await context.push('/pro/profile/services');
                if (context.mounted) await _reloadProviderProfile();
              },
            );
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. MES ÉVÉNEMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEvents(BuildContext context, List<EventEntity> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'MES ÉVÉNEMENTS'),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: events.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i < events.length) {
              return _EventCard(event: events[i], context: context);
            }
            return _DashedAddButton(
              height: 64,
              label: '+ Créer un événement',
              onTap: () => context.push('/pro/events/create'),
            );
          },
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED PRIVATE WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.gris,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Social icon tile ─────────────────────────────────────────────────────────

/// Aperçu du flux : même disposition que le feed (colonne d’actions) sans vidéo réelle.
class _VideoFeedPreviewPlaceholder extends StatelessWidget {
  const _VideoFeedPreviewPlaceholder({required this.onOpenCamera});

  final VoidCallback onOpenCamera;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.surfaceAlt, AppColors.surface],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: h * 0.35,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.fond.withValues(alpha: 0.95),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 72,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Aucune vidéo sur ton compte',
                        style: TextStyle(
                          color: AppColors.blanc.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ici s’affichent uniquement tes vidéos Spotbook (en modération ou déjà publiées). Dès que tu en crées une, elle apparaît dans cette liste.',
                        style: TextStyle(
                          color: AppColors.gris.withValues(alpha: 0.95),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PreviewActionDisc(icon: Icons.favorite_border, label: '0'),
                      const SizedBox(height: 14),
                      _PreviewActionDisc(
                          icon: Icons.bookmark_border, label: '0'),
                      const SizedBox(height: 14),
                      _PreviewActionDisc(icon: Icons.ios_share, label: 'Partager'),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenCamera,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.blanc.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded,
                                color: AppColors.blanc, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Créer une nouvelle vidéo',
                              style: TextStyle(
                                color: AppColors.blanc,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreviewActionDisc extends StatelessWidget {
  const _PreviewActionDisc({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.overlayDark,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.blanc.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, color: AppColors.blanc, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SocialIconTile extends StatelessWidget {
  const _SocialIconTile({
    required this.info,
    required this.isLinked,
    required this.onTap,
  });

  final SocialPlatformInfo info;
  final bool isLinked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: ColoredBox(
                color: AppColors.surfaceAlt,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final side = c.maxWidth;
                    return SizedBox(
                      width: side,
                      height: side,
                      child: Center(
                        child: SocialPlatformBrandIcon(
                          platform: info,
                          size: side,
                          brandAssetFit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (isLinked)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fond, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Add tile (dashed border, "+" icon) ───────────────────────────────────────

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.border,
          borderRadius: 14,
          dashWidth: 5,
          dashSpace: 4,
        ),
        child: const Center(
          child: Icon(Icons.add, color: AppColors.gris, size: 26),
        ),
      ),
    );
  }
}

// ── Quick Action card ────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.blanc, size: 24),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video thumbnail ──────────────────────────────────────────────────────────

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({
    required this.video,
    this.showStatusBadge = false,
  });
  final VideoEntity video;
  final bool showStatusBadge;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 100,
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (video.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: video.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surface),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surface),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.surfaceAlt, AppColors.surface],
                  ),
                ),
              ),

            // Bottom gradient overlay
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.overlayPicker],
                  ),
                ),
              ),
            ),

            // Play icon
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blanc.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.blanc,
                  size: 22,
                ),
              ),
            ),

            // Views badge
            if (video.viewsCount > 0)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.shadowDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_outlined,
                          color: AppColors.blanc, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        _formatViews(video.viewsCount),
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (showStatusBadge &&
                video.status != null &&
                video.status != 'approved')
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    switch (video.status!) {
                      'processing' => 'Traitement',
                      'pending_review' => 'En revue',
                      'rejected' => 'Refusée',
                      'flagged' => 'Signalée',
                      _ => video.status!,
                    },
                    style: const TextStyle(
                      color: AppColors.fond,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Service card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});
  final ServiceEntity service;

  IconData get _icon {
    final name = service.name.toLowerCase();
    if (name.contains('coiff') || name.contains('hair')) {
      return Icons.content_cut;
    }
    if (name.contains('massage') || name.contains('spa')) {
      return Icons.spa_outlined;
    }
    if (name.contains('photo')) return Icons.camera_alt_outlined;
    if (name.contains('makeup') || name.contains('maquill')) {
      return Icons.brush_outlined;
    }
    if (name.contains('ongle') || name.contains('nail')) {
      return Icons.back_hand_outlined;
    }
    return Icons.auto_awesome_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Icon block
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: AppColors.blanc, size: 18),
          ),
          const SizedBox(width: 12),

          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMinutes} min · Sur rendez-vous',
                  style: const TextStyle(color: AppColors.gris, fontSize: 10),
                ),
                if (service.description != null &&
                    service.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    service.description!.trim(),
                    style: const TextStyle(
                      color: AppColors.grisClair,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Price
          Text(
            '\$${service.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event card (with gradient banner) ────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.context});
  final EventEntity event;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final date = event.eventDate;
    final day = date != null ? date.day.toString().padLeft(2, '0') : '--';
    final month = date != null ? _monthAbbr(date.month) : '---';
    final remaining = event.maxAttendees - event.ticketsSold;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gradient banner ──
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.surface, AppColors.border],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (event.venueName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.venueName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.blanc.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                // Date badge (top-right)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.blanc,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$day $month',
                      style: const TextStyle(
                        color: AppColors.fond,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Info zone ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (event.eventTime != null) event.eventTime!,
                          '${event.maxAttendees} places',
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.gris,
                          fontSize: 10,
                        ),
                      ),
                      if (remaining > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '$remaining billets restants',
                            style: const TextStyle(
                              color: AppColors.grisClair,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Manage button
                GestureDetector(
                  onTap: () => context.push('/pro/events/${event.id}/edit'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.blanc,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'GÉRER',
                      style: TextStyle(
                        color: AppColors.fond,
                        fontSize: 11,
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
    );
  }

  String _monthAbbr(int m) {
    const months = [
      'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN',
      'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC',
    ];
    return months[m - 1];
  }
}

// ── Dashed "add" button ──────────────────────────────────────────────────────

class _DashedAddButton extends StatelessWidget {
  const _DashedAddButton({
    this.width,
    required this.height,
    required this.label,
    required this.onTap,
  });

  final double? width;
  final double height;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.border,
          borderRadius: 12,
          dashWidth: 6,
          dashSpace: 4,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashed border painter ────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    double distance = 0;
    while (distance < totalLength) {
      final end = math.min(distance + dashWidth, totalLength);
      final segment = metrics.extractPath(distance, end);
      canvas.drawPath(segment, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      color != old.color ||
      borderRadius != old.borderRadius ||
      dashWidth != old.dashWidth;
}
