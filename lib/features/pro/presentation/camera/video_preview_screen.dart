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

    // Load pro services, events, and profile in parallel
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
      // Default category from pro profile
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
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<VideoUploadCubit, VideoUploadState>(
        listener: (context, state) {
          if (state.step == UploadStep.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video published!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Pop back to camera tab, then to feed
            context.go('/pro/feed');
          } else if (state.step == UploadStep.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Unknown error'),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: AppColors.blanc,
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
                  onPressed: isWorking ? null : () => context.pop(),
                ),
              ),
              title: Text(
                'Preview',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // ── Video preview ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: _videoReady
                            ? GestureDetector(
                                onTap: () {
                                  if (_videoCtrl.value.isPlaying) {
                                    _videoCtrl.pause();
                                  } else {
                                    _videoCtrl.play();
                                  }
                                  setState(() {});
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(_videoCtrl),
                                    if (!_videoCtrl.value.isPlaying)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.overlayMedium,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: AppColors.blanc,
                                          size: 32,
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.blanc,
                                  strokeWidth: 2,
                                ),
                              ),
                      ),
                    ),

                    if (_videoDuration != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Duration: ${_videoDuration!.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: AppColors.gris,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Title ──
                    _buildTextField(
                      controller: _titleCtrl,
                      label: 'Title *',
                      hint: 'E.g.: Women\'s cut + blowout',
                      maxLength: 80,
                    ),
                    const SizedBox(height: 16),

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
                        hint: const Text(
                          'Category *',
                          style: TextStyle(color: AppColors.gris),
                        ),
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.blanc),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.gris,
                        ),
                        decoration: _fieldDecoration(),
                        items: catItems,
                        onChanged:
                            isWorking ? null : (v) => setState(() => _selectedCategory = v),
                      );
                    }),
                    const SizedBox(height: 16),

                    // ── Description ──
                    _buildTextField(
                      controller: _descCtrl,
                      label: 'Description *',
                      hint: 'Describe your service in detail...',
                      maxLength: 500,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // ── Hashtags ──
                    _buildTextField(
                      controller: _hashtagCtrl,
                      label: 'Hashtags (max 5)',
                      hint: 'Type a hashtag and press Enter',
                      onSubmitted: _addHashtag,
                    ),
                    if (_hashtags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _hashtags.map((tag) {
                          return Chip(
                            label: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.blanc,
                                fontSize: 13,
                              ),
                            ),
                            backgroundColor: AppColors.surface,
                            deleteIconColor: AppColors.gris,
                            side: const BorderSide(color: AppColors.border),
                            onDeleted:
                                isWorking ? null : () => _removeHashtag(tag),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Link to service ──
                    if (_services.isNotEmpty) ...[
                      Text(
                        'Link to a service',
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _linkedServiceId,
                        hint: const Text(
                          'None (optional)',
                          style: TextStyle(color: AppColors.gris, fontSize: 14),
                        ),
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 14,
                        ),
                        decoration: _fieldDecoration(),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
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
                      const SizedBox(height: 16),
                    ],

                    // ── Link to event ──
                    if (_events.isNotEmpty) ...[
                      Text(
                        'Link to an event',
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _linkedEventId,
                        hint: const Text(
                          'None (optional)',
                          style: TextStyle(color: AppColors.gris, fontSize: 14),
                        ),
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 14,
                        ),
                        decoration: _fieldDecoration(),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
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
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),

                    // ── Upload progress ──
                    if (isWorking) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.uploadProgress,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.violet,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _progressLabel(state),
                          style: const TextStyle(
                            color: AppColors.gris,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Publish button ──
                    ListenableBuilder(
                      listenable: Listenable.merge([_titleCtrl, _descCtrl]),
                      builder: (context, _) {
                        final canPublish = _isValid && !isWorking;
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: canPublish
                                  ? AppColors.gradientAccent
                                  : null,
                              color: canPublish ? null : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: canPublish ? _publish : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: AppColors.blanc,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: AppColors.gris,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isWorking
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: AppColors.blanc,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Publish',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
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
        return 'Compressing...';
      case UploadStep.uploading:
        return 'Uploading... ${(state.uploadProgress * 100).toInt()}%';
      case UploadStep.processing:
        return 'Processing on Cloudflare...';
      default:
        return '';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
    int maxLines = 1,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.blanc),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.gris),
        hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)),
        counterStyle: const TextStyle(color: AppColors.gris),
        filled: true,
        fillColor: AppColors.surface,
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
          borderSide: const BorderSide(color: AppColors.blanc),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
