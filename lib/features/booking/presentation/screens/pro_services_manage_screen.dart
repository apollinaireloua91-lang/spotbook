import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../../shared/widgets/spotbook_text_field.dart';
import '../../domain/booking_models.dart';
import '../notifiers/pro_scheduling_notifiers.dart';

/// Gestion des prestations et tarifs côté pro (table `services`).
class ProServicesManageScreen extends ConsumerWidget {
  const ProServicesManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final state = ref.watch(proServicesNotifierProvider);
    final notifier = ref.read(proServicesNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
          ),
        ),
        title: Text(
          'Services et tarifs',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
      ),
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
                    style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13),
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
                        Icon(Icons.design_services_outlined,
                            color: AppColors.gris, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun service pour le moment.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                            color: AppColors.gris,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez un service, sa durée et votre tarif — les clients les verront lors de la réservation.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        SpotbookButton.primary(
                          label: 'Ajouter un service',
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
                      priceLabel: CurrencyFormatter.formatAmount(s.price,
                          currency: s.currency),
                      onEdit: () => _openServiceSheet(context, ref, s),
                      onToggle: () {
                        HapticFeedback.selectionClick();
                        notifier.toggleActive(s);
                      },
                      onManageAddons: () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '/pro/services/${s.id}/addons',
                          extra: {
                            'serviceName': s.name,
                            'currency': s.currency,
                            'proId': s.proId,
                          },
                        );
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
    final l = AppLocalizations.of(context)!;
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
                      existing == null ? 'Nouveau service' : 'Modifier le service',
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SpotbookTextField(
                      controller: nameCtrl,
                      label: l.serviceName,
                      hint: 'Ex. Massage suédois 60 min',
                    ),
                    const SizedBox(height: 12),
                    SpotbookTextField(
                      controller: descCtrl,
                      label: l.descriptionOptional,
                      hint: 'Détails pour le client',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SpotbookTextField(
                            controller: priceCtrl,
                            label: l.priceCad,
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
                              Text(
                                'Durée',
                                style: GoogleFonts.dmSans(
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
                                    style: GoogleFonts.dmSans(
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
                    Text(
                      'Mode de paiement',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PaymentModeRadio(
                      label: l.fullPayment,
                      subtitle: 'Le client paie le montant total en ligne',
                      selected: paymentMode == 'full',
                      onTap: () => setModal(() => paymentMode = 'full'),
                    ),
                    const SizedBox(height: 8),
                    _PaymentModeRadio(
                      label: l.depositPlusSurplace,
                      subtitle: 'Le client paie un acompte en ligne, le reste au rendez-vous',
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
                                  'Pourcentage',
                                  style: GoogleFonts.dmSans(
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
                                  'Montant fixe',
                                  style: GoogleFonts.dmSans(
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
                              style: GoogleFonts.sora(
                                color: AppColors.blanc,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: depositPctValue,
                                min: 10,
                                max: 30,
                                divisions: 4,
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
                          label: l.depositAmountCad,
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
                            'Le client paiera $depositPreview \$ en ligne et $remainingPreview \$ sur place',
                            style: GoogleFonts.dmSans(
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
                        title: Text(
                          'Service actif',
                          style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Désactiver pour masquer des nouvelles réservations.',
                          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
                        ),
                        value: active,
                        activeThumbColor: AppColors.fond,
                        activeTrackColor: AppColors.blanc,
                        onChanged: (v) => setModal(() => active = v),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SpotbookButton.primary(
                      label: existing == null ? 'Enregistrer' : 'Mettre à jour',
                      isLoading: ref.read(proServicesNotifierProvider).saving,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.length < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.serviceNameMinChars)),
                          );
                          return;
                        }
                        final price = double.tryParse(
                          priceCtrl.text.replaceAll(',', '.'),
                        );
                        if (price == null || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.invalidPrice)),
                          );
                          return;
                        }

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
                            if (depValue == null || depValue <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.invalidDepositAmount)),
                              );
                              return;
                            }
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
                        if (context.mounted) {
                          if (ok) {
                            context.pop();
                          } else {
                            final err = ref.read(proServicesNotifierProvider).error;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err ?? 'Échec de l\'enregistrement du service'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SpotbookButton.outlined(
                      label: l.cancel,
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
                    style: GoogleFonts.dmSans(
                      color: selected ? AppColors.blanc : AppColors.gris,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11),
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
    required this.onManageAddons,
  });

  final ServiceModel service;
  final String priceLabel;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onManageAddons;

  String _depositLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!service.isDepositMode) return l.fullPayment;
    if (service.depositType == 'fixed') {
      return 'Acompte ${service.depositValue?.toStringAsFixed(0) ?? '—'} \$';
    }
    return 'Acompte ${service.depositValue?.toInt() ?? 30} %';
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
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${service.durationMinutes} min · $priceLabel · ${_depositLabel(context)}',
                        style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
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
                    child: Text(
                      'Inactif',
                      style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 11, fontWeight: FontWeight.w500),
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
                style: GoogleFonts.dmSans(color: AppColors.grisClair, fontSize: 13, height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SpotbookButton.secondary(
                    label: 'Modifier',
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                // Manage add-ons — compact icon button with label
                Material(
                  color: AppColors.violet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onManageAddons,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded,
                              color: AppColors.violetClair, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Extras',
                            style: GoogleFonts.dmSans(
                              color: AppColors.violetClair,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
