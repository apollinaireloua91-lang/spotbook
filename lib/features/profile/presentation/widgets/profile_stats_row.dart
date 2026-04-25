import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/animated_counter.dart';

/// Editorial stats ledger — no container card, just hairline rules top
/// and bottom with four oversized numerals and capped-letter labels.
///
/// Inspired by newspaper typographic ledgers / Aman stat cards.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.totalRdv,
    required this.totalFollowing,
    required this.totalEvents,
    required this.totalReviews,
  });

  final int totalRdv;
  final int totalFollowing;
  final int totalEvents;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Used below — `l` is required so the caps-labels come from the
    // localized strings.
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.blanc.withAlpha(26),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: AppColors.blanc.withAlpha(26),
            width: 0.5,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StatCell(
              value: totalRdv,
              label: 'RDV',
              accent: AppColors.violetClair,
            ),
            const _LedgerDivider(),
            _StatCell(
              value: totalFollowing,
              label: l.followingLabel,
              accent: AppColors.rose,
            ),
            const _LedgerDivider(),
            _StatCell(
              value: totalEvents,
              label: l.eventsTab,
              accent: AppColors.violetClair,
            ),
            const _LedgerDivider(),
            _StatCell(
              value: totalReviews,
              label: l.reviewsTab,
              accent: AppColors.starGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.accent,
  });

  final int value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedCounter(
            value: value,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            duration: const Duration(milliseconds: 700),
          ),
          const SizedBox(height: 8),
          // Accent dot + caps label pairing — quiet but anchors each cell.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.dmSans(
                    color: AppColors.grisInactif,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerDivider extends StatelessWidget {
  const _LedgerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 32,
      color: AppColors.blanc.withAlpha(20),
    );
  }
}
