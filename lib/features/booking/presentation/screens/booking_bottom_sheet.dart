import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../profile/domain/profile_models.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

void showBookingSheet(
  BuildContext context, {
  required String proId,
  required ProProfile proProfile,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(proId: proId, proProfile: proProfile),
  );
}

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
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              LinearProgressIndicator(
                value: (state.step + 1) / 6,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.blanc),
                minHeight: 2,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
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
        color: AppColors.gris,
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

// ─── Step 1: Services + Promo ─────────────────────────────

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
        const Text(
          'Choisir un service',
          style: TextStyle(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (state.isLoading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.blanc))
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
                onTap: () => ref
                    .read(bookingFlowProvider.notifier)
                    .selectService(service),
              );
            },
          ),
        const SizedBox(height: 24),
        const Text(
          'Code promo',
          style: TextStyle(
            color: AppColors.blanc,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: promoCtrl,
                style: const TextStyle(color: AppColors.blanc),
                decoration: InputDecoration(
                  hintText: 'Entrer un code',
                  hintStyle: const TextStyle(color: AppColors.gris),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.promoApplied
                  ? null
                  : () => ref
                      .read(bookingFlowProvider.notifier)
                      .validatePromo(promoCtrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blanc,
                foregroundColor: AppColors.fond,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: Text(state.promoApplied ? 'Appliqué' : 'Valider'),
            ),
          ],
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(state.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.selectedService != null ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blanc,
              foregroundColor: AppColors.fond,
              disabledBackgroundColor: AppColors.surfaceAlt,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Continuer',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blanc.withAlpha(20) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.blanc : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (service.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description!,
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${service.durationMinutes} min',
                    style: const TextStyle(
                        color: AppColors.gris, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${service.price.toStringAsFixed(2)} CA\$',
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Calendar ─────────────────────────────────────

class _Step2Calendar extends ConsumerWidget {
  const _Step2Calendar({required this.state});

  final BookingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final availableSet = state.availableDates.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
              onPressed: () =>
                  ref.read(bookingFlowProvider.notifier).previousStep(),
            ),
            const Text(
              'Choisir une date',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.isLoading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.blanc))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(now.year, now.month, day);
              final dateStr = date.toIso8601String().split('T')[0];
              final isAvailable = availableSet.contains(dateStr);
              final isSelected = state.selectedDate == dateStr;
              final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

              return GestureDetector(
                onTap: isAvailable && !isPast
                    ? () {
                        ref
                            .read(bookingFlowProvider.notifier)
                            .selectDate(dateStr);
                        ref.read(bookingFlowProvider.notifier).nextStep();
                      }
                    : null,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blanc
                        : (!isAvailable || isPast)
                            ? AppColors.surfaceAlt.withAlpha(80)
                            : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.blanc, width: 2)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.fond
                          : (!isAvailable || isPast)
                              ? AppColors.gris.withAlpha(100)
                              : AppColors.blanc,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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

// ─── Step 3: Time slots grid ──────────────────────────────

class _Step3Slots extends ConsumerWidget {
  const _Step3Slots({required this.state});

  final BookingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
              onPressed: () =>
                  ref.read(bookingFlowProvider.notifier).previousStep(),
            ),
            Text(
              'Créneaux — ${state.selectedDate ?? ''}',
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              state.error!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
        if (state.isLoading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.blanc))
        else if (state.timeSlots.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aucun créneau disponible',
                style: TextStyle(color: AppColors.gris, fontSize: 16),
              ),
            ),
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
                        ref
                            .read(bookingFlowProvider.notifier)
                            .selectSlot(slot);
                        ref.read(bookingFlowProvider.notifier).nextStep();
                      }
                    : null,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !slot.isAvailable
                        ? AppColors.surfaceAlt.withAlpha(80)
                        : isSelected
                            ? AppColors.blanc
                            : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: AppColors.blanc, width: 2)
                        : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    slot.startTime.substring(0, 5),
                    style: TextStyle(
                      color: !slot.isAvailable
                          ? AppColors.gris.withAlpha(100)
                          : isSelected
                              ? AppColors.fond
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

// ─── Step 4: Summary ──────────────────────────────────────

class _Step4Summary extends ConsumerWidget {
  const _Step4Summary({
    required this.state,
    required this.proProfile,
  });

  final BookingFlowState state;
  final ProProfile proProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
              onPressed: () =>
                  ref.read(bookingFlowProvider.notifier).previousStep(),
            ),
            const Text(
              'Récapitulatif',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Pro info
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.surfaceAlt,
              backgroundImage: proProfile.avatarUrl != null
                  ? CachedNetworkImageProvider(proProfile.avatarUrl!)
                  : null,
              child: proProfile.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.gris)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proProfile.businessName,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (proProfile.category.isNotEmpty)
                    Text(
                      proProfile.category,
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SummaryRow(
            label: 'Service', value: state.selectedService?.name ?? ''),
        _SummaryRow(label: 'Date', value: state.selectedDate ?? ''),
        _SummaryRow(
          label: 'Heure',
          value: state.selectedSlot?.startTime.substring(0, 5) ?? '',
        ),
        _SummaryRow(
          label: 'Durée',
          value: '${state.selectedService?.durationMinutes ?? 0} min',
        ),
        const Divider(color: AppColors.border, height: 32),
        if (state.promoApplied && state.promoCode != null)
          _SummaryRow(
            label: 'Promo (${state.promoCode!.code})',
            value: state.promoCode!.discountType == 'percentage'
                ? '-${state.promoCode!.discountValue.toStringAsFixed(0)}%'
                : '-${state.promoCode!.discountValue.toStringAsFixed(2)} CA\$',
            valueColor: AppColors.success,
          ),
        _SummaryRow(
          label: 'Total',
          value: '${state.totalPrice.toStringAsFixed(2)} CA\$',
        ),
        _SummaryRow(
          label: 'Acompte à payer',
          value: '${state.depositPrice.toStringAsFixed(2)} CA\$',
          isBold: true,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                ref.read(bookingFlowProvider.notifier).nextStep(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blanc,
              foregroundColor: AppColors.fond,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Payer ${state.depositPrice.toStringAsFixed(2)} CA\$',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.gris,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.blanc,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 5: Payment ──────────────────────────────────────

class _Step5Payment extends ConsumerWidget {
  const _Step5Payment({required this.state});

  final BookingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
              onPressed: () =>
                  ref.read(bookingFlowProvider.notifier).previousStep(),
            ),
            const Text(
              'Paiement',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: CardField(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Acompte de ${state.depositPrice.toStringAsFixed(2)} CA\$',
          style: const TextStyle(
            color: AppColors.gris,
            fontSize: 13,
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(state.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isCreating
                ? null
                : () async {
                    await ref
                        .read(bookingFlowProvider.notifier)
                        .createBooking();
                    final newState = ref.read(bookingFlowProvider);
                    if (newState.bookingResult != null) {
                      ref.read(bookingFlowProvider.notifier).nextStep();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blanc,
              foregroundColor: AppColors.fond,
              disabledBackgroundColor: AppColors.surfaceAlt,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: state.isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.gris, strokeWidth: 2),
                  )
                : Text(
                    'Confirmer ${state.depositPrice.toStringAsFixed(2)} CA\$',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Step 6: Confirmation ─────────────────────────────────

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

    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          width: 150,
          child: Lottie.asset(
            'assets/animations/success.json',
            repeat: false,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 100,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Réservation confirmée !',
          style: TextStyle(
            color: AppColors.blanc,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            bookingCode,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${state.selectedService?.name ?? ''} avec ${proProfile.businessName}',
          style: const TextStyle(color: AppColors.gris, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${state.selectedDate ?? ''} à ${state.selectedSlot?.startTime.substring(0, 5) ?? ''}',
          style: const TextStyle(color: AppColors.gris, fontSize: 14),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final date = state.selectedDate;
              final time = state.selectedSlot?.startTime;
              if (date != null && time != null) {
                final parts = date.split('-');
                final timeParts = time.split(':');
                final start = DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                  int.parse(timeParts[0]),
                  int.parse(timeParts[1]),
                );
                final end = start.add(Duration(
                    minutes: state.selectedService?.durationMinutes ?? 60));
                Add2Calendar.addEvent2Cal(Event(
                  title: '${state.selectedService?.name} — ${proProfile.businessName}',
                  description: 'Code : $bookingCode',
                  startDate: start,
                  endDate: end,
                ));
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blanc,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            label: const Text('Ajouter au calendrier'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blanc,
              foregroundColor: AppColors.fond,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Fermer',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
