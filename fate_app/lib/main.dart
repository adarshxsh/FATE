import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'logic/telemetry_provider.dart';
import 'logic/score_history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TelemetryProvider(prefs)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final userId = prefs.getInt('registered_user_id');
            final service = ScoreHistoryService(prefs: prefs, userId: userId);
            service.startPolling();
            return service;
          },
        ),
      ],
      child: const FateApp(),
    ),
  );
}
