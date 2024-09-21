import 'dart:async';
import 'dart:html';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'measure_startup_time_method_channel.dart';
import 'models/measure_performance.dart';

abstract class MeasureStartupTimePlatform extends PlatformInterface {
  /// Constructs a MeasureStartupTimePlatform.
  MeasureStartupTimePlatform() : super(token: _token);

  static final Object _token = Object();

  static MeasureStartupTimePlatform _instance =
      MethodChannelMeasureStartupTime();

  /// The default instance of [MeasureStartupTimePlatform] to use.
  ///
  /// Defaults to [MethodChannelMeasureStartupTime].
  static MeasureStartupTimePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MeasureStartupTimePlatform] when
  /// they register themselves.
  static set instance(MeasureStartupTimePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Map<String, StreamController<MeasurePerformance>> processStreams = {};

  void startMeasure(String process, {VoidCallback? onStart}) {
    throw UnimplementedError('startMeasure() has not been implemented.');
  }

  void finishMeasure(String process, {VoidCallback? onFinish}) {
    throw UnimplementedError('finishMeasure() has not been implemented.');
  }

  void measure({
    required String process,
    required String metric,
    int? duration,
    VoidCallback? onMeasure,
  }) {
    throw UnimplementedError('measure() has not been implemented.');
  }

  StreamController<MeasurePerformance> getMetrics(String process) {
    throw UnimplementedError('getMetrics() has not been implemented.');
  }
}
