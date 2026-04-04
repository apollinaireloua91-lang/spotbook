import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../booking/presentation/notifiers/pro_scheduling_notifiers.dart';
import '../../data/upload_video_notifier.dart';

const _allowedCategories = <String, String>{
  'coiffure': 'Coiffure',
  'beaute': 'Beauté',
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
    if (s.videoFile == null) out.add('choisir une vidéo');
    if (_titleCtrl.text.trim().length < 5) {
      out.add('titre : au moins 5 caractères');
    }
    if (s.selectedCategory == null) out.add('une catégorie');
    if (_descCtrl.text.trim().length < 20) {
      out.add('description : au moins 20 caractères');
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
          content: Text(
            'Pour publier : ${missing.join(' · ')}',
            style: const TextStyle(
                color: AppColors.blanc, fontSize: 14, height: 1.35),
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
        const SnackBar(
          content: Text(
            'Vidéo envoyée. Elle sera visible après modération.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/pro');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
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
      appBar: const SpotbookAppBar(title: 'Publier'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Video thumbnail preview
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: s.videoFile != null
                          ? Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.videocam,
                                      color: AppColors.success, size: 32),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vidéo sélectionnée (${s.videoDuration?.toStringAsFixed(0) ?? "?"}s)',
                                        style: const TextStyle(
                                            color: AppColors.blanc,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      GestureDetector(
                                        onTap: () async {
                                          await ref
                                              .read(uploadVideoProvider
                                                  .notifier)
                                              .pickVideo();
                                        },
                                        child: const Text(
                                          'Changer la vidéo',
                                          style: TextStyle(
                                              color: AppColors.violet,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: () async {
                                final ok = await ref
                                    .read(uploadVideoProvider.notifier)
                                    .pickVideo();
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Format ou durée invalide (mp4/mov/m4v, max 60s)'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam_outlined,
                                      color: AppColors.gris, size: 36),
                                  SizedBox(height: 6),
                                  Text('Choisir une vidéo (max 60s)',
                                      style: TextStyle(
                                          color: AppColors.gris,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    TextField(
                      controller: _titleCtrl,
                      maxLength: 80,
                      style: const TextStyle(color: AppColors.blanc),
                      decoration: _inputDecoration('Titre *',
                          hint: 'Ex: Coupe femme + brushing'),
                    ),
                    const SizedBox(height: 14),
                    // Category
                    Builder(builder: (context) {
                      final validCat = _allowedCategories.containsKey(s.selectedCategory)
                          ? s.selectedCategory
                          : null;
                      return DropdownButtonFormField<String>(
                        key: ValueKey('pub_cat_$validCat'),
                        initialValue: validCat,
                        hint: const Text('Catégorie *',
                            style: TextStyle(color: AppColors.gris)),
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.blanc),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.gris),
                        decoration: _dropdownDecoration(),
                        items: _allowedCategories.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => n.setCategory(v),
                      );
                    }),
                    const SizedBox(height: 14),
                    // Description
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      maxLength: 300,
                      style: const TextStyle(color: AppColors.blanc),
                      decoration: _inputDecoration('Description *',
                          hint:
                              'Décrivez votre prestation en détail…'),
                    ),
                    const SizedBox(height: 14),
                    // Hashtags
                    TextField(
                      controller: _hashtagCtrl,
                      style: const TextStyle(color: AppColors.blanc),
                      decoration: _inputDecoration(
                          'Hashtags (optionnel, max 5)',
                          hint: 'coiffure, tendance, paris'),
                    ),
                    const SizedBox(height: 14),
                    // Link a service
                    if (!svcState.loading &&
                        svcState.services.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        key: ValueKey(
                            'linked_svc_${_linkedServiceId ?? 'none'}'),
                        initialValue: _linkedServiceId,
                        hint: const Text(
                            'Lier à une prestation (optionnel)',
                            style: TextStyle(color: AppColors.gris)),
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.blanc),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.gris),
                        decoration: _dropdownDecoration(),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Aucune — réservation générale'),
                          ),
                          ...svcState.services.map(
                            (sv) => DropdownMenuItem<String?>(
                              value: sv.id,
                              child: Text(sv.name,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _linkedServiceId = v),
                      ),
                      const SizedBox(height: 14),
                    ],
                    // Allow comments toggle
                    _SettingRow(
                      label: 'Autoriser les commentaires',
                      value: _allowComments,
                      onChanged: (v) =>
                          setState(() => _allowComments = v),
                    ),
                    const SizedBox(height: 8),
                    // Visibility
                    const Text('Visibilité',
                        style: TextStyle(
                            color: AppColors.blanc,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _VisibilityChip(
                          label: 'Public',
                          selected: _visibility == 'public',
                          onTap: () =>
                              setState(() => _visibility = 'public'),
                        ),
                        const SizedBox(width: 10),
                        _VisibilityChip(
                          label: 'Abonnés',
                          selected: _visibility == 'followers',
                          onTap: () => setState(
                              () => _visibility = 'followers'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Upload progress
                    if (s.isUploading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s.uploadProgress,
                          backgroundColor: AppColors.surface,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  AppColors.blanc),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '${(s.uploadProgress * 100).toInt()}% — Envoi en cours…',
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            // Publish button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SpotbookButton.gradient(
                label: s.isUploading
                    ? 'Envoi en cours…'
                    : 'Publier ma prestation',
                isLoading: s.isUploading,
                onPressed: s.isUploading ? null : () => _tryPublish(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
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
    );
  }

  InputDecoration _dropdownDecoration() {
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

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.blanc, fontSize: 14)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.violet,
          ),
        ],
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.blanc : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.blanc : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.fond : AppColors.blanc,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
