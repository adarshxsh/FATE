import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'ui/main_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/theme.dart';
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
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.dark(
          primary: FateColors.primary,
          secondary: FateColors.secondary,
          surface: FateColors.bgCard,
          error: const Color(0xFFFF5252),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: FateColors.bgDeep,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white70),
        ),
        cardTheme: CardThemeData(
          color: FateColors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      home: context.watch<TelemetryProvider>().userId == null
          ? const LoginScreen()
          : const MainScreen(),
    );
  }
}
