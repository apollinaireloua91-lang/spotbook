import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../domain/booking_models.dart';
import '../notifiers/pro_scheduling_notifiers.dart';

/// Calendrier de travail : règles hebdo (`availability_rules`) + aperçu des créneaux (`time_slots`).
class ProAvailabilityScreen extends ConsumerWidget {
  const ProAvailabilityScreen({super.key});

  static List<String> _jsDays(AppLocalizations l) => [
    l.sunday,
    l.monday,
    l.tuesday,
    l.wednesday,
    l.thursday,
    l.friday,
    l.saturday,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final l = AppLocalizations.of(context)!;
    final dayNames = _jsDays(l);
    final state = ref.watch(proAvailabilityNotifierProvider);
    final notifier = ref.read(proAvailabilityNotifierProvider.notifier);
    final dateLabel = state.selectedDate != null
        ? DateFormat.yMMMEd('fr_CA').format(state.selectedDate!)
        : '';

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: SpotbookAppBar(title: l.calendarAndAvailability),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.fond,
        onPressed: state.loading ? null : () => _openRuleSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppColors.blanc,
        onRefresh: () => notifier.load(initialDate: state.selectedDate),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.availabilityRulesHint,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris.withValues(alpha: 0.95),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SpotbookButton.primary(
                      label: state.syncing
                          ? l.syncing
                          : l.generateSlots,
                      isLoading: state.syncing,
                      onPressed: state.syncing
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              final n = await notifier.syncSlots();
                              if (!context.mounted) return;
                              final messenger = ScaffoldMessenger.of(context);
                              if (n != null) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      n == 0
                                          ? l.addRuleFirst
                                          : '$n ${l.slotsUpdated}',
                                    ),
                                    backgroundColor: AppColors.surface,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    state.error!,
                    style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  l.weeklyRulesHeader,
                  style: GoogleFonts.sora(
                    color: AppColors.gris,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            if (state.loading && state.rules.isEmpty)
              const SliverFillRemaining(
                child: SpotbookLoadingShimmer.list(itemCount: 4),
              )
            else if (state.rules.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SpotbookCard(
                    child: Text(
                      l.noRulesHint,
                      style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: state.rules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = state.rules[i];
                    return SpotbookCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayNames[r.dayOfWeek],
                                  style: GoogleFonts.sora(
                                    color: AppColors.blanc,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${r.startTime} – ${r.endTime} · ${r.slotDurationMinutes} min',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.gris,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              await notifier.deleteRule(r.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.slotsPreviewHeader,
                        style: GoogleFonts.sora(
                          color: AppColors.gris,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: state.loading
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365)),
                                builder: (c, child) {
                                  return Theme(
                                    data: Theme.of(c).copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: AppColors.blanc,
                                        onPrimary: AppColors.fond,
                                        surface: AppColors.surface,
                                        onSurface: AppColors.blanc,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                await notifier.selectDate(picked);
                              }
                            },
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                        dateLabel.isEmpty ? l.choose : dateLabel,
                        style: GoogleFonts.dmSans(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.slotsForSelectedDate.isEmpty && !state.loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l.noSlotsForDay,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemCount: state.slotsForSelectedDate.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final slot = state.slotsForSelectedDate[i];
                    return _SlotRow(slot: slot, onToggle: () {
                      HapticFeedback.selectionClick();
                      notifier.toggleSlot(slot);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  static Future<void> _openRuleSheet(BuildContext context, WidgetRef ref) async {
    var dayOfWeek = 1;
    var slotDuration = 60;
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        final dayNames = _jsDays(l);
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              Future<void> pickStart() async {
                final v = await showTimePicker(
                  context: context,
                  initialTime: start,
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.blanc,
                        onPrimary: AppColors.fond,
                        surface: AppColors.surface,
                        onSurface: AppColors.blanc,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (v != null) setModal(() => start = v);
              }

              Future<void> pickEnd() async {
                final v = await showTimePicker(
                  context: context,
                  initialTime: end,
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.blanc,
                        onPrimary: AppColors.fond,
                        surface: AppColors.surface,
                        onSurface: AppColors.blanc,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (v != null) setModal(() => end = v);
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.newTimeSlot,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: dayOfWeek,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceAlt,
                          style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                          items: List.generate(7, (i) {
                            return DropdownMenuItem(
                              value: i,
                              child: Text(dayNames[i]),
                            );
                          }),
                          onChanged: (v) {
                            if (v != null) setModal(() => dayOfWeek = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: pickStart,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.blanc,
                              side: BorderSide(color: AppColors.border),
                            ),
                            child: Text(
                              '${l.startLabel} ${start.format(context)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: pickEnd,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.blanc,
                              side: BorderSide(color: AppColors.border),
                            ),
                            child: Text(
                              '${l.endLabel} ${end.format(context)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.slotDurationLabel,
                      style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: slotDuration,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceAlt,
                          style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 min')),
                            DropdownMenuItem(value: 30, child: Text('30 min')),
                            DropdownMenuItem(value: 45, child: Text('45 min')),
                            DropdownMenuItem(value: 60, child: Text('60 min')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModal(() => slotDuration = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SpotbookButton.primary(
                      label: AppLocalizations.of(context)!.addRule,
                      onPressed: () async {
                        final startM = start.hour * 60 + start.minute;
                        final endM = end.hour * 60 + end.minute;
                        if (endM <= startM) return;
                        HapticFeedback.mediumImpact();
                        final ok = await ref
                            .read(proAvailabilityNotifierProvider.notifier)
                            .addRule(
                              dayOfWeek: dayOfWeek,
                              startTime: _fmtTime(start),
                              endTime: _fmtTime(end),
                              slotDurationMinutes: slotDuration,
                            );
                        if (ok && context.mounted) context.pop();
                      },
                    ),
                    const SizedBox(height: 8),
                    SpotbookButton.outlined(
                      label: AppLocalizations.of(context)!.cancel,
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.onToggle});

  final TimeSlotModel slot;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final start = slot.startTime.length >= 5
        ? slot.startTime.substring(0, 5)
        : slot.startTime;
    final end =
        slot.endTime.length >= 5 ? slot.endTime.substring(0, 5) : slot.endTime;
    return SpotbookCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          '$start – $end',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          slot.isAvailable ? AppLocalizations.of(context)!.openForBooking : AppLocalizations.of(context)!.closedException,
          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
        ),
        value: slot.isAvailable,
        activeThumbColor: AppColors.fond,
        activeTrackColor: AppColors.blanc,
        onChanged: (_) => onToggle(),
      ),
    );
  }
}
