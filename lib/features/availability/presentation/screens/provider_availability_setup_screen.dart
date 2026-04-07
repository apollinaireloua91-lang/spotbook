import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../data/availability_notifier.dart';
import '../../domain/availability_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class ProviderAvailabilitySetupScreen extends ConsumerWidget {
  const ProviderAvailabilitySetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(availabilityProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(child: CircularProgressIndicator(color: AppColors.blanc)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: Text(e.toString(), style: const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (state) => _AvailabilityScreenBody(state: state),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _AvailabilityScreenBody extends ConsumerWidget {
  const _AvailabilityScreenBody({required this.state});
  final AvailabilityState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(availabilityProvider.notifier);

    return PopScope(
      canPop: !state.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => const _UnsavedDialog(),
        );
        if ((leave ?? false) && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: Semantics(
            label: 'Back',
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          title: Text(
            'Disponibilités',
            style: GoogleFonts.sora(
                color: AppColors.blanc, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: false,
        ),
        bottomNavigationBar: _SaveBar(state: state, notifier: notifier),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(state.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ),
            _MasterToggleCard(state: state, notifier: notifier),
            const _SectionHeader(
                title: 'Horaires hebdomadaires', icon: Icons.calendar_today_outlined),
            _WeekRulesSection(state: state, notifier: notifier),
            const _SectionHeader(
                title: 'Dates bloquées', icon: Icons.block_outlined),
            _BlockedDatesSection(state: state, notifier: notifier),
            const _SectionHeader(title: 'Settings', icon: Icons.tune_outlined),
            _SettingsSection(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gris, size: 16),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Master toggle
// ─────────────────────────────────────────────────────────────────────────────

class _MasterToggleCard extends StatelessWidget {
  const _MasterToggleCard({required this.state, required this.notifier});
  final AvailabilityState state;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SpotbookCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: state.settings.acceptsBookings
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                state.settings.acceptsBookings
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: state.settings.acceptsBookings
                    ? AppColors.success
                    : AppColors.gris,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accept bookings',
                    style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  Text(
                    state.settings.acceptsBookings
                        ? 'Clients can book'
                        : 'Bookings disabled',
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: state.settings.acceptsBookings,
              onChanged: notifier.toggleAcceptBookings,
              activeThumbColor: AppColors.blanc,
              activeTrackColor: AppColors.success,
              inactiveThumbColor: AppColors.gris,
              inactiveTrackColor: AppColors.surfaceAlt,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Week rules
// ─────────────────────────────────────────────────────────────────────────────

class _WeekRulesSection extends StatelessWidget {
  const _WeekRulesSection({required this.state, required this.notifier});
  final AvailabilityState state;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: state.weekRules
            .map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DayCard(rule: rule, notifier: notifier),
                ))
            .toList(),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.rule, required this.notifier});
  final DayRule rule;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SpotbookCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rule.isActive ? AppColors.blanc : AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      DayRule.dayShort(rule.dayOfWeek),
                      style: TextStyle(
                        color:
                            rule.isActive ? AppColors.fond : AppColors.gris,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DayRule.dayName(rule.dayOfWeek),
                    style: TextStyle(
                      color: rule.isActive ? AppColors.blanc : AppColors.gris,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Switch(
                  value: rule.isActive,
                  onChanged: (v) => notifier.toggleDay(rule.dayOfWeek, v),
                  activeThumbColor: AppColors.blanc,
                  activeTrackColor: AppColors.success.withValues(alpha: 0.6),
                  inactiveThumbColor: AppColors.gris,
                  inactiveTrackColor: AppColors.surfaceAlt,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: rule.isActive
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _SlotsSection(rule: rule, notifier: notifier),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.bedtime_outlined, color: AppColors.gris, size: 14),
                  const SizedBox(width: 6),
                  const Text('Day off',
                      style: TextStyle(color: AppColors.gris, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slots list with animation
// ─────────────────────────────────────────────────────────────────────────────

class _SlotsSection extends ConsumerStatefulWidget {
  const _SlotsSection({required this.rule, required this.notifier});
  final DayRule rule;
  final AvailabilityNotifier notifier;

  @override
  ConsumerState<_SlotsSection> createState() => _SlotsSectionState();
}

class _SlotsSectionState extends ConsumerState<_SlotsSection> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<DaySlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.from(widget.rule.slots);
  }

  @override
  void didUpdateWidget(_SlotsSection old) {
    super.didUpdateWidget(old);
    final newSlots = widget.rule.slots;
    if (newSlots.length > _slots.length) {
      setState(() => _slots = List.from(newSlots));
      _listKey.currentState?.insertItem(
        _slots.length - 1,
        duration: const Duration(milliseconds: 300),
      );
    } else if (newSlots.length < _slots.length) {
      int removedIdx = _slots.length - 1;
      for (int i = 0; i < _slots.length; i++) {
        if (i >= newSlots.length || _slots[i].tempId != newSlots[i].tempId) {
          removedIdx = i;
          break;
        }
      }
      final removedSlot = _slots[removedIdx];
      setState(() => _slots = List.from(newSlots));
      _listKey.currentState?.removeItem(
        removedIdx,
        (ctx, anim) => FadeTransition(
          opacity: anim,
          child: _SlotRow(
            slot: removedSlot,
            dayOfWeek: widget.rule.dayOfWeek,
            notifier: widget.notifier,
          ),
        ),
        duration: const Duration(milliseconds: 250),
      );
    } else {
      setState(() => _slots = List.from(newSlots));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_slots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _slots.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, idx, anim) {
                if (idx >= _slots.length) return const SizedBox.shrink();
                return SlideTransition(
                  position: anim.drive(
                    Tween<Offset>(
                            begin: const Offset(0.3, 0), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: _SlotRow(
                    slot: _slots[idx],
                    dayOfWeek: widget.rule.dayOfWeek,
                    notifier: widget.notifier,
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: GestureDetector(
            onTap: () => widget.notifier.addSlot(widget.rule.dayOfWeek),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: AppColors.gris, size: 16),
                  const SizedBox(width: 6),
                  Text('Add a slot',
                      style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow(
      {required this.slot, required this.dayOfWeek, required this.notifier});
  final DaySlot slot;
  final int dayOfWeek;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _TimeButton(
            time: slot.startTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: slot.startTime,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) {
                notifier.updateSlotTime(dayOfWeek, slot.tempId, picked, null);
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→',
                style: TextStyle(color: AppColors.gris, fontSize: 14)),
          ),
          _TimeButton(
            time: slot.endTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: slot.endTime,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) {
                notifier.updateSlotTime(dayOfWeek, slot.tempId, null, picked);
              }
            },
          ),
          if (!slot.isValid) ...[
            const SizedBox(width: 6),
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 16),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => notifier.removeSlot(dayOfWeek, slot.tempId),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, color: AppColors.error, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.time, required this.onTap});
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '$h:$m',
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Blocked dates
// ─────────────────────────────────────────────────────────────────────────────

class _BlockedDatesSection extends StatefulWidget {
  const _BlockedDatesSection({required this.state, required this.notifier});
  final AvailabilityState state;
  final AvailabilityNotifier notifier;

  @override
  State<_BlockedDatesSection> createState() => _BlockedDatesSectionState();
}

class _BlockedDatesSectionState extends State<_BlockedDatesSection> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SpotbookCard(
            padding: EdgeInsets.zero,
            child: _MonthCalendar(
              month: _displayMonth,
              blockedDates: widget.state.blockedDates,
              onToggle: widget.notifier.toggleBlockedDate,
              onPrevMonth: () => setState(() => _displayMonth =
                  DateTime(_displayMonth.year, _displayMonth.month - 1)),
              onNextMonth: () => setState(() => _displayMonth =
                  DateTime(_displayMonth.year, _displayMonth.month + 1)),
            ),
          ),
          if (widget.state.blockedDates.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...widget.state.blockedDates.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _BlockedDateRow(
                  blocked: b,
                  onRemove: () =>
                      widget.notifier.toggleBlockedDate(b.date),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.blockedDates,
    required this.onToggle,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final List<BlockedDate> blockedDates;
  final void Function(DateTime) onToggle;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  bool _isBlocked(DateTime d) => blockedDates.any(
        (b) =>
            b.date.year == d.year &&
            b.date.month == d.month &&
            b.date.day == d.day,
      );

  bool _isPast(DateTime d) {
    final today = DateTime.now();
    return d
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _monthName(month.month);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startOffset = (firstDay.weekday - 1) % 7;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            children: [
              Text(
                '$monthLabel ${month.year}',
                style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon:
                    const Icon(Icons.chevron_left, color: AppColors.gris),
                onPressed: onPrevMonth,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon:
                    const Icon(Icons.chevron_right, color: AppColors.gris),
                onPressed: onNextMonth,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _dayLabels
                .map((l) => Expanded(
                      child: Center(
                        child: Text(l,
                            style: const TextStyle(
                                color: AppColors.gris,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: List.generate(rows, (rowIdx) {
              return Row(
                children: List.generate(7, (colIdx) {
                  final cellIdx = rowIdx * 7 + colIdx;
                  final dayNum = cellIdx - startOffset + 1;
                  if (dayNum < 1 || dayNum > lastDay.day) {
                    return const Expanded(child: SizedBox(height: 38));
                  }
                  final date =
                      DateTime(month.year, month.month, dayNum);
                  final blocked = _isBlocked(date);
                  final past = _isPast(date);
                  return Expanded(
                    child: GestureDetector(
                      onTap: past ? null : () => onToggle(date),
                      child: Container(
                        height: 38,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: blocked ? AppColors.blanc : null,
                          borderRadius: BorderRadius.circular(8),
                          border: (!blocked && !past)
                              ? Border.all(
                                  color: AppColors.border
                                      .withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              color: blocked
                                  ? AppColors.fond
                                  : past
                                      ? AppColors.gris
                                          .withValues(alpha: 0.4)
                                      : AppColors.grisClair,
                              fontSize: 13,
                              fontWeight: blocked
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  static String _monthName(int m) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[m];
  }
}

class _BlockedDateRow extends StatelessWidget {
  const _BlockedDateRow({required this.blocked, required this.onRemove});
  final BlockedDate blocked;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final d = blocked.date;
    final label =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: AppColors.error, size: 14),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: AppColors.blanc, fontSize: 14)),
          const Spacer(),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: AppColors.gris, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.state, required this.notifier});
  final AvailabilityState state;
  final AvailabilityNotifier notifier;

  static const _gapOptions = [0, 15, 30, 45, 60, 90, 120];
  static const _advanceOptions = [1, 2, 4, 6, 12, 24, 48];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SpotbookCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Min gap between bookings
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pause entre RDV',
                            style: GoogleFonts.dmSans(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Temps tampon après chaque réservation',
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris, fontSize: 12)),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: state.settings.minGapMinutes,
                    dropdownColor: AppColors.surface,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    onChanged: (v) {
                      if (v != null) notifier.updateMinGap(v);
                    },
                    items: _gapOptions
                        .map((m) => DropdownMenuItem<int>(
                              value: m,
                              child:
                                  Text(m == 0 ? 'None' : '${m}min'),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 24),
            // Min advance hours
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Délai minimum avant réservation',
                            style: GoogleFonts.dmSans(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Temps minimum entre la réservation et le RDV',
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris, fontSize: 12)),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: _advanceOptions.contains(state.settings.minAdvanceHours)
                        ? state.settings.minAdvanceHours
                        : 2,
                    dropdownColor: AppColors.surface,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    onChanged: (v) {
                      if (v != null) notifier.updateMinAdvanceHours(v);
                    },
                    items: _advanceOptions
                        .map((h) => DropdownMenuItem<int>(
                              value: h,
                              child: Text('${h}h'),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 24),
            // Max bookings per day
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Max réservations / jour',
                            style: GoogleFonts.dmSans(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Limite quotidienne de réservations',
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris, fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _CounterButton(
                        icon: Icons.remove,
                        onTap: () => notifier.updateMaxBookings(
                            state.settings.maxBookingsPerDay - 1),
                        enabled: state.settings.maxBookingsPerDay > 1,
                      ),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            '${state.settings.maxBookingsPerDay}',
                            style: const TextStyle(
                              color: AppColors.blanc,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _CounterButton(
                        icon: Icons.add,
                        onTap: () => notifier.updateMaxBookings(
                            state.settings.maxBookingsPerDay + 1),
                        enabled:
                            state.settings.maxBookingsPerDay < 50,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton(
      {required this.icon, required this.onTap, required this.enabled});
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceAlt
              : AppColors.surfaceAlt.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon,
            color: enabled ? AppColors.blanc : AppColors.gris,
            size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save bar
// ─────────────────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.state, required this.notifier});
  final AvailabilityState state;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: state.hasUnsavedChanges ? 90 : 0,
      child: state.hasUnsavedChanges
          ? Container(
              color: AppColors.fond,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SpotbookButton.primary(
                label: state.isSaving
                    ? 'Enregistrement...'
                    : 'Save changes',
                isLoading: state.isSaving,
                onPressed: state.isSaving
                    ? null
                    : () async {
                        final err = notifier.validateRules();
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        try {
                          await notifier.save();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Disponibilités enregistrées'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de l\'enregistrement'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unsaved dialog
// ─────────────────────────────────────────────────────────────────────────────

class _UnsavedDialog extends StatelessWidget {
  const _UnsavedDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Modifications non sauvegardées',
          style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
      content: Text(
        'Vos changements seront perdus si vous quittez maintenant.',
        style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Rester',
              style: GoogleFonts.dmSans(color: AppColors.blanc)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Quitter',
              style: GoogleFonts.dmSans(color: AppColors.error)),
        ),
      ],
    );
  }
}
