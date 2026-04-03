import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/profile_models.dart';
import 'booking_bottom_sheet.dart';

/// Provider that fetches the pro profile for the booking flow entry.
final _bookingProProvider =
    FutureProvider.autoDispose.family<ProProfile, String>((ref, proId) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getProProfile(proId);
});

/// Route plein écran : charge le profil pro puis ouvre le sheet de réservation.
class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({
    super.key,
    required this.providerId,
    this.initialServiceId,
  });

  final String providerId;
  final String? initialServiceId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  bool _opened = false;

  void _openSheet(ProProfile pro) {
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showBookingSheet(
        context,
        proId: widget.providerId,
        proProfile: pro,
        initialServiceId: widget.initialServiceId,
      );
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final proAsync = ref.watch(_bookingProProvider(widget.providerId));

    return proAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(child: SpotbookLoadingShimmer.profile()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.fond,
        appBar: AppBar(
          backgroundColor: AppColors.fond,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.blanc),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.gris, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger le profil',
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gris, fontSize: 13),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => ref.invalidate(
                    _bookingProProvider(widget.providerId),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Réessayer',
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (pro) {
        _openSheet(pro);
        return const Scaffold(
          backgroundColor: AppColors.fond,
          body: Center(child: SpotbookLoadingShimmer.profile()),
        );
      },
    );
  }
}
