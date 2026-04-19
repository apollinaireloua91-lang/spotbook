import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../data/booking_notifier.dart';
import '../../../data/booking_repository.dart';

/// Step 2 — Month-grid calendar. Always visible.
///
/// A date is clickable if ALL these conditions hold:
///   - It's today or in the future (max +30 days from today)
///   - Its day-of-week is in the Pro's active availability_rules
///   - It's NOT in the Pro's blocked_dates or closed exceptions
///   - It has at least one available time_slot (fine-grained filter)
///
/// Rationale: fetching BOTH weekday rules AND time_slots gives us a robust
/// calendar that stays visible even when the generator hasn't run yet (Pro
/// just saved new hours), while still reflecting real booking capacity.
class Step2Date extends ConsumerStatefulWidget {
  const Step2Date({
    super.key,
    required this.notifier,
    required this.state,
  });

  final BookingFlowNotifier notifier;
  final BookingFlowState state;

  @override
  ConsumerState<Step2Date> createState() => _Step2DateState();
}

class _Step2DateState extends ConsumerState<Step2Date> {
  Set<int> _activeWeekdays = const {};
  Set<String> _blockedDates = const {};
  Set<String> _datesWithSlots = const {};
  bool _loading = true;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _loadAll();
  }

  String? get _proId {
    // The first service in the cart holds pro_id indirectly via services list.
    // We rely on the parent state's services list to get proId from the first service's owner.
    final services = widget.state.services;
    if (services.isEmpty) return null;
    return services.first.proId;
  }

  Future<void> _loadAll() async {
    final proId = _proId;
    if (proId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final results = await Future.wait([
        repo.getProActiveWeekdays(proId),
        repo.getProBlockedDates(proId),
        repo.getAvailableDates(proId),
        Future.value(null), // spacer
      ]);
      if (!mounted) return;
      setState(() {
        _activeWeekdays = results[0] as Set<int>;
        _blockedDates = results[1] as Set<String>;
        _datesWithSlots = Set<String>.from(results[2] as List<String>);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isClickable(DateTime date) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayDate)) return false;
    final maxDate = todayDate.add(const Duration(days: 30));
    if (date.isAfter(maxDate)) return false;

    // Check weekday (JS convention: 0=Sunday)
    final dowJs = date.weekday == 7 ? 0 : date.weekday; // Dart: 1=Mon..7=Sun
    if (!_activeWeekdays.contains(dowJs)) return false;

    final iso = _toIso(date);
    if (_blockedDates.contains(iso)) return false;

    // If we have slot data loaded, require at least one available slot.
    // Otherwise (generator hasn't run yet but rules exist), trust the weekday.
    if (_datesWithSlots.isNotEmpty && !_datesWithSlots.contains(iso)) {
      return false;
    }
    return true;
  }

  String _toIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _changeMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final now = DateTime.now();
    // Prevent going before current month or too far in the future
    final thisMonth = DateTime(now.year, now.month);
    final maxMonth = DateTime(now.year, now.month + 1); // allow current + next
    if (next.isBefore(thisMonth)) return;
    if (next.isAfter(maxMonth)) return;
    HapticFeedback.lightImpact();
    setState(() => _visibleMonth = next);
  }

  void _selectDate(DateTime date) {
    if (!_isClickable(date)) return;
    HapticFeedback.selectionClick();
    widget.notifier.selectDate(_toIso(date));
  }

  @override
  Widget build(BuildContext context) {
    final selectedIso = widget.state.selectedDate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Text(
          'Choisis une date',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _loading
              ? 'Chargement...'
              : (_activeWeekdays.isEmpty
                  ? 'Ce pro n\'a pas encore défini ses horaires.'
                  : 'Jours disponibles'),
          style:
              GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _MonthHeader(
          month: _visibleMonth,
          onPrev: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: 8),
        _WeekdayRow(),
        const SizedBox(height: 4),
        _MonthGrid(
          month: _visibleMonth,
          isClickable: _isClickable,
          selectedIso: selectedIso,
          toIso: _toIso,
          onTap: _selectDate,
        ),
        const SizedBox(height: 20),
        // Legend
        Row(
          children: [
            _LegendItem(color: AppColors.violet, label: 'Sélectionné'),
            const SizedBox(width: 14),
            _LegendItem(
                color: AppColors.violetClair.withValues(alpha: 0.3),
                label: 'Disponible'),
            const SizedBox(width: 14),
            _LegendItem(color: AppColors.gris.withValues(alpha: 0.3), label: 'Fermé'),
          ],
        ),
      ],
    );
  }
}

// ─── Month header (← Avril 2026 →) ──────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label =
        '${DateFormat.MMMM('fr_FR').format(month)} ${month.year}';
    final capitalized = label[0].toUpperCase() + label.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: Icon(Icons.chevron_left,
                color: AppColors.blanc, size: 22),
          ),
          Text(
            capitalized,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(Icons.chevron_right,
                color: AppColors.blanc, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─── Weekday row (Lun Mar Mer ...) ──────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Row(
      children: labels
          .map((l) => Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Month grid ──────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.isClickable,
    required this.selectedIso,
    required this.toIso,
    required this.onTap,
  });

  final DateTime month;
  final bool Function(DateTime) isClickable;
  final String? selectedIso;
  final String Function(DateTime) toIso;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    // Dart weekday: 1 = Mon ... 7 = Sun → we want Mon-first grid
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - leadingBlanks + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 48));
              }
              final date = DateTime(month.year, month.month, dayNum);
              final clickable = isClickable(date);
              final iso = toIso(date);
              final isSelected = selectedIso == iso;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onTap: clickable ? () => onTap(date) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.violet
                              : (clickable
                                  ? AppColors.violetClair
                                      .withValues(alpha: 0.12)
                                  : AppColors.surface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.violet
                                : (clickable
                                    ? AppColors.violet
                                        .withValues(alpha: 0.25)
                                    : AppColors.border
                                        .withValues(alpha: 0.3)),
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: GoogleFonts.dmSans(
                              color: isSelected
                                  ? Colors.white
                                  : (clickable
                                      ? AppColors.blanc
                                      : AppColors.gris
                                          .withValues(alpha: 0.5)),
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

// ─── Legend dot ─────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
        ),
      ],
    );
  }
}
