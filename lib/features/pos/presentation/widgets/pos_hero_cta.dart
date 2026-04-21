/// POS Tap to Pay hero CTA, embedded on the Pro dashboard.
///
/// Lives at the feature boundary: uses legacy [AppColors] on the outside
/// so it blends with the rest of the dashboard, but the "pulse dot" micro-
/// signature inside borrows the DS accent to preview the POS world the Pro
/// is about to enter.
///
/// Shows today's live totals (count + net) via [posTodayTotalsProvider] —
/// instant social proof the feature is working before the Pro even taps.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/pos_notifier.dart';
import '../money_format.dart';

class PosHeroCta extends ConsumerWidget {
  const PosHeroCta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(posTodayTotalsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/pro/pos/amount'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3E065F), // accentDeep
                  Color(0xFF8E05C2), // accentDark
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E05C2).withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pulse dot.
                const _PulseDot(),
                const SizedBox(width: 14),
                // Title + today's totals.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Encaisser Tap to Pay',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blanc,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      totals.when(
                        data: (t) => Text(
                          t.count == 0
                              ? 'Aucune transaction aujourd\u2019hui'
                              : _subtitleFor(t.count, t.netCents),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blanc.withValues(alpha: 0.82),
                            height: 1.3,
                          ),
                        ),
                        loading: () => Text(
                          'Chargement…',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blanc.withValues(alpha: 0.65),
                          ),
                        ),
                        error: (_, __) => Text(
                          'Prêt à encaisser',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blanc.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Forward chevron on a subtle white pill.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blanc.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.blanc,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _subtitleFor(int count, int netCents) {
    final txWord = count == 1 ? 'transaction' : 'transactions';
    return '$count $txWord · ${formatCentsToCad(netCents)} net';
  }
}

/// Micro heartbeat dot — signals the POS is "live". Single tick, low cost.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          final innerScale = 1.0 + 0.12 * t;
          final haloScale = 1.0 + 1.2 * t;
          final haloOpacity = 0.55 * (1.0 - t);
          return SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo.
                Opacity(
                  opacity: haloOpacity,
                  child: Transform.scale(
                    scale: haloScale,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
                // Core dot.
                Transform.scale(
                  scale: innerScale,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
