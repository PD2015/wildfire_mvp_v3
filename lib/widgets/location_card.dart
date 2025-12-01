import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/location_mini_map_preview.dart';

/// Enhanced location card with what3words, geocoding, and static map preview
///
/// Displays location information with progressive enhancement:
/// - Basic: coordinates + subtitle (backward compatible)
/// - Enhanced: what3words address with copy button
/// - Enhanced: formattedLocation (reverse geocoded place name)
/// - Enhanced: static map preview
/// - Enhanced: "Use GPS" button when manual location is active
///
/// Constitutional compliance:
/// - C3: All touch targets ≥48dp
/// - C2: Coordinates are pre-redacted, what3words displayed but not logged
class LocationCard extends StatelessWidget {
  // Basic properties (backward compatible)
  final String? coordinatesLabel; // e.g. "57.20, -3.83"
  final String subtitle; // e.g. "Current location (GPS)"
  final bool isLoading;
  final VoidCallback? onChangeLocation;
  final LocationSource? locationSource; // Optional source for icon display

  // Enhanced properties (new in T043)
  /// what3words address (e.g., "///daring.lion.race")
  final String? what3words;

  /// Whether what3words is currently loading
  final bool isWhat3wordsLoading;

  /// Formatted location from reverse geocoding (e.g., "Near Aviemore, Highland")
  final String? formattedLocation;

  /// Whether geocoding is currently loading
  final bool isGeocodingLoading;

  /// Static map URL for preview
  final String? staticMapUrl;

  /// Callback when what3words copy button is tapped
  final VoidCallback? onCopyWhat3words;

  /// Callback when "Use GPS" button is tapped (returns to GPS location)
  /// When provided with manual location, shows "Use GPS Location" button
  /// When null or non-manual location, shows "Change Location" button using onChangeLocation
  final VoidCallback? onUseGps;

  const LocationCard({
    super.key,
    required this.coordinatesLabel,
    required this.subtitle,
    this.isLoading = false,
    this.onChangeLocation,
    this.locationSource,
    // Enhanced properties
    this.what3words,
    this.isWhat3wordsLoading = false,
    this.formattedLocation,
    this.isGeocodingLoading = false,
    this.staticMapUrl,
    this.onCopyWhat3words,
    this.onUseGps,
  });

  /// Returns appropriate icon based on location source for trust building
  ///
  /// Icons help users understand where their location data comes from:
  /// - GPS: gps_fixed (live, accurate)
  /// - Manual: location_pin (user-set, verified)
  /// - Cached: cached (moderate confidence)
  /// - Default: public (low confidence, fallback)
  IconData _getLocationSourceIcon() {
    if (locationSource == null) {
      return Icons.my_location; // Default fallback
    }

    return switch (locationSource!) {
      LocationSource.gps => Icons.gps_fixed,
      LocationSource.manual => Icons.location_pin,
      LocationSource.cached => Icons.cached,
      LocationSource.defaultFallback => Icons.public,
    };
  }

  /// Validates that coordinatesLabel has valid format and parseable values
  ///
  /// Returns true if:
  /// - coordinatesLabel is not null and not empty
  /// - Format is "XX.XX, YY.YY" (comma-separated)
  /// - Both parts parse to valid doubles
  ///
  /// This prevents display of malformed coordinates from corrupted cache
  /// or invalid manual entry.
  bool get _hasValidLocation {
    if (coordinatesLabel == null || coordinatesLabel!.isEmpty) {
      return false;
    }

    // Validate format: "XX.XX, YY.YY"
    final parts = coordinatesLabel!.split(',');
    if (parts.length != 2) {
      return false;
    }

    // Validate both parts parse to doubles
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());

    return lat != null && lon != null;
  }

  /// Whether to show the enhanced layout with map preview
  bool get _hasEnhancedFeatures =>
      staticMapUrl != null || what3words != null || formattedLocation != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasLocation = _hasValidLocation;

    return Semantics(
      container: true,
      label: hasLocation
          ? 'Current location: $coordinatesLabel'
          : 'Location not set',
      child: Card(
        color: scheme.surfaceContainerHigh,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon, location info, and change button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getLocationSourceIcon(),
                      color: scheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Location text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with "Location" title
                        Text(
                          'Location',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Show formatted location if available, else coordinates
                        if (formattedLocation != null) ...[
                          Text(
                            formattedLocation!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _buildCoordinatesRow(context, scheme, hasLocation),
                        ] else if (isGeocodingLoading) ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Loading place name...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          _buildCoordinatesRow(context, scheme, hasLocation),
                        ] else ...[
                          // No formatted location - show coordinates as main display
                          _buildCoordinatesRow(context, scheme, hasLocation,
                              isMainDisplay: true),
                        ],
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (isLoading) ...[
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Source badge in top-right (replaces Change button)
                  if (locationSource != null)
                    _buildSourceBadge(context, scheme),
                ],
              ),

              // what3words row (if available or loading)
              if (what3words != null || isWhat3wordsLoading) ...[
                const SizedBox(height: 12),
                _buildWhat3wordsRow(context, theme, scheme),
              ],

              // Static map preview (if available) - view only, no tap action
              if (staticMapUrl != null || _hasEnhancedFeatures) ...[
                const SizedBox(height: 12),
                LocationMiniMapPreview(
                  staticMapUrl: staticMapUrl,
                  isLoading: staticMapUrl == null && hasLocation,
                  // No onTap - action moved to dedicated button below
                ),
              ],

              // Action button - toggles between "Change Location" and "Use GPS"
              // based on location source
              const SizedBox(height: 12),
              _buildActionButton(context, theme, scheme),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the action button that toggles based on location source
  ///
  /// - Manual location → "Use GPS Location" (returns to GPS)
  /// - GPS/Cached/Default → "Change Location" (opens picker)
  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final isManual = locationSource == LocationSource.manual;

    // Determine button configuration based on location source
    final String label;
    final IconData icon;
    final String semanticsLabel;
    final VoidCallback? onPressed;

    if (isManual && onUseGps != null) {
      // Manual location: offer to return to GPS
      label = 'Use GPS Location';
      icon = Icons.gps_fixed;
      semanticsLabel = 'Return to GPS location';
      onPressed = onUseGps;
    } else {
      // GPS/Cached/Default: offer to change location
      label = 'Change Location';
      icon = Icons.edit_location_alt;
      semanticsLabel = 'Change your location';
      onPressed = onChangeLocation;
    }

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 18,
            color: onPressed != null ? scheme.primary : scheme.onSurfaceVariant,
          ),
          label: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color:
                  onPressed != null ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48), // C3: ≥48dp touch target
            side: BorderSide(
              color: onPressed != null ? scheme.outline : scheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the what3words row with address and copy button
  Widget _buildWhat3wordsRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        // what3words icon
        Icon(
          Icons.grid_3x3,
          size: 16,
          color: scheme.primary,
        ),
        const SizedBox(width: 8),

        // what3words address or loading state
        Expanded(
          child: isWhat3wordsLoading
              ? Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading what3words...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Text(
                  what3words ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),

        // Copy button (only when we have a what3words address)
        if (what3words != null && onCopyWhat3words != null)
          Semantics(
            label: 'Copy what3words address to clipboard',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.copy,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              onPressed: () {
                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: what3words!));
                // Call the callback for snackbar handling
                onCopyWhat3words!();
              },
              tooltip: 'Copy what3words',
            ),
          ),
      ],
    );
  }

  /// Builds the coordinates row with "Lat/Lng:" label
  Widget _buildCoordinatesRow(
    BuildContext context,
    ColorScheme scheme,
    bool hasLocation, {
    bool isMainDisplay = false,
  }) {
    final theme = Theme.of(context);

    if (!hasLocation) {
      return Text(
        'Location not set',
        style: isMainDisplay
            ? theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              )
            : theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
      );
    }

    return Row(
      children: [
        Text(
          'Lat/Lng: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          coordinatesLabel!,
          style: isMainDisplay
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                )
              : theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
        ),
      ],
    );
  }

  /// Builds the location source badge (GPS, Manual, etc.)
  /// Uses Material 3 Chip with tertiary colors for consistency with MapSourceChip
  Widget _buildSourceBadge(BuildContext context, ColorScheme scheme) {
    final label = switch (locationSource!) {
      LocationSource.gps => 'GPS',
      LocationSource.manual => 'MANUAL',
      LocationSource.cached => 'CACHED',
      LocationSource.defaultFallback => 'DEFAULT',
    };

    final icon = switch (locationSource!) {
      LocationSource.gps => Icons.gps_fixed,
      LocationSource.manual => Icons.edit_location_alt,
      LocationSource.cached => Icons.cached,
      LocationSource.defaultFallback => Icons.public,
    };

    // Use Material 3 tertiary color scheme for consistent chip styling
    // Same pattern as MapSourceChip DEMO DATA badge
    return Semantics(
      label: 'Location source: $label',
      child: Chip(
        avatar: Icon(
          icon,
          size: 18,
          color: scheme.onTertiaryContainer,
        ),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onTertiaryContainer,
                letterSpacing: 1.0,
              ),
        ),
        backgroundColor: scheme.tertiaryContainer,
        side: BorderSide(
          color: scheme.tertiary,
          width: 1.5,
        ),
        elevation: 4,
        shadowColor: scheme.shadow.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
