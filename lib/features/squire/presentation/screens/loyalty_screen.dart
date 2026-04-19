import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/squire_repository.dart';
import '../../domain/squire_models.dart';

/// Priority #9 — Loyalty program management (Pro side).
/// Simple screen to configure the pro's loyalty program + view program stats.
class LoyaltyProgramScreen extends ConsumerStatefulWidget {
  const LoyaltyProgramScreen({super.key, required this.proId});
  final String proId;

  @override
  ConsumerState<LoyaltyProgramScreen> createState() =>
      _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState
    extends ConsumerState<LoyaltyProgramScreen> {
  LoyaltyProgram? _program;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      final p = await repo.loadLoyaltyProgram(widget.proId);
      if (!mounted) return;
      setState(() {
        _program = p ?? LoyaltyProgram(proId: widget.proId);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _program = LoyaltyProgram(proId: widget.proId);
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_program == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      await repo.saveLoyaltyProgram(_program!);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Programme mis à jour',
                style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                color: AppColors.blanc, size: 16),
          ),
        ),
        title: Text(
          'Programme fidélité',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SpotbookLoadingShimmer.card(itemCount: 3),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                SpotbookCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_giftcard_rounded,
                              color: AppColors.violet),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration',
                            style: GoogleFonts.sora(
                              color: AppColors.blanc,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Programme actif',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.blanc, fontSize: 14)),
                          Switch(
                            value: _program!.isActive,
                            activeThumbColor: AppColors.violet,
                            onChanged: (v) => setState(() {
                              _program = _program!.copyWith(isActive: v);
                            }),
                          ),
                        ],
                      ),
                      Divider(color: AppColors.border.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                          'Points par dollar : ${_program!.pointsPerDollar}',
                          style: GoogleFonts.dmSans(
                              color: AppColors.blanc, fontSize: 14)),
                      Slider(
                        value: _program!.pointsPerDollar.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '${_program!.pointsPerDollar} pts/\$',
                        activeColor: AppColors.violet,
                        onChanged: (v) => setState(() {
                          _program = _program!
                              .copyWith(pointsPerDollar: v.round());
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Points pour service gratuit : ${_program!.pointsForFreeService}',
                        style: GoogleFonts.dmSans(
                            color: AppColors.blanc, fontSize: 14),
                      ),
                      Slider(
                        value:
                            _program!.pointsForFreeService.toDouble(),
                        min: 50,
                        max: 500,
                        divisions: 9,
                        label: '${_program!.pointsForFreeService} pts',
                        activeColor: AppColors.violet,
                        onChanged: (v) => setState(() {
                          _program = _program!.copyWith(
                              pointsForFreeService: (v / 50).round() * 50);
                        }),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Exemple : avec ${_program!.pointsPerDollar} pts/\$ et '
                          '${_program!.pointsForFreeService} pts pour un service gratuit, '
                          'un client doit dépenser ${(_program!.pointsForFreeService / _program!.pointsPerDollar).toStringAsFixed(0)} \$ '
                          'pour obtenir un service gratuit.',
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
                const SizedBox(height: 16),
                SpotbookButton.primary(
                  label: _saving ? 'Enregistrement...' : 'Enregistrer',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
    );
  }
}
