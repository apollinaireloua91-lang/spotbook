import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';

/// Refund request screen — shows booking details, refund policy, and
/// lets the client submit a cancellation/refund request.
class RefundRequestScreen extends ConsumerStatefulWidget {
  const RefundRequestScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<RefundRequestScreen> createState() =>
      _RefundRequestScreenState();
}

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
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
    }
  }

  /// Calculate hours until booking based on slot date/time.
  double _hoursUntilBooking(BookingModel booking) {
    if (booking.slotDate == null || booking.slotStartTime == null) {
      return 0;
    }
    try {
      final dt = DateTime.parse(
        '${booking.slotDate}T${booking.slotStartTime}',
      );
      return dt.difference(DateTime.now()).inMinutes / 60;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _submitRefund() async {
    final booking = _booking;
    if (booking == null) return;

    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmer l\'annulation ?',
          style: TextStyle(color: AppColors.blanc),
        ),
        content: Text(
          _hoursUntilBooking(booking) > 48
              ? 'Vous recevrez un remboursement complet.'
              : 'L\'annulation est dans moins de 48h — aucun remboursement ne sera effectué.',
          style: const TextStyle(color: AppColors.gris, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Non', style: TextStyle(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final result = await repo.cancelBooking(booking.id);

      if (!mounted) return;

      final status = result['status'] as String? ?? '';
      final isRefunded = status == 'cancelled_full_refund';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            isRefunded
                ? 'Réservation annulée — remboursement en cours.'
                : 'Réservation annulée — aucun remboursement (< 48h).',
            style: const TextStyle(color: AppColors.blanc),
          ),
        ),
      );

      context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString(),
                style: const TextStyle(color: AppColors.blanc)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc,
                size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text('Demande de remboursement',
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
              : _buildContent(_booking!),
    );
  }

  Widget _buildContent(BookingModel booking) {
    final hoursUntil = _hoursUntilBooking(booking);
    final isFullRefund = hoursUntil > 48;
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CA',
      symbol: booking.currency == 'EUR' ? '€' : '\$',
      decimalDigits: 2,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName ?? 'Service',
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow(
                    Icons.person_outline, booking.proName ?? 'Prestataire'),
                if (booking.slotDate != null)
                  _infoRow(Icons.calendar_today, booking.slotDate!),
                if (booking.slotStartTime != null)
                  _infoRow(Icons.access_time, booking.slotStartTime!),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant payé',
                        style: TextStyle(color: AppColors.gris, fontSize: 14)),
                    Text(
                      currencyFormat.format(booking.depositAmount),
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Refund policy
          const Text(
            'Politique de remboursement',
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _policyRow(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            text: 'Plus de 48h avant le RDV → remboursement complet',
          ),
          const SizedBox(height: 8),
          _policyRow(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            text: 'Moins de 48h → aucun remboursement (le pro garde l\'acompte)',
          ),

          const SizedBox(height: 24),

          // Refund estimation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFullRefund
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFullRefund
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isFullRefund
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: isFullRefund
                          ? AppColors.success
                          : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFullRefund
                          ? 'Remboursement complet'
                          : 'Aucun remboursement',
                      style: TextStyle(
                        color: isFullRefund
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFullRefund
                      ? 'Vous serez remboursé de ${currencyFormat.format(booking.depositAmount)} sur votre moyen de paiement.'
                      : 'Il reste moins de 48h avant votre RDV. Conformément à notre politique, aucun remboursement ne sera effectué.',
                  style: TextStyle(
                    color: isFullRefund
                        ? AppColors.success.withValues(alpha: 0.8)
                        : AppColors.warning.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reason field
          const Text(
            'Raison (optionnel)',
            style: TextStyle(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: AppColors.blanc, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Pourquoi souhaitez-vous annuler ?',
              hintStyle: const TextStyle(color: AppColors.gris, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              counterStyle: const TextStyle(color: AppColors.gris),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.blanc),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Submit button
          SpotbookButton(
            label: 'Annuler la réservation',
            variant: SpotbookButtonVariant.destructive,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submitRefund,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gris, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AppColors.gris, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _policyRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.gris, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
