import 'measure_metric.dart';

class MeasurePerformance {
  MeasurePerformance({
    required this.process,
    required this.metrics,
  });

  final String process;
  final List<Metric> metrics;

  MeasurePerformance copyWith({
    List<Metric>? metrics,
  }) {
    return MeasurePerformance(
      process: process,
      metrics: metrics ?? this.metrics,
    );
  }
}
