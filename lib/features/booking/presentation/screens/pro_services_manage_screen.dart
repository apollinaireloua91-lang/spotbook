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

  static final _money = NumberFormat.currency(locale: 'fr_CA', symbol: r'$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proServicesNotifierProvider);
    final notifier = ref.read(proServicesNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: const SpotbookAppBar(title: 'Services & tarifs'),
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
                          'Aucun service pour l’instant.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.gris, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajoute une prestation, sa durée et ton tarif — les clients les verront dans le flux de réservation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.gris, fontSize: 13),
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
    var duration = existing?.durationMinutes ?? 60;
    var active = existing?.isActive ?? true;

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
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'Nouveau service' : 'Modifier le service',
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SpotbookTextField(
                      controller: nameCtrl,
                      label: 'Nom',
                      hint: 'Ex. Massage suédois 60 min',
                    ),
                    const SizedBox(height: 12),
                    SpotbookTextField(
                      controller: descCtrl,
                      label: 'Description (optionnel)',
                      hint: 'Détails pour le client',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SpotbookTextField(
                            controller: priceCtrl,
                            label: 'Tarif (CAD)',
                            hint: '80.00',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Durée',
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
                    if (existing != null) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Service actif',
                          style: TextStyle(color: AppColors.blanc, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Désactive pour le masquer des nouvelles réservations.',
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
                      label: existing == null ? 'Enregistrer' : 'Mettre à jour',
                      isLoading: ref.read(proServicesNotifierProvider).saving,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.length < 2) return;
                        final price = double.tryParse(
                          priceCtrl.text.replaceAll(',', '.'),
                        );
                        if (price == null || price <= 0) return;

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
                              );
                        if (ok && context.mounted) context.pop();
                      },
                    ),
                    const SizedBox(height: 8),
                    SpotbookButton.outlined(
                      label: 'Annuler',
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
                        '${service.durationMinutes} min · $priceLabel',
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
                      'Inactif',
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
                    label: 'Modifier',
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
