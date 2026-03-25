// ============================================================================
// NIGHT VISION (Red Light Mode) - Preserve night vision
// ============================================================================

import 'package:flutter/material.dart';

/// Night Vision theme (red light mode).
class NightVisionTheme {
  // ========================================================================
  // COLOR PALETTE
  // ========================================================================

  static const Color darkMaroon = Color(0xFF1a0000);
  static const Color brightRed = Color(0xFFFF6666);
  static const Color accentRed = Color(0xFFCC3333);
  static const Color darkBackground = Color(0xFF0d0000);
  static const Color redText = Color(0xFFDD5555);
  static const Color disabledRed = Color(0xFF662222);
  static const Color borderRed = Color(0xFF443333);

  // ========================================================================
  // THEME BUILDERS
  // ========================================================================

  /// Get full Night Vision ThemeData.
  static ThemeData getNightVisionTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkMaroon,

      colorScheme: ColorScheme.dark(
        primary: brightRed,
        onPrimary: darkMaroon,
        primaryContainer: accentRed,
        onPrimaryContainer: const Color(0xFFFFCCCC),
        secondary: accentRed,
        onSecondary: darkBackground,
        tertiary: const Color(0xFF994444),
        surface: const Color(0xFF2a1a1a),
        onSurface: redText,
        error: const Color(0xFFFF6666),
        onError: darkMaroon,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkMaroon,
        foregroundColor: brightRed,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: brightRed,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: brightRed),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: brightRed, fontSize: 57, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: brightRed, fontSize: 45, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(color: accentRed, fontSize: 36, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: brightRed, fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: redText, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: redText, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: Color(0xFFCC7777), fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: Color(0xFF994444), fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: brightRed, fontSize: 14, fontWeight: FontWeight.w500),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2a1a1a),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderRed)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderRed, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: brightRed, width: 2)),
        hintStyle: const TextStyle(color: disabledRed, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightRed,
          foregroundColor: darkMaroon,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brightRed;
          return disabledRed;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentRed.withValues(alpha: 0.5);
          return borderRed.withValues(alpha: 0.3);
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: borderRed)),
        titleTextStyle: const TextStyle(color: brightRed, fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }
}