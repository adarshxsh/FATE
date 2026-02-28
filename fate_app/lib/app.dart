import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'ui/main_screen.dart';
import 'ui/auth/login_screen.dart';
import 'logic/telemetry_provider.dart';

class FateApp extends StatelessWidget {
  const FateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FATE System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto', // Replace with a more premium font if added
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF03DAC6),
          surface: const Color(0xFF1E1E1E),
          error: const Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: context.watch<TelemetryProvider>().userId == null
          ? const LoginScreen()
          : const MainScreen(),
    );
  }
}
