import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/availability_models.dart';
import 'availability_repository.dart';

class AvailabilityNotifier extends AsyncNotifier<AvailabilityState> {
  AvailabilityRepository get _repo => ref.read(availabilityRepositoryProvider);

  @override
  Future<AvailabilityState> build() => _repo.load();

  // ─── Master toggle (immediate save) ─────────────────────────────────────────

  Future<void> toggleAcceptBookings(bool value) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      settings: current.settings.copyWith(acceptsBookings: value),
    ));
    try {
      await _repo.toggleAcceptBookings(value);
    } catch (e) {
      state = AsyncData(current.copyWith(
        settings: current.settings.copyWith(acceptsBookings: !value),
        error: e.toString(),
      ));
    }
  }

  // ─── Day toggle ──────────────────────────────────────────────────────────────

  void toggleDay(int dayOfWeek, bool isActive) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      weekRules: current.weekRules.map((r) {
        if (r.dayOfWeek != dayOfWeek) return r;
        return r.copyWith(isActive: isActive);
      }).toList(),
      hasUnsavedChanges: true,
      error: null,
    ));
  }

  // ─── Slot management ─────────────────────────────────────────────────────────

  /// Returns the newly created slot for the caller to animate it in.
  DaySlot addSlot(int dayOfWeek) {
    final current = state.value;
    final existingSlots = current?.weekRules
            .firstWhere((r) => r.dayOfWeek == dayOfWeek,
                orElse: () =>
                    DayRule(dayOfWeek: dayOfWeek, isActive: true, slots: []))
            .slots ??
        [];

    final newSlot = DaySlot(
      tempId: 'new_${dayOfWeek}_${DateTime.now().millisecondsSinceEpoch}',
      slotIndex: existingSlots.length,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 0),
    );

    if (current != null) {
      state = AsyncData(current.copyWith(
        weekRules: current.weekRules.map((r) {
          if (r.dayOfWeek != dayOfWeek) return r;
          return r.copyWith(slots: [...r.slots, newSlot]);
        }).toList(),
        hasUnsavedChanges: true,
        error: null,
      ));
    }

    return newSlot;
  }

  void removeSlot(int dayOfWeek, String tempId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      weekRules: current.weekRules.map((r) {
        if (r.dayOfWeek != dayOfWeek) return r;
        return r.copyWith(
          slots: r.slots.where((s) => s.tempId != tempId).toList(),
        );
      }).toList(),
      hasUnsavedChanges: true,
      error: null,
    ));
  }

  void updateSlotTime(
    int dayOfWeek,
    String tempId,
    TimeOfDay? start,
    TimeOfDay? end,
  ) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      weekRules: current.weekRules.map((r) {
        if (r.dayOfWeek != dayOfWeek) return r;
        return r.copyWith(
          slots: r.slots.map((s) {
            if (s.tempId != tempId) return s;
            return s.copyWith(
              startTime: start ?? s.startTime,
              endTime: end ?? s.endTime,
            );
          }).toList(),
        );
      }).toList(),
      hasUnsavedChanges: true,
      error: null,
    ));
  }

  // ─── Blocked dates (immediate save) ──────────────────────────────────────────

  Future<void> toggleBlockedDate(DateTime date) async {
    final current = state.value;
    if (current == null) return;

    final wasBlocked = current.blockedDates.any((d) => _sameDay(d.date, date));

    // Optimistic update
    final optimistic = wasBlocked
        ? current.blockedDates
            .where((d) => !_sameDay(d.date, date))
            .toList()
        : [
            ...current.blockedDates,
            BlockedDate(
              id: 'temp_${date.millisecondsSinceEpoch}',
              date: date,
            ),
          ];

    state = AsyncData(current.copyWith(blockedDates: optimistic));

    try {
      await _repo.toggleBlockedDate(date, current.blockedDates);
      // Reload to get real IDs from DB
      final fresh = await _repo.loadBlockedDates();
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(blockedDates: fresh));
      }
    } catch (e) {
      // Revert on error
      state = AsyncData(current.copyWith(error: e.toString()));
    }
  }

  // ─── Settings ────────────────────────────────────────────────────────────────

  void updateMinGap(int minutes) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      settings: current.settings.copyWith(minGapMinutes: minutes),
      hasUnsavedChanges: true,
      error: null,
    ));
  }

  void updateMaxBookings(int count) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      settings: current.settings.copyWith(
        maxBookingsPerDay: count.clamp(1, 50),
      ),
      hasUnsavedChanges: true,
      error: null,
    ));
  }

  void updateMinAdvanceHours(int hours) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      settings: current.settings.copyWith(minAdvanceHours: hours),
      hasUnsavedChanges: true,
      error: null,
    ));
  }

  // ─── Validation ──────────────────────────────────────────────────────────────

  String? validateRules() {
    final current = state.value;
    if (current == null) return null;

    for (final rule in current.weekRules) {
      if (!rule.isActive) continue;
      for (final slot in rule.slots) {
        if (!slot.isValid) {
          return 'Heure invalide pour ${DayRule.dayName(rule.dayOfWeek)} : l\'heure de fin doit être après le début.';
        }
      }
    }
    return null;
  }

  // ─── Save (weekly rules + settings) ─────────────────────────────────────────

  Future<void> save() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true, error: null));
    try {
      await Future.wait<void>([
        _repo.saveAvailability(current.weekRules),
        _repo.saveSettings(current.settings),
      ]);
      state = AsyncData(
        current.copyWith(isSaving: false, hasUnsavedChanges: false, error: null),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(isSaving: false, error: e.toString()));
      rethrow;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final availabilityProvider =
    AsyncNotifierProvider<AvailabilityNotifier, AvailabilityState>(
  AvailabilityNotifier.new,
);
