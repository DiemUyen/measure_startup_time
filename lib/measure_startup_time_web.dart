// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'measure_startup_time_platform_interface.dart';
import 'models/measure_exception.dart';
import 'models/measure_metric.dart';
import 'models/measure_performance.dart';

/// A web implementation of the MeasureStartupTimePlatform of the MeasureStartupTime plugin.
class MeasureStartupTimeWeb extends MeasureStartupTimePlatform {
  /// Constructs a MeasureStartupTimeWeb
  MeasureStartupTimeWeb();

  static void registerWith(Registrar registrar) {
    MeasureStartupTimePlatform.instance = MeasureStartupTimeWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = html.window.navigator.userAgent;
    return version;
  }

  static final List<MeasurePerformance> _performances = [];

  /// A list of processes that are currently being measured.
  static final List<String> _measuringProcesses = [];

  /// A list of processes that have been measured.
  static final List<String> _processes = [];

  @override
  void startMeasure(String process, {VoidCallback? onStart}) {
    if (process.isEmpty) {
      throw MeasureException('<name> cannot be empty');
    }
    if (_measuringProcesses.contains(process)) {
      throw MeasureException('A measure process is already running: $process.');
    }

    _measuringProcesses.add(process);
    if (!_processes.contains(process)) _processes.add(process);

    // Set the metrics to the initial state.
    final processIndex =
        _performances.indexWhere((element) => element.process == process);
    if (processIndex != -1) {
      _performances.removeAt(processIndex);
    }
    _performances.add(MeasurePerformance(process: process, metrics: []));
    processStreams.putIfAbsent(
      process,
      () => StreamController<MeasurePerformance>.broadcast(),
    );

    // Listen events from the native browser.
    _listenMetricsFromNative(process);
    // Listen events from the user in native.
    _listenCustomMetricsFromNative(process);

    onStart?.call();
  }

  void _listenMetricsFromNative(String process) {
    // An observer that listens to performance navigation timing metrics.
    final observer = html.PerformanceObserver(
      (entries, observer) {
        entries.getEntries().forEach((element) {
          if (element is html.PerformanceNavigationTiming) {
            int? domContentLoaded = element.domContentLoadedEventStart?.toInt();
            if (domContentLoaded != null) {
              _measureNativeMetrics(
                process: process,
                metric: 'domContentLoaded',
                duration: domContentLoaded,
              );
            }

            int? load = element.loadEventStart?.toInt();
            if (load != null) {
              _measureNativeMetrics(
                process: process,
                metric: 'load',
                duration: load,
              );
            }
          }
        });
      },
    );
    observer.observe({'type': 'navigation', 'buffered': true});

    // An observer that listens to performance paint metrics.
    final paintObserver = html.PerformanceObserver(
      (entries, observer) {
        entries.getEntriesByType('paint').forEach((element) {
          if (element is html.PerformancePaintTiming) {
            _measureNativeMetrics(
              process: process,
              metric: element.name,
              duration: element.startTime.toInt(),
            );
          }
        });
      },
    );
    paintObserver.observe({'type': 'paint', 'buffered': true});

    // An observer that listens to largest contentful paint metric.
    final lcpObserver = html.PerformanceObserver(
      (entries, observer) {
        final results = entries.getEntries();
        if (results.isNotEmpty) {
          final lcp = results.last;
          _measureNativeMetrics(
            process: process,
            metric: lcp.name,
            duration: lcp.startTime.toInt(),
          );
        }
      },
    );
    lcpObserver.observe({'type': 'largest-contentful-paint', 'buffered': true});
  }

  void _listenCustomMetricsFromNative(String process) {
    // An pbserver that listens to the performance metrics user emits in native.
    final measureObserver = html.PerformanceObserver(
      (entries, observer) {
        entries.getEntriesByType('measure').forEach((element) {
          if (element is html.PerformanceMeasure) {

            if (element.name.contains(process)) {
              // Split the process name and event name by ':'
              final parts = element.name.split(': ');
              final eventName = parts[1];
              _measureNativeMetrics(
                process: process,
                metric: eventName,
                duration: element.duration.toInt(),
              );
            }
          }
        });
      },
    );
    measureObserver.observe({'type': 'measure', 'buffered': true});
  }

  @override
  void finishMeasure(String process, {VoidCallback? onFinish}) {
    if (_measuringProcesses.isEmpty || !_measuringProcesses.contains(process)) {
      return;
    }

    // Add performance metric for the end of the measure process.
    // This will be the first time user can see the content of the page.
    measure(
      process: process,
      metric: process,
      onMeasure: () {
        onFinish?.call();
        // Clear the process name.
        _measuringProcesses.remove(process);
      },
    );
  }

  void _measureNativeMetrics({
    required String process,
    required String metric,
    required int duration,
  }) {
    if (metric.trim().isEmpty) {
      throw MeasureException('<metric> cannot be empty');
    }

    final processIndex =
        _performances.indexWhere((element) => element.process == process);
    if (processIndex != -1) {
      // The process has already been measured.
      final metricIndex = _performances[processIndex]
          .metrics
          .indexWhere((element) => element.name == metric);
      if (metricIndex == -1) {
        _performances[processIndex].metrics.add(
              Metric(name: metric, duration: duration),
            );
      } else {
        _performances[processIndex].metrics[metricIndex] =
            _performances[processIndex].metrics[metricIndex].copyWith(
                  duration: duration,
                );
      }

      processStreams[process]?.add(_performances[processIndex]);
    }
  }

  @override
  void measure({
    required String process,
    required String metric,
    int? duration,
    VoidCallback? onMeasure,
  }) {
    if (metric.trim().isEmpty) {
      throw MeasureException('<metric> cannot be empty');
    }

    if (_measuringProcesses.isEmpty || !_measuringProcesses.contains(process)) {
      return;
    }

    // If the metric has already been measured, use that instead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int now = html.window.performance.now().toInt();
      final processIndex =
          _performances.indexWhere((element) => element.process == process);
      if (processIndex != -1) {
        final metricIndex = _performances[processIndex]
            .metrics
            .indexWhere((element) => element.name == metric);
        if (metricIndex != -1) {
          _performances[processIndex].metrics[metricIndex] =
              _performances[processIndex].metrics[metricIndex].copyWith(
                    duration: now,
                  );
        } else {
          _performances[processIndex].metrics.add(
                Metric(name: metric, duration: now),
              );
        }

        onMeasure?.call();
        processStreams[process]?.add(_performances[processIndex]);
      }
    });
  }

  @override
  StreamController<MeasurePerformance> getMetrics(String process) {
    return processStreams[process] ??= StreamController<MeasurePerformance>();
  }
}
