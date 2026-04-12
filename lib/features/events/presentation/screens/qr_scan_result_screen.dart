import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import 'scanner_screen.dart';

/// Persistent QR scan result screen.
/// Route: /pro/scanner/result (receives ScanResult + eventId via extra)
class QrScanResultScreen extends StatelessWidget {
  const QrScanResultScreen({
    super.key,
    required this.result,
    required this.eventId,
  });

  final ScanResult result;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Color bgColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (result.valid) {
      bgColor = AppColors.success;
      iconColor = AppColors.success;
      icon = Icons.check_circle;
      title = l.ticketValidated;
      subtitle = l.ticketValidatedSuccess;
    } else if (result.reason == 'already_used') {
      bgColor = AppColors.warning;
      iconColor = AppColors.warning;
      icon = Icons.warning_amber_rounded;
      title = l.alreadyScanned;
      subtitle = result.scannedAt != null
          ? l.alreadyScannedAt(result.scannedAt!)
          : l.alreadyUsed;
    } else {
      bgColor = AppColors.error;
      iconColor = AppColors.error;
      icon = Icons.cancel;
      title = l.invalidTicket;
      subtitle = result.reason == 'invalid_format'
          ? l.invalidQrCode
          : l.ticketCouldNotBeValidated;
    }

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Result circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: bgColor.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: bgColor.withAlpha(60), width: 3),
                ),
                child: Icon(icon, color: iconColor, size: 60),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: GoogleFonts.sora(
                  color: iconColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (result.reason != null &&
                  result.reason != 'already_used' &&
                  result.reason != 'invalid_format' &&
                  !result.valid) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    result.reason!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: AppColors.grisInactif, fontSize: 12),
                  ),
                ),
              ],
              const Spacer(flex: 3),
              // Scan another button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.pop();
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: Text(l.scanAnotherTicket,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blanc,
                    foregroundColor: AppColors.fond,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back to event button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/pro/events');
                  },
                  child: Text(
                    l.backToEvents,
                    style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
