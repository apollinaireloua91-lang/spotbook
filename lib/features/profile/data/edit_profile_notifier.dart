import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_models.dart';
import 'profile_repository.dart';

class EditProfileState {
  const EditProfileState({
    this.isLoading = true,
    this.isSaving = false,
    this.isPro = false,
    this.proProfile,
    this.clientProfile,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isPro;
  final ProProfile? proProfile;
  final ClientProfile? clientProfile;

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isPro,
    ProProfile? proProfile,
    ClientProfile? clientProfile,
  }) =>
      EditProfileState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        isPro: isPro ?? this.isPro,
        proProfile: proProfile ?? this.proProfile,
        clientProfile: clientProfile ?? this.clientProfile,
      );
}

class EditProfileNotifier extends Notifier<EditProfileState> {
  @override
  EditProfileState build() {
    _loadProfile();
    return const EditProfileState();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final role = repo.currentUserRole;
      final isPro = role == 'pro';
      final uid = repo.currentUserId;
      if (uid == null) return;

      if (isPro) {
        final profile = await repo.getProProfile(uid);
        state = state.copyWith(
          isLoading: false,
          isPro: true,
          proProfile: profile,
        );
      } else {
        final profile = await repo.getClientProfile(uid);
        state = state.copyWith(
          isLoading: false,
          isPro: false,
          clientProfile: profile,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveProfile({
    required String fullName,
    required String username,
    required String bio,
    required String city,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: fullName,
            username: username,
            bio: bio,
            city: city,
          );
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<void> linkSocial(String platform) async {
    await ref.read(profileRepositoryProvider).linkSocial(platform);
    await _loadProfile();
  }

  Future<void> disconnectSocial(String platform) async {
    await ref.read(profileRepositoryProvider).disconnectSocial(platform);
    await _loadProfile();
  }

  Future<void> saveSocialLink({
    required String platform,
    required String handle,
  }) async {
    if (handle.trim().isEmpty) {
      await ref.read(profileRepositoryProvider).disconnectSocial(platform);
    } else {
      await ref.read(profileRepositoryProvider).saveSocialLink(
            platform: platform,
            handle: handle.trim(),
          );
    }
    await _loadProfile();
  }
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
  EditProfileNotifier.new,
  isAutoDispose: true,
);
