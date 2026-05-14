import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ───────────────────────────────────────────────
  static const Color bg           = Color(0xFF080C14);
  static const Color surface      = Color(0xFF111827);
  static const Color surfaceHigh  = Color(0xFF1C2536);
  static const Color primary      = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color accent       = Color(0xFF00D4B4);
  static const Color accentWarm   = Color(0xFFFF6B6B);
  static const Color textPrimary  = Color(0xFFEEF2FF);
  static const Color textSecondary= Color(0xFF8899B0);
  static const Color divider      = Color(0xFF1E293B);

  // Stress level colours
  static const Color stressLow    = Color(0xFF00D4B4);
  static const Color stressMed    = Color(0xFFFFB347);
  static const Color stressHigh   = Color(0xFFFF6B6B);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGrad = LinearGradient(
    colors: [Color(0xFF00D4B4), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bgGrad = LinearGradient(
    colors: [Color(0xFF080C14), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Theme ─────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      background: bg,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
    ),
    textTheme: _textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: divider, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: divider),
  );

  static TextTheme get _textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 40, fontWeight: FontWeight.w700,
      color: textPrimary, fontFamily: 'Inter', letterSpacing: -1,
    ),
    displayMedium: TextStyle(
      fontSize: 32, fontWeight: FontWeight.w700,
      color: textPrimary, fontFamily: 'Inter', letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: 22, fontWeight: FontWeight.w700,
      color: textPrimary, fontFamily: 'Inter',
    ),
    titleMedium: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: textPrimary, fontFamily: 'Inter',
    ),
    titleSmall: TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600,
      color: textPrimary, fontFamily: 'Inter',
    ),
    bodyLarge: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400,
      color: textPrimary, fontFamily: 'Inter',
    ),
    bodyMedium: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400,
      color: textSecondary, fontFamily: 'Inter',
    ),
    bodySmall: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w400,
      color: textSecondary, fontFamily: 'Inter',
    ),
    labelLarge: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600,
      color: textPrimary, fontFamily: 'Inter',
    ),
  );
}
