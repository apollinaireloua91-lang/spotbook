import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../booking/presentation/notifiers/pro_scheduling_notifiers.dart';
import '../../data/upload_video_notifier.dart';

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
  String? _linkedServiceId;

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Sans ça, le bouton ne se met pas à jour après choix catégorie / vidéo (hors titre & description).
    _titleCtrl.addListener(_onTextChanged);
    _descCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTextChanged);
    _descCtrl.removeListener(_onTextChanged);
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

  /// Messages courts pour le SnackBar si l’utilisateur appuie alors que le formulaire est incomplet.
  List<String> _missingPublishRequirements(UploadVideoState s) {
    final out = <String>[];
    if (s.videoFile == null) {
      out.add('choisir une vidéo (max 60 s, mp4/mov/m4v)');
    }
    if (_titleCtrl.text.trim().length < 5) {
      out.add('titre : au moins 5 caractères');
    }
    if (s.selectedCategory == null) {
      out.add('une catégorie');
    }
    if (_descCtrl.text.trim().length < 20) {
      out.add('description : au moins 20 caractères');
    }
    return out;
  }

  Future<void> _tryPublish(UploadVideoState s) async {
    if (s.isUploading) return;
    if (!_isValid(s)) {
      HapticFeedback.lightImpact();
      final missing = _missingPublishRequirements(s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            missing.isEmpty
                ? 'Formulaire incomplet.'
                : 'Pour publier : ${missing.join(' · ')}',
            style: const TextStyle(color: AppColors.blanc, fontSize: 14, height: 1.35),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    await _publish();
  }

  Future<void> _pickVideo() async {
    final ok = await ref.read(uploadVideoProvider.notifier).pickVideo();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vidéo refusée : format (mp4, mov, m4v) ou durée max 60 s'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
        const SnackBar(
          content: Text(
            'Vidéo envoyée. Encodage Cloudflare en cours — statut « traitement ». '
            'Elle sera visible après modération.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Session expirée')) {
        context.go('/auth/login');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
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
        leading: GoRouter.of(context).canPop()
            ? Semantics(
                label: 'Retour',
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
                  onPressed: () => context.pop(),
                ),
              )
            : null,
        title: const Text('Publier une prestation'),
        centerTitle: true,
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: s.isUploading ? null : _pickVideo,
          child: Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: s.videoFile != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.videocam, color: AppColors.success, size: 40), const SizedBox(height: 8),
                    Text('Video selected (${s.videoDuration?.toStringAsFixed(0)}s)', style: const TextStyle(color: AppColors.blanc, fontSize: 14)),
                    const SizedBox(height: 4), const Text('Tap to change', style: TextStyle(color: AppColors.gris, fontSize: 12))]))
                : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.videocam_outlined, color: AppColors.gris, size: 40), SizedBox(height: 8),
                    Text('Select a video (max 60s)', style: TextStyle(color: AppColors.gris, fontSize: 14))]))),
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _titleCtrl,
          builder: (context, value, _) => TextField(
            controller: _titleCtrl, maxLength: 80, style: const TextStyle(color: AppColors.blanc),
            decoration: InputDecoration(labelText: 'Title *', hintText: 'Ex: Coupe femme + brushing', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), counterStyle: const TextStyle(color: AppColors.gris), filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blanc))),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey<String?>('upload_cat_${s.selectedCategory}'),
          initialValue: s.selectedCategory,
          hint: const Text('Select a category *', style: TextStyle(color: AppColors.gris)),
          dropdownColor: AppColors.surface, style: const TextStyle(color: AppColors.blanc), icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gris),
          decoration: InputDecoration(filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
          items: _allowedCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => n.setCategory(v),
        ),
        const SizedBox(height: 16),
        if (!svcState.loading && svcState.services.isNotEmpty) ...[
          DropdownButtonFormField<String?>(
            key: ValueKey<String?>('linked_svc_${_linkedServiceId ?? 'none'}'),
            initialValue: _linkedServiceId,
            hint: const Text('Lier à une prestation (optionnel)', style: TextStyle(color: AppColors.gris)),
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.blanc),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gris),
            decoration: InputDecoration(
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
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Aucune — réservation générale'),
              ),
              ...svcState.services.map(
                (sv) => DropdownMenuItem<String?>(
                  value: sv.id,
                  child: Text(sv.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _linkedServiceId = v),
          ),
          const SizedBox(height: 16),
        ],
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _descCtrl,
          builder: (context, value, _) => TextField(
            controller: _descCtrl, maxLines: 4, maxLength: 300, style: const TextStyle(color: AppColors.blanc),
            decoration: InputDecoration(labelText: 'Description *', hintText: 'Describe your service in detail...', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), counterStyle: const TextStyle(color: AppColors.gris), filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blanc))),
          ),
        ),
        const SizedBox(height: 16),
        TextField(controller: _hashtagCtrl, style: const TextStyle(color: AppColors.blanc),
          decoration: InputDecoration(labelText: 'Hashtags (optional, max 5)', hintText: 'coiffure, tendance, paris', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blanc)))),
        const SizedBox(height: 32),
        if (s.isUploading) ...[
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: s.uploadProgress, backgroundColor: AppColors.surface, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blanc), minHeight: 6)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${(s.uploadProgress * 100).toInt()}% — Envoi et enregistrement…',
              style: const TextStyle(color: AppColors.gris, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: s.isUploading ? null : () => _tryPublish(s),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blanc,
              foregroundColor: AppColors.fond,
              disabledBackgroundColor: AppColors.surfaceAlt,
              disabledForegroundColor: AppColors.gris,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              s.isUploading ? 'Envoi en cours…' : 'Publier ma prestation',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Obligatoire : vidéo · titre (5+ car.) · catégorie · description (20+ car.)',
          style: TextStyle(
            color: _isValid(s) ? AppColors.gris.withValues(alpha: 0.85) : AppColors.grisClair,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 32),
      ]))),
    );
  }
}
