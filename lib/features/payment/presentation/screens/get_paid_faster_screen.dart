import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/payout_repository.dart';
import '../../domain/payout_models.dart';

/// "Get Paid Faster" screen — Squire-style payout dashboard for Pros.
///
/// Features:
///   - Available balance card with "Encaisser maintenant" CTA (Stripe Instant)
///   - Fee breakdown explaining 1.5% instant fee + 30min arrival
///   - Schedule preferences (standard / daily / weekly / manual)
///   - Payout history with status chips
class GetPaidFasterScreen extends ConsumerStatefulWidget {
  const GetPaidFasterScreen({super.key});

  @override
  ConsumerState<GetPaidFasterScreen> createState() =>
      _GetPaidFasterScreenState();
}

class _GetPaidFasterScreenState extends ConsumerState<GetPaidFasterScreen> {
  PayoutPreferences? _prefs;
  List<PayoutRequest> _history = [];
  bool _loading = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(payoutRepositoryProvider);
      final results = await Future.wait([
        repo.loadPreferences(),
        repo.listHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _prefs = results[0] as PayoutPreferences;
        _history = results[1] as List<PayoutRequest>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openInstantPayoutSheet() async {
    final result = await _InstantPayoutSheet.show(
      context: context,
      onRequest: (amountCents) async {
        setState(() => _requesting = true);
        try {
          final repo = ref.read(payoutRepositoryProvider);
          final res = await repo.requestPayout(
            amountCents: amountCents,
            method: PayoutMethod.instant,
          );
          if (!mounted) return false;
          Navigator.pop(context);
          _showSuccess(
              '✅ ${CurrencyFormatter.formatAmount((res['netCents'] as int) / 100.0, currency: res['currency'] as String? ?? 'CAD')} arrive dans ~30 minutes.');
          await _load();
          return true;
        } on PayoutException catch (e) {
          _showError(e.userMessage);
          return false;
        } catch (e) {
          _showError(e.toString());
          return false;
        } finally {
          if (mounted) setState(() => _requesting = false);
        }
      },
    );
    // No-op; sheet closes itself on success
    if (result != null) await _load();
  }

  Future<void> _toggleInstantEnabled(bool value) async {
    final current = _prefs;
    if (current == null) return;
    final next = current.copyWith(instantEnabled: value);
    setState(() => _prefs = next);
    try {
      final repo = ref.read(payoutRepositoryProvider);
      await repo.savePreferences(next);
      HapticFeedback.selectionClick();
    } catch (e) {
      setState(() => _prefs = current);
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                color: AppColors.blanc, size: 16),
          ),
        ),
        title: Text(
          'Être payé plus vite',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SpotbookLoadingShimmer.card(itemCount: 4),
            )
          : RefreshIndicator(
              color: AppColors.violet,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  _HeroCard(
                    onPayoutNow: _requesting ? null : _openInstantPayoutSheet,
                  ),
                  const SizedBox(height: 16),
                  if (_prefs != null)
                    _PreferencesCard(
                      prefs: _prefs!,
                      onToggleInstant: _toggleInstantEnabled,
                    ),
                  const SizedBox(height: 16),
                  _HistoryHeader(count: _history.length),
                  const SizedBox(height: 8),
                  if (_history.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aucun paiement',
                      subtitle:
                          'Tes paiements rapides apparaîtront ici.',
                    )
                  else
                    ..._history.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PayoutRow(request: r),
                        )),
                ],
              ),
            ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onPayoutNow});
  final VoidCallback? onPayoutNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet,
            AppColors.violet.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Paiement instantané',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Encaisse tes revenus en 30 minutes au lieu de 2–7 jours.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SpotbookButton.primary(
                  label: 'Encaisser maintenant',
                  icon: Icons.flash_on,
                  onPressed: onPayoutNow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                'Frais : 1,5 % (max 15 \$). Carte débit requise.',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Preferences card ────────────────────────────────────────────────

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.prefs,
    required this.onToggleInstant,
  });

  final PayoutPreferences prefs;
  final ValueChanged<bool> onToggleInstant;

  String _scheduleLabel() {
    switch (prefs.schedule) {
      case PayoutSchedule.standard:
        return 'Standard (2–7 jours ouvrables)';
      case PayoutSchedule.daily:
        return 'Quotidien (auto chaque jour)';
      case PayoutSchedule.weekly:
        return 'Hebdomadaire (auto chaque semaine)';
      case PayoutSchedule.manual:
        return 'Manuel (tu décides)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpotbookCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded,
                  color: AppColors.violetClair, size: 18),
              const SizedBox(width: 8),
              Text(
                'Préférences de paiement',
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fréquence automatique',
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      _scheduleLabel(),
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            thickness: 0.5,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activer le paiement instantané',
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Autorise le bouton "Encaisser maintenant" (1,5 %)',
                      style: GoogleFonts.dmSans(
                          color: AppColors.gris, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: prefs.instantEnabled,
                onChanged: onToggleInstant,
                activeThumbColor: AppColors.violet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── History ─────────────────────────────────────────────────────────

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.history_rounded, color: AppColors.gris, size: 18),
        const SizedBox(width: 8),
        Text(
          'Historique',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          '$count paiement${count > 1 ? 's' : ''}',
          style: GoogleFonts.dmSans(
              color: AppColors.gris, fontSize: 12),
        ),
      ],
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.request});
  final PayoutRequest request;

  Color _statusColor(PayoutStatus s) {
    switch (s) {
      case PayoutStatus.paid:
        return AppColors.success;
      case PayoutStatus.failed:
      case PayoutStatus.cancelled:
        return AppColors.error;
      case PayoutStatus.processing:
      case PayoutStatus.pending:
        return AppColors.warning;
    }
  }

  String _statusLabel(PayoutStatus s) {
    switch (s) {
      case PayoutStatus.paid:
        return 'Versé';
      case PayoutStatus.processing:
        return 'En cours';
      case PayoutStatus.pending:
        return 'En attente';
      case PayoutStatus.failed:
        return 'Échec';
      case PayoutStatus.cancelled:
        return 'Annulé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInstant = request.method == PayoutMethod.instant;
    return SpotbookCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isInstant ? AppColors.violet : AppColors.gris)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInstant ? Icons.bolt : Icons.schedule_send,
              color: isInstant ? AppColors.violet : AppColors.gris,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(request.netDollars,
                          currency: request.currency),
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (request.feeCents > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(−${CurrencyFormatter.formatAmount(request.feeDollars, currency: request.currency)} frais)',
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy · HH:mm', 'fr_FR')
                      .format(request.requestedAt.toLocal()),
                  style: GoogleFonts.dmSans(
                      color: AppColors.gris, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor(request.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(request.status),
              style: GoogleFonts.dmSans(
                color: _statusColor(request.status),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Instant payout bottom sheet ─────────────────────────────────────

class _InstantPayoutSheet extends StatefulWidget {
  const _InstantPayoutSheet({required this.onRequest});
  final Future<bool> Function(int amountCents) onRequest;

  static Future<bool?> show({
    required BuildContext context,
    required Future<bool> Function(int amountCents) onRequest,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _InstantPayoutSheet(onRequest: onRequest),
    );
  }

  @override
  State<_InstantPayoutSheet> createState() => _InstantPayoutSheetState();
}

class _InstantPayoutSheetState extends State<_InstantPayoutSheet> {
  final TextEditingController _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int? _amountCents() {
    final raw = _ctrl.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v < 1) return null;
    return (v * 100).round();
  }

  int _feeCents(int amountCents) {
    final fee = (amountCents * 0.015).ceil();
    const cap = 1500; // $15 USD
    return fee > cap ? cap : fee;
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountCents();
    final fee = amount != null ? _feeCents(amount) : 0;
    final net = amount != null ? amount - fee : 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Encaisser maintenant',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Arrive dans ~30 minutes sur ta carte débit.',
            style: GoogleFonts.dmSans(
                color: AppColors.gris, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Amount input
          TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.attach_money,
                    color: AppColors.gris, size: 28),
              ),
              hintText: '0.00',
              hintStyle: GoogleFonts.sora(
                color: AppColors.gris,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.violet, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.surfaceAlt,
            ),
          ),
          const SizedBox(height: 16),
          if (amount != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  _BreakdownRow(
                    label: 'Montant demandé',
                    value:
                        CurrencyFormatter.formatAmount(amount / 100.0),
                  ),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: 'Frais (1,5 %, max 15 \$)',
                    value:
                        '−${CurrencyFormatter.formatAmount(fee / 100.0)}',
                    valueColor: AppColors.warning,
                  ),
                  Divider(
                    height: 16,
                    thickness: 0.5,
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                  _BreakdownRow(
                    label: 'Net reçu',
                    value: CurrencyFormatter.formatAmount(net / 100.0),
                    valueBold: true,
                    valueColor: AppColors.violetClair,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SpotbookButton.primary(
            label: _submitting
                ? 'Traitement...'
                : 'Confirmer le paiement',
            icon: Icons.bolt,
            onPressed: (amount == null || _submitting)
                ? null
                : () async {
                    setState(() => _submitting = true);
                    final ok = await widget.onRequest(amount);
                    if (mounted) setState(() => _submitting = false);
                    if (!ok && mounted) {
                      // Stay open — error shown via SnackBar
                    }
                  },
          ),
          const SizedBox(height: 8),
          SpotbookButton.secondary(
            label: 'Annuler',
            onPressed:
                _submitting ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: valueColor ?? AppColors.blanc,
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
