import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/spotbook_button.dart';
import '../../../data/booking_notifier.dart';

/// Step 6 — Booking confirmed. Success animation + CTAs.
class Step6Confirmation extends StatelessWidget {
  const Step6Confirmation({super.key, required this.state});

  final BookingFlowState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Réservation confirmée !',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu recevras un rappel 24h et 2h avant ton RDV.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.dmSans(color: AppColors.grisClair, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 260,
              child: SpotbookButton.primary(
                label: 'Voir mes RDV',
                onPressed: () => context.go('/client/bookings'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              child: SpotbookButton.secondary(
                label: 'Retour au feed',
                onPressed: () => context.go('/client/feed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
