import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/pro_scheduling_repository.dart';
import '../../domain/booking_models.dart';

// ─── Services (tarifs & prestations) ─────────────────────────────────────────

final proServicesNotifierProvider =
    NotifierProvider<ProServicesNotifier, ProServicesState>(
  ProServicesNotifier.new,
  isAutoDispose: true,
);

class ProServicesState {
  const ProServicesState({
    this.services = const [],
    this.loading = true,
    this.error,
    this.saving = false,
  });

  final List<ServiceModel> services;
  final bool loading;
  final String? error;
  final bool saving;

  ProServicesState copyWith({
    List<ServiceModel>? services,
    bool? loading,
    String? error,
    bool? saving,
  }) =>
      ProServicesState(
        services: services ?? this.services,
        loading: loading ?? this.loading,
        error: error,
        saving: saving ?? this.saving,
      );
}

class ProServicesNotifier extends Notifier<ProServicesState> {
  @override
  ProServicesState build() {
    Future.microtask(_load);
    return const ProServicesState();
  }

  ProSchedulingRepository get _repo => ref.read(proSchedulingRepositoryProvider);

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      state = state.copyWith(loading: false, services: [], error: 'Non connecté');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _repo.fetchAllServices(uid);
      state = state.copyWith(services: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<bool> createService({
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
    double depositPercentage = 0.30,
    String paymentMode = 'full',
    String? depositType,
    double? depositValue,
  }) async {
    state = state.copyWith(saving: true, error: null);
    try {
      await _repo.createService(
        name: name,
        description: description,
        durationMinutes: durationMinutes,
        price: price,
        depositPercentage: depositPercentage,
        paymentMode: paymentMode,
        depositType: depositType,
        depositValue: depositValue,
      );
      await _load();
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateService(ServiceModel s, {
    required String name,
    String? description,
    required int durationMinutes,
    required double price,
    required bool isActive,
    double depositPercentage = 0.30,
    String paymentMode = 'full',
    String? depositType,
    double? depositValue,
  }) async {
    state = state.copyWith(saving: true, error: null);
    try {
      await _repo.updateService(
        id: s.id,
        name: name,
        description: description,
        durationMinutes: durationMinutes,
        price: price,
        isActive: isActive,
        depositPercentage: depositPercentage,
        paymentMode: paymentMode,
        depositType: depositType,
        depositValue: depositValue,
      );
      await _load();
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  Future<void> toggleActive(ServiceModel s) async {
    try {
      await _repo.setServiceActive(s.id, !s.isActive);
      await _load();
    } catch (_) {}
  }
}

// ─── Disponibilités (règles + créneaux) ──────────────────────────────────────

final proAvailabilityNotifierProvider =
    NotifierProvider<ProAvailabilityNotifier, ProAvailabilityState>(
  ProAvailabilityNotifier.new,
  isAutoDispose: true,
);

class ProAvailabilityState {
  const ProAvailabilityState({
    this.rules = const [],
    this.slotsForSelectedDate = const [],
    this.selectedDate,
    this.loading = true,
    this.syncing = false,
    this.error,
  });

  final List<AvailabilityRuleModel> rules;
  final List<TimeSlotModel> slotsForSelectedDate;
  final DateTime? selectedDate;
  final bool loading;
  final bool syncing;
  final String? error;

  ProAvailabilityState copyWith({
    List<AvailabilityRuleModel>? rules,
    List<TimeSlotModel>? slotsForSelectedDate,
    DateTime? selectedDate,
    bool? loading,
    bool? syncing,
    String? error,
  }) =>
      ProAvailabilityState(
        rules: rules ?? this.rules,
        slotsForSelectedDate: slotsForSelectedDate ?? this.slotsForSelectedDate,
        selectedDate: selectedDate ?? this.selectedDate,
        loading: loading ?? this.loading,
        syncing: syncing ?? this.syncing,
        error: error,
      );
}

class ProAvailabilityNotifier extends Notifier<ProAvailabilityState> {
  @override
  ProAvailabilityState build() {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    Future.microtask(() => load(initialDate: day));
    return ProAvailabilityState(selectedDate: day);
  }

  ProSchedulingRepository get _repo => ref.read(proSchedulingRepositoryProvider);

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load({DateTime? initialDate}) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final date = initialDate ?? state.selectedDate ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);

    if (uid == null) {
      state = state.copyWith(loading: false, error: 'Non connecté');
      return;
    }

    state = state.copyWith(loading: true, error: null, selectedDate: day);
    try {
      final rules = await _repo.fetchAvailabilityRules(uid);
      final slots = await _repo.fetchTimeSlotsForDate(uid, _fmt(day));
      state = state.copyWith(
        rules: rules,
        slotsForSelectedDate: slots,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> selectDate(DateTime d) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final day = DateTime(d.year, d.month, d.day);
    if (uid == null) return;
    state = state.copyWith(selectedDate: day, loading: true, error: null);
    try {
      final slots = await _repo.fetchTimeSlotsForDate(uid, _fmt(day));
      state = state.copyWith(slotsForSelectedDate: slots, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> addRule({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDurationMinutes,
  }) async {
    try {
      await _repo.addAvailabilityRule(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        slotDurationMinutes: slotDurationMinutes,
      );
      await load(initialDate: state.selectedDate);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> deleteRule(String id) async {
    try {
      await _repo.deleteAvailabilityRule(id);
      await load(initialDate: state.selectedDate);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<int?> syncSlots() async {
    state = state.copyWith(syncing: true, error: null);
    try {
      final n = await _repo.syncTimeSlotsFromRules();
      await load(initialDate: state.selectedDate);
      state = state.copyWith(syncing: false);
      return n;
    } catch (e) {
      state = state.copyWith(syncing: false, error: e.toString());
      return null;
    }
  }

  Future<void> toggleSlot(TimeSlotModel slot) async {
    try {
      await _repo.setSlotAvailable(slot.id, !slot.isAvailable);
      await selectDate(state.selectedDate!);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
