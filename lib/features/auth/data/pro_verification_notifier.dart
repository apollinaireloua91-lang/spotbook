import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_repository.dart';

class ProVerificationState {
  const ProVerificationState({
    this.isUploading = false,
    this.documentName,
    this.isSubmitting = false,
  });
  final bool isUploading;
  final String? documentName;
  final bool isSubmitting;

  ProVerificationState copyWith({
    bool? isUploading,
    String? documentName,
    bool? isSubmitting,
    bool clearDoc = false,
  }) =>
      ProVerificationState(
        isUploading: isUploading ?? this.isUploading,
        documentName: clearDoc ? null : (documentName ?? this.documentName),
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class ProVerificationNotifier extends Notifier<ProVerificationState> {
  @override
  ProVerificationState build() => const ProVerificationState();

  Future<void> pickAndUploadDocument() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 90,
    );
    if (image == null) return;

    state = state.copyWith(isUploading: true);
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      await ref.read(profileRepositoryProvider).uploadKycDocument(bytes, ext);
      state = state.copyWith(isUploading: false, documentName: image.name);
    } catch (e) {
      state = state.copyWith(isUploading: false);
      rethrow;
    }
  }

  Future<void> submit(String phone) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ref.read(profileRepositoryProvider).submitKycVerification(phone);
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final proVerificationProvider =
    NotifierProvider<ProVerificationNotifier, ProVerificationState>(
  ProVerificationNotifier.new,
  isAutoDispose: true,
);
