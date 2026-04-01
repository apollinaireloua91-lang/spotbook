import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../../../shared/widgets/spotbook_bottom_sheet.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/edit_profile_notifier.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../providers/client_profile_screen_provider.dart';
import '../widgets/social_link_sheets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _initControllers(EditProfileState s) {
    if (_controllersInitialized || s.isLoading) return;
    _controllersInitialized = true;
    if (s.isPro && s.proProfile != null) {
      _nameCtrl.text = s.proProfile!.businessName;
      _usernameCtrl.text = s.proProfile!.username ?? '';
      _bioCtrl.text = s.proProfile!.bio ?? '';
      _cityCtrl.text = s.proProfile!.city ?? '';
    } else if (s.clientProfile != null) {
      _nameCtrl.text = s.clientProfile!.fullName;
      _usernameCtrl.text = s.clientProfile!.username ?? '';
      _bioCtrl.text = s.clientProfile!.bio ?? '';
      _cityCtrl.text = s.clientProfile!.city ?? '';
    }
  }

  Future<void> _save() async {
    try {
      await ref.read(editProfileProvider.notifier).saveProfile(
            fullName: _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.success),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _linkSocial(String platform) async {
    final info = platformInfoFor(platform);
    if (info == null) return;
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialLinkBottomSheet(platform: info),
    );
    if (url == null || url.isEmpty) return;
    try {
      await ref.read(editProfileProvider.notifier).linkSocial(platform, url: url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la liaison du compte'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _disconnectSocial(String platform) async {
    try {
      await ref.read(editProfileProvider.notifier).disconnectSocial(platform);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(editProfileProvider);
    _initControllers(s);

    if (s.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(child: CircularProgressIndicator(color: AppColors.blanc)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        title: const Text('Modifier le profil'),
        centerTitle: true,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!s.isPro && s.clientProfile != null) ...[
                _buildClientPhotosHeader(s.clientProfile!),
              ],
              _buildTextField('Nom', _nameCtrl),
              const SizedBox(height: 16),
              _buildTextField('Nom d\'utilisateur', _usernameCtrl),
              const SizedBox(height: 16),
              AddressAutocompleteField(
                controller: _cityCtrl,
                label: 'Ville',
                icon: Icons.location_city,
                fillColor: AppColors.surface,
              ),
              if (!s.isPro) ...[
                const SizedBox(height: 16),
                _buildTextField('Bio', _bioCtrl, maxLines: 3),
              ],
              if (s.isPro) ...[
                const SizedBox(height: 16),
                _buildTextField('Bio', _bioCtrl, maxLines: 3),
                const SizedBox(height: 32),
                const Text(
                  'Réseaux sociaux',
                  style: TextStyle(color: AppColors.blanc, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSocialSection('instagram', Icons.camera_alt_outlined, s),
                const SizedBox(height: 12),
                _buildSocialSection('tiktok', Icons.music_note_outlined, s),
                const SizedBox(height: 12),
                _buildSocialSection('youtube', Icons.play_circle_outline, s),
              ],
              const SizedBox(height: 40),
              SpotbookButton.primary(
                label: 'Enregistrer',
                onPressed: _save,
                isLoading: s.isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientPhotosHeader(ClientProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo de couverture et avatar',
          style: TextStyle(
            color: AppColors.blanc,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Appuie sur la bannière ou sur l’avatar pour les remplacer.',
          style: TextStyle(color: AppColors.gris, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 148,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _pickClientCover(),
                    child: profile.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: profile.coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) =>
                                Container(color: AppColors.surfaceAlt),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.gris,
                              size: 40,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.gris,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: -32,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _pickClientAvatar(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.violet, width: 2),
                        color: AppColors.surfaceAlt,
                      ),
                      child: ClipOval(
                        child: profile.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: profile.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AppColors.surface),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: AppColors.gris,
                                  size: 36,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: AppColors.gris,
                                size: 36,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
      ],
    );
  }

  Future<void> _pickClientCover() async {
    HapticFeedback.lightImpact();
    final source = await showSpotbookBottomSheet<ImageSource>(
      context: context,
      title: 'Couverture',
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.blanc),
              title: const Text('Prendre une photo',
                  style: TextStyle(color: AppColors.blanc)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: AppColors.blanc),
              title: const Text('Galerie',
                  style: TextStyle(color: AppColors.blanc)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 92);
    if (picked == null || !mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer',
          toolbarColor: AppColors.surface,
          activeControlsWidgetColor: AppColors.blanc,
          dimmedLayerColor: AppColors.overlayPicker,
        ),
        IOSUiSettings(title: 'Recadrer'),
      ],
    );
    if (cropped == null || !mounted) return;
    final bytes = await File(cropped.path).readAsBytes();
    try {
      await ref.read(profileRepositoryProvider).uploadCover(bytes, 'jpg');
      ref.invalidate(clientProfileScreenDataProvider(''));
      ref.invalidate(editProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec du téléversement'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickClientAvatar() async {
    HapticFeedback.lightImpact();
    final source = await showSpotbookBottomSheet<ImageSource>(
      context: context,
      title: 'Photo de profil',
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.blanc),
              title: const Text('Prendre une photo',
                  style: TextStyle(color: AppColors.blanc)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: AppColors.blanc),
              title: const Text('Galerie',
                  style: TextStyle(color: AppColors.blanc)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 92);
    if (picked == null || !mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer',
          toolbarColor: AppColors.surface,
          activeControlsWidgetColor: AppColors.blanc,
          dimmedLayerColor: AppColors.overlayPicker,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(title: 'Recadrer', cropStyle: CropStyle.circle),
      ],
    );
    if (cropped == null || !mounted) return;
    final bytes = await File(cropped.path).readAsBytes();
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(bytes, 'jpg');
      ref.invalidate(clientProfileScreenDataProvider(''));
      ref.invalidate(editProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec du téléversement'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.gris, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.blanc),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(String platform, IconData icon, EditProfileState s) {
    final conn = s.proProfile?.socialConnections.where((e) => e.platform == platform).firstOrNull;
    final isConnected = conn != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isConnected ? AppColors.success.withAlpha(77) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: isConnected ? AppColors.success : AppColors.blanc, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform.toUpperCase(),
                  style: const TextStyle(color: AppColors.blanc, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (isConnected)
                  Text(
                    '@${conn.handle} • ${conn.followersCount} followers',
                    style: const TextStyle(color: AppColors.gris, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (isConnected)
            TextButton(
              onPressed: () => _disconnectSocial(platform),
              child: const Text('Déconnecter', style: TextStyle(color: AppColors.error)),
            )
          else
            TextButton(
              onPressed: () => _linkSocial(platform),
              child: const Text('Lier', style: TextStyle(color: AppColors.blanc)),
            ),
        ],
      ),
    );
  }
}
