import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../booking/presentation/notifiers/pro_scheduling_notifiers.dart';
import '../../data/upload_video_notifier.dart';

const _allowedCategories = <String, String>{
  'coiffure': 'Coiffure',
  'beaute': 'Beaute',
  'fitness': 'Fitness',
  'photo': 'Photographie',
  'musique': 'Musique',
  'cuisine': 'Cuisine',
  'massage': 'Massage',
  'tatouage': 'Tatouage',
  'maquillage': 'Maquillage',
  'mode': 'Mode',
  'danse': 'Danse',
  'art': 'Art',
  'coaching': 'Coaching',
  'autre_service': 'Autre service',
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
    extends ConsumerState<ProviderVideoPublishScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();
  String? _linkedServiceId;
  bool _allowComments = true;
  String _visibility = 'public';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  bool _isValid(UploadVideoState s) =>
      s.videoFile != null &&
      _titleCtrl.text.trim().length >= 5 &&
      s.selectedCategory != null &&
      _descCtrl.text.trim().length >= 20;

  List<String> _missingRequirements(UploadVideoState s) {
    final out = <String>[];
    if (s.videoFile == null) out.add('choisir une video');
    if (_titleCtrl.text.trim().length < 5) {
      out.add('titre : au moins 5 caracteres');
    }
    if (s.selectedCategory == null) out.add('une categorie');
    if (_descCtrl.text.trim().length < 20) {
      out.add('description : au moins 20 caracteres');
    }
    return out;
  }

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Pour publier : ${missing.join(' · ')}',
            style: GoogleFonts.dmSans(
                color: AppColors.blanc, fontSize: 13, height: 1.35),
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
            hashtags: _hashtagCtrl.text,
            linkedServiceId: _linkedServiceId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video publiee !',
              style: GoogleFonts.dmSans(color: AppColors.textOnPrimary)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Icon(Icons.arrow_back_ios_new,
                  color: AppColors.blanc, size: 16),
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
                    _VideoPreviewCard(
                      videoFile: s.videoFile,
                      duration: s.videoDuration,
                      onPickVideo: () async {
                        final ok = await ref
                            .read(uploadVideoProvider.notifier)
                            .pickVideo();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Format ou duree invalide (mp4/mov/m4v, max 60s)',
                                style: GoogleFonts.dmSans(
                                    color: AppColors.textOnPrimary),
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Content Details ──
                    _SectionHeader(
                      icon: Icons.edit_note_rounded,
                      title: 'CONTENT',
                    ),
                    const SizedBox(height: 12),

                    // Title
                    _PremiumTextField(
                      controller: _titleCtrl,
                      label: 'Title',
                      hint: 'Ex: Coupe femme + brushing',
                      maxLength: 80,
                      prefixIcon: Icons.title_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    _PremiumTextField(
                      controller: _descCtrl,
                      label: 'Description',
                      hint: 'Describe your service in detail...',
                      maxLength: 300,
                      maxLines: 3,
                      prefixIcon: Icons.notes_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Hashtags
                    _PremiumTextField(
                      controller: _hashtagCtrl,
                      label: 'Hashtags (optional, max 5)',
                      hint: 'coiffure, tendance, paris',
                      prefixIcon: Icons.tag_rounded,
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Category ──
                    _SectionHeader(
                      icon: Icons.category_outlined,
                      title: 'CATEGORY',
                    ),
                    const SizedBox(height: 12),

                    // Category chips grid
                    _CategoryChipsGrid(
                      selectedCategory: s.selectedCategory,
                      onSelected: (cat) => n.setCategory(cat),
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Link Service (optional) ──
                    if (!svcState.loading &&
                        svcState.services.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.link_rounded,
                        title: 'LINK A SERVICE',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey(
                              'linked_svc_${_linkedServiceId ?? 'none'}'),
                          initialValue: _linkedServiceId,
                          hint: Text('None — general post',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.gris, fontSize: 14)),
                          dropdownColor: AppColors.surface,
                          style: GoogleFonts.dmSans(
                              color: AppColors.blanc, fontSize: 14),
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.gris),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.build_circle_outlined,
                                color: AppColors.gris.withAlpha(180),
                                size: 20),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None — general post',
                                  style: GoogleFonts.dmSans(
                                      color: AppColors.gris)),
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
                          onChanged: (v) =>
                              setState(() => _linkedServiceId = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Section: Settings ──
                    _SectionHeader(
                      icon: Icons.tune_rounded,
                      title: 'SETTINGS',
                    ),
                    const SizedBox(height: 12),

                    // Comments toggle
                    _PremiumToggleRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Allow comments',
                      subtitle: 'Let viewers comment on your post',
                      value: _allowComments,
                      onChanged: (v) => setState(() => _allowComments = v),
                    ),
                    const SizedBox(height: 10),

                    // Visibility
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility_outlined,
                                  color: AppColors.gris.withAlpha(180),
                                  size: 18),
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
                                  onTap: () =>
                                      setState(() => _visibility = 'public'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _VisibilityOption(
                                  icon: Icons.people_outline_rounded,
                                  label: 'Followers',
                                  subtitle: 'Your followers',
                                  selected: _visibility == 'followers',
                                  onTap: () => setState(
                                      () => _visibility = 'followers'),
                                ),
                              ),
                            ],
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
                    gradient: _isValid(s) && !s.isUploading
                        ? AppColors.gradientAccent
                        : null,
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
                                color: _isValid(s)
                                    ? AppColors.textOnPrimary
                                    : AppColors.gris,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Publish',
                                style: GoogleFonts.sora(
                                  color: _isValid(s)
                                      ? AppColors.textOnPrimary
                                      : AppColors.gris,
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
    return GestureDetector(
      onTap: onPickVideo,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: videoFile != null
            ? Stack(
                children: [
                  // Video ready indicator
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.videocam_rounded,
                              color: AppColors.violet, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video ready',
                          style: GoogleFonts.dmSans(
                            color: AppColors.blanc,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                  // Duration badge
                  if (duration != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.violet,
                          borderRadius: BorderRadius.circular(8),
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
                  // Checkmark badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: AppColors.textOnPrimary, size: 14),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gris.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.video_call_rounded,
                        color: AppColors.gris, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a video',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'mp4, mov, m4v · max 60s',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.violet.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.violet, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.sora(
            color: AppColors.gris,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
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
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
        hintStyle: GoogleFonts.dmSans(
            color: AppColors.gris.withAlpha(128), fontSize: 13),
        counterStyle:
            GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.gris.withAlpha(180), size: 18)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.violet
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.violet : AppColors.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.gris,
                ),
                const SizedBox(width: 6),
                Text(
                  e.value,
                  style: GoogleFonts.dmSans(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.blanc,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
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
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
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
              if (states.contains(WidgetState.selected)) {
                return AppColors.textOnPrimary;
              }
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
          color: selected
              ? AppColors.violet.withAlpha(12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.violet : AppColors.gris,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: selected ? AppColors.violet : AppColors.blanc,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 11,
              ),
            ),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Uploading...',
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.sora(
                  color: AppColors.violet,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.violet),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
