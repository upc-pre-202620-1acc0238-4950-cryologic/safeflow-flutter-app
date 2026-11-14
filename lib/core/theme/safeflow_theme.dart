import 'package:flutter/material.dart';

abstract final class SafeFlowColors {
  static const background = Color(0xFFF8FAF9);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF17221B);
  static const textSecondary = Color(0xFF536158);
  static const primary = Color(0xFF15803D);
  static const primaryContainer = Color(0xFFEAF5EE);
  static const outline = Color(0xFFDCE5DF);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFFF5E6);
  static const critical = Color(0xFFB91C1C);
  static const criticalContainer = Color(0xFFFDECEC);
}

ThemeData buildSafeFlowTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SafeFlowColors.primary,
    primary: SafeFlowColors.primary,
    surface: SafeFlowColors.surface,
    error: SafeFlowColors.critical,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SafeFlowColors.background,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: SafeFlowColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      headlineSmall: TextStyle(
        color: SafeFlowColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        color: SafeFlowColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: SafeFlowColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: SafeFlowColors.textPrimary,
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: SafeFlowColors.textPrimary,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: SafeFlowColors.textSecondary,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SafeFlowColors.surface,
      foregroundColor: SafeFlowColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: SafeFlowColors.textPrimary,
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: SafeFlowColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: SafeFlowColors.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SafeFlowColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: Color(0xFF8A958E), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SafeFlowColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SafeFlowColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SafeFlowColors.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: SafeFlowColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dividerColor: SafeFlowColors.outline,
  );
}
