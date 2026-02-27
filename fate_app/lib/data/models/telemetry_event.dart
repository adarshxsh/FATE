class TelemetryEvent {
  final String id;
  final int timestamp;
  final String eventType;
  final String packageName;
  final String category;
  final int durationSec;

  TelemetryEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.packageName,
    required this.category,
    required this.durationSec,
  });

  factory TelemetryEvent.fromJson(Map<String, dynamic> json) {
    return TelemetryEvent(
      id: json['id'] as String,
      timestamp: json['timestamp'] as int,
      eventType: json['eventType'] as String,
      packageName: json['packageName'] as String,
      category: json['category'] as String,
      durationSec: json['durationSec'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'eventType': eventType,
      'packageName': packageName,
      'category': category,
      'durationSec': durationSec,
    };
  }
}
