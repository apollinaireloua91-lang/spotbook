import 'package:flutter/material.dart';

// ─── Slot within a day ────────────────────────────────────────────────────────

class DaySlot {
  DaySlot({
    required this.tempId,
    required this.slotIndex,
    required this.startTime,
    required this.endTime,
  });

  final String tempId;
  int slotIndex;
  TimeOfDay startTime;
  TimeOfDay endTime;

  DaySlot copyWith({TimeOfDay? startTime, TimeOfDay? endTime}) => DaySlot(
        tempId: tempId,
        slotIndex: slotIndex,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;
  bool get isValid => endMinutes > startMinutes;
}

// ─── Day rule ─────────────────────────────────────────────────────────────────

class DayRule {
  DayRule({
    required this.dayOfWeek,
    required this.isActive,
    required this.slots,
  });

  final int dayOfWeek; // 0 = Lundi … 6 = Dimanche
  bool isActive;
  List<DaySlot> slots;

  DayRule copyWith({bool? isActive, List<DaySlot>? slots}) => DayRule(
        dayOfWeek: dayOfWeek,
        isActive: isActive ?? this.isActive,
        slots: slots != null ? List<DaySlot>.from(slots) : List<DaySlot>.from(this.slots),
      );

  static String dayName(int dow) {
    const names = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return names[dow.clamp(0, 6)];
  }

  static String dayShort(int dow) {
    const names = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
    return names[dow.clamp(0, 6)];
  }
}

// ─── Blocked date ─────────────────────────────────────────────────────────────

class BlockedDate {
  const BlockedDate({required this.id, required this.date, this.reason});
  final String id;
  final DateTime date;
  final String? reason;
}

// ─── Settings ─────────────────────────────────────────────────────────────────

class AvailabilitySettings {
  const AvailabilitySettings({
    this.minGapMinutes = 15,
    this.maxBookingsPerDay = 10,
    this.acceptsBookings = true,
    this.minAdvanceHours = 2,
  });

  final int minGapMinutes;
  final int maxBookingsPerDay;
  final bool acceptsBookings;
  final int minAdvanceHours;

  AvailabilitySettings copyWith({
    int? minGapMinutes,
    int? maxBookingsPerDay,
    bool? acceptsBookings,
    int? minAdvanceHours,
  }) =>
      AvailabilitySettings(
        minGapMinutes: minGapMinutes ?? this.minGapMinutes,
        maxBookingsPerDay: maxBookingsPerDay ?? this.maxBookingsPerDay,
        acceptsBookings: acceptsBookings ?? this.acceptsBookings,
        minAdvanceHours: minAdvanceHours ?? this.minAdvanceHours,
      );
}

// ─── Screen state ─────────────────────────────────────────────────────────────

class AvailabilityState {
  const AvailabilityState({
    this.isSaving = false,
    this.weekRules = const [],
    this.blockedDates = const [],
    this.settings = const AvailabilitySettings(),
    this.hasUnsavedChanges = false,
    this.error,
  });

  final bool isSaving;
  final List<DayRule> weekRules;
  final List<BlockedDate> blockedDates;
  final AvailabilitySettings settings;
  final bool hasUnsavedChanges;
  final String? error;

  AvailabilityState copyWith({
    bool? isSaving,
    List<DayRule>? weekRules,
    List<BlockedDate>? blockedDates,
    AvailabilitySettings? settings,
    bool? hasUnsavedChanges,
    Object? error = _sentinel,
  }) {
    return AvailabilityState(
      isSaving: isSaving ?? this.isSaving,
      weekRules: weekRules ?? this.weekRules,
      blockedDates: blockedDates ?? this.blockedDates,
      settings: settings ?? this.settings,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();
