import 'package:flutter/material.dart';

/// Exact verified color palette extracted from target app assets & layouts
class AppColors {
  AppColors._();

  // Primary Brand & Accents
  static const Color brandPrimary = Color(0xFFE4AF0A);
  static const Color brandAmber = Color(0xFFFABB00);
  static const Color accentBlue = Color(0xFF0088FF);
  static const Color accentTeal = Color(0xFF00C8B3);
  static const Color accentPurple = Color(0xFFCB30E0);
  static const Color accentRed = Color(0xFFFE2C54);
  static const Color accentOrange = Color(0xFFFF8C27);

  // Surface & Card Neutrals
  static const Color lightCardBg = Color(0xFFF2F2F7);
  static const Color darkCardBg = Color(0xFF39393B);
  static const Color lightScaffold = Color(0xFFFFFFFF);
  static const Color darkScaffold = Color(0xFF1C1C1E);
  static const Color oledBlack = Color(0xFF000000);

  // Note Card Pastel Color Matrix
  static const List<Color> pastelPalette = [
    Color(0xFFFFF275), // Yellow
    Color(0xFFFFB5C2), // Pink
    Color(0xFFB5EAD7), // Mint
    Color(0xFFC7CEEA), // Lavender
    Color(0xFFFFDAC1), // Peach
    Color(0xFFE2F0CB), // Lime
  ];
}

