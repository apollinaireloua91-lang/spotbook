import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/services/cloudflare_stream_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../auth/data/category_repository.dart';
import 'cubit/video_upload_cubit.dart';

/// Preview screen shown after recording or picking a video.
///
/// Shows the video with audio controls, metadata form, and a publish button
/// that triggers the full Cloudflare Stream upload pipeline.
class VideoPreviewScreen extends ConsumerStatefulWidget {
  const VideoPreviewScreen({super.key, required this.videoFile});

  final File videoFile;

  @override
  ConsumerState<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends ConsumerState<VideoPreviewScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();

  String? _selectedCategory;
  String? _linkedServiceId;
  String? _linkedEventId;
  String? _spotifyTitle;
  String? _spotifyArtist;

  double? _videoDuration;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _events = [];
  final List<String> _hashtags = [];

  late final VideoUploadCubit _cubit;
  late final VideoPlayerController _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _cubit = VideoUploadCubit(
      cfService: CloudflareStreamService(Supabase.instance.client),
    );
    _cubit.setStep(UploadStep.previewing);
    _initVideoPreview();
    _loadVideoDuration();
    _loadProData();
  }

  Future<void> _initVideoPreview() async {
    _videoCtrl = VideoPlayerController.file(widget.videoFile);
    await _videoCtrl.initialize();
    _videoCtrl.setLooping(true);
    await _videoCtrl.play();
    if (mounted) setState(() => _videoReady = true);
  }

  Future<void> _loadVideoDuration() async {
    final info = await VideoCompress.getMediaInfo(widget.videoFile.path);
    if (mounted) {
      setState(() {
        _videoDuration = (info.duration ?? 0) / 1000;
      });
    }
  }

  Future<void> _loadProData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final servicesFuture = supabase
        .from('services')
        .select('id, title, price')
        .eq('pro_id', userId)
        .eq('is_active', true);
    final eventsFuture = supabase
        .from('events')
        .select('id, title, event_date')
        .eq('pro_id', userId)
        .eq('is_active', true);
    final profileFuture = supabase
        .from('profiles_pro')
        .select('category')
        .eq('id', userId)
        .maybeSingle();

    final results = await Future.wait<dynamic>(
      [servicesFuture, eventsFuture, profileFuture],
    );

    if (!mounted) return;
    setState(() {
      _services = List<Map<String, dynamic>>.from(results[0] as List);
      _events = List<Map<String, dynamic>>.from(results[1] as List);
      final profile = results[2] as Map<String, dynamic>?;
      if (profile != null && _selectedCategory == null) {
        _selectedCategory = profile['category'] as String?;
      }
    });
  }

  bool get _isValid =>
      _titleCtrl.text.trim().length >= 5 &&
      _selectedCategory != null &&
      _descCtrl.text.trim().length >= 20;

  void _addHashtag(String raw) {
    final tag = raw.trim().replaceAll('#', '');
    if (tag.isEmpty || _hashtags.length >= 5 || _hashtags.contains(tag)) return;
    setState(() {
      _hashtags.add(tag);
      _hashtagCtrl.clear();
    });
  }

  void _removeHashtag(String tag) {
    setState(() => _hashtags.remove(tag));
  }

  Future<void> _publish() async {
    if (!_isValid) return;

    await _cubit.publishVideo(
      videoFile: widget.videoFile,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _selectedCategory!,
      duration: _videoDuration,
      hashtags: _hashtags,
      serviceId: _linkedServiceId,
      eventId: _linkedEventId,
      spotifyTrackTitle: _spotifyTitle,
      spotifyTrackArtist: _spotifyArtist,
    );
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hashtagCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<VideoUploadCubit, VideoUploadState>(
        listener: (context, state) {
          if (state.step == UploadStep.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Vidéo publiée !'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/pro/feed');
          } else if (state.step == UploadStep.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Erreur inconnue'),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Réessayer',
                  textColor: AppColors.textOnPrimary,
                  onPressed: _publish,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isWorking = state.isWorking;

          return Scaffold(
            backgroundColor: AppColors.fond,
            appBar: AppBar(
              backgroundColor: AppColors.fond,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: Semantics(
                label: 'Retour',
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
                  ),
                  onPressed: isWorking ? null : () => context.pop(),
                ),
              ),
              title: Text(
                'Nouvelle publication',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // ── Video preview ──
                          _VideoPreviewCard(
                            videoCtrl: _videoCtrl,
                            videoReady: _videoReady,
                            videoDuration: _videoDuration,
                            onTap: () {
                              if (_videoCtrl.value.isPlaying) {
                                _videoCtrl.pause();
                              } else {
                                _videoCtrl.play();
                              }
                              setState(() {});
                            },
                            isPlaying: _videoReady && _videoCtrl.value.isPlaying,
                          ),

                          const SizedBox(height: 24),

                          // ── Section label ──
                          _SectionLabel(text: 'DÉTAILS'),
                          const SizedBox(height: 12),

                          // ── Title ──
                          _StyledTextField(
                            controller: _titleCtrl,
                            label: 'Titre *',
                            hint: 'Ex. : Coupe femme + brushing',
                            maxLength: 80,
                            prefixIcon: Icons.title_rounded,
                          ),
                          const SizedBox(height: 14),

                          // ── Category ──
                          Builder(builder: (context) {
                            final catItems = ref.watch(proCategoriesProvider).when(
                              data: (cats) => cats
                                  .map((c) => DropdownMenuItem(value: c.label, child: Text(c.label)))
                                  .toList(),
                              loading: () => const <DropdownMenuItem<String>>[],
                              error: (_, __) => const <DropdownMenuItem<String>>[],
                            );
                            final validCat = catItems.any((i) => i.value == _selectedCategory)
                                ? _selectedCategory
                                : null;
                            return DropdownButtonFormField<String>(
                              initialValue: validCat,
                              hint: Text(
                                'Catégorie *',
                                style: TextStyle(color: AppColors.grisInactif),
                              ),
                              dropdownColor: AppColors.surfaceElevated,
                              style: TextStyle(color: AppColors.blanc, fontSize: 14),
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gris),
                              decoration: _fieldDecoration(prefixIcon: Icons.category_rounded),
                              items: catItems,
                              onChanged: isWorking ? null : (v) => setState(() => _selectedCategory = v),
                            );
                          }),
                          const SizedBox(height: 14),

                          // ── Description ──
                          _StyledTextField(
                            controller: _descCtrl,
                            label: 'Description *',
                            hint: 'Décrivez votre service en détail...',
                            maxLength: 500,
                            maxLines: 4,
                            prefixIcon: Icons.description_rounded,
                          ),
                          const SizedBox(height: 14),

                          // ── Hashtags ──
                          _StyledTextField(
                            controller: _hashtagCtrl,
                            label: 'Hashtags (max 5)',
                            hint: 'Tapez un hashtag et appuyez sur Entrée',
                            prefixIcon: Icons.tag_rounded,
                            onSubmitted: _addHashtag,
                          ),
                          if (_hashtags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _hashtags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientAccent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '#$tag',
                                        style: GoogleFonts.dmSans(
                                          color: AppColors.textOnPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (!isWorking) ...[
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _removeHashtag(tag),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: AppColors.textOnPrimary.withAlpha(180),
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // ── Link sections ──
                          if (_services.isNotEmpty || _events.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _SectionLabel(text: 'LIER À'),
                            const SizedBox(height: 12),
                          ],

                          if (_services.isNotEmpty) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _linkedServiceId,
                              hint: Text(
                                'Lier à un service (optionnel)',
                                style: TextStyle(color: AppColors.grisInactif, fontSize: 14),
                              ),
                              dropdownColor: AppColors.surfaceElevated,
                              style: TextStyle(color: AppColors.blanc, fontSize: 14),
                              decoration: _fieldDecoration(prefixIcon: Icons.work_outline_rounded),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Aucun', style: TextStyle(color: AppColors.gris)),
                                ),
                                ..._services.map(
                                  (s) => DropdownMenuItem(
                                    value: s['id'] as String,
                                    child: Text(
                                      '${s['title']} · ${(s['price'] as num).toStringAsFixed(0)} \$',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: isWorking
                                  ? null
                                  : (v) => setState(() => _linkedServiceId = v),
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (_events.isNotEmpty) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _linkedEventId,
                              hint: Text(
                                'Lier à un événement (optionnel)',
                                style: TextStyle(color: AppColors.grisInactif, fontSize: 14),
                              ),
                              dropdownColor: AppColors.surfaceElevated,
                              style: TextStyle(color: AppColors.blanc, fontSize: 14),
                              decoration: _fieldDecoration(prefixIcon: Icons.event_rounded),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Aucun', style: TextStyle(color: AppColors.gris)),
                                ),
                                ..._events.map(
                                  (e) => DropdownMenuItem(
                                    value: e['id'] as String,
                                    child: Text(e['title'] as String),
                                  ),
                                ),
                              ],
                              onChanged: isWorking
                                  ? null
                                  : (v) => setState(() => _linkedEventId = v),
                            ),
                            const SizedBox(height: 14),
                          ],

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom publish area ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: AppColors.fond,
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Upload progress
                        if (isWorking) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: state.uploadProgress,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _progressLabel(state),
                            style: GoogleFonts.dmSans(
                              color: AppColors.gris,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Publish button
                        ListenableBuilder(
                          listenable: Listenable.merge([_titleCtrl, _descCtrl]),
                          builder: (context, _) {
                            final canPublish = _isValid && !isWorking;
                            return SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: canPublish ? AppColors.gradientAccent : null,
                                  color: canPublish ? null : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: canPublish ? AppColors.primaryButtonShadow : null,
                                ),
                                child: ElevatedButton(
                                  onPressed: canPublish ? _publish : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: AppColors.textOnPrimary,
                                    disabledBackgroundColor: Colors.transparent,
                                    disabledForegroundColor: AppColors.grisInactif,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: isWorking
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: AppColors.textOnPrimary,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.rocket_launch_rounded, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Publier',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _progressLabel(VideoUploadState state) {
    switch (state.step) {
      case UploadStep.compressing:
        return 'Compression...';
      case UploadStep.uploading:
        return 'Téléversement... ${(state.uploadProgress * 100).toInt()}%';
      case UploadStep.processing:
        return 'Traitement sur Cloudflare...';
      default:
        return '';
    }
  }

  InputDecoration _fieldDecoration({IconData? prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(prefixIcon, color: AppColors.gris, size: 20),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.violet, width: 1.5),
      ),
    );
  }
}

// ─── Video preview card with rounded corners and overlay ─────────────────────

class _VideoPreviewCard extends StatelessWidget {
  const _VideoPreviewCard({
    required this.videoCtrl,
    required this.videoReady,
    required this.videoDuration,
    required this.onTap,
    required this.isPlaying,
  });

  final VideoPlayerController videoCtrl;
  final bool videoReady;
  final double? videoDuration;
  final VoidCallback onTap;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 9 / 14,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video
              if (videoReady)
                GestureDetector(
                  onTap: onTap,
                  child: VideoPlayer(videoCtrl),
                )
              else
                Container(
                  color: AppColors.surface,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.violet,
                      strokeWidth: 2,
                    ),
                  ),
                ),

              // Play/Pause overlay
              if (videoReady && !isPlaying)
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.overlayMedium,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(40),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),

              // Duration badge
              if (videoDuration != null)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.overlayHeavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${videoDuration!.toStringAsFixed(1)}s',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 12,
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
}

// ─── Section label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        color: AppColors.gris,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }
}

// ─── Styled text field ───────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.prefixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final IconData? prefixIcon;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
        hintStyle: GoogleFonts.dmSans(color: AppColors.grisInactif, fontSize: 13),
        counterStyle: TextStyle(color: AppColors.gris, fontSize: 11),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(prefixIcon, color: AppColors.gris, size: 20),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.violet, width: 1.5),
        ),
      ),
    );
  }
}
