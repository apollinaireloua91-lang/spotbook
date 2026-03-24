import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../data/booking_notifier.dart';

/// Revenus pro : acomptes encaissés (RDV confirmés + terminés) sur la période.
class ProRevenueScreen extends ConsumerStatefulWidget {
  const ProRevenueScreen({super.key});

  @override
  ConsumerState<ProRevenueScreen> createState() => _ProRevenueScreenState();
}

class _ProRevenueScreenState extends ConsumerState<ProRevenueScreen> {
  int _periodDays = 30;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(proRevenueDailyProvider(_periodDays));

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: const Text(
          'Revenus',
          style: TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: async.when(
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
              style: const TextStyle(color: AppColors.gris),
            ),
          ),
        ),
        data: (series) {
          final total = series.fold<double>(0, (a, p) => a + p.amount);
          final maxVal = series.map((e) => e.amount).fold<double>(0, math.max);
          final maxY = maxVal <= 0 ? 50.0 : maxVal * 1.15;

          return RefreshIndicator(
            color: AppColors.blanc,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(proRevenueDailyProvider(_periodDays));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(
                  'Acomptes encaissés (confirmés + terminés), hors frais Stripe.',
                  style: TextStyle(color: AppColors.gris, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
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
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total sur la période',
                        style: TextStyle(color: AppColors.gris, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${total.toStringAsFixed(2)} CAD',
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Par jour',
                  style: TextStyle(
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
                        horizontalInterval: maxY > 0 ? maxY / 4 : 10,
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
                            interval: maxY > 0 ? maxY / 4 : 10,
                            getTitlesWidget: (v, _) => Text(
                              v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(1)}k'
                                  : v.toInt().toString(),
                              style: const TextStyle(
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
                              final step = series.length > 20 ? 5 : 3;
                              if (i % step != 0 && i != series.length - 1) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('d/M').format(series[i].day),
                                  style: const TextStyle(
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
                                  math.min(14, 320 / series.length * 0.45),
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
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
                          getTooltipColor: (_) => AppColors.surfaceAlt,
                          tooltipPadding: const EdgeInsets.all(8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final i = group.x.toInt();
                            if (i < 0 || i >= series.length) return null;
                            final d = series[i].day;
                            return BarTooltipItem(
                              '${DateFormat.yMMMd().format(d)}\n',
                              const TextStyle(
                                color: AppColors.blanc,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '${series[i].amount.toStringAsFixed(2)} CAD',
                                  style: const TextStyle(
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
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push('/pro/stripe-setup');
                  },
                  child: const Text(
                    'Paramètres Stripe Connect',
                    style: TextStyle(color: AppColors.grisClair, fontSize: 14),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
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
