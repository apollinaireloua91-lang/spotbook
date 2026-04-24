import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/booking_models.dart';
import '../screens/booking_qr_screen.dart';
import 'booking_status_presenter.dart';

// ─── Month / weekday abbreviations (fr) ─────────────────────────────────────

const _weekdaysFr = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
const _monthsFr = [
  'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUIN',
  'JUIL', 'AOÛT', 'SEP', 'OCT', 'NOV', 'DÉC',
];

class ReservationCard extends StatefulWidget {
  const ReservationCard({
    super.key,
    required this.booking,
    this.isUpcoming = false,
    this.isPast = false,
    this.onCancel,
    this.onContact,
    this.onReview,
    this.onRebook,
    this.onPayNow,
    this.animationDelay = Duration.zero,
  });

  final BookingModel booking;
  final bool isUpcoming;
  final bool isPast;
  final VoidCallback? onCancel;
  final VoidCallback? onContact;
  final VoidCallback? onReview;
  final VoidCallback? onRebook;

  /// Appelé quand le client tape "Payer maintenant" sur un RDV
  /// `pending_payment`. Fallback : route vers `/booking/:id` (détail).
  final VoidCallback? onPayNow;
  final Duration animationDelay;

  @override
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = widget.booking;
    final presentation = presentBookingStatus(b.status, l);
    final parsedDate = _tryParseDate(b.slotDate);
    final startHHMM = _formatHHMM(b.slotStartTime) ?? '--:--';
    final endHHMM = _formatHHMM(b.slotEndTime);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/booking/${b.id}');
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.violet.withAlpha(18),
          highlightColor: AppColors.violet.withAlpha(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
              boxShadow: AppColors.premiumCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Ticket-stub header (date block | meta) ───
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateStub(date: parsedDate),
                      const _VerticalDashedDivider(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: _MetaBlock(
                            booking: b,
                            status: (tint: presentation.tint, label: presentation.label),
                            startHHMM: startHHMM,
                            endHHMM: endHHMM,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Action row — conditionnel sur le status ──────────────
                // Règles (cf. BOOKING_FLOW_REFONTE_PLAN §2) :
                //   pending_payment → Annuler + Payer maintenant (primary violet)
                //   confirmed       → Annuler + Message (primary violet)
                //   cancelled_*     → Voir détails (outline pleine largeur)
                //   completed       → Laisser avis + Réserver à nouveau
                if (widget.isUpcoming &&
                    presentation.primaryCta == BookingPrimaryCta.payNow)
                  _ActionRow(
                    leading: _GhostButton(
                      label: l.cancel,
                      icon: Icons.close_rounded,
                      tint: AppColors.rose,
                      onTap: widget.onCancel ??
                          () => context.push('/cancel-booking/${b.id}'),
                    ),
                    trailing: _PrimaryButton(
                      label: l.payNowLabel,
                      icon: Icons.credit_card_rounded,
                      onTap: widget.onPayNow ??
                          () => context.push('/booking/${b.id}'),
                    ),
                  )
                else if (widget.isUpcoming &&
                    presentation.primaryCta == BookingPrimaryCta.message) ...[
                  _ActionRow(
                    leading: _GhostButton(
                      label: l.cancel,
                      icon: Icons.close_rounded,
                      tint: AppColors.rose,
                      onTap: widget.onCancel ??
                          () => context.push('/cancel-booking/${b.id}'),
                    ),
                    trailing: _PrimaryButton(
                      label: l.messageLabel,
                      icon: Icons.mail_outline_rounded,
                      onTap: widget.onContact,
                    ),
                  ),
                  // Raccourci QR : ouvre directement le plein écran sans
                  // passer par le booking detail. Visible uniquement pour
                  // les RDV confirmés ayant déjà un QR signé (donc
                  // payment_intent.succeeded a tourné).
                  if (b.hasQrCode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _QrShortcutRow(booking: b),
                    ),
                ]
                else if (presentation.primaryCta == BookingPrimaryCta.viewDetails)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _GhostButton(
                      label: l.viewDetails,
                      icon: Icons.chevron_right_rounded,
                      tint: AppColors.blanc,
                      onTap: () => context.push('/booking/${b.id}'),
                    ),
                  ),

                if (widget.isPast &&
                    presentation.primaryCta == BookingPrimaryCta.leaveReview)
                  _ActionRow(
                    leading: _GhostButton(
                      label: l.leaveReview,
                      icon: Icons.star_outline_rounded,
                      tint: AppColors.violetClair,
                      onTap: widget.onReview ??
                          () => context.push('/review', extra: {
                                'bookingId': b.id,
                                'proId': b.proId,
                                'serviceName': b.serviceName ?? '',
                              }),
                    ),
                    trailing: _GhostButton(
                      label: l.bookAgain,
                      icon: Icons.refresh_rounded,
                      tint: AppColors.blanc,
                      onTap: widget.onRebook ??
                          () => context.push('/client/booking-flow/${b.proId}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date stub ──────────────────────────────────────────────────────────────
// Left column, editorial, ticket-feel: gros jour, mois en caps, weekday en caps.

class _DateStub extends StatelessWidget {
  const _DateStub({required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final dayStr = date != null ? date!.day.toString().padLeft(2, '0') : '--';
    final monthStr =
        date != null ? _monthsFr[date!.month - 1] : '—';
    final weekdayStr =
        date != null ? _weekdaysFr[date!.weekday - 1] : '—';

    return Container(
      width: 88,
      padding: const EdgeInsets.fromLTRB(16, 20, 10, 18),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violet.withAlpha(22),
            AppColors.violet.withAlpha(0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekdayStr,
            style: GoogleFonts.dmSans(
              color: AppColors.violetClair,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dayStr,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            monthStr,
            style: GoogleFonts.dmSans(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta block (service, pro, status, time, amount, acompte) ───────────────

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({
    required this.booking,
    required this.status,
    required this.startHHMM,
    required this.endHHMM,
  });

  final BookingModel booking;
  final ({Color tint, String label}) status;
  final String startHHMM;
  final String? endHHMM;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final timeRange =
        endHHMM != null ? '$startHHMM — $endHHMM' : startHHMM;
    final duration = b.serviceDurationMinutes != null
        ? '${b.serviceDurationMinutes} min'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Pro avatar + name + status dot
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(url: b.proAvatarUrl, fallback: b.proName ?? '?'),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.serviceName ?? 'Service',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: AppColors.blanc,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'avec ${b.proName ?? "—"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(tint: status.tint, label: status.label),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Time / duration / amount
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: AppColors.gris,
            ),
            const SizedBox(width: 6),
            Text(
              timeRange,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (duration != null) ...[
              Text(
                '  ·  ',
                style: TextStyle(color: AppColors.gris, fontSize: 13),
              ),
              Text(
                duration,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const Spacer(),
            Text(
              '${b.totalAmount.toStringAsFixed(0)} \$',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),

        // ─── Acompte line (inline, editorial)
        if (b.isDepositMode) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Acompte',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${b.depositAmount.toStringAsFixed(0)} \$',
                style: GoogleFonts.dmSans(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.glassBorder,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Solde sur place',
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Avatar (ring-less, sober) ──────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fallback});
  final String? url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final initial = fallback.isNotEmpty ? fallback[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _initialFallback(initial),
            )
          : _initialFallback(initial),
    );
  }

  Widget _initialFallback(String initial) => Center(
        child: Text(
          initial,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ─── Status chip — dot + hairline pill ──────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.tint, required this.label});
  final Color tint;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: tint.withAlpha(14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withAlpha(55), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tint.withAlpha(120),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: tint,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vertical dashed divider (ticket-stub feel) ─────────────────────────────

class _VerticalDashedDivider extends StatelessWidget {
  const _VerticalDashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: AppColors.border,
          isVertical: true,
          dashLength: 3,
          gapLength: 4,
        ),
        size: const Size(1, double.infinity),
      ),
    );
  }
}

// ─── Action row ─────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.leading, required this.trailing});
  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(child: leading),
          const SizedBox(width: 10),
          Expanded(child: trailing),
        ],
      ),
    );
  }
}

// ─── Ghost button (outline + icon) ──────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.tint,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: tint.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tint.withAlpha(55), width: 0.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: tint),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: tint,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Primary button (gradient + inner highlight, no emoji) ──────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap!();
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withAlpha(70),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle inner top highlight — mimics polished surface
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha(32),
                        Colors.white.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: AppColors.textOnPrimary),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textOnPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dashed line painter (vertical + horizontal) ────────────────────────────

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({
    required this.color,
    required this.isVertical,
    this.dashLength = 4,
    this.gapLength = 4,
  });

  final Color color;
  final bool isVertical;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    if (isVertical) {
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2, (y + dashLength).clamp(0, size.height)),
          paint,
        );
        y += dashLength + gapLength;
      }
    } else {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset((x + dashLength).clamp(0, size.width), size.height / 2),
          paint,
        );
        x += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isVertical != isVertical ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

DateTime? _tryParseDate(String? date) {
  if (date == null) return null;
  try {
    return DateTime.parse(date);
  } catch (_) {
    return null;
  }
}

String? _formatHHMM(String? raw) {
  if (raw == null || raw.length < 5) return null;
  return raw.substring(0, 5);
}

/// Mini-CTA "Mon QR code" affichée sous l'_ActionRow pour les bookings
/// confirmés ayant déjà un QR signé. Tap → BookingQrScreen plein écran.
///
/// On garde une apparence sobre (ghost button violet) pour ne pas dominer
/// le primary "Message" juste au-dessus, mais avec une icône QR explicite
/// pour qu'on devine immédiatement à quoi sert le bouton.
class _QrShortcutRow extends StatelessWidget {
  const _QrShortcutRow({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          showBookingQrFullscreen(context, booking: booking);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.violet.withValues(alpha: 0.20),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.violetClair,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l.qrFullscreenTitle,
                style: GoogleFonts.dmSans(
                  color: AppColors.violetClair,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.violetClair,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
