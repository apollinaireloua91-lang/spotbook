import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/qr_display_widget.dart';
import '../../domain/booking_models.dart';

/// Écran plein écran d'affichage du QR code d'un RDV.
///
/// Optimisé pour le scan à distance par le Pro :
/// - QR dimensionné dynamiquement à 80 % de la largeur écran (typiquement
///   ~ 320–360 px sur smartphone, beaucoup plus lisible que 200 dans la card)
/// - Background dark + tile blanc → contraste maximal pour les caméras
/// - Métadonnées sous le QR (service, date, heure) pour confirmer
///   visuellement au Pro qu'il scanne le bon RDV
///
/// L'écran est typiquement poussé en modal via `showDialog` ou `showModalBottomSheet`
/// avec `useSafeArea: true`. On peut aussi l'utiliser comme route GoRouter
/// pleine page si on veut un deep-link `/booking/:id/qr`.
class BookingQrScreen extends StatelessWidget {
  const BookingQrScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final qrData = booking.qrData;

    // Cas-edge : QR pas encore généré (paiement pas confirmé ou bug
    // sign-qr-booking). On affiche un placeholder explicatif plutôt
    // qu'un écran vide, pour ne pas laisser le client perplexe.
    if (qrData == null) {
      return _Scaffold(
        title: l.qrFullscreenTitle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: QrUnavailablePlaceholder(
              title: l.qrUnavailableTitle,
              subtitle: l.qrUnavailableSubtitle,
            ),
          ),
        ),
      );
    }

    // Calcul de la taille du QR : 80% de la largeur, clamp entre 240 et 360.
    // Sur petits écrans (iPhone SE) on évite que le QR sorte du viewport
    // une fois les paddings appliqués. Sur tablettes, on cap à 360 pour
    // éviter un QR géant inutilement (au-delà, le scan ne s'améliore plus).
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = (screenWidth * 0.8).clamp(240.0, 360.0);

    final serviceLabel = booking.serviceName ?? '';
    final dateLabel = _formatDateTime(booking);

    return _Scaffold(
      title: l.qrFullscreenTitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Métadonnées du RDV au-dessus du QR : le Pro voit immédiatement
            // qu'il scanne le bon créneau (réassurance avant de pointer
            // la caméra).
            if (serviceLabel.isNotEmpty)
              Text(
                serviceLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                dateLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 28),
            QrDisplayWidget(
              qrData: qrData,
              size: qrSize,
              statusBadge: booking.isScanned
                  ? QrValidatedBadge(label: l.qrAlreadyValidated)
                  : null,
              helpText: l.qrFullscreenHint,
            ),
            const SizedBox(height: 32),
            // Code de réservation pour fallback verbal si le scan
            // échoue (ex: caméra Pro défectueuse, écran client cassé).
            if (booking.bookingCode != null && booking.bookingCode!.isNotEmpty)
              _BookingCodeChip(code: booking.bookingCode!),
          ],
        ),
      ),
    );
  }

  /// Formate `slotDate` + `slotStartTime` du booking en chaîne lisible.
  /// Format simple, pas de localisation lourde — on est sur un écran
  /// transitoire affiché < 30s.
  String _formatDateTime(BookingModel b) {
    final date = b.slotDate ?? '';
    final time = b.slotStartTime ?? '';
    if (date.isEmpty && time.isEmpty) return '';
    if (time.isEmpty) return date;
    if (date.isEmpty) return time;
    // On affiche les heures sur format HH:MM (tronque les secondes).
    final hhmm = time.length >= 5 ? time.substring(0, 5) : time;
    return '$date · $hhmm';
  }
}

/// Wrapper Scaffold partagé entre l'état normal et l'état "QR indisponible".
class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          tooltip: l.qrCloseFullscreen,
          icon: Icon(Icons.close_rounded, color: AppColors.blanc),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: SafeArea(child: child),
    );
  }
}

/// Chip affichant le code de réservation (fallback verbal pour le Pro).
class _BookingCodeChip extends StatelessWidget {
  const _BookingCodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Text(
        code,
        style: GoogleFonts.dmSans(
          color: AppColors.gris,
          fontSize: 13,
          letterSpacing: 1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Helper pratique pour ouvrir le QR plein écran depuis n'importe quel
/// écran client (booking detail, liste Mes RDV, notification tap, etc.).
/// Centralise le `showGeneralDialog` pour garder une transition cohérente.
Future<void> showBookingQrFullscreen(
  BuildContext context, {
  required BookingModel booking,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => BookingQrScreen(booking: booking),
      transitionsBuilder: (_, animation, __, child) {
        // Slide-up depuis le bas — c'est le geste "modale plein écran"
        // standard iOS/Android. Plus rapide qu'un fade pour signaler
        // un état temporaire (vs navigation classique).
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 240),
    ),
  );
}
