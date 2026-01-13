import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/location_mini_map_preview.dart';

/// Full-featured location details panel for expanded view.
///
/// Displays comprehensive location information including:
/// - Coordinates (lat/lng)
/// - what3words address with copy functionality
/// - Static map preview
/// - Action buttons (Change Location, Use GPS)
///
/// Designed to appear below [LocationChip] when expanded. Uses
/// adaptive colors to maintain readability on risk-colored backgrounds.
///
/// ## Design Decisions
/// - No Card wrapper: integrates into parent's visual container
/// - Adaptive colors: calculates contrast from parent background
/// - Compact layout: prioritizes information density over whitespace
/// - Maintains all functionality from legacy LocationCard
///
/// ## Constitutional Compliance
/// - C3: All touch targets ≥48dp, semantic labels for accessibility
/// - C2: Coordinates pre-redacted in logs
/// - C4: Uses BrandPalette tokens, inherits risk colors from parent
class ExpandableLocationPanel extends StatelessWidget {
  /// Formatted location from reverse geocoding (e.g., "Near Aviemore, Highland")
  final String? formattedLocation;

  /// Whether geocoding is currently loading
  final bool isGeocodingLoading;

  /// Coordinates label (e.g., "57.20, -3.83")
  final String? coordinatesLabel;

  /// what3words address (e.g., "///daring.lion.race")
  final String? what3words;

  /// Whether what3words is currently loading
  final bool isWhat3wordsLoading;

  /// Static map URL for preview
  final String? staticMapUrl;

  /// Whether map preview is loading
  final bool isMapLoading;

  /// Location source for icon and badge display
  final LocationSource? locationSource;

  /// Background color of parent container for contrast calculation
  final Color parentBackgroundColor;

  /// Callback when "Change Location" is tapped
  final VoidCallback? onChangeLocation;

  /// Callback when "Use GPS" is tapped (returns to GPS from manual)
  final VoidCallback? onUseGps;

  /// Callback when what3words copy button is tapped
  final VoidCallback? onCopyWhat3words;

  /// Callback when coordinates copy button is tapped
  final VoidCallback? onCopyCoordinates;

  /// Whether to show the map preview
  final bool showMapPreview;

  /// Whether to show action buttons
  final bool showActions;

  /// Whether this panel is embedded in a RiskBanner
  ///
  /// When true, uses explicit white text levels (90%/75%/70%) for
  /// consistent readability on risk-colored backgrounds, instead of
  /// luminance-based adaptive colors.
  final bool embeddedInRiskBanner;

  /// Callback when the collapse button is tapped
  final VoidCallback? onClose;

  const ExpandableLocationPanel({
    super.key,
    this.formattedLocation,
    this.isGeocodingLoading = false,
    this.coordinatesLabel,
    this.what3words,
    this.isWhat3wordsLoading = false,
    this.staticMapUrl,
    this.isMapLoading = false,
    this.locationSource,
    required this.parentBackgroundColor,
    this.onChangeLocation,
    this.onUseGps,
    this.onCopyWhat3words,
    this.onCopyCoordinates,
    this.showMapPreview = true,
    this.showActions = true,
    this.embeddedInRiskBanner = false,
    this.onClose,
  });

  /// Calculates adaptive colors based on parent background luminance
  ///
  /// When [embeddedInRiskBanner] is true, uses explicit white text levels
  /// for consistent readability on all risk colors (especially yellow/orange).
  ({Color surface, Color text, Color textMuted, Color icon, Color divider})
      _getAdaptiveColors() {
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

    // Default: luminance-based adaptive colors for general use
    final luminance = parentBackgroundColor.computeLuminance();
    final isDark = luminance < 0.5;

    if (isDark) {
      return (
        surface: Colors.white.withValues(alpha: 0.1),
        text: Colors.white,
        textMuted: Colors.white.withValues(alpha: 0.7),
        icon: Colors.white.withValues(alpha: 0.8),
        divider: Colors.white.withValues(alpha: 0.2),
      );
    } else {
      return (
        surface: Colors.black.withValues(alpha: 0.05),
        text: const Color(0xFF111111),
        textMuted: const Color(0xFF666666),
        icon: const Color(0xFF333333),
        divider: Colors.black.withValues(alpha: 0.1),
      );
    }
  }

  /// Validates that coordinatesLabel has valid format
  bool get _hasValidCoordinates {
    if (coordinatesLabel == null || coordinatesLabel!.isEmpty) {
      return false;
    }
    final parts = coordinatesLabel!.split(',');
    if (parts.length != 2) return false;
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    return lat != null && lon != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getAdaptiveColors();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Location used" title
          _buildHeader(theme, colors),
          const SizedBox(height: 12),

          // Coordinates row
          if (_hasValidCoordinates || isGeocodingLoading) ...[
            _buildCoordinatesRow(theme, colors),
            const SizedBox(height: 8),
          ],

          // what3words row
          if (what3words != null || isWhat3wordsLoading) ...[
            _buildWhat3wordsRow(theme, colors),
            const SizedBox(height: 8),
          ],

          // Map preview
          if (showMapPreview) ...[
            _buildMapPreview(colors),
            const SizedBox(height: 12),
          ],

          // Action buttons
          if (showActions) _buildActionButtons(theme, colors),

          // Collapse button (only when onClose is provided)
          if (onClose != null) ...[
            const SizedBox(height: 12),
            _buildCollapseButton(colors),
          ],
        ],
      ),
    );
  }

  /// Builds the collapse button with down chevron and dark circular background
  Widget _buildCollapseButton(dynamic colors) {
    return Center(
      child: Semantics(
        label: 'Collapse location details',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header with navigation icon and "Location used" title
  Widget _buildHeader(ThemeData theme, dynamic colors) {
    // Determine source text
    final sourceText = switch (locationSource) {
      LocationSource.gps => 'Current (GPS)',
      LocationSource.manual => 'Manual',
      LocationSource.cached => 'Cached',
      LocationSource.defaultFallback => 'Default',
      null => '',
    };

    return Row(
      children: [
        Icon(
          Icons.navigation_outlined,
          size: 20,
          color: colors.icon,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location used',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (formattedLocation != null || sourceText.isNotEmpty)
                Text(
                  [
                    if (formattedLocation != null) formattedLocation!,
                    if (sourceText.isNotEmpty) sourceText,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the coordinates row with copy functionality
  Widget _buildCoordinatesRow(ThemeData theme, dynamic colors) {
    return Semantics(
      label: 'Coordinates: ${coordinatesLabel ?? "Loading"}',
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 16,
            color: colors.icon,
          ),
          const SizedBox(width: 8),
          Text(
            'Lat/Lng: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              coordinatesLabel ?? '...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (coordinatesLabel != null && onCopyCoordinates != null)
            _buildCopyButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: coordinatesLabel!));
                onCopyCoordinates!();
              },
              tooltip: 'Copy coordinates',
              colors: colors,
            ),
        ],
      ),
    );
  }

  /// Builds the what3words row with copy functionality
  Widget _buildWhat3wordsRow(ThemeData theme, dynamic colors) {
    return Semantics(
      label: what3words != null
          ? 'what3words address: $what3words'
          : 'Loading what3words address',
      child: Row(
        children: [
          Icon(
            Icons.grid_3x3,
            size: 16,
            color: colors.icon,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isWhat3wordsLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(colors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading what3words...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  )
                : Text(
                    what3words ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          if (what3words != null && onCopyWhat3words != null)
            _buildCopyButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: what3words!));
                onCopyWhat3words!();
              },
              tooltip: 'Copy what3words',
              colors: colors,
            ),
        ],
      ),
    );
  }

  /// Builds a compact copy button
  Widget _buildCopyButton({
    required VoidCallback onPressed,
    required String tooltip,
    required dynamic colors,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.copy,
              size: 16,
              color: colors.icon,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the static map preview
  Widget _buildMapPreview(dynamic colors) {
    final hasMap = staticMapUrl != null;
    final hasLocation = _hasValidCoordinates;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(
            color: colors.divider,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: hasMap
            ? LocationMiniMapPreview(
                staticMapUrl: staticMapUrl,
                isLoading: false,
              )
            : isMapLoading || hasLocation
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colors.textMuted),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 32,
                      color: colors.textMuted,
                    ),
                  ),
      ),
    );
  }

  /// Builds action buttons (Change Location / Use GPS)
  Widget _buildActionButtons(ThemeData theme, dynamic colors) {
    final isManual = locationSource == LocationSource.manual;
    final hasGpsCallback = onUseGps != null;

    // Manual location with GPS callback: show both buttons
    if (isManual && hasGpsCallback) {
      return Row(
        children: [
          // Secondary: Change location
          Expanded(
            child: _buildActionButton(
              label: 'Change',
              icon: Icons.edit_location_alt,
              onPressed: onChangeLocation,
              isPrimary: false,
              colors: colors,
            ),
          ),
          const SizedBox(width: 8),
          // Primary: Use GPS
          Expanded(
            child: _buildActionButton(
              label: 'Use GPS',
              icon: Icons.gps_fixed,
              onPressed: onUseGps,
              isPrimary: true,
              colors: colors,
            ),
          ),
        ],
      );
    }

    // Single Change Location button
    return _buildActionButton(
      label: 'Change Location',
      icon: Icons.edit_location_alt,
      onPressed: onChangeLocation,
      isPrimary: false,
      colors: colors,
      fullWidth: true,
    );
  }

  /// Builds an individual action button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required dynamic colors,
    bool fullWidth = false,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 44, // C3: Accessibility minimum
            ),
            width: fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isPrimary
                  ? colors.text.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(
                color: colors.text.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: colors.text,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
