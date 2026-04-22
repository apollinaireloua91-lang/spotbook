import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
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
    ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Close',
          child: IconButton(
            icon:
                Icon(Icons.close, color: AppColors.blanc, size: 22),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text('Reçu de paiement',
            style:
                GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: AppColors.violet))
          : _booking == null
              ? Center(
                  child: Text('Réservation introuvable',
                      style: TextStyle(color: AppColors.gris)))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildReceipt(_booking!),
                ),
    );
  }

  Widget _buildReceipt(BookingModel booking) {
    String currencyFormat(num amount) => CurrencyFormatter.formatAmount(
          amount,
          currency: booking.currency,
          locale: 'en_CA',
        );
    final dateFormat = DateFormat('MMMM d, yyyy', 'en_US');
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
            isPaid ? 'Payment confirmed' : 'Payment failed',
            style: GoogleFonts.sora(
              color: isPaid ? AppColors.success : AppColors.error,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            currencyFormat(booking.depositAmount),
            style: GoogleFonts.sora(
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
                _receiptRow('Provider', booking.proName ?? '—'),
                if (booking.slotDate != null)
                  _receiptRow('Date', booking.slotDate!),
                if (booking.slotStartTime != null)
                  _receiptRow(
                    'Time',
                    booking.slotEndTime != null
                        ? '${booking.slotStartTime} — ${booking.slotEndTime}'
                        : booking.slotStartTime!,
                  ),
                if (booking.serviceDurationMinutes != null)
                  _receiptRow(
                      'Duration', '${booking.serviceDurationMinutes} min'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                _receiptRow(
                  'Deposit',
                  currencyFormat(booking.depositAmount),
                  isBold: true,
                ),
                _receiptRow('Currency', booking.currency.toUpperCase()),
                _receiptRow(
                  'Payment date',
                  dateFormat.format(booking.createdAt.toLocal()),
                ),
                if (booking.bookingCode != null)
                  _receiptRow('Booking code', booking.bookingCode!),
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
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('Code copié',
                        style: TextStyle(color: AppColors.blanc)),
                    duration: const Duration(seconds: 1),
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
                    Icon(Icons.copy,
                        color: AppColors.violetClair, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      booking.bookingCode!,
                      style: GoogleFonts.dmSans(
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
            Text(
              'Show this code at your appointment',
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 12),
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
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
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
