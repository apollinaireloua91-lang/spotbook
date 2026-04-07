import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/event_repository.dart';

class _WaitlistState {
  const _WaitlistState({this.isJoining = false, this.joined = false, this.error});
  final bool isJoining;
  final bool joined;
  final String? error;

  _WaitlistState copyWith({bool? isJoining, bool? joined, String? error}) =>
      _WaitlistState(
        isJoining: isJoining ?? this.isJoining,
        joined: joined ?? this.joined,
        error: error,
      );
}

class _WaitlistNotifier extends Notifier<_WaitlistState> {
  @override
  _WaitlistState build() => const _WaitlistState();

  Future<void> join(String ticketTypeId) async {
    state = state.copyWith(isJoining: true, error: null);
    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.joinWaitlist(ticketTypeId);
      state = state.copyWith(isJoining: false, joined: true);
    } catch (e) {
      state = state.copyWith(isJoining: false, error: e.toString());
    }
  }
}

final _waitlistProvider = NotifierProvider<_WaitlistNotifier, _WaitlistState>(
  _WaitlistNotifier.new,
  isAutoDispose: true,
);

class WaitlistScreen extends ConsumerWidget {
  const WaitlistScreen({super.key, required this.ticketTypeId, required this.eventTitle});
  final String ticketTypeId;
  final String eventTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_waitlistProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text('Liste d\'attente',
            style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.joined ? Icons.check_circle : Icons.hourglass_top,
              color: state.joined ? AppColors.success : AppColors.blanc,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              state.joined ? 'You are registered!' : 'Tickets sold out',
              style: GoogleFonts.sora(color: AppColors.blanc, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state.joined
                  ? 'You will be notified if a ticket becomes available for "$eventTitle". You will have 30 minutes to confirm.'
                  : 'Join the waitlist to get notified if a ticket becomes available.',
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            if (!state.joined)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isJoining
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          ref.read(_waitlistProvider.notifier).join(ticketTypeId);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blanc,
                    foregroundColor: AppColors.fond,
                    disabledBackgroundColor: AppColors.surfaceAlt,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isJoining
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.gris, strokeWidth: 2))
                      : Text('Join the waitlist',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            if (state.joined)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back',
                      style: GoogleFonts.dmSans(color: AppColors.blanc, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
