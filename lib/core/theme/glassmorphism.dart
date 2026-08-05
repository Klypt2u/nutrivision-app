import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

/// Reusable visual atoms for glassmorphism surfaces.
///
/// We compose glass cards using two ingredients:
/// 1. A translucent base color.
/// 2. A subtle border with neon accent gradient (using [BorderSide] over a
///    custom [ShapeDecoration]) — true gradient borders require [ShaderMask].
class GlassDecoration {
  GlassDecoration._();

  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color(0x3300FF87),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> innerHighlight = [
    BoxShadow(
      color: Color(0x14FFFFFF),
      blurRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  /// Subtle outer shadow for floating cards.
  static List<BoxShadow> cardShadow = const [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 30,
      spreadRadius: -10,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x14FFFFFF),
      blurRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> floatingShadow = const [
    BoxShadow(
      color: Color(0xAA000000),
      blurRadius: 40,
      spreadRadius: -8,
      offset: Offset(0, 20),
    ),
  ];

  /// Box decoration for a standard glass card.
  static BoxDecoration standard({
    double radius = 24,
    Color tint = AppColors.glassOverlay,
    Border? border,
  }) {
    return BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
      border: border ??
          Border.all(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
      boxShadow: cardShadow,
    );
  }

  /// Decorative thin top highlight suggesting a glass lip.
  static const LinearGradient topLipGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x33FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.08],
  );

  /// Special "glowing" surface used for hero macro cards.
  static BoxDecoration glow({
    double radius = 28,
    Color tint = const Color(0xE61E1E24),
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1E24), Color(0xFF16161B)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.borderGlow,
        width: 1.0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x5500FF87),
          blurRadius: 36,
          spreadRadius: -12,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

/// Border helpers for neon stroke effects.
class NeonBorder {
  NeonBorder._();

  static Border lime({double width = 1.2}) => Border.all(
        color: AppColors.neonLime.withValues(alpha: 0.6),
        width: width,
      );

  static Border cyan({double width = 1.2}) => Border.all(
        color: AppColors.neonCyan.withValues(alpha: 0.6),
        width: width,
      );
}
