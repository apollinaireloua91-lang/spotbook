import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_snackbar.dart';
import '../../data/edit_profile_notifier.dart';
import '../../data/profile_repository.dart';

// ─── Social platform config ──────────────────────────────
class _SocialPlatform {
  const _SocialPlatform({
    required this.key,
    required this.label,
    required this.icon,
    required this.placeholder,
    this.urlPattern,
  });

  final String key;
  final String label;
  final IconData icon;
  final String placeholder;
  final RegExp? urlPattern;
}

final _socialPlatforms = [
  _SocialPlatform(
    key: 'instagram',
    label: 'Instagram',
    icon: Icons.camera_alt_outlined,
    placeholder: 'https://instagram.com/your_profile',
    urlPattern: RegExp(r'instagram\.com'),
  ),
  _SocialPlatform(
    key: 'tiktok',
    label: 'TikTok',
    icon: Icons.music_note_outlined,
    placeholder: 'https://tiktok.com/@your_profile',
    urlPattern: RegExp(r'tiktok\.com'),
  ),
  _SocialPlatform(
    key: 'youtube',
    label: 'YouTube',
    icon: Icons.play_circle_outline,
    placeholder: 'https://youtube.com/@your_channel',
    urlPattern: RegExp(r'youtube\.com|youtu\.be'),
  ),
  _SocialPlatform(
    key: 'snapchat',
    label: 'Snapchat',
    icon: Icons.photo_camera_front_outlined,
    placeholder: 'https://snapchat.com/add/your_snap',
    urlPattern: RegExp(r'snapchat\.com'),
  ),
  _SocialPlatform(
    key: 'twitter',
    label: 'X / Twitter',
    icon: Icons.alternate_email,
    placeholder: 'https://x.com/your_profile',
    urlPattern: RegExp(r'twitter\.com|x\.com'),
  ),
  _SocialPlatform(
    key: 'website',
    label: 'Website',
    icon: Icons.language,
    placeholder: 'https://your-site.com',
  ),
  _SocialPlatform(
    key: 'spotify',
    label: 'Spotify',
    icon: Icons.headphones_outlined,
    placeholder: 'https://open.spotify.com/artist/...',
    urlPattern: RegExp(r'spotify\.com'),
  ),
];

// ═══════════════════════════════════════════════════════════
// EDIT PROFILE SCREEN
// ═══════════════════════════════════════════════════════════

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final Map<String, TextEditingController> _socialCtrls = {};
  bool _controllersInitialized = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  // Username uniqueness check
  Timer? _usernameDebounce;
  String? _usernameError;
  bool _isCheckingUsername = false;

  @override
  void initState() {
    super.initState();
    for (final p in _socialPlatforms) {
      _socialCtrls[p.key] = TextEditingController();
    }
    _usernameCtrl.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _addressCtrl.dispose();
    for (final c in _socialCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameError = username.isNotEmpty ? 'Min. 3 caractères' : null;
        _isCheckingUsername = false;
      });
      return;
    }
    if (!_usernameRegex.hasMatch(username)) {
      setState(() {
        _usernameError = 'Lettres, chiffres et _ uniquement (3-20 car.)';
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final supabase = Supabase.instance.client;
        final uid = supabase.auth.currentUser?.id;
        final result = await supabase
            .from('users')
            .select('id')
            .eq('username', username)
            .neq('id', uid ?? '')
            .maybeSingle();

        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _usernameError = result != null ? 'Ce nom est déjà pris' : null;
        });
      } catch (_) {
        if (mounted) {
          setState(() => _isCheckingUsername = false);
        }
      }
    });
  }

  void _initControllers(EditProfileState s) {
    if (_controllersInitialized || s.isLoading) return;
    _controllersInitialized = true;
    if (s.isPro && s.proProfile != null) {
      _nameCtrl.text = s.proProfile!.businessName;
      _usernameCtrl.text = s.proProfile!.username ?? '';
      _bioCtrl.text = s.proProfile!.bio ?? '';
      _addressCtrl.text = s.proProfile!.city ?? '';
      _avatarUrl = s.proProfile!.avatarUrl;
      for (final conn in s.proProfile!.socialConnections) {
        _socialCtrls[conn.platform]?.text = conn.handle;
      }
    } else if (s.clientProfile != null) {
      _nameCtrl.text = s.clientProfile!.fullName;
      _usernameCtrl.text = s.clientProfile!.username ?? '';
      _addressCtrl.text = s.clientProfile!.city ?? '';
      _avatarUrl = s.clientProfile!.avatarUrl;
    }
  }

  Future<void> _pickAvatar() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await image.readAsBytes();
      final ext = image.path.split('.').last;
      final repo = ref.read(profileRepositoryProvider);
      final url = await repo.uploadAvatar(bytes, ext);
      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _isUploadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        showSpotbookSnackBar(context,
            message: 'Photo upload error', type: SnackType.error);
      }
    }
  }

  Future<void> _save() async {
    if (_usernameError != null) return;
    HapticFeedback.mediumImpact();
    try {
      await ref.read(editProfileProvider.notifier).saveProfile(
            fullName: _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            city: _addressCtrl.text.trim(),
          );

      // Save social links (pro only)
      final s = ref.read(editProfileProvider);
      if (s.isPro) {
        final notifier = ref.read(editProfileProvider.notifier);
        for (final p in _socialPlatforms) {
          final value = _socialCtrls[p.key]?.text.trim() ?? '';
          final existing = s.proProfile?.socialConnections
              .where((c) => c.platform == p.key)
              .firstOrNull;
          final existingHandle = existing?.handle ?? '';
          if (value != existingHandle) {
            await notifier.saveSocialLink(platform: p.key, handle: value);
          }
        }
      }

      if (!mounted) return;
      showSpotbookSnackBar(context,
          message: 'Profile updated', type: SnackType.success);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showSpotbookSnackBar(context,
          message: 'Erreur : ${e.toString()}', type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(editProfileProvider);
    _initControllers(s);

    if (s.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.blanc)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit profile',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Avatar with photo picker ───
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.violet,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.surfaceAlt,
                          backgroundImage: _avatarUrl != null
                              ? CachedNetworkImageProvider(_avatarUrl!)
                              : null,
                          child: _isUploadingAvatar
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.blanc,
                                )
                              : _avatarUrl == null
                                  ? Icon(Icons.person,
                                      size: 40, color: AppColors.gris)
                                  : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.violet,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.fond,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.blanc,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Change photo',
                  style: GoogleFonts.dmSans(
                    color: AppColors.violetClair,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Name ───
              _buildTextField('Display name', _nameCtrl),

              const SizedBox(height: 16),

              // ─── Username with uniqueness check ───
              _buildLabel('Username'),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameCtrl,
                style: TextStyle(color: AppColors.blanc, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixText: '@',
                  prefixStyle: TextStyle(
                    color: AppColors.gris,
                    fontSize: 15,
                  ),
                  suffixIcon: _isCheckingUsername
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gris,
                            ),
                          ),
                        )
                      : _usernameError == null &&
                              _usernameCtrl.text.trim().length >= 3
                          ? Icon(Icons.check_circle,
                              color: AppColors.success, size: 20)
                          : null,
                  errorText: _usernameError,
                  errorStyle: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _usernameError != null
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _usernameError != null
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _usernameError != null
                          ? AppColors.error
                          : AppColors.violet,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Bio (for all users) ───
              _buildLabel('Bio'),
              const SizedBox(height: 8),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 160,
                style: TextStyle(color: AppColors.blanc, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Describe yourself in a few words...',
                  hintStyle: TextStyle(
                    color: AppColors.gris.withAlpha(120),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  counterStyle: TextStyle(color: AppColors.gris),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.violet),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Address with Google Places autocomplete ───
              _buildLabel('Location'),
              const SizedBox(height: 8),
              AddressAutocompleteField(
                controller: _addressCtrl,
                label: '',
                hint: 'Your city or address',
                icon: Icons.location_on_outlined,
                fillColor: AppColors.surface,
              ),

              // ─── Social links (pro only) ───
              if (s.isPro) ...[
                const SizedBox(height: 32),
                Text(
                  'SOCIAL LINKS',
                  style: GoogleFonts.sora(
                    color: AppColors.gris,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste a link and the platform will be auto-detected.',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                for (final p in _socialPlatforms) ...[
                  _SocialLinkField(
                    platform: p,
                    controller: _socialCtrls[p.key]!,
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              const SizedBox(height: 32),

              SpotbookButton.primary(
                label: 'Save',
                onPressed: _save,
                isLoading: s.isSaving,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        color: AppColors.gris,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.blanc, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.violet),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SOCIAL LINK FIELD
// ═══════════════════════════════════════════════════════════

class _SocialLinkField extends StatelessWidget {
  const _SocialLinkField({
    required this.platform,
    required this.controller,
  });

  final _SocialPlatform platform;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.blanc, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(platform.icon, color: AppColors.gris, size: 20),
        hintText: platform.placeholder,
        hintStyle: TextStyle(
          color: AppColors.gris.withAlpha(100),
          fontSize: 13,
        ),
        labelText: platform.label,
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.gris,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.violet),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear,
                    color: AppColors.gris, size: 18),
                onPressed: () => controller.clear(),
              )
            : null,
      ),
    );
  }
}
