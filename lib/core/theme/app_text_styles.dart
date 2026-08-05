import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text style catalog. Uses SF Pro Display via [GoogleFonts] with a graceful
/// system-font fallback so the app feels native on every iOS device.
class AppText {
  AppText._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.sfProDisplay(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.textPrimary,
    );
  }

  static TextStyle _rounded({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.sfProRounded(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.textPrimary,
    );
  }

  // Display
  static TextStyle display = _base(
    size: 40,
    weight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  static TextStyle displayCompact = _rounded(
    size: 32,
    weight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.6,
  );

  // Headings
  static TextStyle h1 = _base(size: 28, weight: FontWeight.w700, height: 1.2);
  static TextStyle h2 = _base(size: 22, weight: FontWeight.w600, height: 1.25);
  static TextStyle h3 = _base(size: 18, weight: FontWeight.w600, height: 1.3);
  static TextStyle h4 = _base(size: 16, weight: FontWeight.w600, height: 1.35);

  // Body
  static TextStyle bodyLarge = _base(
    size: 17,
    weight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle body = _base(
    size: 15,
    weight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static TextStyle bodySmall = _base(
    size: 13,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Caption / label
  static TextStyle caption = _base(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static TextStyle label = _base(
    size: 13,
    weight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.4,
  );

  static TextStyle overline = _base(
    size: 11,
    weight: FontWeight.w700,
    color: AppColors.textTertiary,
    height: 1.0,
    letterSpacing: 1.6,
  );

  // Numeric / metric
  static TextStyle metric = _rounded(
    size: 36,
    weight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.8,
  );

  static TextStyle metricSmall = _rounded(
    size: 22,
    weight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.4,
  );

  static TextStyle metricTiny = _rounded(
    size: 14,
    weight: FontWeight.w700,
    height: 1.0,
  );

  // Buttons
  static TextStyle button = _base(
    size: 16,
    weight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static TextStyle buttonSmall = _base(
    size: 14,
    weight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );
}
