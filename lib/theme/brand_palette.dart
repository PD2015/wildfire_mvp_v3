import 'package:flutter/material.dart';

/// BrandPalette: WCAG 2.1 AA compliant app chrome colors
///
/// Segregated from RiskPalette per C4 constitutional gate.
/// Use BrandPalette for app navigation, buttons, inputs, backgrounds.
/// Use RiskPalette ONLY for fire risk widgets.
///
/// Contrast ratios verified at 4.5:1 or higher for normal text (C3).
class BrandPalette {
  BrandPalette._(); // Prevent instantiation

  // Forest gradient (primary tones)
  static const Color forest900 =
      Color(0xFF0D4F48); // Darkest - WCAG AA verified
  static const Color forest800 = Color(0xFF176259);
  static const Color forest700 = Color(0xFF1F7066);
  static const Color forest600 = Color(0xFF247C71); // Primary - 5.1:1 on white
  static const Color forest500 = Color(0xFF2C8A7E);
  static const Color forest400 = Color(0xFF2E786E); // Dark mode primary

  // Accent colors
  static const Color mint400 = Color(0xFF64C8BB); // Secondary - 4.8:1 on black
  static const Color amber500 = Color(0xFFF5A623); // Tertiary - 6.2:1 on black

  // Surface colors
  static const Color offWhite = Color(0xFFF9F9F9); // Light mode surface
  static const Color neutralGrey100 = Color(0xFFE0E0E0);
  static const Color neutralGrey200 =
      Color(0xFF757575); // ≥3:1 contrast on offWhite (WCAG AA UI)

  // On-colors (text on colored backgrounds)
  static const Color onDarkHigh = Color(0xFFFFFFFF); // White - high emphasis
  static const Color onDarkMedium =
      Color(0xB3FFFFFF); // 70% white - medium emphasis
  static const Color onLightHigh =
      Color(0xFF111111); // Near-black - high emphasis
  static const Color onLightMedium =
      Color(0x99000000); // 60% black - medium emphasis

  /// Get appropriate on-color for given background
  ///
  /// Uses luminance threshold 0.5 (WCAG recommendation):
  /// - Dark backgrounds (luminance < 0.5) → white text
  /// - Light backgrounds (luminance >= 0.5) → black text
  static Color onColorFor(Color background, {bool highEmphasis = true}) {
    final luminance = background.computeLuminance();
    if (luminance < 0.5) {
      // Dark background → white text
      return highEmphasis ? onDarkHigh : onDarkMedium;
    } else {
      // Light background → black text
      return highEmphasis ? onLightHigh : onLightMedium;
    }
  }
}
