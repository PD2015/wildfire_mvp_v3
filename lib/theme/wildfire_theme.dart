// DEPRECATED: Use WildfireA11yTheme from wildfire_a11y_theme.dart instead
// This file preserved for backwards compatibility during migration
// See specs/017-a11y-theme-overhaul/ for migration details
//
// Migration path:
// - Replace WildfireTheme.light with WildfireA11yTheme.light
// - Replace WildfireTheme.dark with WildfireA11yTheme.dark
// - Update any direct RiskPalette references to use BrandPalette or ColorScheme

import 'package:flutter/material.dart';
import '../theme/risk_palette.dart';

/// Wildfire theme configuration using official Scottish wildfire risk colors
///
/// This theme configuration ensures consistency across the app and supports
/// both light and dark modes while maintaining the official Scottish wildfire
/// risk color palette for critical UI elements.
///
/// Constitutional compliance:
/// - C4: Uses only official Scottish wildfire risk colors from RiskPalette
/// - C3: Provides appropriate contrast ratios for accessibility
class WildfireTheme {
  /// Light theme configuration
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Primary color scheme based on brand forest green
      colorScheme: ColorScheme.fromSeed(
        seedColor: RiskPalette.brandForest,
        brightness: Brightness.light,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: RiskPalette.brandForest,
        foregroundColor: RiskPalette.white,
        elevation: 2,
        centerTitle: true,
      ),

      // Card theme for consistent elevation and colors
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        color: RiskPalette.white,
      ),

      // Button themes with accessibility compliance
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RiskPalette.brandForest,
          foregroundColor: RiskPalette.white,
          minimumSize: const Size(88, 44), // 44dp minimum touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RiskPalette.brandForest,
          minimumSize: const Size(88, 44), // 44dp minimum touch target
          side: const BorderSide(color: RiskPalette.brandForest),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      // Text theme with appropriate contrast
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: RiskPalette.darkGray,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: RiskPalette.darkGray,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: RiskPalette.darkGray),
        bodyMedium: TextStyle(color: RiskPalette.midGray),
        labelLarge: TextStyle(
          color: RiskPalette.white,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: RiskPalette.midGray),

      // Scaffold background
      scaffoldBackgroundColor: RiskPalette.white,

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: RiskPalette.lightGray,
        thickness: 1,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Primary color scheme for dark mode
      colorScheme: ColorScheme.fromSeed(
        seedColor: RiskPalette.brandForest,
        brightness: Brightness.dark,
      ),

      // App bar theme for dark mode
      appBarTheme: const AppBarTheme(
        backgroundColor: RiskPalette.darkGray,
        foregroundColor: RiskPalette.white,
        elevation: 2,
        centerTitle: true,
      ),

      // Card theme for dark mode
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        color: RiskPalette.darkGray,
      ),

      // Button themes for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RiskPalette.brandForest,
          foregroundColor: RiskPalette.white,
          minimumSize: const Size(88, 44), // 44dp minimum touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RiskPalette.white,
          minimumSize: const Size(88, 44), // 44dp minimum touch target
          side: const BorderSide(color: RiskPalette.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      // Text theme for dark mode
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: RiskPalette.white,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: RiskPalette.white,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: RiskPalette.white),
        bodyMedium: TextStyle(color: RiskPalette.lightGray),
        labelLarge: TextStyle(
          color: RiskPalette.white,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon theme for dark mode
      iconTheme: const IconThemeData(color: RiskPalette.lightGray),

      // Scaffold background for dark mode
      scaffoldBackgroundColor: RiskPalette.black,

      // Divider theme for dark mode
      dividerTheme: const DividerThemeData(
        color: RiskPalette.midGray,
        thickness: 1,
      ),
    );
  }
}
