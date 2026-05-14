import 'package:flutter/material.dart';

class AppTheme {
  // ── Primary palette ──────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0E1A); // deep navy
  static const Color surface = Color(0xFF111827); // card surface
  static const Color surfaceElevated = Color(0xFF1A2236); // elevated card
  static const Color accent = Color(0xFF00D4AA); // cyber teal
  static const Color accentDim = Color(0xFF00A880);
  static const Color accentGlow = Color(0x3000D4AA);

  static const Color weakestColor = Color(0xFFD50000);
  static const Color weakColor = Color(0xFFFF4757);
  static const Color weakGlow = Color(0x40FF4757);
  static const Color weakToMediumColor = Color(0xFFFF7043);
  static const Color mediumColor = Color(0xFFFFB300);
  static const Color mediumGlow = Color(0x40FFB300);
  static const Color mediumToStrongColor = Color(0xFF8BC34A);
  static const Color strongColor = Color(0xFF00D4AA);
  static const Color strongGlow = Color(0x4000D4AA);
  static const Color strongestColor = Color(0xFF00E5FF);

  static const Color riskLow = Color(0xFF00D4AA);
  static const Color riskMedium = Color(0xFFFFB300);
  static const Color riskHigh = Color(0xFFFF7043);
  static const Color riskCritical = Color(0xFFFF4757);

  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textHint = Color(0xFF4A5568);

  static const Color border = Color(0xFF1E2D42);
  static const Color borderBright = Color(0xFF2A3F5A);

  // ── Typography ───────────────────────────────────────────────────────────
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'monospace',
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -1,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      letterSpacing: 0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 15, color: textSecondary, height: 1.6),
    bodyMedium: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
    labelLarge: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: textSecondary,
      letterSpacing: 1.2,
    ),
  );

  // ── Theme data ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accentDim,
      surface: surface,
      error: weakColor,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),
    iconTheme: const IconThemeData(color: textSecondary),
  );
}