import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_models.dart';

/// Payment receipt — shows a detailed receipt after a booking payment.
class PaymentReceiptScreen extends ConsumerStatefulWidget {
  const PaymentReceiptScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<PaymentReceiptScreen> createState() =>
      _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends ConsumerState<PaymentReceiptScreen>
    with SingleTickerProviderStateMixin {
  BookingModel? _booking;
  bool _isLoading = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadBooking();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    final repo = ref.read(bookingRepositoryProvider);
    final booking = await repo.getBookingById(widget.bookingId);
    if (mounted) {
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
      _animCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Fermer',
          child: IconButton(
            icon:
                const Icon(Icons.close, color: AppColors.blanc, size: 22),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text('Reçu de paiement',
            style:
                TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.violet))
          : _booking == null
              ? const Center(
                  child: Text('Réservation introuvable',
                      style: TextStyle(color: AppColors.gris)))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildReceipt(_booking!),
                ),
    );
  }

  Widget _buildReceipt(BookingModel booking) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CA',
      symbol: booking.currency == 'EUR' ? '€' : '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_CA');
    final isPaid = booking.status != 'payment_failed';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Status badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
            ),
            child: Icon(
              isPaid ? Icons.check : Icons.close,
              color: isPaid ? AppColors.success : AppColors.error,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPaid ? 'Paiement confirmé' : 'Paiement échoué',
            style: TextStyle(
              color: isPaid ? AppColors.success : AppColors.error,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            currencyFormat.format(booking.depositAmount),
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Receipt card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _receiptRow('Service', booking.serviceName ?? '—'),
                _receiptRow('Prestataire', booking.proName ?? '—'),
                if (booking.slotDate != null)
                  _receiptRow('Date', booking.slotDate!),
                if (booking.slotStartTime != null)
                  _receiptRow(
                    'Heure',
                    booking.slotEndTime != null
                        ? '${booking.slotStartTime} — ${booking.slotEndTime}'
                        : booking.slotStartTime!,
                  ),
                if (booking.serviceDurationMinutes != null)
                  _receiptRow(
                      'Durée', '${booking.serviceDurationMinutes} min'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                _receiptRow(
                  'Acompte',
                  currencyFormat.format(booking.depositAmount),
                  isBold: true,
                ),
                _receiptRow('Devise', booking.currency.toUpperCase()),
                _receiptRow(
                  'Date de paiement',
                  dateFormat.format(booking.createdAt.toLocal()),
                ),
                if (booking.bookingCode != null)
                  _receiptRow('Code réservation', booking.bookingCode!),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Booking code highlight
          if (booking.bookingCode != null) ...[
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: booking.bookingCode!));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('Code copié',
                        style: TextStyle(color: AppColors.blanc)),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy,
                        color: AppColors.violetClair, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      booking.bookingCode!,
                      style: const TextStyle(
                        color: AppColors.violetClair,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Présentez ce code lors de votre rendez-vous',
              style: TextStyle(color: AppColors.gris, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.gris, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
