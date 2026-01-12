import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

/// A compact, tappable chip displaying location summary.
///
/// Used within RiskBanner and Report screens to show location context
/// without dominating the visual hierarchy. Tapping expands to show
/// full location details via [onTap] callback.
///
/// ## Design (from Figma/Screenshots)
/// - Format: `📍 Location Name · Source ˅`
/// - Single map pin icon (always location_on, doesn't change with source)
/// - Location name first, then dot separator, then source in lighter text
/// - No pill/badge around source - just inline text
/// - Thin, clean appearance
///
/// ## Constitutional Compliance
/// - C3: Touch target ≥44dp, semantic labels for screen readers
/// - C4: Uses BrandPalette for chrome, inherits risk colors from parent
class LocationChip extends StatelessWidget {
  /// Display name for the location (place name or coordinates)
  ///
  /// Examples:
  /// - "Grantown-on-Spey" (geocoded)
  /// - "57.20, -3.83" (coordinates fallback)
  final String locationName;

  /// Source of the location for display text
  ///
  /// Shown as text after dot separator:
  /// - [LocationSource.gps]: "GPS"
  /// - [LocationSource.manual]: "Manual"
  /// - [LocationSource.cached]: "Cached"
  /// - [LocationSource.defaultFallback]: "Default"
  final LocationSource? locationSource;

  /// Background color of parent container for contrast calculation
  final Color parentBackgroundColor;

  /// Callback when chip is tapped to expand location details
  final VoidCallback? onTap;

  /// Whether the associated panel is currently expanded
  final bool isExpanded;

  /// Whether the chip is in a loading state
  final bool isLoading;

  /// Optional coordinates to show as secondary text when no place name
  final String? coordinates;

  const LocationChip({
    super.key,
    required this.locationName,
    this.locationSource,
    required this.parentBackgroundColor,
    this.onTap,
    this.isExpanded = false,
    this.isLoading = false,
    this.coordinates,
  });

  /// Returns source text for display after dot separator
  String? _getSourceText() {
    if (locationSource == null) return null;

    return switch (locationSource!) {
      LocationSource.gps => 'GPS',
      LocationSource.manual => 'Manual',
      LocationSource.cached => 'Cached',
      LocationSource.defaultFallback => 'Default',
    };
  }

  /// Calculates appropriate chip colors based on parent background
  ({Color surface, Color text, Color textMuted, Color icon})
      _getAdaptiveColors() {
    final luminance = parentBackgroundColor.computeLuminance();
    final isDark = luminance < 0.5;

    if (isDark) {
      return (
        surface: Colors.white.withValues(alpha: 0.12),
        text: BrandPalette.onDarkHigh,
        textMuted: BrandPalette.onDarkHigh.withValues(alpha: 0.7),
        icon: BrandPalette.onDarkHigh.withValues(alpha: 0.8),
      );
    } else {
      return (
        surface: Colors.black.withValues(alpha: 0.06),
        text: BrandPalette.onLightHigh,
        textMuted: BrandPalette.onLightMedium,
        icon: BrandPalette.onLightMedium,
      );
    }
  }

  /// Builds semantic label for screen readers
  String _buildSemanticLabel() {
    final sourceLabel = locationSource?.accessibilityLabel ?? 'Location';
    final expandState = isExpanded ? 'expanded' : 'collapsed';
    final actionHint = onTap != null
        ? 'Double tap to ${isExpanded ? 'collapse' : 'expand'} location details'
        : '';

    return '$sourceLabel: $locationName. $expandState. $actionHint';
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getAdaptiveColors();
    final theme = Theme.of(context);
    final sourceText = _getSourceText();

    return Semantics(
      label: _buildSemanticLabel(),
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 36, // Thinner chip per design
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Map pin icon (always the same, doesn't change with source)
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colors.icon),
                    ),
                  )
                else
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colors.icon,
                  ),
                const SizedBox(width: 6),

                // Location name
                Flexible(
                  child: Text(
                    locationName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // Dot separator + Source text (e.g., " · GPS")
                if (sourceText != null && !isLoading) ...[
                  Text(
                    ' · ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  Text(
                    sourceText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],

                // Expand/collapse chevron
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: colors.icon,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
