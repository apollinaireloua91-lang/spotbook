import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/booking_notifier.dart';
import '../../data/booking_repository.dart';

class BookingCancellationScreen extends ConsumerStatefulWidget {
  const BookingCancellationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingCancellationScreen> createState() =>
      _BookingCancellationScreenState();
}

class _BookingCancellationScreenState
    extends ConsumerState<BookingCancellationScreen> {
  bool _isCancelling = false;
  String? _error;

  Future<void> _cancel() async {
    setState(() {
      _isCancelling = true;
      _error = null;
    });
    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancelBooking(widget.bookingId);
      ref.invalidate(clientBookingsProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCancelling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Annuler le RDV',
          style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Politique d\'annulation',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _PolicyRow(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              text:
                  'Plus de 48h avant le RDV : remboursement intégral de l\'acompte.',
            ),
            const SizedBox(height: 12),
            _PolicyRow(
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              text:
                  'Moins de 48h avant le RDV : le pro conserve l\'acompte. Aucun remboursement.',
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(50)),
              ),
              child: const Text(
                'Cette action est irréversible. Confirmez-vous l\'annulation ?',
                style: TextStyle(color: AppColors.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style:
                      const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCancelling ? null : _cancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.blanc,
                  disabledBackgroundColor: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.blanc, strokeWidth: 2),
                      )
                    : const Text('Confirmer l\'annulation',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isCancelling ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blanc,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Retour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.grisClair, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
