import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/services/app_config_provider.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/utils/analytics_service.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/spotbook_button.dart';
import '../../../data/booking_notifier.dart';

/// Step 5 — Payment.
/// Creates the booking (atomic RPC) on mount, fetches the Stripe PaymentIntent
/// clientSecret, renders a CardField for card input, then confirms the payment.
/// On success, advances the flow to the confirmation step.
class Step5Payment extends ConsumerStatefulWidget {
  const Step5Payment({
    super.key,
    required this.state,
    required this.notifier,
    required this.currency,
  });

  final BookingFlowState state;
  final BookingFlowNotifier notifier;
  final String currency;

  @override
  ConsumerState<Step5Payment> createState() => _Step5PaymentState();
}

class _Step5PaymentState extends ConsumerState<Step5Payment> {
  bool _cardComplete = false;
  bool _confirming = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    // Create the booking + payment intent on first mount if not already done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(bookingFlowProvider);
      if (s.bookingResult == null && !s.isCreating) {
        widget.notifier.createBooking();
      }
    });
  }

  Future<void> _confirmPayment() async {
    final s = ref.read(bookingFlowProvider);
    final secret = s.clientSecret;
    if (secret == null) {
      setState(() => _localError = 'Paiement non initialisé. Réessaie.');
      return;
    }
    if (!_cardComplete) {
      setState(() => _localError = 'Saisis tes infos de carte');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _confirming = true;
      _localError = null;
    });

    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: secret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      await AnalyticsService.instance.capture(
        'booking_completed',
        properties: {
          'booking_id':
              s.bookingResult?['bookingId']?.toString() ?? '',
        },
      );
      if (!mounted) return;
      widget.notifier.nextStep();
    } on StripeException catch (e) {
      setState(() {
        _confirming = false;
        _localError = e.error.localizedMessage ?? 'Paiement refusé';
      });
      await AnalyticsService.instance.capture(
        'payment_failed',
        properties: {
          'booking_id':
              s.bookingResult?['bookingId']?.toString() ?? '',
          'error': e.error.localizedMessage ?? 'payment_failed',
        },
      );
    } catch (e) {
      setState(() {
        _confirming = false;
        _localError = 'Erreur paiement : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final cfg = ref.watch(appConfigProvider).value ?? AppConfig.fallback;
    final serviceFee = cfg.serviceFeeClient;
    final servicesTotal = flowState.totalPrice;
    final deposit =
        (servicesTotal * 0.30 * 100).roundToDouble() / 100;
    final dueNow = deposit + serviceFee;
    final remaining = servicesTotal - deposit;

    String fmt(double v) =>
        CurrencyFormatter.formatAmount(v, currency: widget.currency);

    final isInitializing =
        flowState.isCreating || flowState.clientSecret == null;
    final errorText = _localError ?? flowState.error;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          children: [
            Text(
              'Paiement',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tu règles l\'acompte maintenant, le solde sur place',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // ── Card input ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_card_rounded,
                          color: AppColors.violetClair, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Carte bancaire',
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.lock_outline,
                          color: AppColors.gris, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Stripe',
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CardField(
                    enablePostalCode: true,
                    style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 15,
                    ),
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
                      hintText: '1234 1234 1234 1234',
                      hintStyle: TextStyle(
                        color: AppColors.grisInactif,
                        fontSize: 14,
                      ),
                    ),
                    onCardChanged: (details) {
                      final complete = details?.complete ?? false;
                      if (complete != _cardComplete) {
                        setState(() => _cardComplete = complete);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount breakdown ───────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  _PaymentRow(
                      label: 'Total services', value: fmt(servicesTotal)),
                  const SizedBox(height: 8),
                  _PaymentRow(
                    label: 'Acompte (30%)',
                    value: fmt(deposit),
                    valueColor: AppColors.violetClair,
                  ),
                  const SizedBox(height: 8),
                  _PaymentRow(
                      label: 'Frais de service',
                      value: fmt(serviceFee)),
                  const SizedBox(height: 8),
                  _PaymentRow(
                      label: 'Solde sur place',
                      value: fmt(remaining),
                      muted: true),
                  const SizedBox(height: 12),
                  Container(
                    height: 0.5,
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'À payer maintenant',
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        fmt(dueNow),
                        style: GoogleFonts.sora(
                          color: AppColors.violetClair,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (errorText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorText,
                        style: GoogleFonts.dmSans(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Pay button (in-body, replaces footer CTA when valid) ──
            SpotbookButton.primary(
              label: 'Payer ${fmt(dueNow)}',
              icon: Icons.lock_rounded,
              onPressed: (isInitializing || _confirming || !_cardComplete)
                  ? null
                  : _confirmPayment,
              isLoading: isInitializing || _confirming,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                isInitializing
                    ? 'Initialisation du paiement...'
                    : 'Paiement sécurisé par Stripe',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.muted = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: muted ? AppColors.gris : AppColors.grisClair,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: valueColor ?? AppColors.blanc,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
