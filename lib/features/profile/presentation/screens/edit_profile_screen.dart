import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/edit_profile_notifier.dart';

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
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
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
    try {
      await ref.read(editProfileProvider.notifier).linkSocial(platform);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to link account'), backgroundColor: AppColors.error),
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
        title: const Text('Edit Profile'),
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
              _buildTextField('Name', _nameCtrl),
              const SizedBox(height: 16),
              _buildTextField('Username', _usernameCtrl),
              const SizedBox(height: 16),
              AddressAutocompleteField(
                controller: _cityCtrl,
                label: 'City',
                icon: Icons.location_city,
                fillColor: AppColors.surface,
              ),
              if (s.isPro) ...[
                const SizedBox(height: 16),
                _buildTextField('Bio', _bioCtrl, maxLines: 3),
                const SizedBox(height: 32),
                const Text(
                  'Social Connections',
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
                label: 'Save Changes',
                onPressed: _save,
                isLoading: s.isSaving,
              ),
            ],
          ),
        ),
      ),
    );
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
              child: const Text('Disconnect', style: TextStyle(color: AppColors.error)),
            )
          else
            TextButton(
              onPressed: () => _linkSocial(platform),
              child: const Text('Link', style: TextStyle(color: AppColors.blanc)),
            ),
        ],
      ),
    );
  }
}
