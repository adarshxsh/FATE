import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'logic/telemetry_provider.dart';
import 'logic/score_history_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // In background, we need our own instance of SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('registered_user_id');

    if (userId != null) {
      // Create a temporary instance to fetch and store
      final service = ScoreHistoryService(prefs: prefs, userId: userId);
      await service.fetchAndStore();
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(callbackDispatcher);

  // Register the background task to run periodically
  Workmanager().registerPeriodicTask(
    "fate_background_analysis",
    "backgroundAnalysisTask",
    frequency: const Duration(
      minutes: 15,
    ), // Minimum allowed by Android is 15 mins
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run if we have internet
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
          create: (_) {
            final userId = prefs.getInt('registered_user_id');
            final service = ScoreHistoryService(prefs: prefs, userId: userId);
            if (userId != null) service.startPolling();
            return service;
          },
          update: (_, telemetry, service) {
            service!.updateUserId(telemetry.userId);
            return service;
          },
        ),
      ],
      child: const FateApp(),
    ),
  );
}
