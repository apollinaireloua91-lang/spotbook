import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_app_bar.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../../shared/widgets/spotbook_text_field.dart';
import '../../domain/booking_models.dart';
import '../notifiers/pro_scheduling_notifiers.dart';

/// Gestion des prestations et tarifs côté pro (table `services`).
class ProServicesManageScreen extends ConsumerWidget {
  const ProServicesManageScreen({super.key});

  static final _money = NumberFormat.currency(locale: 'en_CA', symbol: r'$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proServicesNotifierProvider);
    final notifier = ref.read(proServicesNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: const SpotbookAppBar(title: 'Services & pricing'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.fond,
        onPressed: state.saving
            ? null
            : () => _openServiceSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppColors.blanc,
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ),
            if (state.loading)
              const SliverFillRemaining(
                child: SpotbookLoadingShimmer.list(itemCount: 6),
              )
            else if (state.services.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.design_services_outlined,
                            color: AppColors.gris, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'No services yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.gris, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add a service, its duration and your rate — clients will see them in the booking flow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.gris, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        SpotbookButton.primary(
                          label: 'Add a service',
                          onPressed: () => _openServiceSheet(context, ref, null),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList.separated(
                  itemCount: state.services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = state.services[i];
                    return _ServiceTile(
                      service: s,
                      priceLabel: _money.format(s.price),
                      onEdit: () => _openServiceSheet(context, ref, s),
                      onToggle: () {
                        HapticFeedback.selectionClick();
                        notifier.toggleActive(s);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openServiceSheet(
    BuildContext context,
    WidgetRef ref,
    ServiceModel? existing,
  ) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(2) : '',
    );
    final fixedAmountCtrl = TextEditingController(
      text: existing?.depositType == 'fixed' && existing?.depositValue != null
          ? existing!.depositValue!.toStringAsFixed(2)
          : '',
    );
    var duration = existing?.durationMinutes ?? 60;
    var active = existing?.isActive ?? true;
    var paymentMode = existing?.paymentMode ?? 'full';
    var depositType = existing?.depositType ?? 'percentage';
    var depositPctValue = existing?.depositType == 'percentage'
        ? (existing?.depositValue ?? 30)
        : 30.0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              final price = double.tryParse(
                priceCtrl.text.replaceAll(',', '.'),
              );

              // Compute preview amounts.
              String? depositPreview;
              String? remainingPreview;
              if (price != null && price > 0 && paymentMode == 'deposit') {
                double dep;
                if (depositType == 'fixed') {
                  final fixedVal = double.tryParse(
                    fixedAmountCtrl.text.replaceAll(',', '.'),
                  );
                  dep = (fixedVal != null && fixedVal > 0)
                      ? (fixedVal > price ? price : fixedVal)
                      : 0;
                } else {
                  dep = price * depositPctValue / 100;
                }
                if (dep > 0) {
                  depositPreview = dep.toStringAsFixed(2);
                  remainingPreview = (price - dep).toStringAsFixed(2);
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'New service' : 'Edit service',
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SpotbookTextField(
                      controller: nameCtrl,
                      label: 'Name',
                      hint: 'E.g. Swedish massage 60 min',
                    ),
                    const SizedBox(height: 12),
                    SpotbookTextField(
                      controller: descCtrl,
                      label: 'Description (optional)',
                      hint: 'Details for the client',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SpotbookTextField(
                            controller: priceCtrl,
                            label: 'Rate (CAD)',
                            hint: '80.00',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setModal(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duration',
                                style: TextStyle(
                                  color: AppColors.gris,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                    value: duration,
                                    isExpanded: true,
                                    dropdownColor: AppColors.surfaceAlt,
                                    style: const TextStyle(
                                        color: AppColors.blanc, fontSize: 15),
                                    items: const [
                                      DropdownMenuItem(value: 15, child: Text('15 min')),
                                      DropdownMenuItem(value: 30, child: Text('30 min')),
                                      DropdownMenuItem(value: 45, child: Text('45 min')),
                                      DropdownMenuItem(value: 60, child: Text('60 min')),
                                      DropdownMenuItem(value: 90, child: Text('90 min')),
                                      DropdownMenuItem(value: 120, child: Text('120 min')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setModal(() => duration = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ─── Payment mode: full vs deposit ──────────────────
                    const SizedBox(height: 20),
                    const Text(
                      'Payment mode',
                      style: TextStyle(
                        color: AppColors.gris,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PaymentModeRadio(
                      label: 'Full payment',
                      subtitle: 'Client pays the full amount online',
                      selected: paymentMode == 'full',
                      onTap: () => setModal(() => paymentMode = 'full'),
                    ),
                    const SizedBox(height: 8),
                    _PaymentModeRadio(
                      label: 'Deposit + remainder on site',
                      subtitle: 'Client pays a deposit online, the rest at the appointment',
                      selected: paymentMode == 'deposit',
                      onTap: () => setModal(() => paymentMode = 'deposit'),
                    ),

                    // ─── Deposit config (only if deposit mode) ──────────
                    if (paymentMode == 'deposit') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModal(() => depositType = 'percentage'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: depositType == 'percentage'
                                      ? AppColors.blanc.withAlpha(15)
                                      : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: depositType == 'percentage'
                                        ? AppColors.blanc
                                        : AppColors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Percentage',
                                  style: TextStyle(
                                    color: depositType == 'percentage'
                                        ? AppColors.blanc
                                        : AppColors.gris,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModal(() => depositType = 'fixed'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: depositType == 'fixed'
                                      ? AppColors.blanc.withAlpha(15)
                                      : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: depositType == 'fixed'
                                        ? AppColors.blanc
                                        : AppColors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Fixed amount',
                                  style: TextStyle(
                                    color: depositType == 'fixed'
                                        ? AppColors.blanc
                                        : AppColors.gris,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (depositType == 'percentage') ...[
                        Row(
                          children: [
                            Text(
                              '${depositPctValue.toInt()} %',
                              style: const TextStyle(
                                color: AppColors.blanc,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: depositPctValue,
                                min: 10,
                                max: 50,
                                divisions: 8,
                                activeColor: AppColors.blanc,
                                inactiveColor: AppColors.border,
                                label: '${depositPctValue.toInt()} %',
                                onChanged: (v) =>
                                    setModal(() => depositPctValue = v),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SpotbookTextField(
                          controller: fixedAmountCtrl,
                          label: 'Deposit amount (CAD)',
                          hint: '100.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setModal(() {}),
                        ),
                      ],
                      if (depositPreview != null && remainingPreview != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Client will pay \$$depositPreview online and \$$remainingPreview on site',
                            style: const TextStyle(
                              color: AppColors.gris,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],

                    if (existing != null) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active service',
                          style: TextStyle(color: AppColors.blanc, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Disable to hide from new bookings.',
                          style: TextStyle(color: AppColors.gris, fontSize: 12),
                        ),
                        value: active,
                        activeThumbColor: AppColors.fond,
                        activeTrackColor: AppColors.blanc,
                        onChanged: (v) => setModal(() => active = v),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SpotbookButton.primary(
                      label: existing == null ? 'Save' : 'Update',
                      isLoading: ref.read(proServicesNotifierProvider).saving,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.length < 2) return;
                        final price = double.tryParse(
                          priceCtrl.text.replaceAll(',', '.'),
                        );
                        if (price == null || price <= 0) return;

                        // Resolve deposit value.
                        final isDeposit = paymentMode == 'deposit';
                        double? depValue;
                        String? depType;
                        double legacyPct = 1.0;
                        if (isDeposit) {
                          depType = depositType;
                          if (depositType == 'percentage') {
                            depValue = depositPctValue;
                            legacyPct = depositPctValue / 100;
                          } else {
                            depValue = double.tryParse(
                              fixedAmountCtrl.text.replaceAll(',', '.'),
                            );
                            if (depValue == null || depValue <= 0) return;
                            legacyPct = (depValue / price).clamp(0.10, 1.0);
                          }
                        }

                        HapticFeedback.mediumImpact();
                        final n = ref.read(proServicesNotifierProvider.notifier);
                        final ok = existing == null
                            ? await n.createService(
                                name: name,
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                durationMinutes: duration,
                                price: price,
                                depositPercentage: legacyPct,
                                paymentMode: paymentMode,
                                depositType: depType,
                                depositValue: depValue,
                              )
                            : await n.updateService(
                                existing,
                                name: name,
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                durationMinutes: duration,
                                price: price,
                                isActive: active,
                                depositPercentage: legacyPct,
                                paymentMode: paymentMode,
                                depositType: depType,
                                depositValue: depValue,
                              );
                        if (ok && context.mounted) context.pop();
                      },
                    ),
                    const SizedBox(height: 8),
                    SpotbookButton.outlined(
                      label: 'Cancel',
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

class _PaymentModeRadio extends StatelessWidget {
  const _PaymentModeRadio({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.blanc.withAlpha(15) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.blanc : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.blanc : AppColors.gris,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppColors.blanc : AppColors.gris,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.gris, fontSize: 11),
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

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.priceLabel,
    required this.onEdit,
    required this.onToggle,
  });

  final ServiceModel service;
  final String priceLabel;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  String get _depositLabel {
    if (!service.isDepositMode) return 'Full payment';
    if (service.depositType == 'fixed') {
      return 'Deposit ${service.depositValue?.toStringAsFixed(0) ?? '—'} \$';
    }
    return 'Deposit ${service.depositValue?.toInt() ?? 30} %';
  }

  @override
  Widget build(BuildContext context) {
    return SpotbookCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 4),
                      Text(
                        '${service.durationMinutes} min · $priceLabel · $_depositLabel',
                        style: const TextStyle(color: AppColors.gris, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!service.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gris.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(color: AppColors.gris, fontSize: 11),
                    ),
                  ),
              ],
            ),
            if (service.description != null &&
                service.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                service.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grisClair, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SpotbookButton.secondary(
                    label: 'Edit',
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceAlt,
                    foregroundColor: AppColors.blanc,
                  ),
                  onPressed: onToggle,
                  icon: Icon(
                    service.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
