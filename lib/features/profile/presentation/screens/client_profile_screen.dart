import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_bottom_sheet.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../chat/data/chat_repository.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../providers/client_profile_screen_provider.dart';

/// Profil client style Twitter/Threads. État chargé via [clientProfileScreenDataProvider] (Riverpod, équivalent Cubit).
class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key, this.profileUserKey = ''});

  /// Chaîne vide = utilisateur connecté ; sinon id du profil affiché (`?id=` dans la route).
  final String profileUserKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(clientProfileScreenDataProvider(profileUserKey));

    return Scaffold(
      backgroundColor: SpotbookColors.background,
      body: async.when(
        data: (data) => _ClientProfileLoadedView(
          data: data,
          profileUserKey: profileUserKey,
        ),
        loading: () => const _ClientProfileShimmer(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is StateError
                  ? l10n.clientProfileNotSignedIn
                  : l10n.error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SpotbookColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientProfileLoadedView extends ConsumerWidget {
  const _ClientProfileLoadedView({
    required this.data,
    required this.profileUserKey,
  });

  final ClientProfileScreenData data;
  final String profileUserKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = data.profile;
    final showBack = context.canPop() || profileUserKey.isNotEmpty;
    final locale = Localizations.localeOf(context).toString();

    String? memberLine;
    if (profile.createdAt != null) {
      final fmt = DateFormat.yMMMM(locale);
      memberLine = l10n.clientProfileMemberSince(fmt.format(profile.createdAt!));
    }

    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, inner) {
          return [
            SliverAppBar(
              pinned: true,
              backgroundColor: SpotbookColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: SpotbookColors.textPrimary, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                    )
                  : null,
              automaticallyImplyLeading: false,
              titleSpacing: showBack ? 0 : 20,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SpotbookColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    l10n.clientProfileReviewsCount(data.reviewsCount),
                    style: const TextStyle(
                      color: SpotbookColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                if (data.isOwnProfile)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/client/profile/settings');
                    },
                    icon: const Icon(Icons.settings_outlined,
                        color: SpotbookColors.textPrimary),
                    tooltip: l10n.settings,
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: _ProfileHeaderSection(
                data: data,
                memberLine: memberLine,
                profileUserKey: profileUserKey,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  indicatorColor: SpotbookColors.textPrimary,
                  labelColor: SpotbookColors.textPrimary,
                  unselectedLabelColor: SpotbookColors.textSecondary,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: l10n.favorites),
                    Tab(text: l10n.history),
                    Tab(text: l10n.myTickets),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            _FavoritesTab(data: data, profileUserKey: profileUserKey),
            _HistoryTab(data: data),
            _TicketsTab(data: data),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderSection extends ConsumerWidget {
  const _ProfileHeaderSection({
    required this.data,
    required this.memberLine,
    required this.profileUserKey,
  });

  final ClientProfileScreenData data;
  final String? memberLine;
  final String profileUserKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = data.profile;
    final isClientProfile =
        profile.role == null || profile.role == 'client';
    final showCollab =
        !data.isOwnProfile && data.viewerRole == 'pro' && isClientProfile;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverAndAvatarRow(
            profile: profile,
            isOwn: data.isOwnProfile,
            profileUserKey: profileUserKey,
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    color: SpotbookColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (profile.username != null &&
                    profile.username!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      color: SpotbookColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
                if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    profile.bio!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SpotbookColors.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (profile.city != null && profile.city!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: SpotbookColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            profile.city!,
                            style: const TextStyle(
                              color: SpotbookColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    if (memberLine != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: SpotbookColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            memberLine!,
                            style: const TextStyle(
                              color: SpotbookColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.clientProfileConnectedSocials,
                  style: const TextStyle(
                    color: SpotbookColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _SocialRow(urls: data.socialUrls),
                if (showCollab) ...[
                  const SizedBox(height: 20),
                  SpotbookCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.handshake_outlined,
                                color: SpotbookColors.textPrimary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.clientProfileCollaborationTitle,
                                style: const TextStyle(
                                  color: SpotbookColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.clientProfileCollaborationBody,
                          style: const TextStyle(
                            color: SpotbookColors.textSecondary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SpotbookButton.primary(
                          label: l10n.clientProfileSendCollaborationRequest,
                          onPressed: () => _openCollaboration(context, ref, data),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCollaboration(
    BuildContext context,
    WidgetRef ref,
    ClientProfileScreenData data,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conv = await repo.getOrCreateConversation(
        clientId: data.profile.id,
        proId: data.viewerUserId,
        tag: 'collaboration',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.clientProfileCollaborationOpened),
          backgroundColor: SpotbookColors.surface,
        ),
      );
      context.push(
        '/client/messages/${conv.id}',
        extra: {'otherUserName': data.profile.fullName},
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clientProfileCollaborationError),
            backgroundColor: SpotbookColors.error,
          ),
        );
      }
    }
  }
}

class _CoverAndAvatarRow extends ConsumerWidget {
  const _CoverAndAvatarRow({
    required this.profile,
    required this.isOwn,
    required this.profileUserKey,
  });

  final ClientProfile profile;
  final bool isOwn;
  final String profileUserKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: SpotbookColors.surface,
              child: InkWell(
                onTap: isOwn
                    ? () => _pickCover(context, ref, profileUserKey)
                    : null,
                child: profile.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: profile.coverUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: SpotbookColors.surface,
                          highlightColor: SpotbookColors.surfaceVariant,
                          child: Container(color: SpotbookColors.surface),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: SpotbookColors.textSecondary,
                          size: 48,
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.photo_camera_back_outlined,
                            color: SpotbookColors.textSecondary, size: 40),
                      ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: -35,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isOwn
                        ? () => _pickAvatar(context, ref, profileUserKey)
                        : null,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SpotbookColors.textPrimary,
                          width: 2,
                        ),
                        color: SpotbookColors.surfaceVariant,
                      ),
                      child: ClipOval(
                        child: profile.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: profile.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Shimmer.fromColors(
                                  baseColor: SpotbookColors.surface,
                                  highlightColor: SpotbookColors.surfaceVariant,
                                  child: Container(color: SpotbookColors.surface),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: SpotbookColors.textSecondary,
                                  size: 36,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: SpotbookColors.textSecondary,
                                size: 36,
                              ),
                      ),
                    ),
                  ),
                ),
                if (isOwn) ...[
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SpotbookButton.outlined(
                      label: l10n.clientProfileEditProfile,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/client/profile/edit');
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCover(
      BuildContext context, WidgetRef ref, String profileUserKey) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showSpotbookBottomSheet<ImageSource>(
      context: context,
      title: l10n.edit,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera,
                  color: SpotbookColors.textPrimary),
              title: Text(l10n.clientProfileTakePhoto,
                  style: const TextStyle(color: SpotbookColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: SpotbookColors.textPrimary),
              title: Text(l10n.clientProfileFromGallery,
                  style: const TextStyle(color: SpotbookColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 92);
    if (picked == null || !context.mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n.edit,
          toolbarColor: SpotbookColors.surface,
          activeControlsWidgetColor: SpotbookColors.textPrimary,
          dimmedLayerColor: Colors.black87,
        ),
        IOSUiSettings(title: l10n.edit),
      ],
    );
    if (cropped == null || !context.mounted) return;

    final bytes = await File(cropped.path).readAsBytes();
    try {
      await ref.read(profileRepositoryProvider).uploadCover(bytes, 'jpg');
      ref.invalidate(clientProfileScreenDataProvider(profileUserKey));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error),
            backgroundColor: SpotbookColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickAvatar(
      BuildContext context, WidgetRef ref, String profileUserKey) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showSpotbookBottomSheet<ImageSource>(
      context: context,
      title: l10n.edit,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera,
                  color: SpotbookColors.textPrimary),
              title: Text(l10n.clientProfileTakePhoto,
                  style: const TextStyle(color: SpotbookColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: SpotbookColors.textPrimary),
              title: Text(l10n.clientProfileFromGallery,
                  style: const TextStyle(color: SpotbookColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 92);
    if (picked == null || !context.mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n.edit,
          toolbarColor: SpotbookColors.surface,
          activeControlsWidgetColor: SpotbookColors.textPrimary,
          dimmedLayerColor: Colors.black87,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: l10n.edit,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
    if (cropped == null || !context.mounted) return;

    final bytes = await File(cropped.path).readAsBytes();
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(bytes, 'jpg');
      ref.invalidate(clientProfileScreenDataProvider(profileUserKey));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error),
            backgroundColor: SpotbookColors.error,
          ),
        );
      }
    }
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.urls});

  final Map<String, String> urls;

  static const _platforms = [
    ('tiktok', Icons.music_note),
    ('facebook', Icons.facebook),
    ('snapchat', Icons.photo_camera),
    ('twitter', Icons.chat_bubble_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _platforms.map((e) {
        final platform = e.$1;
        final icon = e.$2;
        final url = urls[platform];
        final enabled = url != null && url.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Material(
            color: SpotbookColors.surfaceVariant,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled
                  ? () async {
                      HapticFeedback.lightImpact();
                      final link = urls[platform]!;
                      final uri = Uri.tryParse(link);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    }
                  : null,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  icon,
                  size: 22,
                  color: enabled
                      ? SpotbookColors.textPrimary
                      : SpotbookColors.textDisabled,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({
    required this.data,
    required this.profileUserKey,
  });

  final ClientProfileScreenData data;
  final String profileUserKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (!data.isOwnProfile) {
      return _PrivateTabHint(message: l10n.clientProfilePrivateTabs);
    }

    final entries = <_FavoriteGridEntry>[
      ...data.favoritePros.map(_FavoriteGridEntry.pro),
      ...data.favoriteVideos.map(_FavoriteGridEntry.video),
    ];

    if (entries.isEmpty) {
      return Center(
        child: Text(
          l10n.clientProfileNoFavorites,
          style: const TextStyle(color: SpotbookColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        return Dismissible(
          key: ValueKey(e.key),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: SpotbookColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.delete,
              style: const TextStyle(
                color: SpotbookColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onDismissed: (_) async {
            final repo = ref.read(profileRepositoryProvider);
            await repo.removeFavoriteForUser(
              userId: data.viewerUserId,
              targetId: e.targetId,
            );
            ref.invalidate(clientProfileScreenDataProvider(profileUserKey));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.clientProfileRemovedFavorite),
                  backgroundColor: SpotbookColors.surface,
                ),
              );
            }
          },
          child: SpotbookCard(
            padding: const EdgeInsets.all(10),
            child: e.when(
              pro: (p) => _ProFavoriteCell(item: p),
              video: (v) => _VideoFavoriteCell(item: v),
            ),
          ),
        );
      },
    );
  }
}

sealed class _FavoriteGridEntry {
  const _FavoriteGridEntry._(this.targetId, this.key);

  final String targetId;
  final String key;

  factory _FavoriteGridEntry.pro(ClientFavoriteProItem item) =
      _FavProEntry;
  factory _FavoriteGridEntry.video(ClientFavoriteVideoItem item) =
      _FavVideoEntry;

  T when<T>({
    required T Function(ClientFavoriteProItem) pro,
    required T Function(ClientFavoriteVideoItem) video,
  });
}

final class _FavProEntry extends _FavoriteGridEntry {
  _FavProEntry(this.item)
      : super._(item.proId, 'pro_${item.proId}');

  final ClientFavoriteProItem item;

  @override
  T when<T>({
    required T Function(ClientFavoriteProItem) pro,
    required T Function(ClientFavoriteVideoItem) video,
  }) =>
      pro(item);
}

final class _FavVideoEntry extends _FavoriteGridEntry {
  _FavVideoEntry(this.item)
      : super._(item.videoId, 'vid_${item.videoId}');

  final ClientFavoriteVideoItem item;

  @override
  T when<T>({
    required T Function(ClientFavoriteProItem) pro,
    required T Function(ClientFavoriteVideoItem) video,
  }) =>
      video(item);
}

class _ProFavoriteCell extends ConsumerWidget {
  const _ProFavoriteCell({required this.item});

  final ClientFavoriteProItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: SpotbookColors.surfaceVariant,
              backgroundImage: item.avatarUrl != null
                  ? CachedNetworkImageProvider(item.avatarUrl!)
                  : null,
              child: item.avatarUrl == null
                  ? const Icon(Icons.person, color: SpotbookColors.textSecondary)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SpotbookColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          '${item.rating.toStringAsFixed(1)} ★ (${item.reviewCount})',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SpotbookColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        SpotbookButton.primary(
          label: l10n.clientProfileBookNow,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push('/client/provider/${item.proId}');
          },
        ),
      ],
    );
  }
}

class _VideoFavoriteCell extends StatelessWidget {
  const _VideoFavoriteCell({required this.item});

  final ClientFavoriteVideoItem item;

  String? _durationLabel() {
    final s = item.durationSeconds;
    if (s == null) return null;
    final total = s.round();
    final m = total ~/ 60;
    final sec = total % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dur = _durationLabel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: SpotbookColors.surfaceVariant,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/client/video/${item.videoId}');
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.thumbnailUrl != null)
                      CachedNetworkImage(
                        imageUrl: item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: SpotbookColors.surface,
                          highlightColor: SpotbookColors.surfaceVariant,
                          child: Container(color: SpotbookColors.surface),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.play_circle_outline,
                          color: SpotbookColors.textSecondary,
                          size: 40,
                        ),
                      )
                    else
                      const Icon(
                        Icons.play_circle_outline,
                        color: SpotbookColors.textSecondary,
                        size: 40,
                      ),
                    if (dur != null)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dur,
                            style: const TextStyle(
                              color: SpotbookColors.textPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SpotbookColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.data});

  final ClientProfileScreenData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!data.isOwnProfile) {
      return _PrivateTabHint(message: l10n.clientProfilePrivateTabs);
    }

    if (data.completedBookings.isEmpty) {
      return Center(
        child: Text(
          l10n.clientProfileNoHistory,
          style: const TextStyle(color: SpotbookColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: data.completedBookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = data.completedBookings[i];
        return SpotbookCard(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/client/bookings/${b.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.serviceName ?? '—',
                style: const TextStyle(
                  color: SpotbookColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                b.proName ?? '—',
                style: const TextStyle(
                  color: SpotbookColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${b.slotDate ?? ''} · ${b.slotStartTime ?? ''}',
                style: const TextStyle(
                  color: SpotbookColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({required this.data});

  final ClientProfileScreenData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!data.isOwnProfile) {
      return _PrivateTabHint(message: l10n.clientProfilePrivateTabs);
    }

    if (data.tickets.isEmpty) {
      return Center(
        child: Text(
          l10n.clientProfileNoTickets,
          style: const TextStyle(color: SpotbookColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: data.tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = data.tickets[i];
        final used = t.status == 'used';
        final statusLabel =
            used ? l10n.clientProfileTicketUsed : l10n.clientProfileTicketValid;
        return SpotbookCard(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/ticket-detail', extra: t);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: t.eventCoverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: t.eventCoverUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: SpotbookColors.surface,
                          highlightColor: SpotbookColors.surfaceVariant,
                          child: Container(
                              width: 64, height: 64, color: SpotbookColors.surface),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: SpotbookColors.surfaceVariant,
                          child: const Icon(Icons.event,
                              color: SpotbookColors.textSecondary),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: SpotbookColors.surfaceVariant,
                        child: const Icon(Icons.event,
                            color: SpotbookColors.textSecondary),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.eventTitle ?? '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SpotbookColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (t.eventDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'd MMM yyyy · HH:mm',
                          Localizations.localeOf(context).toString(),
                        ).format(t.eventDate!.toLocal()),
                        style: const TextStyle(
                          color: SpotbookColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${t.ticketTypeName ?? '—'} · $statusLabel',
                      style: const TextStyle(
                        color: SpotbookColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrivateTabHint extends StatelessWidget {
  const _PrivateTabHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SpotbookColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ClientProfileShimmer extends StatelessWidget {
  const _ClientProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SpotbookColors.surface,
      highlightColor: SpotbookColors.surfaceVariant,
      child: ListView(
        children: [
          Container(height: 200, color: SpotbookColors.surface),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 22,
                  width: 200,
                  decoration: BoxDecoration(
                    color: SpotbookColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: SpotbookColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: SpotbookColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
