import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/theme/app_colors.dart';
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
    final state = ref.watch(proInsightsProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
          ),
        ),
        title: const Text(
          'Insights Pro',
          style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold),
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
                  // Period selector
                  Row(
                    children: [
                      _PeriodChip(
                        label: '7j',
                        selected: state.period == 7,
                        onTap: () => ref.read(proInsightsProvider.notifier).setPeriod(7),
                      ),
                      const SizedBox(width: 8),
                      _PeriodChip(
                        label: '30j',
                        selected: state.period == 30,
                        onTap: () => ref.read(proInsightsProvider.notifier).setPeriod(30),
                      ),
                      const SizedBox(width: 8),
                      _PeriodChip(
                        label: '90j',
                        selected: state.period == 90,
                        onTap: () => ref.read(proInsightsProvider.notifier).setPeriod(90),
                      ),
                      const SizedBox(width: 8),
                      _PeriodChip(
                        label: '1 an',
                        selected: state.period == 365,
                        onTap: () => ref.read(proInsightsProvider.notifier).setPeriod(365),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (data == null || data.revenueSeries.every((p) => p.value == 0)) ...[
                    const SizedBox(height: 60),
                    const Icon(Icons.bar_chart, color: AppColors.gris, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune donnée pour cette période',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gris, fontSize: 15),
                    ),
                  ] else ...[
                    // Key metrics cards
                    _KeyMetricsGrid(data: data),
                    const SizedBox(height: 20),
                    // Revenue chart
                    _ChartSection(
                      title: 'Revenus',
                      series: data.revenueSeries,
                      lineColor: AppColors.success,
                      suffix: ' \$',
                    ),
                    const SizedBox(height: 20),
                    // Views chart — build from metrics
                    if (_findMetric(data, 'Vues vidéo') != null)
                      _ChartSection(
                        title: 'Vues vidéo',
                        series: data.revenueSeries, // reuses timeline
                        lineColor: AppColors.violet,
                        metric: _findMetric(data, 'Vues vidéo'),
                      ),
                    const SizedBox(height: 20),
                    // Detailed metrics list
                    const Text(
                      'Détails',
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...data.metrics.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MetricTile(metric: m),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  InsightMetric? _findMetric(ProInsights data, String label) {
    for (final m in data.metrics) {
      if (m.label == label) return m;
    }
    return null;
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
              4,
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
          // Shimmer squelette métriques
          Row(
            children: List.generate(
              2,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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

// ─── Key Metrics Grid ─────────────────────────────────────

class _KeyMetricsGrid extends StatelessWidget {
  const _KeyMetricsGrid({required this.data});
  final ProInsights data;

  @override
  Widget build(BuildContext context) {
    final revenue = data.metrics.where((m) => m.label == 'Revenus').firstOrNull;
    final bookings = data.metrics.where((m) => m.label == 'Événements').firstOrNull;
    final views = data.metrics.where((m) => m.label == 'Vues vidéo').firstOrNull;

    final cards = <_KeyMetricData>[
      if (revenue != null)
        _KeyMetricData(
          icon: Icons.attach_money,
          label: 'Revenus',
          value: '${revenue.value.toStringAsFixed(0)} \$',
          delta: revenue.deltaPercent,
        ),
      if (bookings != null)
        _KeyMetricData(
          icon: Icons.event,
          label: 'Événements',
          value: bookings.value.toStringAsFixed(0),
          delta: bookings.deltaPercent,
        ),
      if (views != null)
        _KeyMetricData(
          icon: Icons.visibility,
          label: 'Vues',
          value: views.value.toStringAsFixed(0),
          delta: views.deltaPercent,
        ),
      _KeyMetricData(
        icon: Icons.trending_up,
        label: 'Taux conv.',
        value: _conversionRate(data),
        delta: 0,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: cards.map((c) => _KeyMetricCard(data: c)).toList(),
    );
  }

  String _conversionRate(ProInsights data) {
    final views =
        data.metrics.where((m) => m.label == 'Vues vidéo').firstOrNull;
    final revenue =
        data.metrics.where((m) => m.label == 'Revenus').firstOrNull;
    if (views == null || views.value == 0) return '—';
    if (revenue == null) return '0%';
    // Approximate: bookings / views
    final bookingCount = data.metrics
        .where((m) => m.label == 'Événements')
        .firstOrNull
        ?.value ?? 0;
    if (views.value == 0) return '—';
    return '${(bookingCount / views.value * 100).toStringAsFixed(1)}%';
  }
}

class _KeyMetricData {
  const _KeyMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
  });
  final IconData icon;
  final String label;
  final String value;
  final double delta;
}

class _KeyMetricCard extends StatelessWidget {
  const _KeyMetricCard({required this.data});
  final _KeyMetricData data;

  @override
  Widget build(BuildContext context) {
    final up = data.delta >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(data.icon, color: AppColors.gris, size: 16),
              const SizedBox(width: 6),
              Text(data.label,
                  style: const TextStyle(
                      color: AppColors.gris, fontSize: 12)),
              const Spacer(),
              if (data.delta != 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up ? Icons.arrow_upward : Icons.arrow_downward,
                      color: up ? AppColors.success : AppColors.error,
                      size: 12,
                    ),
                    Text(
                      '${data.delta.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: up ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: const TextStyle(
              color: AppColors.blanc,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Section ────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.series,
    required this.lineColor,
    this.suffix = '',
    this.metric,
  });

  final String title;
  final List<InsightPoint> series;
  final Color lineColor;
  final String suffix;
  final InsightMetric? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (metric != null) ...[
              const Spacer(),
              Text(
                metric!.value.toStringAsFixed(metric!.label == 'Revenus' ? 2 : 0) + suffix,
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: _leftInterval(series),
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: AppColors.gris, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= series.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every Nth label
                        final step = series.length > 10 ? 3 : 1;
                        if (idx % step != 0 && idx != series.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          series[idx].label,
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      series.length,
                      (i) => FlSpot(i.toDouble(), series[i].value),
                    ),
                    color: lineColor,
                    barWidth: 2.2,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withAlpha(24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _leftInterval(List<InsightPoint> points) {
    if (points.isEmpty) return 1;
    final maxVal = points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxVal <= 5) return 1;
    return (maxVal / 4).ceilToDouble();
  }
}

// ─── Period Chip ──────────────────────────────────────────

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
      label: 'Période $label',
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
            style: TextStyle(
              color: selected ? AppColors.fond : AppColors.blanc,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Metric Tile ─────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final InsightMetric metric;

  @override
  Widget build(BuildContext context) {
    final up = metric.deltaPercent >= 0;
    return Container(
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
              style: const TextStyle(color: AppColors.gris, fontSize: 14),
            ),
          ),
          Text(
            metric.value.toStringAsFixed(metric.label == 'Revenus' ? 2 : 0),
            style: const TextStyle(
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
                style: TextStyle(
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
