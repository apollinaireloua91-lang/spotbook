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
    // On first-time onboarding, pick the payout country. Stripe Express locks
    // the country at account creation, so this decision is one-shot.
    String? country;
    if (_status == 'not_connected') {
      country = await _pickCountry();
      if (country == null) return; // user dismissed sheet
    }

    setState(() => _isActionLoading = true);
    try {
      String url;

      if (_status == 'not_connected') {
        url = await ref
            .read(paymentRepositoryProvider)
            .createStripeConnectLink(country: country);
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
        throw Exception('Impossible d\'ouvrir Stripe');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<String?> _pickCountry() async {
    final l = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l.stripeCountryPickerTitle,
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.stripeCountryPickerSub,
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _CountryTile(
                  flag: '🇨🇦',
                  label: l.stripeCountryCA,
                  subtitle: l.stripeCountryCASub,
                  onTap: () => Navigator.of(sheetCtx).pop('CA'),
                ),
                const SizedBox(height: 10),
                _CountryTile(
                  flag: '🇫🇷',
                  label: l.stripeCountryFR,
                  subtitle: l.stripeCountryFRSub,
                  onTap: () => Navigator.of(sheetCtx).pop('FR'),
                ),
                const SizedBox(height: 10),
                _CountryTile(
                  flag: '🇺🇸',
                  label: l.stripeCountryUS,
                  subtitle: l.stripeCountryUSSub,
                  onTap: () => Navigator.of(sheetCtx).pop('US'),
                ),
              ],
            ),
          ),
        );
      },
    );
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

                  const SizedBox(height: 24),
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

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.flag,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final String flag;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.grisInactif,
                size: 14,
              ),
            ],
          ),
        ),
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

