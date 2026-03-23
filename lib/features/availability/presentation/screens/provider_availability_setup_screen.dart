import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../data/availability_notifier.dart';
import '../../domain/availability_models.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProviderAvailabilitySetupScreen extends ConsumerStatefulWidget {
  const ProviderAvailabilitySetupScreen({super.key});

  @override
  ConsumerState<ProviderAvailabilitySetupScreen> createState() =>
      _ProviderAvailabilitySetupScreenState();
}

class _ProviderAvailabilitySetupScreenState
    extends ConsumerState<ProviderAvailabilitySetupScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(availabilityProvider);
    final notifier = ref.read(availabilityProvider.notifier);

    return PopScope(
      canPop: !(asyncState.value?.hasUnsavedChanges ?? false),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await _showUnsavedDialog(context);
        if (confirm == true && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 20),
            onPressed: () {
              if (asyncState.value?.hasUnsavedChanges ?? false) {
                _showUnsavedDialog(context).then((confirm) {
                  if (confirm == true && context.mounted) context.pop();
                });
              } else {
                context.pop();
              }
            },
          ),
          title: const Text(
            'Disponibilités',
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBar: asyncState.value != null
            ? _SaveBar(notifier: notifier, asyncState: asyncState)
            : null,
        body: asyncState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.blanc),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  e.toString(),
                  style: const TextStyle(color: AppColors.gris, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => ref.invalidate(availabilityProvider),
                  child: const Text('Réessayer', style: TextStyle(color: AppColors.blanc)),
                ),
              ],
            ),
          ),
          data: (avail) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Error banner
              if (avail.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      avail.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ),
              // Master toggle
              _MasterToggleCard(
                value: avail.settings.acceptsBookings,
                isSaving: avail.isSaving,
                onChanged: (v) => notifier.toggleAcceptBookings(v),
              ),
              const SizedBox(height: 24),
              // Weekly rules
              const _SectionHeader(
                icon: Icons.calendar_today_outlined,
                title: 'Horaires hebdomadaires',
                subtitle: 'Définissez vos créneaux disponibles par jour',
              ),
              const SizedBox(height: 12),
              _WeekRulesSection(weekRules: avail.weekRules, notifier: notifier),
              const SizedBox(height: 24),
              // Blocked dates
              const _SectionHeader(
                icon: Icons.block_outlined,
                title: 'Jours bloqués',
                subtitle: 'Bloquez des jours spécifiques (congés, absences…)',
              ),
              const SizedBox(height: 12),
              _BlockedDatesSection(
                blockedDates: avail.blockedDates,
                notifier: notifier,
              ),
              const SizedBox(height: 24),
              // Settings
              const _SectionHeader(
                icon: Icons.tune_outlined,
                title: 'Paramètres',
                subtitle: 'Délai minimum entre réservations et limite journalière',
              ),
              const SizedBox(height: 12),
              _SettingsSection(settings: avail.settings, notifier: notifier),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showUnsavedDialog(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Modifications non sauvegardées',
            style: TextStyle(color: AppColors.blanc, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Vos changements n\'ont pas été enregistrés. Voulez-vous quitter sans sauvegarder ?',
            style: TextStyle(color: AppColors.gris, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler', style: TextStyle(color: AppColors.gris)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Quitter', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
}

// ─── Save bar ─────────────────────────────────────────────────────────────────

class _SaveBar extends ConsumerWidget {
  const _SaveBar({required this.notifier, required this.asyncState});
  final AvailabilityNotifier notifier;
  final AsyncValue<AvailabilityState> asyncState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avail = asyncState.value;
    if (avail == null) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SpotbookButton.primary(
          label: avail.isSaving ? 'Enregistrement…' : 'Enregistrer les disponibilités',
          isLoading: avail.isSaving,
          onPressed: avail.hasUnsavedChanges && !avail.isSaving
              ? () async {
                  final error = notifier.validateRules();
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  try {
                    await notifier.save();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Disponibilités enregistrées'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (_) {}
                }
              : null,
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.blanc, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.gris, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
}

// ─── Master toggle card ───────────────────────────────────────────────────────

class _MasterToggleCard extends StatelessWidget {
  const _MasterToggleCard({
    required this.value,
    required this.isSaving,
    required this.onChanged,
  });
  final bool value;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SpotbookCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accepter les réservations',
                    style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value
                        ? 'Votre profil est visible et réservable'
                        : 'Vous n\'acceptez pas de nouvelles réservations',
                    style: const TextStyle(color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.blanc,
                    ),
                  )
                : Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: AppColors.blanc,
                    activeTrackColor: AppColors.surfaceAlt,
                    inactiveThumbColor: AppColors.gris,
                    inactiveTrackColor: AppColors.border,
                  ),
          ],
        ),
      );
}

// ─── Week rules ───────────────────────────────────────────────────────────────

class _WeekRulesSection extends StatelessWidget {
  const _WeekRulesSection({required this.weekRules, required this.notifier});
  final List<DayRule> weekRules;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) => Column(
        children: weekRules
            .map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DayCard(rule: rule, notifier: notifier),
                ))
            .toList(),
      );
}

// ─── Day card ─────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({required this.rule, required this.notifier});
  final DayRule rule;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) => SpotbookCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Text(
                    DayRule.dayName(rule.dayOfWeek),
                    style: TextStyle(
                      color: rule.isActive ? AppColors.blanc : AppColors.gris,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: rule.isActive,
                    onChanged: (v) => notifier.toggleDay(rule.dayOfWeek, v),
                    activeThumbColor: AppColors.blanc,
                    activeTrackColor: AppColors.surfaceAlt,
                    inactiveThumbColor: AppColors.gris,
                    inactiveTrackColor: AppColors.border,
                  ),
                ],
              ),
            ),
            // Animated content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: rule.isActive
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _ActiveDayContent(rule: rule, notifier: notifier),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.bedtime_outlined, color: AppColors.gris, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Jour de repos',
                      style: const TextStyle(color: AppColors.gris, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── Active day content ───────────────────────────────────────────────────────

class _ActiveDayContent extends StatelessWidget {
  const _ActiveDayContent({required this.rule, required this.notifier});
  final DayRule rule;
  final AvailabilityNotifier notifier;

  @override
  Widget build(BuildContext context) => _SlotsAnimatedList(
        rule: rule,
        notifier: notifier,
      );
}

// ─── Slots animated list ──────────────────────────────────────────────────────

class _SlotsAnimatedList extends StatefulWidget {
  const _SlotsAnimatedList({required this.rule, required this.notifier});
  final DayRule rule;
  final AvailabilityNotifier notifier;

  @override
  State<_SlotsAnimatedList> createState() => _SlotsAnimatedListState();
}

class _SlotsAnimatedListState extends State<_SlotsAnimatedList> {
  @override
  Widget build(BuildContext context) {
    final slots = widget.rule.slots;
    return Column(
      children: [
        // Use a simple column since AnimatedList needs fixed count management
        ...slots.asMap().entries.map((entry) {
          final slot = entry.value;
          return _SlotRow(
            key: ValueKey(slot.tempId),
            slot: slot,
            dayOfWeek: widget.rule.dayOfWeek,
            notifier: widget.notifier,
          );
        }),
        // Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: GestureDetector(
            onTap: () => widget.notifier.addSlot(widget.rule.dayOfWeek),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.gris, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Ajouter un créneau',
                    style: TextStyle(color: AppColors.gris, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Slot row ─────────────────────────────────────────────────────────────────

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    super.key,
    required this.slot,
    required this.dayOfWeek,
    required this.notifier,
  });
  final DaySlot slot;
  final int dayOfWeek;
  final AvailabilityNotifier notifier;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}h${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            // Start time
            _TimeButton(
              label: _fmt(slot.startTime),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: slot.startTime,
                  builder: (ctx, child) => MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  notifier.updateSlotTime(dayOfWeek, slot.tempId, picked, null);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text(
                '→',
                style: TextStyle(color: AppColors.gris, fontSize: 14),
              ),
            ),
            // End time
            _TimeButton(
              label: _fmt(slot.endTime),
              hasError: !slot.isValid,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: slot.endTime,
                  builder: (ctx, child) => MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  notifier.updateSlotTime(dayOfWeek, slot.tempId, null, picked);
                }
              },
            ),
            const Spacer(),
            // Remove
            GestureDetector(
              onTap: () => notifier.removeSlot(dayOfWeek, slot.tempId),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, color: AppColors.gris, size: 16),
              ),
            ),
          ],
        ),
      );
}

// ─── Time button ──────────────────────────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.onTap,
    this.hasError = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.border,
              width: hasError ? 1 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: hasError ? AppColors.error : AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
}

// ─── Blocked dates section ────────────────────────────────────────────────────

class _BlockedDatesSection extends StatefulWidget {
  const _BlockedDatesSection({required this.blockedDates, required this.notifier});
  final List<BlockedDate> blockedDates;
  final AvailabilityNotifier notifier;

  @override
  State<_BlockedDatesSection> createState() => _BlockedDatesSectionState();
}

class _BlockedDatesSectionState extends State<_BlockedDatesSection> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) => SpotbookCard(
        child: Column(
          children: [
            _MonthCalendar(
              displayedMonth: _displayedMonth,
              blockedDates: widget.blockedDates,
              onToggle: widget.notifier.toggleBlockedDate,
              onMonthChanged: (m) => setState(() => _displayedMonth = m),
            ),
            if (widget.blockedDates.isNotEmpty) ...[
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
              ...widget.blockedDates.map((d) => _BlockedDateRow(
                    date: d,
                    onRemove: () => widget.notifier.toggleBlockedDate(d.date),
                  )),
            ],
          ],
        ),
      );
}

// ─── Month calendar ───────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.displayedMonth,
    required this.blockedDates,
    required this.onToggle,
    required this.onMonthChanged,
  });
  final DateTime displayedMonth;
  final List<BlockedDate> blockedDates;
  final ValueChanged<DateTime> onToggle;
  final ValueChanged<DateTime> onMonthChanged;

  static const _dayHeaders = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  bool _isBlocked(DateTime d) =>
      blockedDates.any((b) => b.date.year == d.year && b.date.month == d.month && b.date.day == d.day);

  bool _isPast(DateTime d) {
    final today = DateTime.now();
    return d.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    // Monday = 0 offset
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);

    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => onMonthChanged(
                DateTime(displayedMonth.year, displayedMonth.month - 1),
              ),
              icon: const Icon(Icons.chevron_left, color: AppColors.blanc, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Text(
              _monthLabel(displayedMonth),
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () => onMonthChanged(
                DateTime(displayedMonth.year, displayedMonth.month + 1),
              ),
              icon: const Icon(Icons.chevron_right, color: AppColors.blanc, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Day headers
        Row(
          children: _dayHeaders
              .map((h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          color: AppColors.gris,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final date = DateTime(displayedMonth.year, displayedMonth.month, day);
            final blocked = _isBlocked(date);
            final past = _isPast(date);

            return GestureDetector(
              onTap: past ? null : () => onToggle(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: blocked
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: blocked ? AppColors.error : AppColors.border,
                    width: blocked ? 1 : 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: past
                          ? AppColors.border
                          : blocked
                              ? AppColors.error
                              : AppColors.blanc,
                      fontSize: 12,
                      fontWeight: blocked ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ─── Blocked date row ─────────────────────────────────────────────────────────

class _BlockedDateRow extends StatelessWidget {
  const _BlockedDateRow({required this.date, required this.onRemove});
  final BlockedDate date;
  final VoidCallback onRemove;

  String _label(DateTime d) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.block, color: AppColors.error, size: 14),
            const SizedBox(width: 8),
            Text(
              _label(date.date),
              style: const TextStyle(color: AppColors.grisClair, fontSize: 13),
            ),
            if (date.reason != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  date.reason!,
                  style: const TextStyle(color: AppColors.gris, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            GestureDetector(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: AppColors.gris, size: 16),
              ),
            ),
          ],
        ),
      );
}

// ─── Settings section ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.settings, required this.notifier});
  final AvailabilitySettings settings;
  final AvailabilityNotifier notifier;

  static const _gapOptions = [0, 5, 10, 15, 20, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) => SpotbookCard(
        child: Column(
          children: [
            // Min gap
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Délai entre réservations',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Temps de pause entre deux RDV',
                        style: TextStyle(color: AppColors.gris, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _gapOptions.contains(settings.minGapMinutes)
                          ? settings.minGapMinutes
                          : 15,
                      dropdownColor: AppColors.surfaceAlt,
                      style: const TextStyle(color: AppColors.blanc, fontSize: 13),
                      isDense: true,
                      items: _gapOptions
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v == 0 ? 'Aucun' : '$v min'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) notifier.updateMinGap(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),
            // Max bookings
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max réservations / jour',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Limite de RDV acceptés par jour',
                        style: TextStyle(color: AppColors.gris, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _CounterButton(
                      icon: Icons.remove,
                      onTap: () => notifier.updateMaxBookings(settings.maxBookingsPerDay - 1),
                    ),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          '${settings.maxBookingsPerDay}',
                          style: const TextStyle(
                            color: AppColors.blanc,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    _CounterButton(
                      icon: Icons.add,
                      onTap: () => notifier.updateMaxBookings(settings.maxBookingsPerDay + 1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}

// ─── Counter button ───────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Icon(icon, color: AppColors.blanc, size: 16),
        ),
      );
}
