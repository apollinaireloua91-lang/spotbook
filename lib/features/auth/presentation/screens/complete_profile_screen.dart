import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/auth_repository.dart';

class _ProfileState {
  const _ProfileState({this.avatarUrl, this.isUploading = false, this.isSaving = false});
  final String? avatarUrl;
  final bool isUploading;
  final bool isSaving;
  _ProfileState copyWith({String? avatarUrl, bool? isUploading, bool? isSaving, bool clearAvatar = false}) =>
      _ProfileState(avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl), isUploading: isUploading ?? this.isUploading, isSaving: isSaving ?? this.isSaving);
}

class _ProfileNotifier extends Notifier<_ProfileState> {
  @override
  _ProfileState build() => const _ProfileState();

  Future<void> uploadAvatar(XFile image) async {
    state = state.copyWith(isUploading: true);
    try {
      final bytes = await image.readAsBytes();
      final url = await ref.read(authRepositoryProvider).uploadAvatar(bytes);
      state = state.copyWith(isUploading: false, avatarUrl: url);
    } catch (_) {
      state = state.copyWith(isUploading: false);
      rethrow;
    }
  }

  Future<void> save({required String displayName, required String bio}) async {
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
        fullName: displayName,
        bio: bio.isNotEmpty ? bio : null,
        avatarUrl: state.avatarUrl,
      );
      state = state.copyWith(isSaving: false);
    } catch (_) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  String? get userRole => ref.read(authRepositoryProvider).currentUserRole;
}

final _profileProvider = NotifierProvider<_ProfileNotifier, _ProfileState>(_ProfileNotifier.new, isAutoDispose: true);

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> with SingleTickerProviderStateMixin {
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
    _checkController.forward();
    _displayNameCtrl.text = ref.read(authRepositoryProvider).currentUserFullName ?? '';
  }

  @override
  void dispose() {
    _checkController.dispose(); _displayNameCtrl.dispose(); _bioCtrl.dispose(); super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (image == null) return;
    try {
      await ref.read(_profileProvider.notifier).uploadAvatar(image);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec du téléchargement'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _save() async {
    try {
      await ref.read(_profileProvider.notifier).save(displayName: _displayNameCtrl.text.trim(), bio: _bioCtrl.text.trim());
      if (!mounted) return;
      _navigateNext();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de la sauvegarde'), backgroundColor: AppColors.error));
    }
  }

  void _navigateNext() {
    final role = ref.read(_profileProvider.notifier).userRole ?? 'client';
    context.go(role == 'pro' ? '/pro/business-details' : '/client/interests');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_profileProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
        const SizedBox(height: 48),
        ScaleTransition(scale: _checkScale, child: Container(width: 64, height: 64, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success), child: const Icon(Icons.check, color: AppColors.blanc, size: 32))),
        const SizedBox(height: 16),
        const Text('Compte créé !', style: TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        const Text('Complétez votre profil', style: TextStyle(color: AppColors.blanc, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Ajoutez une photo et une bio pour que les professionnels sachent qui vous êtes.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gris, fontSize: 15)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: s.isUploading ? null : _pickAvatar,
          child: Stack(children: [
            CircleAvatar(radius: 50, backgroundColor: AppColors.surface, backgroundImage: s.avatarUrl != null ? CachedNetworkImageProvider(s.avatarUrl!) : null, child: s.avatarUrl == null ? const Icon(Icons.person, size: 40, color: AppColors.gris) : null),
            Positioned(bottom: 0, right: 0, child: Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceAlt),
              child: s.isUploading ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blanc)) : const Icon(Icons.camera_alt, size: 16, color: AppColors.blanc))),
          ]),
        ),
        const SizedBox(height: 32),
        TextField(controller: _displayNameCtrl, style: const TextStyle(color: AppColors.blanc), decoration: InputDecoration(labelText: 'Nom affiché', labelStyle: const TextStyle(color: AppColors.gris), prefixIcon: const Icon(Icons.edit, color: AppColors.gris, size: 20), filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 16),
        TextField(controller: _bioCtrl, style: const TextStyle(color: AppColors.blanc), maxLines: 3, decoration: InputDecoration(labelText: 'Bio', hintText: 'Parlez-nous un peu de vous...', labelStyle: const TextStyle(color: AppColors.gris), hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)), filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: s.isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blanc, foregroundColor: AppColors.fond, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: s.isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fond)) : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 16),
        GestureDetector(onTap: _navigateNext, child: const Text('Passer pour le moment', style: TextStyle(color: AppColors.gris, fontSize: 14))),
        const SizedBox(height: 32),
      ]))),
    );
  }
}
