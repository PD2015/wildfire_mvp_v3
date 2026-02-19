import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

/// Adaptive color set for widgets that overlay dynamic background colors.
///
/// Provides semantically named colors for surface, text, icons, and dividers
/// that maintain sufficient contrast on both light and dark backgrounds.
///
/// Used by [LocationChip], [ExpandableLocationPanel], and any future widget
/// that needs to adapt its chrome to a parent's background color.
typedef AdaptiveColors = ({
  Color surface,
  Color text,
  Color textMuted,
  Color icon,
  Color divider,
});

/// Calculates accessible color sets based on parent background luminance.
///
/// Two modes:
/// - **Risk banner mode** (`embeddedInRiskBanner: true`): Uses explicit
///   white-on-translucent styling for consistent readability on all risk
///   banner colors (especially yellow/orange MODERATE).
/// - **Default mode**: Uses BrandPalette on-color tokens with luminance
///   threshold 0.5 (WCAG recommendation) to select dark-on-light or
///   light-on-dark schemes.
///
/// Constitutional compliance:
/// - C3: Ensures sufficient contrast for text readability
/// - C4: Uses BrandPalette tokens exclusively (no ad-hoc hex colors)
class AdaptiveColorCalculator {
  AdaptiveColorCalculator._(); // Prevent instantiation

  /// Returns an [AdaptiveColors] record for the given background context.
  ///
  /// When [embeddedInRiskBanner] is true, returns white-on-translucent-black
  /// colors that provide consistent contrast on all risk banner backgrounds.
  ///
  /// Otherwise, evaluates [parentBackgroundColor] luminance to select either
  /// a dark-on-light or light-on-dark color scheme using BrandPalette tokens.
  static AdaptiveColors getColors({
    required Color parentBackgroundColor,
    bool embeddedInRiskBanner = false,
  }) {
    // When embedded in RiskBanner, use explicit white-on-dark styling
    // for consistent contrast on all risk colors (esp. MODERATE yellow)
    if (embeddedInRiskBanner) {
      return (
        surface: Colors.black.withValues(alpha: 0.15),
        text: Colors.white.withValues(alpha: 0.95),
        textMuted: Colors.white.withValues(alpha: 0.75),
        icon: Colors.white.withValues(alpha: 0.85),
        divider: Colors.white.withValues(alpha: 0.25),
      );
    }

    // Default: luminance-based adaptive colors using BrandPalette tokens
    final luminance = parentBackgroundColor.computeLuminance();
    final isDark = luminance < 0.5;

    if (isDark) {
      return (
        surface: Colors.white.withValues(alpha: 0.12),
        text: BrandPalette.onDarkHigh,
        textMuted: BrandPalette.onDarkHigh.withValues(alpha: 0.7),
        icon: BrandPalette.onDarkHigh.withValues(alpha: 0.8),
        divider: Colors.white.withValues(alpha: 0.2),
      );
    } else {
      return (
        surface: Colors.black.withValues(alpha: 0.06),
        text: BrandPalette.onLightHigh,
        textMuted: BrandPalette.onLightMedium,
        icon: BrandPalette.onLightMedium,
        divider: Colors.black.withValues(alpha: 0.1),
      );
    }
  }
}
