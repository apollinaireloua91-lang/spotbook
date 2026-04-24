import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import 'unified_scanner_screen.dart';

/// Rich scan result screen — shows client info, service, date, status.
class UnifiedScanResultScreen extends StatelessWidget {
  const UnifiedScanResultScreen({super.key, required this.result});

  final UnifiedScanResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final (Color accentColor, IconData icon, String title, String subtitle) =
        switch (result.status) {
      ScanStatus.valid => (
          AppColors.success,
          Icons.check_circle,
          result.type == ScanType.booking
              ? l.bookingValidated
              : l.ticketValidated,
          result.type == ScanType.booking
              ? l.bookingValidatedSuccess
              : l.ticketValidatedSuccess,
        ),
      ScanStatus.alreadyUsed => (
          AppColors.warning,
          Icons.warning_amber_rounded,
          l.alreadyScanned,
          result.scannedAt != null
              ? l.alreadyScannedAt(result.scannedAt!)
              : l.alreadyScanned,
        ),
      ScanStatus.cancelled => (
          AppColors.error,
          Icons.cancel,
          l.bookingCancelled,
          l.qrBookingCancelled,
        ),
      ScanStatus.invalid => (
          AppColors.error,
          Icons.cancel,
          result.type == ScanType.booking
              ? l.invalidBookingQr
              : l.invalidTicket,
          result.reason == 'invalid_format'
              ? l.invalidQrCode
              : l.qrCouldNotBeValidated,
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Status icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withAlpha(60), width: 3),
                ),
                child: Icon(icon, color: accentColor, size: 50),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: GoogleFonts.sora(
                  color: accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Bannière encaissement (bookings + scan valide uniquement).
              // Cachée pour les tickets (pas de notion d'acompte) et pour les
              // statuts erreur/déjà-scanné où le Pro n'a rien à encaisser.
              if (result.type == ScanType.booking &&
                  result.status == ScanStatus.valid &&
                  result.paymentMode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PaymentBanner(result: result),
                ),

              // Client + booking details card
              if (result.clientName != null) _DetailsCard(result: result),

              const Spacer(flex: 2),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.pop();
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: Text(
                    l.scanAnother,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blanc,
                    foregroundColor: AppColors.fond,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/pro/dashboard');
                  },
                  child: Text(
                    l.backToDashboard,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.result});

  final UnifiedScanResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Client avatar + name
          Row(
            children: [
              ClipOval(
                child: result.clientAvatar != null &&
                        result.clientAvatar!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: result.clientAvatar!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _fallbackAvatar(),
                        errorWidget: (_, __, ___) => _fallbackAvatar(),
                      )
                    : _fallbackAvatar(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.clientName ?? 'Client',
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (result.bookingCode != null)
                      Text(
                        result.bookingCode!,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.type == ScanType.booking
                      ? AppColors.violet.withValues(alpha: 0.15)
                      : AppColors.rose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.type == ScanType.booking ? l.appointment : l.ticket,
                  style: GoogleFonts.dmSans(
                    color: result.type == ScanType.booking
                        ? AppColors.violetClair
                        : AppColors.rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (result.serviceName != null ||
              result.date != null ||
              result.amountPaid != null) ...[
            const SizedBox(height: 16),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),

            // Service
            if (result.serviceName != null)
              _InfoRow(
                icon: Icons.spa_outlined,
                label: l.service,
                value: result.serviceName!,
              ),

            // Date & time
            if (result.date != null)
              _InfoRow(
                icon: Icons.calendar_today,
                label: l.date,
                value:
                    '${result.date}${result.startTime != null ? " · ${result.startTime}" : ""}',
              ),

            // Duration
            if (result.serviceDuration != null)
              _InfoRow(
                icon: Icons.timer_outlined,
                label: l.duration,
                value: '${result.serviceDuration} min',
              ),

            // Amount — caché si la bannière d'encaissement prend le relais
            // (booking valide). Affiché pour les tickets ou pour les statuts
            // où la bannière ne s'affiche pas (déjà scanné, annulé…).
            if (result.amountPaid != null &&
                !(result.type == ScanType.booking &&
                    result.status == ScanStatus.valid &&
                    result.paymentMode != null))
              _InfoRow(
                icon: Icons.payments_outlined,
                label: l.amountPaid,
                value: CurrencyFormatter.formatAmount(result.amountPaid!,
                    currency: result.currency),
              ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    final initial = (result.clientName ?? '?').isNotEmpty
        ? result.clientName![0].toUpperCase()
        : '?';
    return Container(
      width: 48,
      height: 48,
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.sora(
          color: AppColors.blanc,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gris, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bannière d'encaissement affichée après un scan de booking valide.
///
/// Deux états visuels selon `paymentMode` :
/// - `full`    → bannière VERTE (success). Un seul montant affiché : ce que
///               le client a payé via Stripe. Message : « Payé en intégralité ».
/// - `deposit` → bannière AMBRE (warning). Trois lignes : acompte payé,
///               solde à percevoir au RDV, total du service. Message : le
///               Pro doit encaisser le solde restant.
///
/// Montants formatés en CAD québécois (`150,00 $`) via
/// [CurrencyFormatter.formatCadFr].
class _PaymentBanner extends StatelessWidget {
  const _PaymentBanner({required this.result});

  final UnifiedScanResult result;

  @override
  Widget build(BuildContext context) {
    final isFull = result.paymentMode == PaymentMode.full;
    final Color bannerColor = isFull ? AppColors.success : AppColors.warning;
    final IconData icon = isFull
        ? Icons.check_circle_outline
        : Icons.account_balance_wallet_outlined;
    final String title = isFull
        ? 'Payé en intégralité'
        : 'Solde à percevoir au RDV';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: bannerColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: bannerColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isFull)
            _AmountRow(
              label: 'Montant encaissé',
              amount: result.amountPaid ?? 0,
              emphasis: true,
            )
          else ...[
            _AmountRow(
              label: 'Acompte payé',
              amount: result.amountPaid ?? 0,
            ),
            const SizedBox(height: 6),
            _AmountRow(
              label: 'Solde à percevoir',
              amount: result.amountRemaining ?? 0,
              emphasis: true,
              emphasisColor: bannerColor,
            ),
            const SizedBox(height: 6),
            Divider(
              color: bannerColor.withValues(alpha: 0.20),
              height: 1,
            ),
            const SizedBox(height: 6),
            _AmountRow(
              label: 'Total du service',
              amount: result.totalAmount ?? 0,
              muted: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne montant dans la bannière d'encaissement. Format CAD-QC obligatoire.
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.emphasis = false,
    this.muted = false,
    this.emphasisColor,
  });

  final String label;
  final double amount;

  /// Ligne mise en avant (typiquement le montant à percevoir ou à encaisser).
  final bool emphasis;

  /// Ligne secondaire (typiquement le total pour référence).
  final bool muted;

  /// Couleur du montant quand [emphasis] est vrai. Null = blanc (dark) standard.
  final Color? emphasisColor;

  @override
  Widget build(BuildContext context) {
    final labelColor = muted ? AppColors.gris : AppColors.blanc;
    final amountColor = emphasis
        ? (emphasisColor ?? AppColors.blanc)
        : (muted ? AppColors.gris : AppColors.blanc);
    final amountWeight = emphasis ? FontWeight.w800 : FontWeight.w600;
    final amountSize = emphasis ? 16.0 : 14.0;

    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          CurrencyFormatter.formatCadFr(amount),
          style: GoogleFonts.dmSans(
            color: amountColor,
            fontSize: amountSize,
            fontWeight: amountWeight,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
