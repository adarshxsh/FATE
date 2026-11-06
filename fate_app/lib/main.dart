import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'logic/telemetry_provider.dart';
import 'logic/score_history_service.dart';
import 'logic/scoring_engine.dart';

/// Background dispatcher — runs fully offline, no network required.
/// Computes local CAS from the encrypted SQLite DB and stores the snapshot.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final localId = prefs.getString('local_identity_id');

    if (localId != null) {
      try {
        // Recalculate CAS from local DB — fully offline
        final scores = await ScoringEngine.calculateDailyCas(DateTime.now());
        final service = ScoreHistoryService(prefs: prefs);
        service.storeBackgroundSnapshot(scores);
        debugPrint('[BG] Offline analysis complete: CAS=${scores['CAS']}');
      } catch (e) {
        debugPrint('[BG] Analysis error: $e');
      }
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager — no network dependency
  Workmanager().initialize(callbackDispatcher);

  // Background task runs completely offline — no network constraint
  Workmanager().registerPeriodicTask(
    'fate_background_analysis',
    'backgroundAnalysisTask',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.notRequired, // ← offline-first
      requiresBatteryNotLow: false,
      requiresCharging: false,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TelemetryProvider(prefs)..initialize(),
        ),
        ChangeNotifierProxyProvider<TelemetryProvider, ScoreHistoryService>(
          create: (_) => ScoreHistoryService(prefs: prefs)..startPolling(),
          update: (_, telemetry, service) {
            service!.syncRealtimeScores(
              telemetry.focusScore,
              telemetry.sLoc,
              telemetry.sSoc,
              telemetry.sDig,
            );
            return service;
          },
        ),
      ],
      child: const FateApp(),
    ),
  );
}
