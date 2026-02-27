import 'package:hive_flutter/hive_flutter.dart';
import '../models/telemetry_event.dart';

class LocalMetricsRepository {
  static const String _boxName = 'telemetry_events';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  Future<void> saveEvent(TelemetryEvent event) async {
    final box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    await box.put(event.id, event.toJson());
  }

  Future<List<TelemetryEvent>> getUnsyncedEvents() async {
    final box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    return box.values.map((e) => TelemetryEvent.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> clearSyncedEvents(List<String> ids) async {
    final box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    await box.deleteAll(ids);
  }
}
