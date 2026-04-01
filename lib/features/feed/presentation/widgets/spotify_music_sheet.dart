import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/spotify_link_notifier.dart';
import '../../data/spotify_notifier.dart';
import '../../domain/spotify_track.dart';

/// Feuille musique Spotify (top tracks si compte lié + recherche).
void showSpotifyMusicSheet({
  required BuildContext context,
  ValueChanged<SpotifyTrack>? onTrackSelected,
}) {
  final height = MediaQuery.sizeOf(context).height * 0.8;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SizedBox(
      height: height,
      child: _SpotifySheetChrome(
        child: _SpotifyMusicSheetBody(onTrackSelected: onTrackSelected),
      ),
    ),
  );
}

class _SpotifySheetChrome extends StatelessWidget {
  const _SpotifySheetChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 4, 0),
            child: Row(
              children: [
                const Icon(Icons.music_note,
                    color: AppColors.spotifyGreen, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.spotifySheetTitle,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, color: AppColors.gris),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SpotifyMusicSheetBody extends ConsumerStatefulWidget {
  const _SpotifyMusicSheetBody({this.onTrackSelected});

  final ValueChanged<SpotifyTrack>? onTrackSelected;

  @override
  ConsumerState<_SpotifyMusicSheetBody> createState() =>
      _SpotifyMusicSheetBodyState();
}

class _SpotifyMusicSheetBodyState extends ConsumerState<_SpotifyMusicSheetBody> {
  final _controller = TextEditingController();

  /// Player créé de façon lazy (seulement quand l'user tape play)
  /// pour ne pas toucher à l'AVAudioSession au simple ouverture du sheet.
  AudioPlayer? _player;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spotifyLinkProvider.notifier).refresh();
      ref.read(spotifySearchProvider.notifier).prepareSheet();
    });
  }

  @override
  void dispose() {
    _player?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(SpotifyTrack track) async {
    if (_playingId == track.id) {
      await _player?.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    final url = track.previewUrl;
    if (url == null || url.isEmpty) return;

    // Initialisation lazy : on crée le player uniquement au premier tap play.
    if (_player == null) {
      _player = AudioPlayer();
      // mixWithOthers : le preview Spotify ne coupe pas le son des vidéos.
      await _player!.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
      _player!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      });
    }

    await _player!.stop();
    await _player!.play(UrlSource(url));
    if (mounted) setState(() => _playingId = track.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(spotifySearchProvider);
    final linkAsync = ref.watch(spotifyLinkProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final linked = switch (linkAsync) {
      AsyncData(:final value) => value.linked,
      _ => false,
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.spotifyGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sheetSeparator),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: linked ? AppColors.spotifyGreen : AppColors.gris,
                  size: 10,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    linked
                        ? l10n.spotifySheetLinkedHint
                        : l10n.spotifySheetNotLinkedHint,
                    style: const TextStyle(
                      color: AppColors.grisClair,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (!linked)
                  TextButton(
                    onPressed: () {
                      context.pop();
                      context.push('/pro/profile/settings');
                    },
                    child: Text(l10n.spotifySheetOpenSettings),
                  ),
              ],
            ),
          ),
          TextField(
            controller: _controller,
            onChanged: (v) {
              setState(() {});
              ref.read(spotifySearchProvider.notifier).search(v);
            },
            style: const TextStyle(color: AppColors.blanc, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.spotifySheetSearchHint,
              hintStyle:
                  const TextStyle(color: AppColors.gris, fontSize: 14),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.gris, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        ref.read(spotifySearchProvider.notifier).search('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close,
                          color: AppColors.gris, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.fond,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.spotifyGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (state.showingTopTracks && state.tracks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.spotifySheetTopTracksHeader,
                style: const TextStyle(
                  color: AppColors.gris,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (state.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.spotifyGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (state.tracks.isEmpty && state.query.trim().length >= 2)
            Expanded(
              child: Center(
                child: Text(
                  l10n.spotifySheetNoResults,
                  style: const TextStyle(color: AppColors.gris, fontSize: 14),
                ),
              ),
            )
          else if (state.tracks.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  linked
                      ? l10n.spotifySheetEmptyTop
                      : l10n.spotifySheetEmptyNeedLink,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gris, fontSize: 12),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: state.tracks.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: AppColors.sheetSeparator,
                ),
                itemBuilder: (context, index) {
                  final track = state.tracks[index];
                  final selected = state.selectedTrack?.id == track.id;
                  final playing = _playingId == track.id;
                  return _TrackTile(
                    track: track,
                    isSelected: selected,
                    isPlaying: playing,
                    onPlayPreview: track.previewUrl != null
                        ? () => _togglePreview(track)
                        : null,
                    onTap: () {
                      ref
                          .read(spotifySearchProvider.notifier)
                          .selectTrack(track);
                      widget.onTrackSelected?.call(track);
                      final messenger = ScaffoldMessenger.of(context);
                      context.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceAlt,
                          content: Text(
                            l10n.spotifySheetTrackAdded(track.name),
                            style: const TextStyle(color: AppColors.blanc),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.onTap,
    this.isSelected = false,
    this.isPlaying = false,
    this.onPlayPreview,
  });

  final SpotifyTrack track;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback? onPlayPreview;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: track.albumArt != null
                      ? CachedNetworkImage(
                          imageUrl: track.albumArt!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _albumPlaceholder(),
                        )
                      : _albumPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      style: const TextStyle(
                        color: AppColors.gris,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onPlayPreview != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onPlayPreview,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      color: isPlaying
                          ? AppColors.spotifyGreen
                          : AppColors.gris,
                      size: 22,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.spotifyGreen
                        : AppColors.border,
                    width: 1.5,
                  ),
                  color: isSelected
                      ? AppColors.spotifyGreen.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        size: 14, color: AppColors.spotifyGreen)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _albumPlaceholder() => Container(
        color: AppColors.surface,
        child: const Icon(Icons.album, color: AppColors.gris, size: 22),
      );
}
