class Metric {
  Metric({
    required this.name,
    required this.duration,
  });

  final String name;

  /// From user navigates to the website to the time user wants to measure metric
  final int duration;

  Metric copyWith({
    int? duration,
  }) {
    return Metric(
      name: name,
      duration: duration ?? this.duration,
    );
  }
}
