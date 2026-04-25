import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../auth/data/category_repository.dart';
import '../../data/upload_video_notifier.dart';

/// Fallback categories for upload when Supabase data hasn't loaded yet.
const _fallbackCategories = <String, String>{
  'Coiffure': 'Coiffure', 'Barbier': 'Barber', 'Esthétique': 'Beauty',
  'Massage': 'Massage', 'Fitness': 'Fitness', 'Photographie': 'Photo',
  'Musique / DJ': 'DJ', 'Tatouage': 'Tattoo', 'Maquillage': 'Makeup',
  'Mode': 'Fashion', 'Cuisine': 'Catering', 'Coaching': 'Coaching',
};

class UploadVideoScreen extends ConsumerStatefulWidget {
  const UploadVideoScreen({super.key});
  @override
  ConsumerState<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen>
    with TickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();

  late final AnimationController _auroraCtrl;
  late final AnimationController _revealCtrl;

  @override
  void initState() {
    super.initState();
    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCtrl.forward());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hashtagCtrl.dispose();
    _auroraCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  bool _isValid(UploadVideoState s) =>
      s.videoFile != null &&
      _titleCtrl.text.trim().length >= 5 &&
      s.selectedCategory != null &&
      _descCtrl.text.trim().length >= 20;

  Future<void> _pickVideo() async {
    HapticFeedback.lightImpact();
    final ok = await ref.read(uploadVideoProvider.notifier).pickVideo();
    if (!ok && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.videoTooLong,
              style: GoogleFonts.dmSans(color: AppColors.blanc)),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _publish() async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(uploadVideoProvider.notifier).publish(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            hashtags: _hashtagCtrl.text,
          );
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.videoPublished,
              style: GoogleFonts.dmSans(color: AppColors.blanc)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.dmSans(color: AppColors.blanc)),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Animation<double> _reveal(double start, double end) => CurvedAnimation(
        parent: _revealCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(uploadVideoProvider);
    final n = ref.read(uploadVideoProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Semantics(
            label: l.a11yBack,
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(200),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.blanc.withAlpha(30),
                    width: 0.5,
                  ),
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    color: AppColors.blanc, size: 15),
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          l.publishAService,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _auroraCtrl,
            builder: (_, __) => CustomPaint(
              painter: _PublishAuroraPainter(progress: _auroraCtrl.value),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Eyebrow + display title
                        _RevealFade(
                          animation: _reveal(0.0, 0.45),
                          child: _Eyebrow(label: 'NEW PUBLICATION'),
                        ),
                        const SizedBox(height: 10),
                        _RevealSlide(
                          animation: _reveal(0.1, 0.55),
                          child: Text(
                            l.publishAService,
                            style: GoogleFonts.sora(
                              color: AppColors.blanc,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _RevealSlide(
                          animation: _reveal(0.18, 0.6),
                          child: Text(
                            l.uploadScreenEditorialSubtitle,
                            style: GoogleFonts.dmSans(
                              color: AppColors.gris,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Section: Media
                        _RevealSlide(
                          animation: _reveal(0.25, 0.7),
                          child: const _SectionLabel(label: 'MÉDIA'),
                        ),
                        const SizedBox(height: 12),
                        _RevealSlide(
                          animation: _reveal(0.3, 0.75),
                          child: _VideoDropzone(
                            state: s,
                            onTap: s.isUploading ? null : _pickVideo,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Section: Title
                        _RevealSlide(
                          animation: _reveal(0.35, 0.8),
                          child: const _SectionLabel(label: 'TITRE'),
                        ),
                        const SizedBox(height: 12),
                        _RevealSlide(
                          animation: _reveal(0.4, 0.85),
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _titleCtrl,
                            builder: (context, value, _) => _GlassTextField(
                              controller: _titleCtrl,
                              hint: l.titleHint,
                              maxLength: 80,
                              counter: '${value.text.length}/80',
                              minChars: 5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section: Category
                        _RevealSlide(
                          animation: _reveal(0.45, 0.9),
                          child: const _SectionLabel(label: 'CATÉGORIE'),
                        ),
                        const SizedBox(height: 12),
                        _RevealSlide(
                          animation: _reveal(0.5, 0.95),
                          child: Builder(builder: (context) {
                            final catItems =
                                ref.watch(proCategoriesProvider).when(
                                      data: (cats) => cats
                                          .map((c) => DropdownMenuItem(
                                                value: c.label,
                                                child: Text(c.label),
                                              ))
                                          .toList(),
                                      loading: () => _fallbackCategories.entries
                                          .map((e) => DropdownMenuItem<String>(
                                                value: e.key,
                                                child: Text(e.value),
                                              ))
                                          .toList(),
                                      error: (_, __) =>
                                          _fallbackCategories.entries
                                              .map((e) =>
                                                  DropdownMenuItem<String>(
                                                    value: e.key,
                                                    child: Text(e.value),
                                                  ))
                                              .toList(),
                                    );
                            final validCat = catItems
                                    .any((i) => i.value == s.selectedCategory)
                                ? s.selectedCategory
                                : null;
                            return _GlassDropdown<String>(
                              value: validCat,
                              hint: l.selectCategoryRequired,
                              items: catItems,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                n.setCategory(v);
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // Section: Description
                        _RevealSlide(
                          animation: _reveal(0.55, 1.0),
                          child: const _SectionLabel(label: 'DESCRIPTION'),
                        ),
                        const SizedBox(height: 12),
                        _RevealSlide(
                          animation: _reveal(0.6, 1.0),
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _descCtrl,
                            builder: (context, value, _) => _GlassTextField(
                              controller: _descCtrl,
                              hint: l.descriptionHint,
                              maxLength: 300,
                              maxLines: 4,
                              counter: '${value.text.length}/300',
                              minChars: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section: Hashtags
                        _RevealSlide(
                          animation: _reveal(0.65, 1.0),
                          child: const _SectionLabel(label: 'HASHTAGS'),
                        ),
                        const SizedBox(height: 12),
                        _RevealSlide(
                          animation: _reveal(0.7, 1.0),
                          child: _GlassTextField(
                            controller: _hashtagCtrl,
                            hint: l.hashtagsHint,
                            prefixText: '#',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Upload progress
                        if (s.isUploading) ...[
                          _UploadProgress(progress: s.uploadProgress, label: l),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom publish bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.fond.withAlpha(230),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.blanc.withAlpha(16),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([_titleCtrl, _descCtrl]),
                    builder: (context, _) {
                      final valid = _isValid(s);
                      return _PublishCta(
                        enabled: valid && !s.isUploading,
                        uploading: s.isUploading,
                        label: l.publishMyService,
                        onPressed: _publish,
                      );
                    },
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

// ─── Reveal helpers ─────────────────────────────────────────────────────────

class _RevealFade extends StatelessWidget {
  const _RevealFade({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, c) => Opacity(opacity: animation.value, child: c),
      child: child,
    );
  }
}

class _RevealSlide extends StatelessWidget {
  const _RevealSlide({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, c) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 14),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

// ─── Eyebrow ─────────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 2,
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.6,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.violetClair,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.grisClair,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 0.5,
            color: AppColors.blanc.withAlpha(18),
          ),
        ),
      ],
    );
  }
}

// ─── Video dropzone ─────────────────────────────────────────────────────────

class _VideoDropzone extends StatelessWidget {
  const _VideoDropzone({required this.state, required this.onTap});
  final UploadVideoState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasVideo = state.videoFile != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(0.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: hasVideo
              ? LinearGradient(
                  colors: [AppColors.violet, AppColors.rose],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasVideo ? null : AppColors.blanc.withAlpha(22),
          boxShadow: hasVideo
              ? [
                  BoxShadow(
                    color: AppColors.violet.withAlpha(60),
                    blurRadius: 32,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(220),
            borderRadius: BorderRadius.circular(21),
          ),
          child: hasVideo
              ? _PickedVideoContent(duration: state.videoDuration)
              : const _EmptyDropzoneContent(),
        ),
      ),
    );
  }
}

class _EmptyDropzoneContent extends StatelessWidget {
  const _EmptyDropzoneContent();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.violet.withAlpha(60),
                AppColors.rose.withAlpha(40),
              ],
            ),
            border: Border.all(
              color: AppColors.blanc.withAlpha(30),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.movie_filter_outlined,
            color: AppColors.blanc,
            size: 26,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.uploadVideoEmptyDropzoneTitle,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'mp4 · mov · m4v — max 2 min',
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _PickedVideoContent extends StatelessWidget {
  const _PickedVideoContent({required this.duration});
  final double? duration;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientAccent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withAlpha(120),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: AppColors.blanc, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                l.uploadVideoReady,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.uploadVideoTapToChange,
                style: GoogleFonts.dmSans(
                  color: AppColors.violetClair,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (duration != null)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.fond.withAlpha(200),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.blanc.withAlpha(30),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      color: AppColors.violetClair, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${duration!.toStringAsFixed(0)}s',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientAccent,
            ),
            child:
                Icon(Icons.check_rounded, color: AppColors.blanc, size: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Glass text field ──────────────────────────────────────────────────────

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.counter,
    this.minChars,
    this.prefixText,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final String? counter;
  final int? minChars;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final len = controller.text.trim().length;
    final valid = minChars == null || len >= minChars!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.blanc.withAlpha(8),
            border: Border.all(
              color: AppColors.blanc.withAlpha(26),
              width: 0.5,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            style: GoogleFonts.dmSans(
              color: AppColors.blanc,
              fontSize: 14.5,
              height: 1.45,
            ),
            cursorColor: AppColors.violetClair,
            cursorWidth: 1.5,
            cursorRadius: const Radius.circular(2),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: AppColors.gris.withAlpha(140),
                fontSize: 14,
              ),
              prefixText: prefixText,
              prefixStyle: GoogleFonts.dmSans(
                color: AppColors.violetClair,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              filled: false,
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        if (counter != null || (minChars != null && len > 0)) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                if (minChars != null && len > 0) ...[
                  Icon(
                    valid
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 12,
                    color: valid ? AppColors.success : AppColors.gris,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    valid ? l.uploadVideoFieldValid : l.uploadVideoFieldMinChars(minChars!),
                    style: GoogleFonts.dmSans(
                      color: valid ? AppColors.success : AppColors.gris,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                if (counter != null)
                  Text(
                    counter!,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Glass dropdown ────────────────────────────────────────────────────────

class _GlassDropdown<T> extends StatelessWidget {
  const _GlassDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.blanc.withAlpha(8),
        border: Border.all(
          color: AppColors.blanc.withAlpha(26),
          width: 0.5,
        ),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        hint: Text(
          hint,
          style: GoogleFonts.dmSans(
            color: AppColors.gris.withAlpha(140),
            fontSize: 14,
          ),
        ),
        dropdownColor: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.violetClair,
          size: 22,
        ),
        decoration: const InputDecoration(
          filled: false,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Publish CTA ───────────────────────────────────────────────────────────

class _PublishCta extends StatelessWidget {
  const _PublishCta({
    required this.enabled,
    required this.uploading,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final bool uploading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: enabled
            ? AppColors.gradientAccent
            : LinearGradient(colors: [
                AppColors.blanc.withAlpha(18),
                AppColors.blanc.withAlpha(10),
              ]),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.violet.withAlpha(120),
                  blurRadius: 32,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: uploading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blanc,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l.uploadVideoUploading,
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.sora(
                          color: enabled
                              ? AppColors.blanc
                              : AppColors.blanc.withAlpha(110),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: enabled
                            ? AppColors.blanc
                            : AppColors.blanc.withAlpha(110),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Upload progress ───────────────────────────────────────────────────────

class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.progress, required this.label});
  final double progress;
  final AppLocalizations label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.blanc.withAlpha(8),
        border: Border.all(
          color: AppColors.violet.withAlpha(60),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.violetClair,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.uploadVideoPublishing,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.sora(
                  color: AppColors.violetClair,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 4,
              color: AppColors.blanc.withAlpha(18),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aurora backdrop ───────────────────────────────────────────────────────

class _PublishAuroraPainter extends CustomPainter {
  _PublishAuroraPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    // Top-left violet halo
    final vp = Paint()
      ..color = AppColors.violet.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 130);
    canvas.drawCircle(
      Offset(size.width * (0.15 + 0.06 * math.sin(t)),
          size.height * (0.1 + 0.04 * math.cos(t))),
      size.width * 0.55,
      vp,
    );

    // Bottom-right rose halo
    final rp = Paint()
      ..color = AppColors.rose.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150);
    canvas.drawCircle(
      Offset(size.width * (0.9 + 0.05 * math.sin(t + math.pi)),
          size.height * (0.9 + 0.03 * math.cos(t + math.pi))),
      size.width * 0.5,
      rp,
    );

    // Sparse film grain
    final g = Paint()..color = AppColors.blanc.withAlpha(6);
    final rand = math.Random(11);
    for (var i = 0; i < 140; i++) {
      canvas.drawCircle(
        Offset(rand.nextDouble() * size.width,
            rand.nextDouble() * size.height),
        0.5,
        g,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PublishAuroraPainter old) =>
      old.progress != progress;
}
