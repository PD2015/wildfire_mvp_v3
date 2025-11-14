import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

/// WildfireA11yTheme: WCAG 2.1 AA compliant Material 3 theme
///
/// Provides light and dark theme configurations with:
/// - ≥4.5:1 contrast for normal text (C3 constitutional gate)
/// - ≥3:1 contrast for UI components (WCAG AA)
/// - ≥44dp touch targets for all interactive elements (C3)
/// - Material 3 ColorScheme with BrandPalette colors
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: WildfireA11yTheme.light,
///   darkTheme: WildfireA11yTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
class WildfireA11yTheme {
  WildfireA11yTheme._(); // Prevent instantiation

  /// Light theme with forest600 primary and offWhite surface
  /// Contrast ratios: forest600+white = 5.1:1, mint400+black = 4.8:1
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: BrandPalette.forest600,
      onPrimary: BrandPalette.onDarkHigh,
      secondary: BrandPalette.mint400,
      onSecondary: BrandPalette.onLightHigh,
      tertiary: BrandPalette.amber500,
      onTertiary: BrandPalette.onLightHigh,
      surface: BrandPalette.offWhite,
      onSurface: BrandPalette.onLightHigh,
      error: Colors.red.shade700,
      onError: BrandPalette.onDarkHigh,
      outline: BrandPalette.neutralGrey200,
      outlineVariant: BrandPalette.neutralGrey100,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,

      // ElevatedButton: ≥44dp height (C3)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // OutlinedButton: ≥44dp height (C3)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          side: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
      ),

      // TextButton: ≥44dp height (C3)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // InputDecoration: outlined style with sufficient padding
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ChipTheme: sufficient padding for ≥44dp height
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        backgroundColor: colorScheme.surface,
        side: BorderSide(color: colorScheme.outline),
      ),

      // SnackBarTheme: accessible colors and spacing
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BrandPalette.forest900,
        contentTextStyle:
            TextStyle(color: BrandPalette.onDarkHigh, fontSize: 16),
        behavior: SnackBarBehavior.floating,
        actionTextColor: BrandPalette.mint400,
      ),

      // AppBarTheme: forest600 background with white text
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // CardTheme: elevated surface with outline
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }

  /// Dark theme with forest400 primary and forest900 surface
  /// Contrast ratios: forest400+white = 7.8:1, surface+onSurface = 14.2:1
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: BrandPalette.forest400,
      onPrimary: BrandPalette.onDarkHigh,
      secondary: BrandPalette.mint400,
      onSecondary: BrandPalette.onLightHigh,
      tertiary: BrandPalette.amber500,
      onTertiary: BrandPalette.onLightHigh,
      surface: BrandPalette.forest900,
      onSurface: BrandPalette.onDarkHigh,
      error: Colors.red.shade400,
      onError: BrandPalette.onLightHigh,
      outline: BrandPalette.mint400, // ≥3:1 on forest900 surface (WCAG AA UI)
      outlineVariant: BrandPalette.forest700,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,

      // ElevatedButton: ≥44dp height (C3)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // OutlinedButton: ≥44dp height (C3)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          side: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
      ),

      // TextButton: ≥44dp height (C3)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // InputDecoration: outlined style with sufficient padding
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ChipTheme: sufficient padding for ≥44dp height
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        backgroundColor: colorScheme.surface,
        side: BorderSide(color: colorScheme.outline),
      ),

      // SnackBarTheme: accessible colors and spacing
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BrandPalette.forest400,
        contentTextStyle:
            TextStyle(color: BrandPalette.onDarkHigh, fontSize: 16),
        behavior: SnackBarBehavior.floating,
        actionTextColor: BrandPalette.mint400,
      ),

      // AppBarTheme: darker surface with high contrast text
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // CardTheme: elevated surface with outline
      cardTheme: CardThemeData(
        color: BrandPalette.forest800,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
