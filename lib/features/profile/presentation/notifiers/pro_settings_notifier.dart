import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/provider_settings_repository.dart';

final proSettingsProvider =
    AsyncNotifierProvider<ProSettingsNotifier, ProSettingsSnapshot>(
  ProSettingsNotifier.new,
);

class ProSettingsNotifier extends AsyncNotifier<ProSettingsSnapshot> {
  @override
  Future<ProSettingsSnapshot> build() async {
    return ref.read(providerSettingsRepositoryProvider).fetchSnapshot();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(providerSettingsRepositoryProvider).fetchSnapshot(),
    );
  }

  Future<void> patchSettings(Map<String, dynamic> patch) async {
    final prev = state.value;
    if (prev == null) return;
    await ref.read(providerSettingsRepositoryProvider).upsertProviderSettings(patch);
    state = AsyncValue.data(_mergeSnapshot(prev, patch));
  }

  Future<void> patchProfilePro(Map<String, dynamic> patch) async {
    final prev = state.value;
    if (prev == null) return;
    await ref.read(providerSettingsRepositoryProvider).updateProfilePro(patch);
    state = AsyncValue.data(_mergePro(prev, patch));
  }

  ProSettingsSnapshot _mergeSnapshot(
    ProSettingsSnapshot s,
    Map<String, dynamic> p,
  ) {
    return ProSettingsSnapshot(
      email: s.email,
      phone: s.phone,
      cancellationPolicy:
          p['cancellation_policy'] as String? ?? s.cancellationPolicy,
      minAdvanceHours: p['min_advance_hours'] as int? ?? s.minAdvanceHours,
      minGapMinutes: p['min_gap_minutes'] as int? ?? s.minGapMinutes,
      maxBookingsPerDay:
          p['max_bookings_per_day'] as int? ?? s.maxBookingsPerDay,
      isPublic: s.isPublic,
      searchVisible: s.searchVisible,
      stripeOnboarded: s.stripeOnboarded,
      stripeAccountId: s.stripeAccountId,
      kycStatus: s.kycStatus,
      stripePayoutLast4: s.stripePayoutLast4,
    );
  }

  ProSettingsSnapshot _mergePro(
    ProSettingsSnapshot s,
    Map<String, dynamic> p,
  ) {
    return ProSettingsSnapshot(
      email: s.email,
      phone: p['tel'] as String? ?? s.phone,
      cancellationPolicy: s.cancellationPolicy,
      minAdvanceHours: s.minAdvanceHours,
      minGapMinutes: s.minGapMinutes,
      maxBookingsPerDay: s.maxBookingsPerDay,
      isPublic: p['is_public'] as bool? ?? s.isPublic,
      searchVisible: p['search_visible'] as bool? ?? s.searchVisible,
      stripeOnboarded: s.stripeOnboarded,
      stripeAccountId: s.stripeAccountId,
      kycStatus: s.kycStatus,
      stripePayoutLast4: s.stripePayoutLast4,
    );
  }
}
