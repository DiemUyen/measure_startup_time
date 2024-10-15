import 'dart:async';
import 'dart:html';

import 'measure_startup_time_platform_interface.dart';
import 'models/measure_performance.dart';

class MeasureStartupTime {
  /// Start a measure process with the given name, \
  /// and optional [onStart] callback that will be called when the measure process started.
  ///
  /// When a measure process is already running, this method will throw a [MeasureException].
  static void startMeasure(String process, {VoidCallback? onStart}) {
    MeasureStartupTimePlatform.instance.startMeasure(process, onStart: onStart);
  }

  /// Finish the last measure process.
  ///
  /// When there is no measure process running, this method will throw a [MeasureException].
  static void finishMeasure(String process, {VoidCallback? onFinish}) {
    MeasureStartupTimePlatform.instance
        .finishMeasure(process, onFinish: onFinish);
  }

  /// Measure the duration of the given event.
  ///
  /// This method can be called from Flutter to emit a custom event that will be measured.
  static void measure({
    required String process,
    required String metric,
    int? duration,
    VoidCallback? onMeasure,
  }) {
    MeasureStartupTimePlatform.instance.measure(
      process: process,
      metric: metric,
      duration: duration,
      onMeasure: onMeasure,
    );
  }

  /// Get the metrics of the given process.
  static Stream<MeasurePerformance> getMetrics(String process) {
    return MeasureStartupTimePlatform.instance.getMetrics(process).stream;
  }
}
