import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';

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
  bool _isLoading = true;
  bool _isSaving = false;
  ProProfile? _proProfile;
  ClientProfile? _clientProfile;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final role = Supabase.instance.client.auth.currentUser?.userMetadata?['role'];
      _isPro = role == 'pro';
      final uid = repo.currentUserId;
      if (uid == null) return;

      if (_isPro) {
        _proProfile = await repo.getProProfile(uid);
        _nameCtrl.text = _proProfile!.businessName;
        _usernameCtrl.text = _proProfile!.username ?? '';
        _bioCtrl.text = _proProfile!.bio ?? '';
        _cityCtrl.text = _proProfile!.city ?? '';
      } else {
        _clientProfile = await repo.getClientProfile(uid);
        _nameCtrl.text = _clientProfile!.fullName;
        _usernameCtrl.text = _clientProfile!.username ?? '';
        _cityCtrl.text = _clientProfile!.city ?? '';
      }
    } catch (_) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _linkSocial(String platform) async {
    // Mocking OAuth flow
    try {
      final res = await Supabase.instance.client.functions.invoke('link-$platform', body: {'code': 'mock_code'});
      if (res.status == 200) {
        await _loadProfile(); // Reload to get new connections
      }
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
      await ref.read(profileRepositoryProvider).disconnectSocial(platform);
      await _loadProfile();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
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
              _buildTextField('City', _cityCtrl),
              if (_isPro) ...[
                const SizedBox(height: 16),
                _buildTextField('Bio', _bioCtrl, maxLines: 3),
                const SizedBox(height: 32),
                const Text(
                  'Social Connections',
                  style: TextStyle(color: AppColors.blanc, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSocialSection('instagram', Icons.camera_alt_outlined),
                const SizedBox(height: 12),
                _buildSocialSection('tiktok', Icons.music_note_outlined),
                const SizedBox(height: 12),
                _buildSocialSection('youtube', Icons.play_circle_outline),
              ],
              const SizedBox(height: 40),
              SpotbookButton.primary(
                label: 'Save Changes',
                onPressed: _save,
                isLoading: _isSaving,
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

  Widget _buildSocialSection(String platform, IconData icon) {
    final conn = _proProfile?.socialConnections.where((e) => e.platform == platform).firstOrNull;
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
              child: const Text('Link', style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
    );
  }
}
