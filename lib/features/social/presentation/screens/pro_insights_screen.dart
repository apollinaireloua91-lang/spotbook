import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_mode_notifier.dart';
import '../../data/social_repository.dart';
import '../../domain/social_models.dart';

class ProInsightsState {
  const ProInsightsState({
    this.period = 7,
    this.data,
    this.isLoading = true,
  });

  final int period;
  final ProInsights? data;
  final bool isLoading;

  ProInsightsState copyWith({int? period, ProInsights? data, bool? isLoading}) {
    return ProInsightsState(
      period: period ?? this.period,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProInsightsNotifier extends Notifier<ProInsightsState> {
  @override
  ProInsightsState build() {
    _load();
    return const ProInsightsState();
  }

  Future<void> _load() async {
    final uid = ref.read(socialRepositoryProvider).currentUserId;
    if (uid == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final data = await ref.read(socialRepositoryProvider).getProInsights(
          proId: uid,
          period: state.period,
        );
    state = state.copyWith(data: data, isLoading: false);
  }

  Future<void> setPeriod(int period) async {
    state = state.copyWith(period: period, isLoading: true);
    await _load();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }
}

final proInsightsProvider = NotifierProvider<ProInsightsNotifier, ProInsightsState>(
  ProInsightsNotifier.new,
  isAutoDispose: true,
);

class ProInsightsScreen extends ConsumerWidget {
  const ProInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final state = ref.watch(proInsightsProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          child: IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.blanc, size: 16),
            ),
          ),
        ),
        title: Text(
          'Insights Pro',
          style: GoogleFonts.sora(color: AppColors.blanc, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              color: AppColors.blanc,
              backgroundColor: AppColors.surface,
              onRefresh: () => ref.read(proInsightsProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Row(
                    children: [
                      _PeriodChip(
                        label: '7d',
                        selected: state.period == 7,
                        onTap: () => ref.read(proInsightsProvider.notifier).setPeriod(7),
                      ),
                      const SizedBox(width: 8),
                      _PeriodChip(
                        label: '30d',
                        selected: state.period == 30,
                        onTap: () => ref.read(proInsightsProvider.notifier).setPeriod(30),
                      ),
                      const SizedBox(width: 8),
                      _PeriodChip(
                        label: '90d',
                        selected: state.period == 90,
                        onTap: () => ref.read(proInsightsProvider.notifier).setPeriod(90),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (data == null || data.revenueSeries.every((p) => p.value == 0)) ...[
                    const SizedBox(height: 60),
                    Icon(Icons.bar_chart, color: AppColors.gris, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune donnée pour cette période',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 15),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.border,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 38,
                                  interval: _leftInterval(data.revenueSeries),
                                  getTitlesWidget: (value, _) => Text(
                                    value.toInt().toString(),
                                    style: TextStyle(color: AppColors.gris, fontSize: 11),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, _) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= data.revenueSeries.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      data.revenueSeries[idx].label,
                                      style: TextStyle(color: AppColors.gris, fontSize: 11),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  data.revenueSeries.length,
                                  (i) => FlSpot(i.toDouble(), data.revenueSeries[i].value),
                                ),
                                color: AppColors.blanc,
                                barWidth: 2.2,
                                isCurved: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.blanc.withAlpha(24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...data.metrics.map((m) => _MetricTile(metric: m)),
                  ],
                ],
              ),
            ),
    );
  }

  double _leftInterval(List<InsightPoint> points) {
    if (points.isEmpty) return 1;
    final maxVal = points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxVal <= 5) return 1;
    return (maxVal / 4).ceilToDouble();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceAlt,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Row(
            children: List.generate(
              3,
              (_) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 56,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
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
    return Semantics(
      label: 'Period $label',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.blanc : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.blanc : AppColors.border),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: selected ? AppColors.fond : AppColors.blanc,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final InsightMetric metric;

  @override
  Widget build(BuildContext context) {
    final up = metric.deltaPercent >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              metric.label,
              style: GoogleFonts.dmSans(color: AppColors.gris, fontSize: 14),
            ),
          ),
          Text(
            metric.value.toStringAsFixed(metric.label == 'Revenus' ? 2 : 0),
            style: GoogleFonts.sora(
              color: AppColors.blanc,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(
                up ? Icons.arrow_upward : Icons.arrow_downward,
                color: up ? AppColors.success : AppColors.error,
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                '${metric.deltaPercent.abs().toStringAsFixed(1)}%',
                style: GoogleFonts.dmSans(
                  color: up ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
