import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF14151F);
  static const Color surfaceHighlight = Color(0xFF1E1F2E);
  
  static const Color primary = Color(0xFF00FFCC);
  static const Color secondary = Color(0xFFB388FF);
  static const Color tertiary = Color(0xFFFF2D55);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF48484A);

  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFCC00);
  static const Color error = Color(0xFFFF3B30);

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
