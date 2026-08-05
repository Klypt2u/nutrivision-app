import 'package:flutter/cupertino.dart';

/// Centralized color palette for NutriVision AI.
///
/// Palette philosophy:
/// - **Background**: deep matte charcoal for unobtrusive OLED viewing.
/// - **Surfaces**: translucent glass tint for layered glassmorphism.
/// - **Accents**: high-saturation neon for active state and rings.
class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFF0F0F12);
  static const Color backgroundAlt = Color(0xFF14141A);
  static const Color backgroundDeep = Color(0xFF08080B);

  // Glassmorphism surfaces
  static const Color glass = Color(0xFF1E1E24);
  static const Color glassLight = Color(0xFF25252D);
  static const Color glassDark = Color(0xFF16161B);

  // Translucent overlays
  static const Color glassOverlay = Color(0xCC1E1E24); // 80% alpha
  static const Color glassOverlaySoft = Color(0x991E1E24); // 60% alpha
  static const Color glassOverlayFaint = Color(0x661E1E24); // 40% alpha

  // Borders
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white
  static const Color borderGlow = Color(0x33FFFFFF); // 20% white
  static const Color borderAccent = Color(0x6600FF87); // 40% lime

  // Neon accents
  static const Color neonLime = Color(0xFF00FF87);
  static const Color neonLimeSoft = Color(0x6600FF87);
  static const Color neonCyan = Color(0xFF60EFFF);
  static const Color neonCyanSoft = Color(0x6660EFFF);
  static const Color neonPink = Color(0xFFFF4D8D);
  static const Color neonPurple = Color(0xFFA06CFF);
  static const Color neonAmber = Color(0xFFFFB547);

  // Macro semantic colors
  static const Color macroCalories = neonLime;
  static const Color macroProtein = neonCyan;
  static const Color macroCarbs = neonAmber;
  static const Color macroFat = neonPink;
  static const Color macroFiber = neonPurple;
  static const Color macroWater = Color(0xFF6BB7FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B8);
  static const Color textTertiary = Color(0xFF6E6E78);
  static const Color textOnAccent = Color(0xFF0A0A0F);

  // Status
  static const Color success = neonLime;
  static const Color warning = neonAmber;
  static const Color danger = Color(0xFFFF5C5C);
  static const Color info = neonCyan;

  // Gradients
  static const LinearGradient neonSweep = LinearGradient(
    colors: [neonLime, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient macroSweep = LinearGradient(
    colors: [neonLime, neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scannerOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xCC0F0F12)],
    stops: [0.5, 1.0],
  );

  static const RadialGradient ringBackground = RadialGradient(
    colors: [Color(0x3300FF87), Color(0x0000FF87)],
    radius: 1.0,
  );
}
