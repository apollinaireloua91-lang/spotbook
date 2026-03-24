import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/profile_models.dart';
import 'booking_bottom_sheet.dart';

/// Route plein écran : ouvre le flux réservation 6 étapes (PageView dans le sheet).
class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, required this.providerId});

  final String providerId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  ProProfile? _pro;
  Object? _error;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final pro = await repo.getProProfile(widget.providerId);
      if (!mounted) return;
      setState(() => _pro = pro);
      await _openSheetIfReady();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _openSheetIfReady() async {
    if (_opened || _pro == null || !mounted) return;
    _opened = true;
    await showBookingSheet(
      context,
      proId: widget.providerId,
      proProfile: _pro!,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
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
            child: Text(
              _error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gris),
            ),
          ),
        ),
      );
    }

    if (_pro == null) {
      return const Scaffold(
        backgroundColor: AppColors.fond,
        body: Center(
          child: SpotbookLoadingShimmer.profile(),
        ),
      );
    }

    return const Scaffold(
      backgroundColor: AppColors.fond,
      body: Center(
        child: SpotbookLoadingShimmer.profile(),
      ),
    );
  }
}
