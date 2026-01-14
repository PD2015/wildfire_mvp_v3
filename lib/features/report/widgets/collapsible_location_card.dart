import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/location_display_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';
import 'package:wildfire_mvp_v3/widgets/location_mini_map_preview.dart';

/// Report-specific location card optimized for emergency UX
///
/// Displays location information with all details visible.
/// Unlike the Risk screen location UI, this version:
/// - Uses emergency-focused copy: "Copy location details"
/// - Shows all location data at once (no expand/collapse)
///
/// Layout:
/// - Header: "Your location for the call"
/// - Summary: Place name · Source
/// - Coordinates: Lat/Lng boxes side-by-side
/// - what3words: Full-width box
/// - Map preview (if API key available)
/// - Action buttons: Copy for your call, Change location
///
/// Constitutional compliance:
/// - C3: All touch targets ≥48dp
/// - C3: Semantic labels on all interactive elements
/// - C4: Does not contact emergency services
class CollapsibleLocationCard extends StatefulWidget {
  /// Current location display state
  final LocationDisplayState locationState;

  /// Callback when user taps "Copy for your call"
  final VoidCallback? onCopyForCall;

  /// Callback when user taps "Update location"
  final VoidCallback? onUpdateLocation;

  /// Callback when user taps "Use GPS" (shown when using manual location)
  final VoidCallback? onUseGps;

  const CollapsibleLocationCard({
    super.key,
    required this.locationState,
    this.onCopyForCall,
    this.onUpdateLocation,
    this.onUseGps,
  });

  @override
  State<CollapsibleLocationCard> createState() =>
      _CollapsibleLocationCardState();
}

class _CollapsibleLocationCardState extends State<CollapsibleLocationCard> {
  /// Copies location to clipboard for emergency call
  ///
  /// Formats: Place name, coordinates (5dp), what3words
  /// Shows snackbar confirmation after copy
  void _copyLocationToClipboard() {
    final state = widget.locationState;
    if (state is! LocationDisplaySuccess) return;

    final buffer = StringBuffer();

    // Place name if available
    if (state.placeName != null && state.placeName!.isNotEmpty) {
      buffer.writeln('Nearest place: ${state.placeName}');
    }

    // Coordinates with 5 decimal precision
    buffer.writeln(
      'Coordinates: ${LocationUtils.formatPrecise(state.coordinates.latitude, state.coordinates.longitude)}',
    );

    // What3words if available
    if (state.what3words != null && state.what3words!.isNotEmpty) {
      buffer.writeln('what3words: ${state.what3words}');
    } else {
      buffer.writeln('what3words: Unavailable');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Location copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      container: true,
      label: 'Location card for emergency calls',
      child: Card(
        // Uses theme cardTheme (surfaceContainerLow) for consistency with EmergencyHeroCard
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              _buildHeader(theme, cs),
              const SizedBox(height: 16),

              // Location content based on state
              // Left padding aligns with header title (icon 24 + spacing 12 = 36)
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: _buildLocationContent(theme, cs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header row with title and expand button
  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Location pin icon (no background)
        Icon(
          Icons.location_on_outlined,
          color: cs.onSurface,
          size: 24,
        ),
        const SizedBox(width: 12),

        // Title (matches EmergencyHeroCard heading)
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Your location for the call',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds location content based on current state
  Widget _buildLocationContent(ThemeData theme, ColorScheme cs) {
    switch (widget.locationState) {
      case LocationDisplayInitial():
        return _buildEmptyState(theme, cs);

      case LocationDisplayLoading(:final lastKnownLocation):
        return _buildLoadingState(theme, cs, lastKnownLocation);

      case LocationDisplaySuccess(
          :final coordinates,
          :final source,
          :final placeName,
          :final what3words,
          :final isWhat3wordsLoading,
          :final formattedLocation,
        ):
        return _buildSuccessState(
          theme,
          cs,
          coordinates: coordinates,
          source: source,
          placeName: placeName,
          what3words: what3words,
          isWhat3wordsLoading: isWhat3wordsLoading,
          formattedLocation: formattedLocation,
        );

      case LocationDisplayError(:final message):
        return _buildErrorState(theme, cs, message);
    }
  }

  /// Empty state - no location set
  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No location set',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButtons(theme, cs, hasLocation: false),
      ],
    );
  }

  /// Loading state - fetching location
  Widget _buildLoadingState(
    ThemeData theme,
    ColorScheme cs,
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
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Finding your location...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (lastKnownLocation != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last known: ${LocationUtils.logRedact(lastKnownLocation.latitude, lastKnownLocation.longitude)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Success state - location available
  Widget _buildSuccessState(
    ThemeData theme,
    ColorScheme cs, {
    required LatLng coordinates,
    required LocationSource source,
    String? placeName,
    String? what3words,
    bool isWhat3wordsLoading = false,
    String? formattedLocation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row: Place name · Source badge
        _buildSummaryRow(theme, cs, placeName, source, formattedLocation),
        const SizedBox(height: 16),

        // Coordinates: Two separate boxes side-by-side
        Row(
          children: [
            // Latitude box
            Expanded(
              child: _buildCoordinateBox(
                theme,
                cs,
                label: 'Latitude',
                value: coordinates.latitude.toStringAsFixed(5),
              ),
            ),
            const SizedBox(width: 12),
            // Longitude box
            Expanded(
              child: _buildCoordinateBox(
                theme,
                cs,
                label: 'Longitude',
                value: coordinates.longitude.toStringAsFixed(5),
              ),
            ),
          ],
        ),

        // What3words: Full-width box below coordinates
        const SizedBox(height: 12),
        _buildWhat3wordsBox(
          theme,
          cs,
          what3words: what3words,
          isLoading: isWhat3wordsLoading,
        ),

        // Mini map preview (only if API key available)
        _buildMapPreview(coordinates),

        // Action buttons below map (full-width stacked)
        const SizedBox(height: 16),
        _buildActionButtons(
          theme,
          cs,
          hasLocation: true,
          showUseGps: source == LocationSource.manual,
        ),
      ],
    );
  }

  /// Error state
  Widget _buildErrorState(ThemeData theme, ColorScheme cs, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              color: cs.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionButtons(theme, cs, hasLocation: false),
      ],
    );
  }

  /// Builds the summary row with place name · source format (consistent with RiskBanner)
  Widget _buildSummaryRow(
    ThemeData theme,
    ColorScheme cs,
    String? placeName,
    LocationSource source,
    String? formattedLocation,
  ) {
    // Determine display text
    final displayText = placeName ?? formattedLocation ?? 'Location set';

    // Source text (no icon, no pill - matches LocationChip format)
    final sourceText = switch (source) {
      LocationSource.gps => 'GPS',
      LocationSource.manual => 'Manual',
      LocationSource.cached => 'Cached',
      LocationSource.defaultFallback => 'Default',
    };

    return Text(
      '$displayText · $sourceText',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: cs.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the action buttons (full-width stacked below map)
  Widget _buildActionButtons(
    ThemeData theme,
    ColorScheme cs, {
    required bool hasLocation,
    bool showUseGps = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Copy location details button (primary action)
        if (hasLocation)
          _ActionButton(
            icon: Icons.copy,
            label: 'Copy location details',
            onPressed: widget.onCopyForCall ?? _copyLocationToClipboard,
            isPrimary: true,
          ),
        if (hasLocation) const SizedBox(height: 8),
        // Change location button (secondary)
        _ActionButton(
          icon: Icons.edit_location_outlined,
          label: hasLocation ? 'Change location' : 'Set location',
          onPressed: widget.onUpdateLocation,
          isPrimary: !hasLocation,
        ),
      ],
    );
  }

  /// Builds a coordinate box (Latitude or Longitude) with label and value
  Widget _buildCoordinateBox(
    ThemeData theme,
    ColorScheme cs, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the what3words box (full width)
  Widget _buildWhat3wordsBox(
    ThemeData theme,
    ColorScheme cs, {
    String? what3words,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'what3words',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (isLoading)
            SizedBox(
              width: 120,
              height: 20,
              child: LinearProgressIndicator(
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
              ),
            )
          else
            SelectableText(
              what3words ?? '/// Unavailable',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the mini map preview (if API key is available)
  Widget _buildMapPreview(LatLng coordinates) {
    final staticMapUrl = _buildStaticMapUrl(
      coordinates.latitude,
      coordinates.longitude,
    );

    // If no API key, don't show map preview
    if (staticMapUrl == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: LocationMiniMapPreview(
              staticMapUrl: staticMapUrl,
              isLoading: false,
            ),
          ),
        ),
      ],
    );
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

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/staticmap').replace(
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
}

/// Action button with icon and label
///
/// Supports primary (filled) and secondary (outlined) styles.
/// Minimum 48dp touch target for C3 compliance.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: SizedBox(
        height: 48,
        child: isPrimary
            ? FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
                style: FilledButton.styleFrom(
                  // 12dp radius matches theme baseline
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outline),
                  // 12dp radius matches theme baseline
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
      ),
    );
  }
}
