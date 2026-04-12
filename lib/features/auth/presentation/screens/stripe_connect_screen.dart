import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/payment/data/payment_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// STRIPE CONNECT SCREEN — Pro bank account setup + dashboard
// ═════════════════════════════════════════════════════════════════════════════

class StripeConnectScreen extends ConsumerStatefulWidget {
  const StripeConnectScreen({super.key});

  @override
  ConsumerState<StripeConnectScreen> createState() =>
      _StripeConnectScreenState();
}

class _StripeConnectScreenState extends ConsumerState<StripeConnectScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isActionLoading = false;

  String _status = 'not_connected';
  bool _detailsSubmitted = false;
  bool _chargesEnabled = false;
  bool _payoutsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data =
          await ref.read(paymentRepositoryProvider).getStripeConnectStatus();
      if (!mounted) return;
      setState(() {
        _status = data['status'] as String? ?? 'not_connected';
        _detailsSubmitted = data['detailsSubmitted'] as bool? ?? false;
        _chargesEnabled = data['chargesEnabled'] as bool? ?? false;
        _payoutsEnabled = data['payoutsEnabled'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openStripeAction() async {
    setState(() => _isActionLoading = true);
    try {
      String url;

      if (_status == 'not_connected') {
        url = await ref
            .read(paymentRepositoryProvider)
            .createStripeConnectLink();
      } else {
        final data = await ref
            .read(paymentRepositoryProvider)
            .getStripeConnectStatus();
        url = data['url'] as String? ?? '';
      }

      if (url.isEmpty) throw Exception('No URL returned');

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        HapticFeedback.mediumImpact();
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open Stripe');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bool isActive = _status == 'active';

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.a11yBack,
          child: IconButton(
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
        ),
        title: Text(
          l.stripePaymentsTitle,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchStatus,
            icon: Icon(Icons.refresh_rounded, size: 22, color: AppColors.gris),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.violet))
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              color: AppColors.violet,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  // ── Hero banner ──
                  _HeroBanner(status: _status),

                  const SizedBox(height: 20),

                  // ── Status card ──
                  _StatusCard(
                    status: _status,
                    detailsSubmitted: _detailsSubmitted,
                    chargesEnabled: _chargesEnabled,
                    payoutsEnabled: _payoutsEnabled,
                  ),

                  const SizedBox(height: 20),

                  // ── Main CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientAccent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.primaryButtonShadow,
                      ),
                      child: ElevatedButton.icon(
                        onPressed:
                            _isActionLoading ? null : _openStripeAction,
                        icon: _isActionLoading
                            ? const SizedBox.shrink()
                            : Icon(
                                isActive
                                    ? Icons.dashboard_rounded
                                    : _status == 'pending'
                                        ? Icons.arrow_forward_rounded
                                        : Icons.link_rounded,
                                size: 20,
                              ),
                        label: _isActionLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : Text(
                                isActive
                                    ? l.stripeOpenDashboard
                                    : _status == 'pending'
                                        ? l.stripeFinishSetup
                                        : l.stripeConnectBank,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppColors.textOnPrimary,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── How it works section ──
                  _SectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: l.stripeHowItWorks,
                  ),
                  const SizedBox(height: 16),

                  _StepTile(
                    number: '1',
                    icon: Icons.account_balance_rounded,
                    title: l.stripeStep1Title,
                    subtitle: l.stripeStep1Desc,
                  ),
                  _StepTile(
                    number: '2',
                    icon: Icons.calendar_month_rounded,
                    title: l.stripeStep2Title,
                    subtitle: l.stripeStep2Desc,
                  ),
                  _StepTile(
                    number: '3',
                    icon: Icons.payments_rounded,
                    title: l.stripeStep3Title,
                    subtitle: l.stripeStep3Desc,
                    isLast: true,
                  ),

                  const SizedBox(height: 28),

                  // ── Fees breakdown ──
                  _SectionHeader(
                    icon: Icons.receipt_long_rounded,
                    title: l.stripeFeesTitle,
                  ),
                  const SizedBox(height: 14),

                  _FeeCard(
                    items: [
                      _FeeItem(
                        label: l.stripeFeeBooking,
                        value: '18%',
                        subtitle: l.stripeFeeBookingSub,
                      ),
                      _FeeItem(
                        label: l.stripeFeeEvent,
                        value: '12%',
                        subtitle: l.stripeFeeEventSub,
                      ),
                      _FeeItem(
                        label: l.stripeFeeService,
                        value: '\$2.50',
                        subtitle: l.stripeFeeServiceSub,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withAlpha(40), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.stripeNoMonthlyFees,
                            style: GoogleFonts.dmSans(
                              color: AppColors.success,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Security trust badges ──
                  _SectionHeader(
                    icon: Icons.shield_rounded,
                    title: l.stripeSecurityTitle,
                  ),
                  const SizedBox(height: 14),

                  _TrustBadge(
                    icon: Icons.lock_rounded,
                    title: l.stripeTrustSsl,
                    subtitle: l.stripeTrustSslSub,
                  ),
                  const SizedBox(height: 10),
                  _TrustBadge(
                    icon: Icons.verified_rounded,
                    title: l.stripeTrustPowered,
                    subtitle: l.stripeTrustPoweredSub,
                  ),
                  const SizedBox(height: 10),
                  _TrustBadge(
                    icon: Icons.speed_rounded,
                    title: l.stripeTrustFast,
                    subtitle: l.stripeTrustFastSub,
                  ),

                  const SizedBox(height: 32),

                  // ── FAQ section ──
                  _SectionHeader(
                    icon: Icons.help_outline_rounded,
                    title: l.stripeFaqTitle,
                  ),
                  const SizedBox(height: 14),

                  _FAQItem(
                    question: l.stripeFaqWhenPaid,
                    answer: l.stripeFaqWhenPaidAnswer,
                  ),
                  _FAQItem(
                    question: l.stripeFaqCancel,
                    answer: l.stripeFaqCancelAnswer,
                  ),
                  _FAQItem(
                    question: l.stripeFaqDeposit,
                    answer: l.stripeFaqDepositAnswer,
                  ),

                  const SizedBox(height: 24),

                  // ── Support link ──
                  Center(
                    child: GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(
                            'https://getspotbook.app/support#contact'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support_agent_rounded,
                              color: AppColors.violet, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            l.stripeNeedHelp,
                            style: GoogleFonts.dmSans(
                              color: AppColors.violet,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO BANNER — visual context for the Pro
// ═════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bool isActive = status == 'active';
    final bool isPending = status == 'pending';

    final String title;
    final String subtitle;
    final IconData icon;

    if (isActive) {
      title = l.stripeHeroActiveTitle;
      subtitle = l.stripeHeroActiveSub;
      icon = Icons.check_circle_rounded;
    } else if (isPending) {
      title = l.stripeHeroPendingTitle;
      subtitle = l.stripeHeroPendingSub;
      icon = Icons.hourglass_top_rounded;
    } else {
      title = l.stripeHeroConnectTitle;
      subtitle = l.stripeHeroConnectSub;
      icon = Icons.account_balance_wallet_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppColors.success.withAlpha(20),
                  AppColors.success.withAlpha(8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.gradientAccent,
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border.all(color: AppColors.success.withAlpha(40))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.success.withAlpha(30)
                  : Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.success : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color:
                        isActive ? AppColors.success : AppColors.textOnPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: isActive
                        ? AppColors.success.withAlpha(180)
                        : Colors.white.withAlpha(200),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STATUS CARD
// ═════════════════════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.detailsSubmitted,
    required this.chargesEnabled,
    required this.payoutsEnabled,
  });

  final String status;
  final bool detailsSubmitted;
  final bool chargesEnabled;
  final bool payoutsEnabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bool isActive = status == 'active';
    final bool isPending = status == 'pending';

    if (!isPending && !isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.success.withAlpha(60)
              : AppColors.warning.withAlpha(60),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.stripeSetupProgress,
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _CheckItem(
            label: l.stripeDetailsSubmitted,
            subtitle: l.stripeDetailsSubmittedSub,
            done: detailsSubmitted,
          ),
          const SizedBox(height: 10),
          _CheckItem(
            label: l.stripeChargesEnabled,
            subtitle: l.stripeChargesEnabledSub,
            done: chargesEnabled,
          ),
          const SizedBox(height: 10),
          _CheckItem(
            label: l.stripePayoutsEnabled,
            subtitle: l.stripePayoutsEnabledSub,
            done: payoutsEnabled,
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.label,
    required this.done,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? AppColors.success : AppColors.grisInactif,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: done ? AppColors.blanc : AppColors.gris,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.dmSans(
                    color: AppColors.grisInactif,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.violet, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.blanc,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STEP TILE — numbered steps with icons
// ═════════════════════════════════════════════════════════════════════════════

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Timeline ──
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // ── Content ──
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: AppColors.violet, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.sora(
                            color: AppColors.blanc,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FEE CARD — commission breakdown
// ═════════════════════════════════════════════════════════════════════════════

class _FeeItem {
  const _FeeItem({
    required this.label,
    required this.value,
    required this.subtitle,
  });
  final String label;
  final String value;
  final String subtitle;
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({required this.items});
  final List<_FeeItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].label,
                        style: GoogleFonts.dmSans(
                          color: AppColors.blanc,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        items[i].subtitle,
                        style: GoogleFonts.dmSans(
                          color: AppColors.grisInactif,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    items[i].value,
                    style: GoogleFonts.sora(
                      color: AppColors.violet,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (i < items.length - 1)
              Divider(
                  color: AppColors.border, height: 20, thickness: 0.5),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRUST BADGE
// ═════════════════════════════════════════════════════════════════════════════

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FAQ ITEM — expandable question/answer
// ═════════════════════════════════════════════════════════════════════════════

class _FAQItem extends StatefulWidget {
  const _FAQItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.gris,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              Text(
                widget.answer,
                style: GoogleFonts.dmSans(
                  color: AppColors.gris,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
