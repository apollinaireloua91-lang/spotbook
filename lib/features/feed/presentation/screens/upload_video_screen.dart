import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
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

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();

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

  Future<void> _pickVideo() async {
    final ok = await ref.read(uploadVideoProvider.notifier).pickVideo();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Video too long — max 2 minutes'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _publish() async {
    try {
      await ref.read(uploadVideoProvider.notifier).publish(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        hashtags: _hashtagCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Video published!'), backgroundColor: AppColors.success),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(uploadVideoProvider);
    final n = ref.read(uploadVideoProvider.notifier);

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
            onPressed: () => context.pop(),
          ),
        ),
        title: Text('Publish a Service', style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: s.isUploading ? null : _pickVideo,
          child: Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: s.videoFile != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.videocam, color: AppColors.success, size: 40), const SizedBox(height: 8),
                    Text('Video selected (${s.videoDuration?.toStringAsFixed(0)}s)', style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14)),
                    const SizedBox(height: 4), Text('Tap to change', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12))]))
                : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.videocam_outlined, color: AppColors.gris, size: 40), const SizedBox(height: 8),
                    Text('Select a video (max 2 min)', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14))]))),
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _titleCtrl,
          builder: (context, value, _) => TextField(
            controller: _titleCtrl, maxLength: 80, style: GoogleFonts.dmSans(color: AppColors.blanc),
            decoration: InputDecoration(labelText: 'Title *', hintText: 'E.g.: Women\'s cut + blow-dry', labelStyle: GoogleFonts.dmSans(color: AppColors.gris), hintStyle: GoogleFonts.dmSans(color: AppColors.gris.withAlpha(128)), counterStyle: GoogleFonts.dmSans(color: AppColors.gris), filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.blanc))),
          ),
        ),
        const SizedBox(height: 16),
        Builder(builder: (context) {
          final catItems = ref.watch(proCategoriesProvider).when(
            data: (cats) => cats.map((c) => DropdownMenuItem(value: c.label, child: Text(c.label))).toList(),
            loading: () => _fallbackCategories.entries.map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value))).toList(),
            error: (_, __) => _fallbackCategories.entries.map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value))).toList(),
          );
          final validCat = catItems.any((i) => i.value == s.selectedCategory) ? s.selectedCategory : null;
          return DropdownButtonFormField<String>(
            initialValue: validCat,
            hint: Text('Select a category *', style: GoogleFonts.dmSans(color: AppColors.gris)),
            dropdownColor: AppColors.surface, style: GoogleFonts.dmSans(color: AppColors.blanc), icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gris),
            decoration: InputDecoration(filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border))),
            items: catItems,
            onChanged: (v) => n.setCategory(v),
          );
        }),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _descCtrl,
          builder: (context, value, _) => TextField(
            controller: _descCtrl, maxLines: 4, maxLength: 300, style: GoogleFonts.dmSans(color: AppColors.blanc),
            decoration: InputDecoration(labelText: 'Description *', hintText: 'Describe your service in detail...', labelStyle: GoogleFonts.dmSans(color: AppColors.gris), hintStyle: GoogleFonts.dmSans(color: AppColors.gris.withAlpha(128)), counterStyle: GoogleFonts.dmSans(color: AppColors.gris), filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.blanc))),
          ),
        ),
        const SizedBox(height: 16),
        TextField(controller: _hashtagCtrl, style: GoogleFonts.dmSans(color: AppColors.blanc),
          decoration: InputDecoration(labelText: 'Hashtags (optional, max 5)', hintText: 'haircut, trending, paris', labelStyle: GoogleFonts.dmSans(color: AppColors.gris), hintStyle: GoogleFonts.dmSans(color: AppColors.gris.withAlpha(128)), filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.blanc)))),
        const SizedBox(height: 32),
        if (s.isUploading) ...[
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: s.uploadProgress, backgroundColor: AppColors.surface, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blanc), minHeight: 6)),
          const SizedBox(height: 8),
          Center(child: Text('${(s.uploadProgress * 100).toInt()}% — Publishing...', style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13))),
          const SizedBox(height: 16),
        ],
        ListenableBuilder(
          listenable: Listenable.merge([_titleCtrl, _descCtrl]),
          builder: (context, _) {
            final valid = _isValid(s);
            return SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: valid && !s.isUploading ? _publish : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blanc, foregroundColor: AppColors.fond, disabledBackgroundColor: AppColors.surfaceAlt, disabledForegroundColor: AppColors.gris, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Publish my service', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
            ));
          },
        ),
        const SizedBox(height: 32),
      ]))),
    );
  }
}
