import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/location_display_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';
import 'package:wildfire_mvp_v3/widgets/location_mini_map_preview.dart';

/// Fire-report-specific location card with emergency context
///
/// Wraps location display with fire-reporting-specific features:
/// - Header: "Location to give when you call"
/// - Subtitle: "Optional — helps you tell 999 where the fire is."
/// - 5dp precision coordinates (vs 2dp on Home screen)
/// - Helper text: "Exact coordinates recommended for fire service"
/// - Copy button for coordinates + what3words
///
/// Uses LocationDisplayState from shared LocationStateManager for
/// consistent state handling across screens.
///
/// Constitutional compliance:
/// - C3: All touch targets ≥48dp
/// - C3: Semantic labels on all interactive elements
/// - C4: Clear that this doesn't contact emergency services
class ReportFireLocationCard extends StatelessWidget {
  /// Current location display state from LocationStateManager
  final LocationDisplayState locationState;

  /// Callback when user taps to change/set location
  final VoidCallback onChangeLocation;

  /// Callback when user taps "Use GPS" (only shown for manual locations)
  final VoidCallback? onUseGps;

  const ReportFireLocationCard({
    super.key,
    required this.locationState,
    required this.onChangeLocation,
    this.onUseGps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: 'Location helper for emergency calls',
      child: Card(
        color: scheme.surfaceContainerHigh,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and fire-specific text
              _buildHeader(context, theme, scheme),
              const SizedBox(height: 16),

              // Location content based on state
              _buildLocationContent(context, theme, scheme),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the fire-specific header
  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leading icon - matches Home LocationCard style
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.my_location,
            color: scheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Header text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Location to give when you call',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Helps you tell 999 where the fire is.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds location content based on current state
  Widget _buildLocationContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    switch (locationState) {
      case LocationDisplayInitial():
        return _buildEmptyState(context, theme, scheme);

      case LocationDisplayLoading(:final lastKnownLocation):
        return _buildLoadingState(context, theme, scheme, lastKnownLocation);

      case LocationDisplaySuccess(
        :final coordinates,
        :final source,
        :final placeName,
        :final what3words,
        :final isWhat3wordsLoading,
        :final formattedLocation,
        :final isGeocodingLoading,
      ):
        return _buildSuccessState(
          context,
          theme,
          scheme,
          coordinates: coordinates,
          source: source,
          placeName: placeName,
          what3words: what3words,
          isWhat3wordsLoading: isWhat3wordsLoading,
          formattedLocation: formattedLocation,
          isGeocodingLoading: isGeocodingLoading,
        );

      case LocationDisplayError(:final cachedLocation):
        return _buildErrorState(context, theme, scheme, cachedLocation);
    }
  }

  /// Empty state - no location set yet
  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'No location set. Use the map to pick where the fire is.',
          child: Text(
            'Use the map to pick where the fire is. Your location will appear here so you can read it out when you call.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSetLocationButton(context, scheme),
      ],
    );
  }

  /// Loading state
  Widget _buildLoadingState(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    LatLng? lastKnownLocation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Getting your location...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (lastKnownLocation != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last known: ${LocationUtils.formatPrecise(lastKnownLocation.latitude, lastKnownLocation.longitude)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildSetLocationButton(context, scheme),
      ],
    );
  }

  /// Success state - location resolved
  Widget _buildSuccessState(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme, {
    required LatLng coordinates,
    required LocationSource source,
    String? placeName,
    String? what3words,
    bool isWhat3wordsLoading = false,
    String? formattedLocation,
    bool isGeocodingLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Place name (if available from geocoding)
        if (formattedLocation != null) ...[
          _buildLabeledRow(
            context,
            theme,
            scheme,
            label: 'Nearest place',
            value: formattedLocation,
            isValueBold: true,
          ),
          const SizedBox(height: 12),
        ] else if (isGeocodingLoading) ...[
          _buildLoadingRow(context, scheme, 'Loading place name...'),
          const SizedBox(height: 12),
        ],

        // Helper text explaining current location and update option
        Text.rich(
          TextSpan(
            text: 'Your current location. Tap ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            children: [
              TextSpan(
                text: 'Update Location',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' to report a fire elsewhere.'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Coordinates (5dp precision with monospace) - split for readability
        _buildLabeledRow(
          context,
          theme,
          scheme,
          label: 'Latitude',
          value: coordinates.latitude.toStringAsFixed(5),
          isMonospace: true,
        ),
        const SizedBox(height: 4),
        _buildLabeledRow(
          context,
          theme,
          scheme,
          label: 'Longitude',
          value: coordinates.longitude.toStringAsFixed(5),
          isMonospace: true,
        ),
        const SizedBox(height: 6),

        // Helper text for coordinates
        Text(
          'Exact coordinates recommended for fire service',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),

        // what3words row
        _buildWhat3wordsRow(
          context,
          theme,
          scheme,
          what3words: what3words,
          isLoading: isWhat3wordsLoading,
        ),
        const SizedBox(height: 12),

        // Static map preview
        _buildMapPreview(context, scheme, coordinates),
        const SizedBox(height: 12),

        // Action buttons
        _buildActionButtons(context, scheme, source),
        const SizedBox(height: 12),

        // Copy all button
        _buildCopyAllButton(
          context,
          theme,
          scheme,
          coordinates: coordinates,
          what3words: what3words,
          placeName: formattedLocation ?? placeName,
        ),
      ],
    );
  }

  /// Error state
  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    LatLng? cachedLocation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: scheme.error),
            const SizedBox(width: 8),
            Text(
              'Could not get location',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap below to set your location manually.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _buildSetLocationButton(context, scheme),
      ],
    );
  }

  /// Builds a labeled row with optional monospace/bold styling
  Widget _buildLabeledRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme, {
    required String label,
    required String value,
    bool isMonospace = false,
    bool isValueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: isValueBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a loading indicator row
  Widget _buildLoadingRow(
    BuildContext context,
    ColorScheme scheme,
    String message,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Builds the what3words row with tap-to-open functionality
  Widget _buildWhat3wordsRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme, {
    String? what3words,
    bool isLoading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            'what3words',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: isLoading
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
                      'Loading...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : what3words != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Open $what3words in what3words app or website',
                      button: true,
                      child: InkWell(
                        onTap: () => _openWhat3words(context, what3words),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            what3words,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to open in what3words',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              : Text(
                  '/// Unavailable',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
        ),
      ],
    );
  }

  /// Opens what3words address in app or website
  Future<void> _openWhat3words(BuildContext context, String what3words) async {
    // Remove leading slashes if present
    final address = what3words.replaceAll('///', '').trim();

    // Try what3words app deep link first, fall back to website
    final appUri = Uri.parse('https://what3words.com/$address');

    try {
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open what3words for $what3words'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open what3words for $what3words'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Builds static map preview
  Widget _buildMapPreview(
    BuildContext context,
    ColorScheme scheme,
    LatLng coordinates,
  ) {
    final staticMapUrl = _buildStaticMapUrl(
      coordinates.latitude,
      coordinates.longitude,
    );

    // When no API key, show graceful fallback (not permanent spinner)
    return LocationMiniMapPreview(staticMapUrl: staticMapUrl, isLoading: false);
  }

  /// Builds a Google Static Maps URL for the given coordinates
  String? _buildStaticMapUrl(double lat, double lon) {
    final apiKey = FeatureFlags.googleMapsApiKey;
    if (apiKey.isEmpty) {
      return null;
    }

    // Round to 2 decimal places for the URL (privacy)
    final roundedLat = (lat * 100).round() / 100;
    final roundedLon = (lon * 100).round() / 100;

    final url = Uri.parse('https://maps.googleapis.com/maps/api/staticmap')
        .replace(
          queryParameters: {
            'center': '$roundedLat,$roundedLon',
            'zoom': '14',
            'size': '600x300',
            'markers': 'color:red|$roundedLat,$roundedLon',
            'key': apiKey,
            'scale': '2',
            'maptype': 'roadmap',
          },
        );

    return url.toString();
  }

  /// Builds action buttons (Change/Use GPS)
  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme scheme,
    LocationSource source,
  ) {
    final isManual = source == LocationSource.manual;

    if (isManual && onUseGps != null) {
      // Two buttons: Change + Use GPS
      return Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Change the fire location on the map',
              button: true,
              child: OutlinedButton.icon(
                onPressed: onChangeLocation,
                icon: const Icon(Icons.edit_location_alt, size: 18),
                label: const Text('Change'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: 'Switch back to your GPS location',
              button: true,
              child: FilledButton.icon(
                onPressed: onUseGps,
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: const Text('Use GPS'),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Single button: Update location
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Update fire location',
        button: true,
        child: OutlinedButton.icon(
          onPressed: onChangeLocation,
          icon: const Icon(Icons.edit_location_alt, size: 18),
          label: const Text('Update location'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }

  /// Builds the "Set location" button for empty/error states
  Widget _buildSetLocationButton(BuildContext context, ColorScheme scheme) {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Open map to set fire location',
        button: true,
        child: OutlinedButton.icon(
          onPressed: onChangeLocation,
          icon: const Icon(Icons.add_location_alt, size: 18),
          label: const Text('Open map to set location'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }

  /// Builds the "Copy Location" button that copies coordinates + w3w
  ///
  /// Uses FilledTonalButton for medium emphasis - this is the primary
  /// utility action after setting a location (M3 button hierarchy).
  Widget _buildCopyAllButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme, {
    required LatLng coordinates,
    String? what3words,
    String? placeName,
  }) {
    return Semantics(
      label: 'Copy location details to clipboard',
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: () => _copyLocationToClipboard(
            context,
            coordinates: coordinates,
            what3words: what3words,
            placeName: placeName,
          ),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy location for your call'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ),
    );
  }

  /// Copies formatted location text to clipboard
  void _copyLocationToClipboard(
    BuildContext context, {
    required LatLng coordinates,
    String? what3words,
    String? placeName,
  }) {
    final buffer = StringBuffer();

    // Add place name if available
    if (placeName != null && placeName.isNotEmpty) {
      buffer.writeln('Nearest place: $placeName');
    }

    // Add coordinates (5dp)
    final preciseCoords = LocationUtils.formatPrecise(
      coordinates.latitude,
      coordinates.longitude,
    );
    buffer.writeln('Coordinates: $preciseCoords');

    // Add what3words
    if (what3words != null) {
      buffer.writeln('what3words: $what3words');
    } else {
      buffer.writeln('what3words: Unavailable');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Location copied. You can paste it into notes before calling.',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
