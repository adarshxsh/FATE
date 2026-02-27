import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF0F1110);
  static const Color surfaceHighlight = Color(0xFF1E2422); // Slightly lighter than surface
  static const Color gridLines = Color(0xFF1A2220); // Grid/Lines Dark Green-Grey
  
  static const Color primary = Color(0xFF39FF14); // Neon Green
  static const Color secondary = Color(0xFF00FFFF); // Electric Blue
  static const Color tertiary = Color(0xFFFF0099); // Hot Pink
  static const Color alert = Color(0xFFFF0099); // Hot Pink
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF50605A);

  static const Color success = Color(0xFF39FF14);
  static const Color warning = Color(0xFFFFCC00);
  static const Color error = Color(0xFFFF0099);

  static const LinearGradient focusGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [tertiary, error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
