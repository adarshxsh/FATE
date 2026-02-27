class AttentionMetrics {
  final double currentCAS;
  final int fragmentationScore;
  final int contextSwitches;
  final int notificationBurstRate;
  final String dominantApp;

  AttentionMetrics({
    required this.currentCAS,
    required this.fragmentationScore,
    required this.contextSwitches,
    required this.notificationBurstRate,
    required this.dominantApp,
  });

  factory AttentionMetrics.initial() {
    return AttentionMetrics(
      currentCAS: 100.0,
      fragmentationScore: 0,
      contextSwitches: 0,
      notificationBurstRate: 0,
      dominantApp: 'None',
    );
  }

  factory AttentionMetrics.fromJson(Map<String, dynamic> json) {
    return AttentionMetrics(
      currentCAS: (json['currentCAS'] as num).toDouble(),
      fragmentationScore: json['fragmentationScore'] as int,
      contextSwitches: json['contextSwitches'] as int,
      notificationBurstRate: json['notificationBurstRate'] as int,
      dominantApp: json['dominantApp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentCAS': currentCAS,
      'fragmentationScore': fragmentationScore,
      'contextSwitches': contextSwitches,
      'notificationBurstRate': notificationBurstRate,
      'dominantApp': dominantApp,
    };
  }

  AttentionMetrics copyWith({
    double? currentCAS,
    int? fragmentationScore,
    int? contextSwitches,
    int? notificationBurstRate,
    String? dominantApp,
  }) {
    return AttentionMetrics(
      currentCAS: currentCAS ?? this.currentCAS,
      fragmentationScore: fragmentationScore ?? this.fragmentationScore,
      contextSwitches: contextSwitches ?? this.contextSwitches,
      notificationBurstRate: notificationBurstRate ?? this.notificationBurstRate,
      dominantApp: dominantApp ?? this.dominantApp,
    );
  }
}
