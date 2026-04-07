import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../shared/theme/app_colors.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyTicketProvider.notifier).selectType(widget.ticketType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyTicketProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gris,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.ticketType.name,
            style: const TextStyle(color: AppColors.blanc, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.event.title,
            style: const TextStyle(color: AppColors.gris, fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Quantity selector
          Row(
            children: [
              const Text('Quantité', style: TextStyle(color: AppColors.blanc, fontSize: 15)),
              const Spacer(),
              Semantics(
                label: 'Réduire quantité',
                child: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.blanc),
                  onPressed: state.quantity > 1
                      ? () => ref.read(buyTicketProvider.notifier).setQuantity(state.quantity - 1)
                      : null,
                ),
              ),
              Text('${state.quantity}',
                  style: const TextStyle(color: AppColors.blanc, fontSize: 18, fontWeight: FontWeight.bold)),
              Semantics(
                label: 'Augmenter quantité',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.blanc),
                  onPressed: state.quantity < 4 && state.quantity < widget.ticketType.remaining
                      ? () => ref.read(buyTicketProvider.notifier).setQuantity(state.quantity + 1)
                      : null,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          _PriceRow(label: 'Subtotal', value: '${state.total.toStringAsFixed(2)} CA\$'),
          _PriceRow(label: 'Service fee (12%)', value: '${state.commission.toStringAsFixed(2)} CA\$'),
          const SizedBox(height: 8),
          _PriceRow(label: 'Total', value: '${state.grandTotal.toStringAsFixed(2)} CA\$', isBold: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
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
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      // Create PaymentIntent
                      await ref.read(buyTicketProvider.notifier).createIntent();
                      final flow = ref.read(buyTicketProvider);
                      if (flow.clientSecret == null) return;

                      // Confirm with Stripe
                      try {
                        await Stripe.instance.confirmPayment(
                          paymentIntentClientSecret: flow.clientSecret!,
                          data: const PaymentMethodParams.card(
                            paymentMethodData: PaymentMethodData(),
                          ),
                        );

                        // Create ticket records + sign QR
                        final repo = ref.read(eventRepositoryProvider);
                        await repo.createTickets(
                          ticketTypeId: widget.ticketType.id,
                          eventId: widget.event.id,
                          quantity: flow.quantity,
                          stripePaymentIntentId: flow.clientSecret!.split('_secret_')[0],
                        );

                        ref.invalidate(userTicketsProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Billet(s) acheté(s) !'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } on StripeException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.error.localizedMessage ?? 'Paiement échoué'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blanc,
                foregroundColor: AppColors.fond,
                disabledBackgroundColor: AppColors.surfaceAlt,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.gris, strokeWidth: 2))
                  : Text('Payer ${state.grandTotal.toStringAsFixed(2)} CA\$', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.gris, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: AppColors.blanc, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
