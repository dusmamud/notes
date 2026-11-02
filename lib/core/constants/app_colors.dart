import 'package:flutter/material.dart';

/// Exact verified color palette extracted from target app assets & layouts
class AppColors {
  AppColors._();

  // Primary Brand & Accents
  static const Color brandPrimary = Color(0xFFE4AF0A);
  static const Color accentGold = Color(0xFFE4AF0A);
  static const Color brandAmber = Color(0xFFFABB00);
  static const Color accentBlue = Color(0xFF0088FF);
  static const Color tagBlue = Color(0xFF0088FF);
  static const Color accentTeal = Color(0xFF00C8B3);
  static const Color tagTeal = Color(0xFF00C8B3);
  static const Color accentPurple = Color(0xFFCB30E0);
  static const Color tagPurple = Color(0xFFCB30E0);
  static const Color accentRed = Color(0xFFFE2C54);
  static const Color tagCoral = Color(0xFFFE2C54);
  static const Color accentOrange = Color(0xFFFF8C27);
  static const Color tagOrange = Color(0xFFFF8C27);
  static const Color tagForest = Color(0xFF34C759);
  static const Color tagSky = Color(0xFF32ADE6);
  static const Color tagLime = Color(0xFFA2845E);

  // Surface & Card Neutrals
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2C2C2E);
  static const Color lightCardBg = Color(0xFFF2F2F7);
  static const Color darkCardBg = Color(0xFF39393B);
  static const Color lightScaffold = Color(0xFFFFFFFF);
  static const Color darkScaffold = Color(0xFF1C1C1E);
  static const Color oledBlack = Color(0xFF000000);

  // Typography Neutrals
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);

  // Note Card Pastel Color Matrix (Verified REA Ground Truth)
  static const Color pastelYellow = Color(0xFFFFF9C4);
  static const Color pastelMint = Color(0xFFC8E6C9);
  static const Color pastelLavender = Color(0xFFE1BEE7);
  static const Color pastelPeach = Color(0xFFFFE0B2);
  static const Color pastelSky = Color(0xFFBBDEFB);

  static const List<Color> pastelPalette = [
    pastelYellow,
    pastelMint,
    pastelLavender,
    pastelPeach,
    pastelSky,
  ];
}
