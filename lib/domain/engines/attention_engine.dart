import '../../data/models/telemetry_event.dart';
import '../../data/models/attention_metrics.dart';

class AttentionEngine {
  final Map<String, int> _appWeights = {
    "com.notion.android": 3,
    "com.microsoft.office.word": 3,
    "com.instagram.android": -4,
    "com.whatsapp": -1,
    "com.google.android.youtube": -2
  };

  AttentionMetrics calculateRealTimeMetrics(List<TelemetryEvent> recentEvents, AttentionMetrics currentMetrics) {
    int contextSwitches = 0;
    int notifBurst = 0;
    double digitalScore = 100.0;
    String dominant = currentMetrics.dominantApp;

    for (var event in recentEvents) {
      if (event.eventType == 'ACTIVITY_RESUMED') {
        contextSwitches++;
        dominant = event.packageName;
        int weight = _appWeights[event.packageName] ?? 0;
        digitalScore += weight;
      } else if (event.eventType == 'NOTIFICATION_POSTED') {
        notifBurst++;
        digitalScore -= 2.0; 
      }
    }

    if (digitalScore < 0) digitalScore = 0;
    if (digitalScore > 100) digitalScore = 100;

    return currentMetrics.copyWith(
      currentCAS: digitalScore,
      fragmentationScore: currentMetrics.fragmentationScore,
      contextSwitches: currentMetrics.contextSwitches + contextSwitches,
      notificationBurstRate: notifBurst,
      dominantApp: dominant,
    );
  }
}
