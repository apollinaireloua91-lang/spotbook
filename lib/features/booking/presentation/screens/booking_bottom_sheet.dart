import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/app_config_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/analytics_service.dart';
import '../../../../shared/widgets/confetti_overlay.dart';
import '../../../profile/domain/profile_models.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';
import '../widgets/person_count_picker.dart';

Future<void> showBookingSheet(
  BuildContext context, {
  required String proId,
  required ProProfile proProfile,
  String? initialServiceId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(proId: proId, proProfile: proProfile),
  );
}

// ─── Step labels ─────────────────────────────────────────
const _stepLabels = [
  'Service',
  'Date',
  'Time',
  'Summary',
  'Payment',
  'Confirmed',
];

const _months = [
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
  'December',
];

const _daysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ─── Main sheet ──────────────────────────────────────────

class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({required this.proId, required this.proProfile});

  final String proId;
  final ProProfile proProfile;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  final _promoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).init(widget.proId);
    });
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    ref.read(bookingFlowProvider.notifier).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingFlowProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.fond,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _StepIndicator(currentStep: state.step),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: _buildStep(state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gris.withAlpha(80),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStep(BookingFlowState state) {
    switch (state.step) {
      case 0:
        return _Step1Services(
          state: state,
          promoCtrl: _promoCtrl,
          onNext: () {
            ref.read(bookingFlowProvider.notifier).nextStep();
            ref.read(bookingFlowProvider.notifier).loadDates();
          },
        );
      case 1:
        return _Step2Calendar(state: state);
      case 2:
        return _Step3Slots(state: state);
      case 3:
        return _Step4Summary(state: state, proProfile: widget.proProfile);
      case 4:
        return _Step5Payment(state: state);
      case 5:
        return _Step6Confirmation(
          state: state,
          proProfile: widget.proProfile,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Step indicator dots ─────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(6, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.violet
                          : isActive
                              ? AppColors.violetClair
                              : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepLabels[i],
                    style: GoogleFonts.dmSans(
                      color: isActive || isDone
                          ? AppColors.blanc
                          : AppColors.gris.withAlpha(120),
                      fontSize: 10,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step header ─────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    this.subtitle,
    this.onBack,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onBack!();
              },
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.blanc,
                  size: 16,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris.withAlpha(180),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA button ──────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.gradientAccent : null,
          color: enabled ? null : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.blanc,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: enabled ? AppColors.blanc : AppColors.gris,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Shimmer placeholders ────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();
  final int count = 4;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: Column(
        children: List.generate(
          count,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 1: Services + Promo
// ═══════════════════════════════════════════════════════════

class _Step1Services extends ConsumerWidget {
  const _Step1Services({
    required this.state,
    required this.promoCtrl,
    required this.onNext,
  });

  final BookingFlowState state;
  final TextEditingController promoCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          title: 'Choose a service',
          subtitle: 'Select the desired service',
        ),
        if (state.isLoading)
          const _ShimmerList()
        else if (state.services.isEmpty)
          _EmptyState(
            icon: Icons.content_cut,
            message: 'No services available',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final service = state.services[index];
              final isSelected = state.selectedService?.id == service.id;
              return _ServiceTile(
                service: service,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(bookingFlowProvider.notifier)
                      .selectService(service);
                },
              );
            },
          ),

        // Person count picker for traiteur services
        if (state.selectedService?.isTraiteurService == true) ...[
          const SizedBox(height: 20),
          PersonCountPicker(
            service: state.selectedService!,
            count: state.personCount,
            onChanged: (count) =>
                ref.read(bookingFlowProvider.notifier).setPersonCount(count),
          ),
        ],

        const SizedBox(height: 24),

        // Promo code section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer_outlined,
                      color: AppColors.violetClair, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Code promo',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: promoCtrl,
                      style: GoogleFonts.dmSans(color: AppColors.blanc),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter a code',
                        hintStyle: GoogleFonts.dmSans(color: AppColors.gris),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: state.promoApplied
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(bookingFlowProvider.notifier)
                                .validatePromo(promoCtrl.text.trim());
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: state.promoApplied
                            ? AppColors.success.withAlpha(30)
                            : AppColors.violet,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        state.promoApplied ? 'Applied ✓' : 'Apply',
                        style: GoogleFonts.dmSans(
                          color: state.promoApplied
                              ? AppColors.success
                              : AppColors.blanc,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (state.error != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
        _CtaButton(
          label: 'Continuer',
          onPressed: state.selectedService != null ? onNext : null,
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.violet.withAlpha(20)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.violet : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.violet.withAlpha(40)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.content_cut,
                color: isSelected ? AppColors.violetClair : AppColors.gris,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (service.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.description!,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 12,
                          color: AppColors.gris.withAlpha(160)),
                      const SizedBox(width: 4),
                      Text(
                        '${service.durationMinutes} min',
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris.withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${service.price.toStringAsFixed(0)} CA\$',
                  style: GoogleFonts.sora(
                    color: isSelected ? AppColors.violetClair : AppColors.blanc,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sélectionné',
                      style: GoogleFonts.dmSans(
                        color: AppColors.violetClair,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 2: Calendar with month navigation
// ═══════════════════════════════════════════════════════════

class _Step2Calendar extends ConsumerStatefulWidget {
  const _Step2Calendar({required this.state});
  final BookingFlowState state;

  @override
  ConsumerState<_Step2Calendar> createState() => _Step2CalendarState();
}

class _Step2CalendarState extends ConsumerState<_Step2Calendar> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _previousMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return;
    setState(() {
      _month--;
      if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _month++;
      if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
    final firstWeekday = DateTime(_year, _month, 1).weekday; // 1=Mon
    final availableSet = widget.state.availableDates.toSet();
    final canGoPrev = !(_year == now.year && _month == now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          title: 'Choose a date',
          subtitle: 'Available days are highlighted',
          onBack: () =>
              ref.read(bookingFlowProvider.notifier).previousStep(),
        ),

        if (widget.state.isLoading)
          const _ShimmerGrid()
        else ...[
          // Month nav
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: canGoPrev ? AppColors.blanc : AppColors.gris.withAlpha(60),
                  ),
                  onPressed: canGoPrev ? _previousMonth : null,
                ),
                Text(
                  '${_months[_month - 1]} $_year',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.blanc),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Day of week labels
          Row(
            children: _daysShort
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris.withAlpha(160),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: daysInMonth + (firstWeekday - 1),
            itemBuilder: (context, index) {
              // Empty cells for alignment
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final day = index - (firstWeekday - 1) + 1;
              if (day > daysInMonth) return const SizedBox.shrink();

              final date = DateTime(_year, _month, day);
              final dateStr = date.toIso8601String().split('T')[0];
              final isAvailable = availableSet.contains(dateStr);
              final isSelected = widget.state.selectedDate == dateStr;
              final isPast = date.isBefore(
                DateTime(now.year, now.month, now.day),
              );
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return GestureDetector(
                onTap: isAvailable && !isPast
                    ? () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(bookingFlowProvider.notifier)
                            .selectDate(dateStr);
                        ref.read(bookingFlowProvider.notifier).nextStep();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.violet
                        : isAvailable && !isPast
                            ? AppColors.surface
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.violetClair.withAlpha(100),
                          )
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: GoogleFonts.dmSans(
                      color: isSelected
                          ? AppColors.blanc
                          : isAvailable && !isPast
                              ? AppColors.blanc
                              : AppColors.gris.withAlpha(60),
                      fontWeight:
                          isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 3: Time slots grid
// ═══════════════════════════════════════════════════════════

class _Step3Slots extends ConsumerWidget {
  const _Step3Slots({required this.state});
  final BookingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Format selected date in French
    String dateLabel = state.selectedDate ?? '';
    if (state.selectedDate != null) {
      try {
        final parts = state.selectedDate!.split('-');
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final day = d.day;
        final month = _months[d.month - 1];
        dateLabel = '$day $month';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          title: 'Choose a time slot',
          subtitle: dateLabel,
          onBack: () =>
              ref.read(bookingFlowProvider.notifier).previousStep(),
        ),

        if (state.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: GoogleFonts.dmSans(
                        color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        if (state.isLoading)
          const _ShimmerGrid()
        else if (state.timeSlots.isEmpty)
          _EmptyState(
            icon: Icons.event_busy,
            message: 'No slots available for this date',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: state.timeSlots.length,
            itemBuilder: (context, index) {
              final slot = state.timeSlots[index];
              final isSelected = state.selectedSlot?.id == slot.id;

              return GestureDetector(
                onTap: slot.isAvailable
                    ? () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(bookingFlowProvider.notifier)
                            .selectSlot(slot);
                        ref.read(bookingFlowProvider.notifier).nextStep();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !slot.isAvailable
                        ? AppColors.surfaceAlt.withAlpha(60)
                        : isSelected
                            ? AppColors.violet
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: slot.isAvailable
                                ? AppColors.border
                                : Colors.transparent,
                          ),
                  ),
                  child: Text(
                    slot.startTime.substring(0, 5),
                    style: GoogleFonts.dmSans(
                      color: !slot.isAvailable
                          ? AppColors.gris.withAlpha(80)
                          : isSelected
                              ? AppColors.blanc
                              : AppColors.blanc,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 4: Summary
// ═══════════════════════════════════════════════════════════

class _Step4Summary extends ConsumerWidget {
  const _Step4Summary({
    required this.state,
    required this.proProfile,
  });

  final BookingFlowState state;
  final ProProfile proProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Format date nicely
    String dateDisplay = state.selectedDate ?? '';
    if (state.selectedDate != null) {
      try {
        final parts = state.selectedDate!.split('-');
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        dateDisplay = '${d.day} ${_months[d.month - 1]} ${d.year}';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          title: 'Summary',
          subtitle: 'Review your booking details',
          onBack: () =>
              ref.read(bookingFlowProvider.notifier).previousStep(),
        ),

        // Pro card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: proProfile.avatarUrl != null
                    ? CachedNetworkImageProvider(proProfile.avatarUrl!)
                    : null,
                child: proProfile.avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.gris, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proProfile.businessName,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (proProfile.category.isNotEmpty)
                      Text(
                        proProfile.category,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pro',
                  style: GoogleFonts.dmSans(
                    color: AppColors.violetClair,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Details card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.content_cut,
                label: 'Service',
                value: state.selectedService?.name ?? '',
              ),
              const Divider(color: AppColors.border, height: 20),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: dateDisplay,
              ),
              const Divider(color: AppColors.border, height: 20),
              _DetailRow(
                icon: Icons.schedule,
                label: 'Heure',
                value: state.selectedSlot?.startTime.substring(0, 5) ?? '',
              ),
              const Divider(color: AppColors.border, height: 20),
              _DetailRow(
                icon: Icons.timelapse,
                label: 'Durée',
                value: '${state.selectedService?.durationMinutes ?? 0} min',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment breakdown card
        Builder(builder: (context) {
          final appConfig =
              ref.watch(appConfigProvider).value ?? AppConfig.fallback;
          final serviceFee = appConfig.serviceFeeClient;
          final depositAmount = state.depositPrice;
          final clientPaysNow = depositAmount + serviceFee;
          final remainingAmount = state.totalPrice - depositAmount;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _PriceRow(
                  label: state.selectedService?.name ?? 'Service',
                  value:
                      '${state.selectedService?.price.toStringAsFixed(2) ?? '0'} CA\$',
                ),
                if (state.promoApplied && state.promoCode != null) ...[
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: 'Promo (${state.promoCode!.code})',
                    value: state.promoCode!.discountType == 'percentage'
                        ? '-${state.promoCode!.discountValue.toStringAsFixed(0)}%'
                        : '-${state.promoCode!.discountValue.toStringAsFixed(2)} CA\$',
                    valueColor: AppColors.success,
                  ),
                  const SizedBox(height: 4),
                  _PriceRow(
                    label: 'Sous-total',
                    value: '${state.totalPrice.toStringAsFixed(2)} CA\$',
                  ),
                ],
                const Divider(color: AppColors.border, height: 20),
                _PriceRow(
                  label: 'Acompte (30%)',
                  value: '${depositAmount.toStringAsFixed(2)} CA\$',
                ),
                const SizedBox(height: 8),
                _PriceRow(
                  label: 'Frais de service',
                  value: '${serviceFee.toStringAsFixed(2)} CA\$',
                ),
                const Divider(color: AppColors.border, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'À payer maintenant',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${clientPaysNow.toStringAsFixed(2)} CA\$',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.violet.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined,
                          color: AppColors.violetClair, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solde le jour du RDV : ${remainingAmount.toStringAsFixed(2)} CA\$',
                          style: GoogleFonts.dmSans(
                            color: AppColors.violetClair,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 28),
        Builder(builder: (context) {
          final appConfig =
              ref.watch(appConfigProvider).value ?? AppConfig.fallback;
          final clientPaysNow =
              state.depositPrice + appConfig.serviceFeeClient;
          return _CtaButton(
            label: 'Payer ${clientPaysNow.toStringAsFixed(2)} CA\$',
            onPressed: () =>
                ref.read(bookingFlowProvider.notifier).nextStep(),
          );
        }),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gris, size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: valueColor ?? AppColors.blanc,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 5: Payment (Stripe)
// ═══════════════════════════════════════════════════════════

class _Step5Payment extends ConsumerWidget {
  const _Step5Payment({required this.state});
  final BookingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          title: 'Payment',
          subtitle: (() {
            final fee = (ref.read(appConfigProvider).value ?? AppConfig.fallback).serviceFeeClient;
            return 'Pay now: ${(state.depositPrice + fee).toStringAsFixed(2)} CA\$';
          })(),
          onBack: () =>
              ref.read(bookingFlowProvider.notifier).previousStep(),
        ),

        // Card input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card,
                      color: AppColors.violetClair, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Carte bancaire',
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.lock_outline,
                      color: AppColors.gris.withAlpha(120), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Sécurisé',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris.withAlpha(120),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CardField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Payment summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Builder(
            builder: (ctx) {
              final cfg = ref.watch(appConfigProvider).value ?? AppConfig.fallback;
              final serviceFee = cfg.serviceFeeClient;
              return Column(
                children: [
                  _PriceRow(
                    label: 'Service total',
                    value: '${state.totalPrice.toStringAsFixed(2)} CA\$',
                  ),
                  const SizedBox(height: 6),
                  _PriceRow(
                    label: 'Acompte (30%)',
                    value: '${state.depositPrice.toStringAsFixed(2)} CA\$',
                    valueColor: AppColors.violetClair,
                  ),
                  const SizedBox(height: 6),
                  _PriceRow(
                    label: 'Frais de service',
                    value: '${serviceFee.toStringAsFixed(2)} CA\$',
                  ),
                  const SizedBox(height: 6),
                  _PriceRow(
                    label: 'Solde restant (sur place)',
                    value:
                        '${(state.totalPrice - state.depositPrice).toStringAsFixed(2)} CA\$',
                  ),
                ],
              );
            },
          ),
        ),

        if (state.error != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
        _CtaButton(
          label: (() {
            final fee = (ref.read(appConfigProvider).value ?? AppConfig.fallback).serviceFeeClient;
            return 'Payer ${(state.depositPrice + fee).toStringAsFixed(2)} CA\$';
          })(),
          isLoading: state.isCreating || state.isPaying,
          onPressed: (state.isCreating || state.isPaying)
              ? null
              : () async {
                  HapticFeedback.mediumImpact();

                  // Step 1: Create booking + get clientSecret
                  if (state.bookingResult == null) {
                    await AnalyticsService.instance.capture(
                      'booking_started',
                      properties: {
                        'pro_id': state.selectedSlot?.proId ?? '',
                        'service_id': state.selectedService?.id ?? '',
                      },
                    );
                    await ref
                        .read(bookingFlowProvider.notifier)
                        .createBooking();
                  }
                  final flowState = ref.read(bookingFlowProvider);
                  final clientSecret = flowState.clientSecret;
                  if (clientSecret == null) return;

                  // Step 2: Confirm payment via Stripe SDK
                  try {
                    await Stripe.instance.confirmPayment(
                      paymentIntentClientSecret: clientSecret,
                      data: const PaymentMethodParams.card(
                        paymentMethodData: PaymentMethodData(),
                      ),
                    );
                    await AnalyticsService.instance.capture(
                      'booking_completed',
                      properties: {
                        'booking_id':
                            flowState.bookingResult?['bookingId']?.toString() ??
                                '',
                        'pro_id': state.selectedSlot?.proId ?? '',
                      },
                    );
                    ref.read(bookingFlowProvider.notifier).nextStep();
                  } on StripeException catch (e) {
                    await AnalyticsService.instance.capture(
                      'payment_failed',
                      properties: {
                        'booking_id':
                            flowState.bookingResult?['bookingId']?.toString() ??
                                '',
                        'error':
                            e.error.localizedMessage ?? 'payment_failed',
                      },
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.error.localizedMessage ?? 'Paiement échoué',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step 6: Confirmation
// ═══════════════════════════════════════════════════════════

class _Step6Confirmation extends StatelessWidget {
  const _Step6Confirmation({
    required this.state,
    required this.proProfile,
  });

  final BookingFlowState state;
  final ProProfile proProfile;

  @override
  Widget build(BuildContext context) {
    final bookingCode =
        state.bookingResult?['bookingCode'] as String? ?? 'SPT-XXXXXXXX';

    // Format date
    String dateDisplay = '';
    if (state.selectedDate != null) {
      try {
        final parts = state.selectedDate!.split('-');
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        dateDisplay = '${d.day} ${_months[d.month - 1]} ${d.year}';
      } catch (_) {
        dateDisplay = state.selectedDate!;
      }
    }

    return Stack(
      children: [
        Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          width: 130,
          child: Lottie.asset(
            'assets/animations/success.json',
            repeat: false,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withAlpha(25),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Booking confirmed!',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre RDV est bien enregistré',
          style: GoogleFonts.dmSans(
            color: AppColors.gris.withAlpha(180),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),

        // Booking code card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                'Booking code',
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc.withAlpha(200),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bookingCode,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Details card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.content_cut,
                label: 'Service',
                value: state.selectedService?.name ?? '',
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.person,
                label: 'Pro',
                value: proProfile.businessName,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: dateDisplay,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.schedule,
                label: 'Heure',
                value:
                    state.selectedSlot?.startTime.substring(0, 5) ?? '',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Add to calendar
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final date = state.selectedDate;
            final time = state.selectedSlot?.startTime;
            if (date != null && time != null) {
              final dateParts = date.split('-');
              final timeParts = time.split(':');
              final start = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
                int.parse(timeParts[0]),
                int.parse(timeParts[1]),
              );
              final end = start.add(Duration(
                minutes: state.selectedService?.durationMinutes ?? 60,
              ));
              Add2Calendar.addEvent2Cal(Event(
                title:
                    '${state.selectedService?.name} — ${proProfile.businessName}',
                description: 'Code : $bookingCode',
                startDate: start,
                endDate: end,
              ));
            }
          },
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, color: AppColors.blanc, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Add to calendar',
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _CtaButton(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
        ),
        const Positioned.fill(child: ConfettiOverlay()),
      ],
    );
  }
}

// ─── Empty state ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gris.withAlpha(100), size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
