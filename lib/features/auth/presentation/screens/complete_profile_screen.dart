import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/auth_repository.dart';

class _ProfileState {
  const _ProfileState({
    this.avatarUrl,
    this.isUploading = false,
    this.isSaving = false,
  });
  final String? avatarUrl;
  final bool isUploading;
  final bool isSaving;
  _ProfileState copyWith({
    String? avatarUrl,
    bool? isUploading,
    bool? isSaving,
    bool clearAvatar = false,
  }) =>
      _ProfileState(
        avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
        isUploading: isUploading ?? this.isUploading,
        isSaving: isSaving ?? this.isSaving,
      );
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

  Future<void> save({
    required String displayName,
    required String bio,
  }) async {
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

final _profileProvider = NotifierProvider<_ProfileNotifier, _ProfileState>(
  _ProfileNotifier.new,
  isAutoDispose: true,
);

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _checkController.forward();
    _displayNameCtrl.text =
        ref.read(authRepositoryProvider).currentUserFullName ?? '';
  }

  @override
  void dispose() {
    _checkController.dispose();
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;
    try {
      await ref.read(_profileProvider.notifier).uploadAvatar(image);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(_profileProvider.notifier).save(
            displayName: _displayNameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          );
      if (!mounted) return;
      _navigateNext();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Save failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateNext() {
    final role = ref.read(_profileProvider.notifier).userRole ?? 'client';
    context.go(role == 'pro' ? '/pro/business-details' : '/client/interests');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_profileProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Animated check
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientAccent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(40),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.blanc,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Account created!',
                style: GoogleFonts.sora(
                  color: AppColors.violet,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Complete your profile',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a photo and bio so pros know who they\'re working with.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Avatar picker
              GestureDetector(
                onTap: s.isUploading ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surface,
                      backgroundImage: s.avatarUrl != null
                          ? NetworkImage(s.avatarUrl!)
                          : null,
                      child: s.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.gris,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.gradientAccent,
                        ),
                        child: s.isUploading
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.blanc,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: AppColors.blanc,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Display Name
              TextField(
                controller: _displayNameCtrl,
                style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Full name',
                  hintStyle: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.gris,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.violet),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              TextField(
                controller: _bioCtrl,
                style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Bio — tell us a bit about yourself...',
                  hintStyle: GoogleFonts.dmSans(
                    color: AppColors.gris.withAlpha(128),
                    fontSize: 15,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.gris,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.violet),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppColors.gradientAccent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(30),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: s.isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.blanc,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: AppColors.blanc.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: s.isSaving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.blanc,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Skip
              GestureDetector(
                onTap: _navigateNext,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
                  ),
                ),
              ),
              SizedBox(height: bottomPadding + 24),
            ],
          ),
        ),
      ),
    );
  }
}
