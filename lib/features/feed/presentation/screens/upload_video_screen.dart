import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/video_repository.dart';

const _allowedCategories = <String, String>{
  'coiffure': 'Coiffure', 'beaute': 'Beauté', 'fitness': 'Fitness',
  'photo': 'Photographie', 'musique': 'Musique', 'cuisine': 'Cuisine',
  'massage': 'Massage', 'tatouage': 'Tatouage', 'maquillage': 'Maquillage',
  'mode': 'Mode', 'danse': 'Danse', 'art': 'Art',
  'coaching': 'Coaching', 'autre_service': 'Autre service',
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
  String? _selectedCategory;
  XFile? _videoFile;
  double? _videoDuration;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); _hashtagCtrl.dispose(); super.dispose(); }

  bool get _isValid => _videoFile != null && _titleCtrl.text.trim().length >= 5 && _selectedCategory != null && _descCtrl.text.trim().length >= 20;

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (file == null) return;
    final info = await VideoCompress.getMediaInfo(file.path);
    final durationSec = (info.duration ?? 0) / 1000;
    if (durationSec > 60) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video too long — max 60 seconds'), backgroundColor: AppColors.error));
      return;
    }
    setState(() { _videoFile = file; _videoDuration = durationSec; });
  }

  Future<void> _publish() async {
    if (!_isValid) return;
    setState(() { _isUploading = true; _uploadProgress = 0; });
    try {
      final repo = ref.read(videoRepositoryProvider);

      setState(() => _uploadProgress = 0.1);
      final compressed = await VideoCompress.compressVideo(_videoFile!.path, quality: VideoQuality.MediumQuality);
      final compressedFile = compressed?.file;
      if (compressedFile == null) throw Exception('Compression failed');

      setState(() => _uploadProgress = 0.3);
      final uploadData = await repo.getCloudflareUploadUrl();
      final cloudflareId = uploadData['videoId'] as String;

      setState(() => _uploadProgress = 0.5);
      // TODO: Use proper TUS upload client in production
      await compressedFile.readAsBytes();

      setState(() => _uploadProgress = 0.8);
      final hashtags = _hashtagCtrl.text.split(',').map((h) => h.trim().replaceAll('#', '')).where((h) => h.isNotEmpty).take(5).toList();

      await repo.submitForModeration(
        title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(), category: _selectedCategory!,
        duration: _videoDuration, cloudflareId: cloudflareId,
        streamUrl: 'https://customer-${const String.fromEnvironment("CLOUDFLARE_CUSTOMER_CODE")}.cloudflarestream.com/$cloudflareId/manifest/video.m3u8',
        thumbnailUrl: 'https://customer-${const String.fromEnvironment("CLOUDFLARE_CUSTOMER_CODE")}.cloudflarestream.com/$cloudflareId/thumbnails/thumbnail.jpg',
        hashtags: hashtags,
      );

      setState(() => _uploadProgress = 1.0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video submitted for review. You will be notified when published.'), backgroundColor: AppColors.success));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(backgroundColor: AppColors.fond, title: const Text('Publish a Service'), centerTitle: true),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isUploading ? null : _pickVideo,
          child: Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: _videoFile != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.videocam, color: AppColors.success, size: 40), const SizedBox(height: 8),
                    Text('Video selected (${_videoDuration?.toStringAsFixed(0)}s)', style: const TextStyle(color: AppColors.blanc, fontSize: 14)),
                    const SizedBox(height: 4), const Text('Tap to change', style: TextStyle(color: AppColors.gris, fontSize: 12))]))
                : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.videocam_outlined, color: AppColors.gris, size: 40), SizedBox(height: 8),
                    Text('Select a video (max 60s)', style: TextStyle(color: AppColors.gris, fontSize: 14))]))),
        ),
        const SizedBox(height: 24),
        TextField(controller: _titleCtrl, maxLength: 80, onChanged: (_) => setState(() {}), style: const TextStyle(color: AppColors.blanc),
          decoration: InputDecoration(labelText: 'Title *', hintText: 'Ex: Coupe femme + brushing', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), counterStyle: const TextStyle(color: AppColors.gris), filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blanc)))),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          hint: const Text('Select a category *', style: TextStyle(color: AppColors.gris)),
          dropdownColor: AppColors.surface, style: const TextStyle(color: AppColors.blanc), icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gris),
          decoration: InputDecoration(filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
          items: _allowedCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
        const SizedBox(height: 16),
        TextField(controller: _descCtrl, maxLines: 4, maxLength: 300, onChanged: (_) => setState(() {}), style: const TextStyle(color: AppColors.blanc),
          decoration: InputDecoration(labelText: 'Description *', hintText: 'Describe your service in detail...', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), counterStyle: const TextStyle(color: AppColors.gris), filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blanc)))),
        const SizedBox(height: 16),
        TextField(controller: _hashtagCtrl, style: const TextStyle(color: AppColors.blanc),
          decoration: InputDecoration(labelText: 'Hashtags (optional, max 5)', hintText: 'coiffure, tendance, paris', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blanc)))),
        const SizedBox(height: 32),
        if (_isUploading) ...[
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _uploadProgress, backgroundColor: AppColors.surface, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blanc), minHeight: 6)),
          const SizedBox(height: 8),
          Center(child: Text('${(_uploadProgress * 100).toInt()}% — Publishing...', style: const TextStyle(color: AppColors.gris, fontSize: 13))),
          const SizedBox(height: 16),
        ],
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _isValid && !_isUploading ? _publish : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blanc, foregroundColor: AppColors.fond, disabledBackgroundColor: AppColors.surfaceAlt, disabledForegroundColor: AppColors.gris, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Publier ma prestation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 32),
      ]))),
    );
  }
}
