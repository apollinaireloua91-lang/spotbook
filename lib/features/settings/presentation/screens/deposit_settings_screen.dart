import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../profile/presentation/notifiers/pro_settings_notifier.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DEPOSIT SETTINGS SCREEN — Pro configures deposit percentage & toggle
// ═════════════════════════════════════════════════════════════════════════════

class DepositSettingsScreen extends ConsumerStatefulWidget {
  const DepositSettingsScreen({super.key});

  @override
  ConsumerState<DepositSettingsScreen> createState() =>
      _DepositSettingsScreenState();
}

class _DepositSettingsScreenState extends ConsumerState<DepositSettingsScreen> {
  bool _depositEnabled = true;
  double _depositPercentage = 30.0;
  double _minDepositAmount = 10.0;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(proSettingsProvider);

    // Initialize local state from loaded snapshot (once)
    if (!_initialized) {
      settingsAsync.whenData((snap) {
        _depositEnabled = snap.depositEnabled;
        _depositPercentage = snap.depositPercentage.clamp(10, 30);
        _minDepositAmount = snap.minDepositAmount;
        _initialized = true;
      });
    }

    // Example calculation
    const examplePrice = 100.0;
    final exampleDeposit = examplePrice * (_depositPercentage / 100);
    final exampleRemaining = examplePrice - exampleDeposit;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: l.retourLabel,
          child: IconButton(
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
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: Text(
          l.depositSettingsTitle,
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.violet,
                    ),
                  )
                : Text(
                    l.save,
                    style: GoogleFonts.dmSans(
                      color: AppColors.violet,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.violet)),
        error: (e, _) => Center(
          child: Text('${l.error} : $e',
              style: GoogleFonts.dmSans(color: AppColors.gris)),
        ),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header explanation ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.violet.withAlpha(51)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: AppColors.violet, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      l.depositRequireOnBooking,
                      style: GoogleFonts.sora(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.depositExplanation,
                      style: GoogleFonts.dmSans(
                        color: AppColors.gris,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Enable/Disable toggle ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.depositRequire,
                            style: GoogleFonts.dmSans(
                              color: AppColors.blanc,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _depositEnabled
                                ? l.depositEnabledDescription
                                : l.depositDisabledDescription,
                            style: GoogleFonts.dmSans(
                              color: AppColors.gris,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _depositEnabled,
                      activeThumbColor: AppColors.violet,
                      activeTrackColor: AppColors.violet.withAlpha(77),
                      onChanged: (val) => setState(() => _depositEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Deposit percentage slider ──
              AnimatedOpacity(
                opacity: _depositEnabled ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_depositEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.depositPercentageTitle,
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.depositPercentageDescription,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Percentage display
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_depositPercentage.toInt()}%',
                            style: GoogleFonts.sora(
                              color: AppColors.violet,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Slider (10-30% per CLAUDE.md max 30% constraint)
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.violet,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.violet,
                          overlayColor: AppColors.violet.withAlpha(38),
                          valueIndicatorColor: AppColors.violet,
                          valueIndicatorTextStyle: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Slider(
                          value: _depositPercentage,
                          min: 10,
                          max: 30,
                          divisions: 4, // 10, 15, 20, 25, 30
                          label: '${_depositPercentage.toInt()}%',
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() =>
                                _depositPercentage = val.roundToDouble());
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('10%',
                                style: GoogleFonts.dmSans(
                                    color: AppColors.gris, fontSize: 12)),
                            Text('30%',
                                style: GoogleFonts.dmSans(
                                    color: AppColors.gris, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Quick select buttons ──
                      Text(
                        l.depositQuickSelect,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [10, 15, 20, 25, 30].map((pct) {
                          final isSelected = _depositPercentage == pct;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() =>
                                      _depositPercentage = pct.toDouble());
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.violet
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.violet
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$pct%',
                                      style: GoogleFonts.dmSans(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.blanc,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // ── Minimum deposit ──
                      Text(
                        l.depositMinimumTitle,
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.depositMinimumDescription,
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '\$',
                              style: GoogleFonts.sora(
                                color: AppColors.violet,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    _minDepositAmount.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.sora(
                                  color: AppColors.blanc,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                onChanged: (val) {
                                  final parsed = double.tryParse(val);
                                  if (parsed != null &&
                                      parsed >= 5 &&
                                      parsed <= 200) {
                                    setState(
                                        () => _minDepositAmount = parsed);
                                  }
                                },
                              ),
                            ),
                            Text(
                              l.depositCadMinimum,
                              style: GoogleFonts.dmSans(
                                color: AppColors.grisInactif,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Live preview ──
                      Text(
                        l.depositPreviewTitle,
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.depositPreviewDescription(examplePrice.toStringAsFixed(0)),
                        style: GoogleFonts.dmSans(
                          color: AppColors.gris,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.violet.withAlpha(77),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            _PreviewRow(
                              label: l.depositServiceTotal,
                              value:
                                  '\$${examplePrice.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            Divider(color: AppColors.border, height: 1),
                            const SizedBox(height: 8),
                            _PreviewRow(
                              label:
                                  l.depositAmountLabel(_depositPercentage.toInt()),
                              value:
                                  '\$${exampleDeposit.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 4),
                            _PreviewRow(
                              label: l.depositServiceFee,
                              value: '\$2.50',
                              isSmall: true,
                            ),
                            const SizedBox(height: 8),
                            Divider(color: AppColors.border, height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l.depositClientPaysNow,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.violet,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${(exampleDeposit + 2.50).toStringAsFixed(2)}',
                                  style: GoogleFonts.sora(
                                    color: AppColors.violet,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.violet.withAlpha(15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule,
                                      color: AppColors.violet, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l.depositRemainingOnDay(exampleRemaining.toStringAsFixed(2)),
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.violet,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Save button (bottom) ──
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientAccent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppColors.primaryButtonShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l.depositSaveSettings,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(proSettingsProvider.notifier).patchProfilePro({
        'deposit_enabled': _depositEnabled,
        'deposit_percentage': _depositPercentage,
        'min_deposit_amount': _minDepositAmount,
      });

      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.depositSettingsSaved,
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppColors.violet,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.error} : $e',
                style: GoogleFonts.dmSans(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PreviewRow — label + value in the live preview card
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.isSmall = false,
  });

  final String label;
  final String value;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontSize: isSmall ? 12 : 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
            fontSize: isSmall ? 12 : 14,
          ),
        ),
      ],
    );
  }
}
