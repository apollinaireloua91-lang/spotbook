import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_config_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/booking_notifier.dart';
import '../../domain/booking_models.dart';

/// Revenus pro : acomptes encaissés (RDV confirmés + terminés) sur la période,
/// avec liste de transactions, toggle période, et bouton "Retirer".
class ProRevenueScreen extends ConsumerStatefulWidget {
  const ProRevenueScreen({super.key});

  @override
  ConsumerState<ProRevenueScreen> createState() => _ProRevenueScreenState();
}

class _ProRevenueScreenState extends ConsumerState<ProRevenueScreen> {
  int _periodDays = 30;

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(proRevenueDailyProvider(_periodDays));
    final txAsync = ref.watch(proTransactionsProvider(_periodDays));
    final config = ref.watch(appConfigProvider).value ?? AppConfig.fallback;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          'Revenus',
          style: GoogleFonts.sora(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: AppColors.blanc, size: 22),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/pro/stripe-setup');
            },
          ),
        ],
      ),
      body: chartAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: SpotbookLoadingShimmer.card(itemCount: 4),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.gris),
            ),
          ),
        ),
        data: (series) {
          final total =
              series.fold<double>(0, (a, p) => a + p.amount);
          final maxVal =
              series.map((e) => e.amount).fold<double>(0, math.max);
          final maxY = maxVal <= 0 ? 50.0 : maxVal * 1.15;

          return RefreshIndicator(
            color: AppColors.blanc,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(proRevenueDailyProvider(_periodDays));
              ref.invalidate(proTransactionsProvider(_periodDays));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Acomptes encaissés (confirmés + terminés), hors frais Stripe.',
                  style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 16),
                // Period chips
                Row(
                  children: [
                    _PeriodChip(
                      label: '7 j',
                      selected: _periodDays == 7,
                      onTap: () => setState(() => _periodDays = 7),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: '30 j',
                      selected: _periodDays == 30,
                      onTap: () => setState(() => _periodDays = 30),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: '90 j',
                      selected: _periodDays == 90,
                      onTap: () => setState(() => _periodDays = 90),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: '1 an',
                      selected: _periodDays == 365,
                      onTap: () => setState(() => _periodDays = 365),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Total + Payout button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total for period',
                        style: GoogleFonts.dmSans(
                            color: AppColors.gris, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${total.toStringAsFixed(2)} CAD',
                        style: GoogleFonts.sora(
                          color: AppColors.blanc,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.push('/pro/payouts');
                          },
                          icon: const Icon(
                              Icons.account_balance_outlined,
                              size: 18),
                          label: Text('Retirer',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blanc,
                            foregroundColor: AppColors.fond,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Chart
                Text(
                  'Par jour',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            maxY > 0 ? maxY / 4 : 10,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval:
                                maxY > 0 ? maxY / 4 : 10,
                            getTitlesWidget: (v, _) => Text(
                              v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(1)}k'
                                  : v.toInt().toString(),
                              style: GoogleFonts.dmSans(
                                color: AppColors.gris,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= series.length) {
                                return const SizedBox.shrink();
                              }
                              final step =
                                  series.length > 20 ? 5 : 3;
                              if (i % step != 0 &&
                                  i != series.length - 1) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('d/M')
                                      .format(series[i].day),
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.gris,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < series.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: series[i].amount,
                                color: AppColors.grisClair,
                                width: math.max(
                                  3.0,
                                  math.min(14,
                                      320 / series.length * 0.45),
                                ),
                                borderRadius:
                                    const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                                backDrawRodData:
                                    BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxY,
                                  color: AppColors.surfaceAlt,
                                ),
                              ),
                            ],
                          ),
                      ],
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              AppColors.surfaceAlt,
                          tooltipPadding:
                              const EdgeInsets.all(8),
                          getTooltipItem: (group, groupIndex,
                              rod, rodIndex) {
                            final i = group.x.toInt();
                            if (i < 0 || i >= series.length) {
                              return null;
                            }
                            final d = series[i].day;
                            return BarTooltipItem(
                              '${DateFormat.yMMMd().format(d)}\n',
                              GoogleFonts.dmSans(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${series[i].amount.toStringAsFixed(2)} CAD',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.grisClair,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Transaction list header
                Text(
                  'Transactions',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Transaction list
                txAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.violet)),
                  ),
                  error: (e, _) => Text(e.toString(),
                      style:
                          GoogleFonts.dmSans(color: AppColors.gris)),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                              'No transactions for this period',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.gris,
                                  fontSize: 14)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _TransactionRow(
                        booking: transactions[index],
                        commissionRate: config.commissionBookings,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.booking,
    required this.commissionRate,
  });

  final BookingModel booking;
  final double commissionRate;

  @override
  Widget build(BuildContext context) {
    final gross = booking.depositAmount;
    final commission = gross * commissionRate;
    final net = gross - commission;
    final dateFmt = DateFormat('dd/MM/yy').format(booking.createdAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.clientName ?? 'Client',
                  style: GoogleFonts.dmSans(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                dateFmt,
                style: GoogleFonts.dmSans(
                    color: AppColors.gris, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            booking.serviceName ?? 'Service',
            style: GoogleFonts.dmSans(
                color: AppColors.gris, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _AmountLabel(
                  label: 'Brut',
                  value: '${gross.toStringAsFixed(2)} \$'),
              const SizedBox(width: 16),
              _AmountLabel(
                  label: 'Commission',
                  value: '-${commission.toStringAsFixed(2)} \$',
                  color: AppColors.rose),
              const SizedBox(width: 16),
              _AmountLabel(
                  label: 'Net',
                  value: '${net.toStringAsFixed(2)} \$',
                  color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                color: AppColors.grisInactif, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.dmSans(
              color: color ?? AppColors.blanc,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blanc : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: selected ? AppColors.fond : AppColors.blanc,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
