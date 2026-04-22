import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../booking/presentation/notifiers/pro_scheduling_notifiers.dart';
import '../../data/upload_video_notifier.dart';

const _allowedCategories = <String, String>{
  'coiffure': 'Hair',
  'beaute': 'Beauty',
  'fitness': 'Fitness',
  'photo': 'Photography',
  'musique': 'Music',
  'cuisine': 'Cooking',
  'massage': 'Massage',
  'tatouage': 'Tattoo',
  'maquillage': 'Makeup',
  'mode': 'Fashion',
  'danse': 'Dance',
  'art': 'Art',
  'coaching': 'Coaching',
  'autre_service': 'Other',
};

const _categoryIcons = <String, IconData>{
  'coiffure': Icons.content_cut,
  'beaute': Icons.spa_outlined,
  'fitness': Icons.fitness_center,
  'photo': Icons.camera_alt_outlined,
  'musique': Icons.music_note_outlined,
  'cuisine': Icons.restaurant_outlined,
  'massage': Icons.self_improvement,
  'tatouage': Icons.brush_outlined,
  'maquillage': Icons.face_retouching_natural,
  'mode': Icons.checkroom_outlined,
  'danse': Icons.directions_run,
  'art': Icons.palette_outlined,
  'coaching': Icons.psychology_outlined,
  'autre_service': Icons.miscellaneous_services,
};

// ── Validation constants ──
const int _minTitleLength = 5;
const int _maxTitleLength = 80;
const int _minDescLength = 20;
const int _maxDescLength = 300;
const int _maxHashtags = 5;

// ── Hashtag suggestions per category ──
const _hashtagSuggestions = <String, List<String>>{
  'coiffure': ['haircut', 'fade', 'style', 'hair', 'salon', 'blowout'],
  'beaute': ['beauty', 'skincare', 'facial', 'glow', 'treatment', 'spa'],
  'fitness': ['fitness', 'coaching', 'workout', 'training', 'health', 'gym'],
  'photo': ['photography', 'portrait', 'photoshoot', 'creative', 'studio'],
  'musique': ['dj', 'music', 'mix', 'party', 'beats', 'nightlife'],
  'cuisine': ['food', 'catering', 'chef', 'cuisine', 'gourmet', 'event'],
  'massage': ['massage', 'relaxation', 'wellness', 'therapy', 'bodywork'],
  'tatouage': ['tattoo', 'ink', 'tattooart', 'bodyart', 'design'],
  'maquillage': ['makeup', 'beauty', 'glam', 'mua', 'bridal', 'look'],
  'mode': ['fashion', 'style', 'ootd', 'design', 'trend', 'outfit'],
  'danse': ['dance', 'choreo', 'performance', 'movement', 'rhythm'],
  'art': ['art', 'creative', 'design', 'visual', 'painting', 'sketch'],
  'coaching': ['coaching', 'motivation', 'growth', 'mentor', 'success'],
};

/// Pre-publish review screen: description, tags, link service, visibility, publish.
class ProviderVideoPublishScreen extends ConsumerStatefulWidget {
  const ProviderVideoPublishScreen({super.key, this.editData});

  /// Optional data from the edit screen (videoPath, trimStartMs, etc.).
  final Map<String, dynamic>? editData;

  @override
  ConsumerState<ProviderVideoPublishScreen> createState() =>
      _ProviderVideoPublishScreenState();
}

class _ProviderVideoPublishScreenState
    extends ConsumerState<ProviderVideoPublishScreen>
    with TickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hashtagInputCtrl = TextEditingController();
  final List<String> _hashtags = [];
  String? _linkedServiceId;
  bool _allowComments = true;
  String _visibility = 'public';

  late final AnimationController _staggerCtrl;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _titleCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
    _hashtagInputCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hashtagInputCtrl.dispose();
    _staggerCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Validation helpers ──
  bool get _isTitleValid => _titleCtrl.text.trim().length >= _minTitleLength;
  bool get _isDescValid => _descCtrl.text.trim().length >= _minDescLength;
  int get _titleCharCount => _titleCtrl.text.trim().length;
  int get _descCharCount => _descCtrl.text.trim().length;

  bool _isValid(UploadVideoState s) =>
      s.videoFile != null &&
      _isTitleValid &&
      s.selectedCategory != null &&
      _isDescValid;

  List<String> _missingRequirements(UploadVideoState s) {
    final out = <String>[];
    if (s.videoFile == null) out.add('select a video');
    if (!_isTitleValid) out.add('title: at least $_minTitleLength characters');
    if (s.selectedCategory == null) out.add('choose a category');
    if (!_isDescValid) out.add('description: at least $_minDescLength characters');
    return out;
  }

  // ── Hashtag helpers ──
  void _addHashtag(String tag) {
    final cleaned = tag.trim().replaceAll('#', '').replaceAll(' ', '').toLowerCase();
    if (cleaned.isEmpty || _hashtags.length >= _maxHashtags || _hashtags.contains(cleaned)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _hashtags.add(cleaned);
      _hashtagInputCtrl.clear();
    });
  }

  void _removeHashtag(int index) {
    HapticFeedback.lightImpact();
    setState(() => _hashtags.removeAt(index));
  }

  List<String> _getSuggestions(String? category) {
    return _hashtagSuggestions[category] ??
        ['spotbook', 'montreal', 'professional', 'talent', 'trending'];
  }

  // ── Publish logic ──
  Future<void> _tryPublish(UploadVideoState s) async {
    if (s.isUploading) return;
    if (!_isValid(s)) {
      HapticFeedback.lightImpact();
      final missing = _missingRequirements(s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'To publish: ${missing.join(' · ')}',
            style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 13, height: 1.35),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    await _publish();
  }

  Future<void> _publish() async {
    try {
      await ref.read(uploadVideoProvider.notifier).publish(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            hashtags: _hashtags.join(','),
            linkedServiceId: _linkedServiceId,
          );
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.videoPublished,
              style: GoogleFonts.dmSans(color: AppColors.textOnPrimary)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/pro');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.dmSans(color: AppColors.textOnPrimary)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final s = ref.watch(uploadVideoProvider);
    final n = ref.read(uploadVideoProvider.notifier);
    final svcState = ref.watch(proServicesNotifierProvider);

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
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          'Publish',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedOpacity(
              opacity: _isValid(s) ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _isValid(s) && !s.isUploading ? () => _tryPublish(s) : null,
                child: Text(
                  'Publish',
                  style: GoogleFonts.sora(
                    color: AppColors.violet,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
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

                    // ── Video Preview Card ──
                    _StaggeredEntry(
                      index: 0,
                      controller: _staggerCtrl,
                      child: _VideoPreviewCard(
                        videoFile: s.videoFile,
                        duration: s.videoDuration,
                        onPickVideo: () async {
                          final ok = await ref.read(uploadVideoProvider.notifier).pickVideo();
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Invalid format or duration (mp4/mov/m4v, max 60s)',
                                  style: GoogleFonts.dmSans(color: AppColors.textOnPrimary),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Content Details ──
                    _StaggeredEntry(
                      index: 1,
                      controller: _staggerCtrl,
                      child: const _SectionHeader(icon: Icons.edit_note_rounded, title: 'CONTENT'),
                    ),
                    const SizedBox(height: 12),

                    // ── Title with validation ──
                    _StaggeredEntry(
                      index: 2,
                      controller: _staggerCtrl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PremiumTextField(
                            controller: _titleCtrl,
                            label: 'Title',
                            hint: 'Ex: Women\'s cut + blowout',
                            maxLength: _maxTitleLength,
                            prefixIcon: Icons.title_rounded,
                          ),
                          if (_titleCtrl.text.isNotEmpty && !_isTitleValid)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, size: 13, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Min $_minTitleLength chars ($_titleCharCount/$_minTitleLength)',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_isTitleValid)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, size: 13, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Looks good!',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Description with validation + progress ──
                    _StaggeredEntry(
                      index: 3,
                      controller: _staggerCtrl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PremiumTextField(
                            controller: _descCtrl,
                            label: 'Description',
                            hint: 'Describe your service in detail...',
                            maxLength: _maxDescLength,
                            maxLines: 3,
                            prefixIcon: Icons.notes_rounded,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_descCtrl.text.isNotEmpty && !_isDescValid)
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber, size: 13, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Min $_minDescLength chars ($_descCharCount/$_minDescLength)',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              else if (_isDescValid)
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 13, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Looks good!',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox(),
                            ],
                          ),
                          // Progress bar toward min chars
                          if (_descCtrl.text.isNotEmpty && !_isDescValid)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (_descCharCount / _minDescLength).clamp(0.0, 1.0),
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _descCharCount / _minDescLength > 0.7
                                        ? AppColors.warning
                                        : AppColors.error,
                                  ),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Hashtags ──
                    _StaggeredEntry(
                      index: 4,
                      controller: _staggerCtrl,
                      child: const _SectionHeader(icon: Icons.tag_rounded, title: 'HASHTAGS'),
                    ),
                    const SizedBox(height: 12),

                    _StaggeredEntry(
                      index: 5,
                      controller: _staggerCtrl,
                      child: _buildHashtagSection(s.selectedCategory),
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Category ──
                    _StaggeredEntry(
                      index: 6,
                      controller: _staggerCtrl,
                      child: const _SectionHeader(icon: Icons.category_outlined, title: 'CATEGORY'),
                    ),
                    const SizedBox(height: 12),

                    _StaggeredEntry(
                      index: 7,
                      controller: _staggerCtrl,
                      child: _CategoryChipsGrid(
                        selectedCategory: s.selectedCategory,
                        onSelected: (cat) => n.setCategory(cat),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Link Service (optional) ──
                    if (!svcState.loading && svcState.services.isNotEmpty) ...[
                      _StaggeredEntry(
                        index: 8,
                        controller: _staggerCtrl,
                        child: const _SectionHeader(icon: Icons.link_rounded, title: 'LINK A SERVICE'),
                      ),
                      const SizedBox(height: 12),
                      _StaggeredEntry(
                        index: 9,
                        controller: _staggerCtrl,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: DropdownButtonFormField<String?>(
                            key: ValueKey('linked_svc_${_linkedServiceId ?? 'none'}'),
                            initialValue: _linkedServiceId,
                            hint: Text('None — general post',
                                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14)),
                            dropdownColor: AppColors.surface,
                            style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gris),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.build_circle_outlined,
                                  color: AppColors.gris.withAlpha(180), size: 20),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None — general post',
                                    style: GoogleFonts.dmSans(color: AppColors.gris)),
                              ),
                              ...svcState.services.map(
                                (sv) => DropdownMenuItem<String?>(
                                  value: sv.id,
                                  child: Text(sv.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans()),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _linkedServiceId = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Section: Settings ──
                    _StaggeredEntry(
                      index: 10,
                      controller: _staggerCtrl,
                      child: const _SectionHeader(icon: Icons.tune_rounded, title: 'SETTINGS'),
                    ),
                    const SizedBox(height: 12),

                    _StaggeredEntry(
                      index: 11,
                      controller: _staggerCtrl,
                      child: Column(
                        children: [
                          _PremiumToggleRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Allow comments',
                            subtitle: 'Let viewers comment on your post',
                            value: _allowComments,
                            onChanged: (v) => setState(() => _allowComments = v),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.visibility_outlined,
                                        color: AppColors.gris.withAlpha(180), size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Visibility',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.blanc,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _VisibilityOption(
                                        icon: Icons.public_rounded,
                                        label: 'Public',
                                        subtitle: 'Everyone',
                                        selected: _visibility == 'public',
                                        onTap: () => setState(() => _visibility = 'public'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _VisibilityOption(
                                        icon: Icons.people_outline_rounded,
                                        label: 'Followers',
                                        subtitle: 'Your followers',
                                        selected: _visibility == 'followers',
                                        onTap: () => setState(() => _visibility = 'followers'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Upload Progress ──
                    if (s.isUploading) ...[
                      _UploadProgressCard(progress: s.uploadProgress),
                      const SizedBox(height: 16),
                    ],

                    // ── Validation Checklist ──
                    if (!s.isUploading)
                      _StaggeredEntry(
                        index: 12,
                        controller: _staggerCtrl,
                        child: _ValidationChecklist(
                          hasVideo: s.videoFile != null,
                          isTitleValid: _isTitleValid,
                          isDescValid: _isDescValid,
                          hasCategory: s.selectedCategory != null,
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Publish Button ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.fond,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowCard,
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: s.isUploading ? null : () => _tryPublish(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _isValid(s) && !s.isUploading ? AppColors.gradientAccent : null,
                    color: _isValid(s) || s.isUploading
                        ? null
                        : AppColors.grisInactif.withAlpha(60),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isValid(s) && !s.isUploading
                        ? [
                            BoxShadow(
                              color: AppColors.violet.withAlpha(60),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: s.isUploading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Uploading...',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                color: _isValid(s) ? AppColors.textOnPrimary : AppColors.gris,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Publish',
                                style: GoogleFonts.sora(
                                  color: _isValid(s) ? AppColors.textOnPrimary : AppColors.gris,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hashtag section builder ──
  Widget _buildHashtagSection(String? category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hashtag input field
        TextField(
          controller: _hashtagInputCtrl,
          enabled: _hashtags.length < _maxHashtags,
          style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
          decoration: InputDecoration(
            labelText: _hashtags.length >= _maxHashtags
                ? 'Maximum reached'
                : 'Add a hashtag',
            hintText: 'e.g. barber, fade, style...',
            labelStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
            hintStyle: GoogleFonts.dmSans(color: AppColors.gris.withAlpha(128), fontSize: 13),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(Icons.tag_rounded, color: AppColors.gris.withAlpha(180), size: 18),
            suffixText: '${_hashtags.length}/$_maxHashtags',
            suffixStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
            suffixIcon: _hashtagInputCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.add_circle, color: AppColors.violet),
                    onPressed: () => _addHashtag(_hashtagInputCtrl.text),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.violet, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border.withAlpha(60), width: 0.5),
            ),
          ),
          onSubmitted: _addHashtag,
        ),
        const SizedBox(height: 10),

        // Hashtag chips
        if (_hashtags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hashtags.asMap().entries.map((entry) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + entry.key * 50),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.violet.withAlpha(77)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${entry.value}',
                        style: GoogleFonts.dmSans(
                          color: AppColors.violet,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeHashtag(entry.key),
                        child: Icon(Icons.close, size: 14, color: AppColors.violet),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        // Suggested hashtags
        if (_hashtags.length < _maxHashtags) ...[
          const SizedBox(height: 12),
          Text(
            'Suggested',
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _getSuggestions(category)
                .where((s) => !_hashtags.contains(s))
                .take(6)
                .map((suggestion) {
              return GestureDetector(
                onTap: () => _addHashtag(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '+ $suggestion',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STAGGERED ENTRY ANIMATION
// ═════════════════════════════════════════════════════════════════════════════

class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({
    required this.index,
    required this.controller,
    required this.child,
  });

  final int index;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 60).clamp(0, 800);
    final start = delay / 1200;
    final end = ((delay + 400) / 1200).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(
          ((controller.value - start) / (end - start)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VALIDATION CHECKLIST
// ═════════════════════════════════════════════════════════════════════════════

class _ValidationChecklist extends StatelessWidget {
  const _ValidationChecklist({
    required this.hasVideo,
    required this.isTitleValid,
    required this.isDescValid,
    required this.hasCategory,
  });

  final bool hasVideo;
  final bool isTitleValid;
  final bool isDescValid;
  final bool hasCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to publish?',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _CheckRow(label: 'Video selected', isValid: hasVideo),
          _CheckRow(label: 'Title (min $_minTitleLength chars)', isValid: isTitleValid),
          _CheckRow(label: 'Description (min $_minDescLength chars)', isValid: isDescValid),
          _CheckRow(label: 'Category selected', isValid: hasCategory),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.isValid});

  final String label;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isValid ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(isValid),
              size: 16,
              color: isValid ? AppColors.success : AppColors.grisInactif,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: isValid ? AppColors.blanc : AppColors.gris,
              fontSize: 13,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.w400,
              decoration: isValid ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VIDEO PREVIEW CARD
// ═════════════════════════════════════════════════════════════════════════════

class _VideoPreviewCard extends StatelessWidget {
  const _VideoPreviewCard({
    required this.videoFile,
    required this.duration,
    required this.onPickVideo,
  });

  final dynamic videoFile;
  final double? duration;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context) {
    final hasVideo = videoFile != null;
    return GestureDetector(
      onTap: onPickVideo,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          gradient: hasVideo ? AppColors.gradientAccent : null,
          color: hasVideo ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: hasVideo ? null : Border.all(color: AppColors.border, width: 1),
          boxShadow: hasVideo ? AppColors.primaryButtonShadow : AppColors.cardShadow,
        ),
        child: hasVideo
            ? Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.violet.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.videocam_rounded, color: AppColors.violet, size: 32),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Video ready',
                            style: GoogleFonts.sora(
                              color: AppColors.blanc,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to change',
                            style: GoogleFonts.dmSans(
                              color: AppColors.violet,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (duration != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.violet,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: AppColors.primaryButtonShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: AppColors.textOnPrimary, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '${duration!.toStringAsFixed(0)}s',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: AppColors.textOnPrimary, size: 14),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withAlpha(15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.violet.withAlpha(30), width: 1.5),
                    ),
                    child: Icon(Icons.video_call_rounded, color: AppColors.violet, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a video',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'mp4, mov, m4v · max 60s',
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppColors.primaryButtonShadow,
          ),
          child: Icon(icon, color: AppColors.textOnPrimary, size: 13),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM TEXT FIELD
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
        hintStyle: GoogleFonts.dmSans(color: AppColors.gris.withAlpha(128), fontSize: 13),
        counterStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.gris.withAlpha(180), size: 18)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.violet, width: 1.5),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CATEGORY CHIPS GRID
// ═════════════════════════════════════════════════════════════════════════════

class _CategoryChipsGrid extends StatelessWidget {
  const _CategoryChipsGrid({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allowedCategories.entries.map((e) {
        final isSelected = selectedCategory == e.key;
        final icon = _categoryIcons[e.key] ?? Icons.label_outline;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(isSelected ? null : e.key);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.violet : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.violet : AppColors.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14,
                    color: isSelected ? AppColors.textOnPrimary : AppColors.gris),
                const SizedBox(width: 6),
                Text(
                  e.value,
                  style: GoogleFonts.dmSans(
                    color: isSelected ? AppColors.textOnPrimary : AppColors.blanc,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM TOGGLE ROW
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumToggleRow extends StatelessWidget {
  const _PremiumToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gris.withAlpha(180), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeTrackColor: AppColors.violet,
            inactiveTrackColor: AppColors.border,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.textOnPrimary;
              return AppColors.gris;
            }),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VISIBILITY OPTION
// ═════════════════════════════════════════════════════════════════════════════

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.violet.withAlpha(12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.violet : AppColors.gris, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: selected ? AppColors.violet : AppColors.blanc,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text(subtitle,
                style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// UPLOAD PROGRESS CARD
// ═════════════════════════════════════════════════════════════════════════════

class _UploadProgressCard extends StatelessWidget {
  const _UploadProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.violet.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.violet.withAlpha(40), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.violet),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Uploading...',
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.sora(
                    color: AppColors.violet, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
