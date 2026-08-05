import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

/// App-wide Cupertino theme. Built once in `MaterialApp.cupertinoOverrideTheme`.
class AppTheme {
  AppTheme._();

  static const CupertinoThemeData cupertino = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.neonLime,
    primaryContrastingColor: AppColors.textOnAccent,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.backgroundAlt,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.neonLime,
      textStyle: TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Text',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        decoration: TextDecoration.none,
      ),
      navTitleTextStyle: TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Display',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      navLargeTitleTextStyle: TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Display',
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.6,
      ),
      tabLabelTextStyle: TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Text',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: -0.1,
      ),
    ),
  );

  /// Page transition — smooth asymmetric horizontal slide used app-wide.
  static const PageTransitionsTheme pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );
}

/// Page-transitions theme placeholder for non-cupertino routes.
class PageTransitionsTheme {
  final Map<TargetPlatform, PageTransitionsBuilder> builders;
  const PageTransitionsTheme({required this.builders});
}
