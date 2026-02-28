import 'package:flutter/material.dart';

class AppColors {
  // Pur AMOLED Black as requested
  static const Color background = Color(0xFF000000); 
  
  // Restored original colors
  static const Color surface = Color(0xFF14151F);
  static const Color surfaceHighlight = Color(0xFF1E1F2E);
  static const Color gridLines = Color(0xFF2A2A35);
  
  static const Color primary = Color(0xFF3DE0D8);
  static const Color secondary = Color(0xFF2A9E99);
  static const Color tertiary = Color(0xFF1A615E);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF48484A);

  static const Color success = Color(0xFF3DE0D8);
  static const Color warning = Color(0xFF81EFEA);
  static const Color error = Color(0xFF1A615E);
  static const Color alert = error;

  // FATE Loading Screen Specific Brand Colors
  static const Color backgroundDark = Color(0xFF050714);
  static const Color backgroundCard = Color(0xFF0A0E27);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color deepCyan = Color(0xFF0088CC);
  static const Color neonPurple = Color(0xFFD500F9);
  static const Color deepPurple = Color(0xFF651FFF);
  static const Color errorRed = Color(0xFFFF1744);
  static const Color successGreen = Color(0xFF00E676);

  static const Color shadowDark = Color(0x33000000); 
  static const Color shadowLight = Color(0x11FFFFFF);

  static const LinearGradient focusGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [secondary, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper for AMOLED Distinct Surface - Flat with sharp border instead of 3D
  static BoxDecoration neumorphicDecoration({double radius = 16}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF2A2A35), width: 1.0),
      boxShadow: [
        BoxShadow(color: primary.withOpacity(0.02), offset: const Offset(0, 4), blurRadius: 16),
      ],
    );
  }

  // Helper for "Pressed" / Active AMOLED Look - Neon border glow
  static BoxDecoration neumorphicPressedDecoration({double radius = 16}) {
    return BoxDecoration(
      color: surfaceHighlight,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: primary.withOpacity(0.3), width: 1.0),
      boxShadow: [
        BoxShadow(color: primary.withOpacity(0.05), blurRadius: 8),
      ],
    );
  }
}
