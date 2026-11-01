import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: AppColors.brandPrimary,
        primaryContainer: AppColors.brandAmber,
        secondary: AppColors.accentBlue,
        secondaryContainer: AppColors.accentTeal,
      ),
      fontFamily: AppTypography.fontFamily,
      useMaterial3: true,
      scaffoldBackground: AppColors.lightScaffold,
    );
  }

  static ThemeData dark({bool oled = false}) {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.brandPrimary,
        primaryContainer: AppColors.brandAmber,
        secondary: AppColors.accentBlue,
        secondaryContainer: AppColors.accentTeal,
      ),
      fontFamily: AppTypography.fontFamily,
      useMaterial3: true,
      scaffoldBackground: oled ? AppColors.oledBlack : AppColors.darkScaffold,
    );
  }
}

