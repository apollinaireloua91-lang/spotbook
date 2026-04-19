import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/squire_repository.dart';

/// Priority #3 — Tip sheet shown after service completion.
/// Uses quick-select percentages (10/15/20%) + custom amount option.
/// Tips are 100% to the pro (no Spotbook commission).
class TipSheet extends ConsumerStatefulWidget {
  const TipSheet({
    super.key,
    required this.bookingId,
    required this.proName,
    required this.bookingTotalCents,
    required this.currency,
  });

  final String bookingId;
  final String proName;
  final int bookingTotalCents;
  final String currency;

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required String proName,
    required int bookingTotalCents,
    required String currency,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TipSheet(
        bookingId: bookingId,
        proName: proName,
        bookingTotalCents: bookingTotalCents,
        currency: currency,
      ),
    );
  }

  @override
  ConsumerState<TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends ConsumerState<TipSheet> {
  int? _selectedPct;
  final _customCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int get _amountCents {
    if (_selectedPct != null) {
      return ((widget.bookingTotalCents * _selectedPct!) ~/ 100);
    }
    final raw = _customCtrl.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null) return 0;
    return (v * 100).round();
  }

  Future<void> _submit() async {
    if (_amountCents < 100) {
      _showSnack('Minimum 1,00 \$.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      final res = await repo.startTipPayment(
        bookingId: widget.bookingId,
        amountCents: _amountCents,
      );
      final clientSecret = res['clientSecret'] as String?;
      if (clientSecret == null) throw Exception('no_client_secret');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Spotbook',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _showSnack('✅ Merci ! Ton pourboire de '
          '${CurrencyFormatter.formatAmount(_amountCents / 100.0, currency: widget.currency)} est parti.');
      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (mounted) {
        _showSnack(e.error.localizedMessage ?? 'Paiement annulé');
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountCents;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
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
            'Laisser un pourboire',
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '100 % revient à ${widget.proName}. Aucune commission.',
            style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [10, 15, 20].map((pct) {
              final isSelected = _selectedPct == pct;
              final pctAmount =
                  (widget.bookingTotalCents * pct) ~/ 100 / 100.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedPct = pct;
                        _customCtrl.clear();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.violet
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.violet
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$pct %',
                            style: GoogleFonts.sora(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.blanc,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatAmount(pctAmount,
                                currency: widget.currency),
                            style: GoogleFonts.dmSans(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppColors.gris,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Ou un montant libre',
            style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _customCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() => _selectedPct = null),
            style: GoogleFonts.dmSans(
                color: AppColors.blanc, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.attach_money,
                  color: AppColors.gris, size: 20),
              hintText: '10.00',
              hintStyle:
                  GoogleFonts.dmSans(color: AppColors.gris, fontSize: 16),
              filled: true,
              fillColor: AppColors.surfaceAlt,
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
            ),
          ),
          const SizedBox(height: 20),
          SpotbookButton.primary(
            label: _submitting
                ? 'Traitement...'
                : (amount > 0
                    ? 'Donner ${CurrencyFormatter.formatAmount(amount / 100.0, currency: widget.currency)}'
                    : 'Donner un pourboire'),
            onPressed: (amount == 0 || _submitting) ? null : _submit,
          ),
          const SizedBox(height: 8),
          SpotbookButton.secondary(
            label: 'Non merci',
            onPressed:
                _submitting ? null : () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }
}
