import "package:flutter_riverpod/flutter_riverpod.dart";

import "moderation_repository.dart";

class ReportState {
  const ReportState({this.selectedReason, this.isSubmitting = false});

  final String? selectedReason;
  final bool isSubmitting;

  ReportState copyWith({String? selectedReason, bool? isSubmitting}) {
    return ReportState(
      selectedReason: selectedReason ?? this.selectedReason,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ReportNotifier extends AsyncNotifier<ReportState> {
  @override
  Future<ReportState> build() async => const ReportState();

  void selectReason(String reason) {
    final current = state.asData?.value ?? const ReportState();
    state = AsyncValue.data(current.copyWith(selectedReason: reason));
  }

  Future<void> submitReport({
    required String targetId,
    required String targetType,
  }) async {
    final current = state.asData?.value ?? const ReportState();
    final reason = current.selectedReason;
    if (reason == null || current.isSubmitting) return;

    state = AsyncValue.data(current.copyWith(isSubmitting: true));
    try {
      await ref.read(moderationRepositoryProvider).report(
            targetId: targetId,
            targetType: targetType,
            reason: reason,
          );
      state = AsyncValue.data(current.copyWith(isSubmitting: false));
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}

final reportNotifierProvider =
    AsyncNotifierProvider<ReportNotifier, ReportState>(
  ReportNotifier.new,
);
