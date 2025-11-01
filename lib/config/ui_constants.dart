import 'package:flutter/material.dart';

/// UI constants for Fire Risk screen
///
/// Centralized constants for all Fire Risk UI strings, icons, and routes
/// to ensure consistency across the application.
///
/// Constitutional compliance:
/// - C1: Clean code with centralized constants
/// - C2: No secrets or PII in constants
/// - C4: Official branding and terminology
class UIConstants {
  // Private constructor to prevent instantiation
  UIConstants._();

  /// Navigation label for bottom navigation bar
  static const String fireRiskTitle = "Fire Risk";

  /// AppBar title for fire risk screen
  static const String fireRiskAppBarTitle = "Wildfire Risk";

  /// Primary icon for fire risk navigation (Material Design warning symbol)
  static const IconData fireRiskIcon = Icons.warning_amber;

  /// Fallback icon if primary icon has rendering issues
  static const IconData fireRiskIconFallback = Icons.report_outlined;

  /// Primary route path
  static const String fireRiskRoute = "/";

  /// Semantic alias route for clarity
  static const String fireRiskRouteAlias = "/fire-risk";

  /// Semantic label for screen readers (navigation)
  static const String fireRiskNavSemantic = "Fire risk information tab";

  /// Semantic description template for RiskBanner
  /// Format: "Current wildfire risk is {LEVEL}, updated {RELATIVE_TIME}. Source: {SOURCE}."
  /// Replace placeholders at runtime with actual values
  static String buildRiskSemanticLabel({
    required String level,
    required String relativeTime,
    required String source,
  }) {
    return "Current wildfire risk is $level, updated $relativeTime. Source: $source.";
  }
}
