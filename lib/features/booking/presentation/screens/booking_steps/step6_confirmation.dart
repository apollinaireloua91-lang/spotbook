import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/spotbook_button.dart';
import '../../../data/booking_notifier.dart';

/// Step 6 — Booking confirmed. Animated success with callout + CTAs.
class Step6Confirmation extends StatefulWidget {
  const Step6Confirmation({super.key, required this.state});
  final BookingFlowState state;

  @override
  State<Step6Confirmation> createState() => _Step6ConfirmationState();
}

class _Step6ConfirmationState extends State<Step6Confirmation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Success ring with scale+fade in
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _anim,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.3),
                    AppColors.success.withValues(alpha: 0.08),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),
            child: Column(
              children: [
                Text(
                  'Réservation confirmée',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ton RDV est bloqué.\nTu recevras un rappel 24h et 30 min avant.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColors.grisClair,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded,
                      color: AppColors.violetClair, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ton QR code a été envoyé par email. Montre-le au pro à ton arrivée.',
                      style: GoogleFonts.dmSans(
                        color: AppColors.grisClair,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: SpotbookButton.primary(
              label: 'Voir mes RDV',
              icon: Icons.event_note_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go('/client/bookings');
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SpotbookButton.secondary(
              label: 'Retour au feed',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go('/client/feed');
              },
            ),
          ),
        ],
      ),
    );
  }
}
