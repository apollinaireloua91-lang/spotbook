import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/booking_models.dart';
import '../../../domain/service_addon_models.dart';

/// Step 1 — Service selection (multi-select) + per-service add-ons.
///
/// UX pattern:
///   - Tapping a service card toggles it in the cart.
///   - When a service is selected, an "Extras" expandable section appears
///     inline with fetched add-ons. Add-ons toggle on/off via checkboxes.
///   - Running totals live in the sticky footer (parent screen).
///
/// This is the only step that's fundamentally new (not a port of the sheet).
class Step1Services extends StatelessWidget {
  const Step1Services({
    super.key,
    required this.services,
    required this.cart,
    required this.onToggleService,
    required this.onToggleAddon,
    required this.loadAddonsForService,
  });

  final List<ServiceModel> services;
  final BookingCart cart;
  final ValueChanged<ServiceModel> onToggleService;
  final void Function(String serviceId, ServiceAddon addon) onToggleAddon;
  final Future<List<ServiceAddon>> Function(String serviceId)
      loadAddonsForService;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.room_service_outlined,
                  color: AppColors.gris, size: 48),
              const SizedBox(height: 12),
              Text(
                'Aucun service disponible',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ce pro n\'a pas encore ajouté de services.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    color: AppColors.gris, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: services.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) {
          return _Header(selectedCount: cart.items.length);
        }
        final svc = services[i - 1];
        final cartIndex =
            cart.items.indexWhere((it) => it.serviceId == svc.id);
        final isSelected = cartIndex >= 0;
        final selectedAddons = isSelected
            ? cart.items[cartIndex].selectedAddons
            : const <ServiceAddon>[];

        return _ServiceCard(
          service: svc,
          isSelected: isSelected,
          selectedAddonIds: selectedAddons.map((a) => a.id).toSet(),
          onToggle: () {
            HapticFeedback.selectionClick();
            onToggleService(svc);
          },
          onToggleAddon: (addon) {
            HapticFeedback.selectionClick();
            onToggleAddon(svc.id, addon);
          },
          loadAddons: () => loadAddonsForService(svc.id),
        );
      },
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisis tes services',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedCount == 0
                ? 'Tu peux sélectionner plusieurs services — ils seront enchaînés.'
                : '$selectedCount service${selectedCount > 1 ? 's' : ''} sélectionné${selectedCount > 1 ? 's' : ''}',
            style:
                GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Service card with inline add-ons ────────────────────────────────

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.selectedAddonIds,
    required this.onToggle,
    required this.onToggleAddon,
    required this.loadAddons,
  });

  final ServiceModel service;
  final bool isSelected;
  final Set<String> selectedAddonIds;
  final VoidCallback onToggle;
  final ValueChanged<ServiceAddon> onToggleAddon;
  final Future<List<ServiceAddon>> Function() loadAddons;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  List<ServiceAddon>? _addons;
  bool _loading = false;

  @override
  void didUpdateWidget(covariant _ServiceCard old) {
    super.didUpdateWidget(old);
    // Lazy-load add-ons the first time a service is selected.
    if (widget.isSelected && !old.isSelected && _addons == null && !_loading) {
      _fetch();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isSelected && _addons == null) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = await widget.loadAddons();
      if (!mounted) return;
      setState(() {
        _addons = list.where((a) => a.isActive).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addons = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final priceLabel =
        CurrencyFormatter.formatAmount(svc.price, currency: svc.currency);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? AppColors.violet
              : AppColors.border.withValues(alpha: 0.5),
          width: widget.isSelected ? 1.5 : 0.5,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _Checkbox(isSelected: widget.isSelected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          svc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                color: AppColors.gris, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${svc.durationMinutes} min',
                              style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '  ·  ',
                              style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              priceLabel,
                              style: GoogleFonts.dmSans(
                                color: AppColors.violetClair,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (svc.description != null &&
                            svc.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            svc.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              color: AppColors.grisClair,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add-ons section (only when selected)
          if (widget.isSelected) _buildAddonsSection(svc),
        ],
      ),
    );
  }

  Widget _buildAddonsSection(ServiceModel svc) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final addons = _addons ?? [];
    if (addons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          thickness: 0.5,
          color: AppColors.border.withValues(alpha: 0.6),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline,
                  color: AppColors.violetClair, size: 14),
              const SizedBox(width: 6),
              Text(
                'Extras disponibles',
                style: GoogleFonts.dmSans(
                  color: AppColors.violetClair,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        ...addons.map((a) => _AddonRow(
              addon: a,
              currency: svc.currency,
              isSelected: widget.selectedAddonIds.contains(a.id),
              onToggle: () => widget.onToggleAddon(a),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Checkbox ────────────────────────────────────────────────────────

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.violet : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppColors.violet : AppColors.border,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}

// ─── Add-on row ──────────────────────────────────────────────────────

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.addon,
    required this.currency,
    required this.isSelected,
    required this.onToggle,
  });

  final ServiceAddon addon;
  final String currency;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final priceLabel =
        CurrencyFormatter.formatAmount(addon.price, currency: currency);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              _Checkbox(isSelected: isSelected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addon.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (addon.description != null &&
                        addon.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        addon.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+$priceLabel',
                    style: GoogleFonts.dmSans(
                      color: AppColors.violetClair,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (addon.durationMinutes > 0)
                    Text(
                      '+${addon.durationMinutes} min',
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
