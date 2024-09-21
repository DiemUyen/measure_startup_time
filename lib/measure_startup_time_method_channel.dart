import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'measure_startup_time_platform_interface.dart';

/// An implementation of [MeasureStartupTimePlatform] that uses method channels.
class MethodChannelMeasureStartupTime extends MeasureStartupTimePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('measure_startup_time');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
