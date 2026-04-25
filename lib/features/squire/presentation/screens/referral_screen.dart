import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/share_branding.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/squire_repository.dart';
import '../../domain/squire_models.dart';

/// Priority #10 — Referral program screen.
/// Shows the user's unique code, total referrals, CTA to share.
class SquireReferralScreen extends ConsumerStatefulWidget {
  const SquireReferralScreen({super.key});

  @override
  ConsumerState<SquireReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<SquireReferralScreen> {
  UserReferral? _myCode;
  List<UserReferral> _myReferrals = [];
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      final code = await repo.loadMyReferralCode();
      final referrals = await repo.listMyReferrals();
      if (!mounted) return;
      setState(() {
        _myCode = code;
        _myReferrals = referrals;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final repo = ref.read(squireRepositoryProvider);
      final code = await repo.generateReferralCode();
      HapticFeedback.mediumImpact();
      setState(() => _myCode = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _share() async {
    if (_myCode == null) return;
    final text =
        'Découvre Spotbook avec mon code ${_myCode!.referralCode} et on reçoit chacun '
        '${CurrencyFormatter.formatAmount(_myCode!.rewardDollars)} sur notre prochaine réservation !';
    await ShareBranding.shareWithLogo(text: text);
  }

  int get _completedCount =>
      _myReferrals.where((r) => r.status == ReferralStatus.completed).length;

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
          'Parrainage',
          style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.w700),
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
                _HeroCard(
                  code: _myCode,
                  onGenerate: _generating ? null : _generate,
                  onShare: _share,
                  generating: _generating,
                ),
                const SizedBox(height: 16),
                SpotbookCard(
                  child: Row(
                    children: [
                      Icon(Icons.group_add,
                          color: AppColors.success, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_completedCount parrainages réussis',
                            style: GoogleFonts.sora(
                              color: AppColors.blanc,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Total gagné : ${CurrencyFormatter.formatAmount(_completedCount * (_myCode?.rewardDollars ?? 10))}',
                            style: GoogleFonts.dmSans(
                                color: AppColors.gris, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.code,
    required this.onGenerate,
    required this.onShare,
    required this.generating,
  });

  final UserReferral? code;
  final VoidCallback? onGenerate;
  final VoidCallback onShare;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.violet, AppColors.violetClair],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism,
                  color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Invite un ami',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            code == null
                ? 'Génère ton code unique et partage-le. Vous gagnez chacun 10 \$ à sa première réservation.'
                : 'Partage ce code. Vous gagnez chacun ${CurrencyFormatter.formatAmount(code!.rewardDollars)} à sa première réservation.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (code != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code!.referralCode,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: code!.referralCode));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Code copié',
                              style: GoogleFonts.dmSans()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SpotbookButton.primary(
              label: 'Partager mon code',
              icon: Icons.share,
              onPressed: onShare,
            ),
          ] else
            SpotbookButton.primary(
              label: generating ? 'Génération...' : 'Générer mon code',
              icon: Icons.auto_awesome,
              onPressed: onGenerate,
            ),
        ],
      ),
    );
  }
}
