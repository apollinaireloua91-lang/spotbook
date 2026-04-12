class InsightPoint {
  const InsightPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class InsightMetric {
  const InsightMetric({
    required this.label,
    required this.value,
    required this.deltaPercent,
  });

  final String label;
  final double value;
  final double deltaPercent;
}

class ProInsights {
  const ProInsights({
    required this.periodDays,
    required this.revenueSeries,
    required this.metrics,
  });

  final int periodDays;
  final List<InsightPoint> revenueSeries;
  final List<InsightMetric> metrics;
}
