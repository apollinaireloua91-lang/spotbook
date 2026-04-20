import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../data/event_notifier.dart';
import '../../data/event_repository.dart';
import '../../domain/event_models.dart';

void showBuyTicketSheet(
  BuildContext context, {
  required TicketTypeModel ticketType,
  required EventModel event,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _BuyTicketSheet(ticketType: ticketType, event: event),
  );
}

class _BuyTicketSheet extends ConsumerStatefulWidget {
  const _BuyTicketSheet({required this.ticketType, required this.event});
  final TicketTypeModel ticketType;
  final EventModel event;

  @override
  ConsumerState<_BuyTicketSheet> createState() => _BuyTicketSheetState();
}

class _BuyTicketSheetState extends ConsumerState<_BuyTicketSheet> {
  /// Stripe fires per-keystroke completeness events — we mirror them here
  /// so the pay button only activates with a valid card (matches step5).
  bool _cardComplete = false;
  bool _platformPaySupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyTicketProvider.notifier).selectType(widget.ticketType);
    });
    _checkPlatformPaySupport();
  }

  Future<void> _checkPlatformPaySupport() async {
    try {
      final supported = await Stripe.instance.isPlatformPaySupported();
      if (!mounted) return;
      setState(() => _platformPaySupported = supported);
    } catch (_) {
      // If the SDK can't answer, silently hide the native button.
    }
  }

  Future<bool> _ensureIntent() async {
    final flow = ref.read(buyTicketProvider);
    if (flow.clientSecret != null && flow.paymentIntentId != null) {
      return true;
    }
    await ref.read(buyTicketProvider.notifier).createIntent();
    final after = ref.read(buyTicketProvider);
    return after.clientSecret != null && after.paymentIntentId != null;
  }

  Future<void> _confirmPlatformPay() async {
    final l = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();

    if (!await _ensureIntent()) return;
    final flow = ref.read(buyTicketProvider);

    try {
      // Stripe veut le code ISO 4217 en minuscules ('cad' pas 'CAD').
      final currencyCode = widget.ticketType.currency.toLowerCase();
      final confirmParams = Platform.isIOS
          ? PlatformPayConfirmParams.applePay(
              applePay: ApplePayParams(
                merchantCountryCode: 'CA',
                currencyCode: currencyCode,
                cartItems: [
                  ApplePayCartSummaryItem.immediate(
                    label: 'Spotbook — ${widget.event.title}',
                    amount: flow.grandTotal.toStringAsFixed(2),
                  ),
                ],
              ),
            )
          : PlatformPayConfirmParams.googlePay(
              googlePay: GooglePayParams(
                merchantCountryCode: 'CA',
                currencyCode: currencyCode,
                testEnv: true,
              ),
            );
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: flow.clientSecret!,
        confirmParams: confirmParams,
      );
      await _recordTicketsAndClose(flow.paymentIntentId!, flow.quantity);
    } on StripeException catch (e) {
      final canceled = e.error.code == FailureCode.Canceled;
      if (!canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.error.localizedMessage ?? l.paymentFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmCardPayment() async {
    final l = AppLocalizations.of(context)!;
    if (!_cardComplete) return;
    HapticFeedback.mediumImpact();

    if (!await _ensureIntent()) return;
    final flow = ref.read(buyTicketProvider);

    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: flow.clientSecret!,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      await _recordTicketsAndClose(flow.paymentIntentId!, flow.quantity);
    } on StripeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.error.localizedMessage ?? l.paymentFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _recordTicketsAndClose(
    String paymentIntentId,
    int quantity,
  ) async {
    final l = AppLocalizations.of(context)!;
    final repo = ref.read(eventRepositoryProvider);
    await repo.createTickets(
      ticketTypeId: widget.ticketType.id,
      eventId: widget.event.id,
      quantity: quantity,
      stripePaymentIntentId: paymentIntentId,
    );
    ref.invalidate(userTicketsProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.ticketPurchasedSnack),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyTicketProvider);
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + safeBottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderRow(event: widget.event, onClose: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    }),
                    const SizedBox(height: 18),
                    _TicketSummaryCard(
                      type: widget.ticketType,
                      event: widget.event,
                    ),
                    const SizedBox(height: 18),
                    _QuantityStepper(
                      quantity: state.quantity,
                      maxQuantity:
                          widget.ticketType.remaining.clamp(0, 4),
                      remaining: widget.ticketType.remaining,
                      onDecrement: state.quantity > 1
                          ? () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(buyTicketProvider.notifier)
                                  .setQuantity(state.quantity - 1);
                            }
                          : null,
                      onIncrement: (state.quantity < 4 &&
                              state.quantity <
                                  widget.ticketType.remaining)
                          ? () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(buyTicketProvider.notifier)
                                  .setQuantity(state.quantity + 1);
                            }
                          : null,
                      l: l,
                    ),
                    const SizedBox(height: 18),
                    _PriceBreakdown(
                      subtotal: state.subtotal,
                      serviceFee: state.serviceFee,
                      serviceFeePerTicket: state.serviceFeePerTicket,
                      commission: state.commission,
                      quantity: state.quantity,
                      grandTotal: state.grandTotal,
                      commissionPct: state.commissionPct,
                      currency: widget.ticketType.currency,
                      l: l,
                    ),
                    const SizedBox(height: 22),
                    if (_platformPaySupported) ...[
                      _PlatformPayButton(
                        onTap: state.isLoading ? null : _confirmPlatformPay,
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 14),
                      _OrDivider(label: l.orSeparator),
                      const SizedBox(height: 14),
                    ],
                    _CardFieldSection(
                      onCardChanged: (c) {
                        final complete = c?.complete ?? false;
                        if (complete != _cardComplete) {
                          setState(() => _cardComplete = complete);
                        }
                      },
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 10),
                      _ErrorBanner(message: state.error!),
                    ],
                    const SizedBox(height: 18),
                    _PayButton(
                      enabled: _cardComplete && !state.isLoading,
                      isLoading: state.isLoading,
                      amount: CurrencyFormatter.formatAmount(
                        state.grandTotal,
                        currency: widget.ticketType.currency,
                      ),
                      onTap: _confirmCardPayment,
                    ),
                    const SizedBox(height: 12),
                    const _SecurityNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Handle + header
// ═════════════════════════════════════════════════════════════════════════════

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gris.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.event, required this.onClose});
  final EventModel event;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Checkout',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              event.title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.blanc,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Ticket summary card — torn-ticket metaphor mirroring event detail
// ═════════════════════════════════════════════════════════════════════════════

class _TicketSummaryCard extends StatelessWidget {
  const _TicketSummaryCard({required this.type, required this.event});
  final TicketTypeModel type;
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.violet.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left stub — shows cover thumbnail or fallback gradient
          SizedBox(
            width: 72,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.violet.withValues(alpha: 0.8),
                    AppColors.rose.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.coverUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.3),
                          BlendMode.darken,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: event.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Center(
                    child: Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _DashedSeam(color: AppColors.border),
          // Body — ticket name + event meta
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    type.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (event.eventDate != null)
                    _MetaRow(
                      icon: Icons.event_rounded,
                      text: DateFormat('EEE d MMM · HH:mm')
                          .format(event.eventDate!),
                    ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    _MetaRow(
                      icon: Icons.location_on_rounded,
                      text: event.location!,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatAmount(
                      type.price,
                      currency: type.currency,
                    ),
                    style: GoogleFonts.sora(
                      color: AppColors.violetClair,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gris, size: 12),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedSeam extends StatelessWidget {
  const _DashedSeam({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 80.0;
        const dashHeight = 4.0;
        const gap = 4.0;
        final dashCount = (height / (dashHeight + gap)).floor().clamp(1, 40);
        return SizedBox(
          width: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: 1,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              );
            }),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Quantity stepper
// ═════════════════════════════════════════════════════════════════════════════

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.remaining,
    required this.onDecrement,
    required this.onIncrement,
    required this.l,
  });

  final int quantity;
  final int maxQuantity;
  final int remaining;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.ticketQuantity,
                style: GoogleFonts.dmSans(
                  color: AppColors.blanc,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$remaining remaining',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            semanticsLabel: l.ticketDecreaseQty,
          ),
          SizedBox(
            width: 54,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            semanticsLabel: l.ticketIncreaseQty,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.emphasized = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticsLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled && emphasized
                  ? AppColors.gradientAccent
                  : null,
              color: enabled && emphasized
                  ? null
                  : (enabled ? AppColors.surface : AppColors.surfaceAlt),
              border: Border.all(
                color: enabled && !emphasized
                    ? AppColors.border
                    : Colors.transparent,
                width: 0.5,
              ),
              boxShadow: enabled && emphasized && AppColors.isDark
                  ? [
                      BoxShadow(
                        color: AppColors.violet.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: enabled
                  ? (emphasized
                      ? AppColors.textOnPrimary
                      : AppColors.blanc)
                  : AppColors.gris,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Price breakdown
// ═════════════════════════════════════════════════════════════════════════════

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.subtotal,
    required this.serviceFee,
    required this.serviceFeePerTicket,
    required this.commission,
    required this.quantity,
    required this.grandTotal,
    required this.commissionPct,
    required this.currency,
    required this.l,
  });

  final double subtotal;
  final double serviceFee;
  final double serviceFeePerTicket;
  final double commission;
  final int quantity;
  final double grandTotal;
  final int commissionPct;
  final String currency;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    String fmt(double v) =>
        CurrencyFormatter.formatAmount(v, currency: currency);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _PriceRow(label: l.ticketSubtotal, value: fmt(subtotal)),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Frais de service (${fmt(serviceFeePerTicket)} × $quantity)',
            value: fmt(serviceFee),
          ),
          const SizedBox(height: 8),
          // Commission = ce que Spotbook prélève sur le payout du pro, pas
          // ce qu'on ajoute à la note client. Affichée en "muted" pour ne
          // pas laisser croire au client qu'elle s'ajoute au total.
          _PriceRow(
            label: 'Commission Spotbook ($commissionPct%)',
            value: fmt(commission),
            muted: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(height: 0.5, color: AppColors.border),
          ),
          _PriceRow(
            label: l.ticketTotal,
            value: fmt(grandTotal),
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.muted = false,
  });
  final String label;
  final String value;
  final bool isTotal;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.dmSans(
      color: isTotal ? AppColors.blanc : AppColors.gris,
      fontSize: isTotal ? 15 : 13.5,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
    );
    final valueStyle = isTotal
        ? GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          )
        : GoogleFonts.dmSans(
            color: muted ? AppColors.gris : AppColors.blanc,
            fontSize: 14,
            fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Payment — Platform Pay + card field
// ═════════════════════════════════════════════════════════════════════════════

class _PlatformPayButton extends StatelessWidget {
  const _PlatformPayButton({required this.onTap, required this.isLoading});
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Stripe's PlatformPayButton enforces platform branding (Apple/Google)
    // so we host it inside a sized box with themed padding. `onPressed` is
    // non-null on the Stripe widget; we disable interaction via IgnorePointer
    // (and dim with Opacity) when the sheet is loading or a tap isn't allowed.
    final disabled = onTap == null || isLoading;
    return SizedBox(
      height: 52,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: IgnorePointer(
          ignoring: disabled,
          child: PlatformPayButton(
            onPressed: onTap ?? () {},
            appearance: AppColors.isDark
                ? PlatformButtonStyle.whiteOutline
                : PlatformButtonStyle.black,
            type: PlatformButtonType.buy,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 0.5, color: AppColors.border),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ],
    );
  }
}

class _CardFieldSection extends StatelessWidget {
  const _CardFieldSection({required this.onCardChanged});
  final ValueChanged<CardFieldInputDetails?> onCardChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.credit_card_rounded,
              color: AppColors.gris,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Card information',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: CardField(
            onCardChanged: onCardChanged,
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Pay button + security footer
// ═════════════════════════════════════════════════════════════════════════════

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.enabled,
    required this.isLoading,
    required this.amount,
    required this.onTap,
  });
  final bool enabled;
  final bool isLoading;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.gradientAccent : null,
              color: enabled ? null : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: enabled
                  ? null
                  : Border.all(color: AppColors.border, width: 0.5),
              boxShadow: enabled && AppColors.isDark
                  ? [
                      BoxShadow(
                        color: AppColors.violet.withValues(alpha: 0.5),
                        blurRadius: 22,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : enabled
                      ? [
                          BoxShadow(
                            color:
                                AppColors.violet.withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: enabled
                            ? AppColors.textOnPrimary
                            : AppColors.gris,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pay $amount',
                        style: GoogleFonts.dmSans(
                          color: enabled
                              ? AppColors.textOnPrimary
                              : AppColors.gris,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_rounded,
          color: AppColors.gris,
          size: 13,
        ),
        const SizedBox(width: 6),
        Text(
          'Secured by Stripe · Encrypted payment',
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
