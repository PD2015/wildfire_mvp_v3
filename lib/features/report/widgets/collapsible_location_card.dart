import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/location_display_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';
import 'package:wildfire_mvp_v3/widgets/location_mini_map_preview.dart';

/// Report-specific location card optimized for emergency UX
///
/// Displays location information with an expandable panel for details.
/// Unlike the Risk screen location UI, this version:
/// - Shows Copy + Update buttons always visible (not in expanded panel)
/// - Uses emergency-focused copy: "Copy for your call"
/// - Collapses by default
///
/// Layout:
/// - Header: "Your location for the call"
/// - Summary: Place name · Source badge
/// - **Always visible**: Copy for your call, Update location buttons
/// - **Expandable**: Lat/lng, what3words, map preview
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

  /// Whether the expandable section is initially expanded
  final bool initiallyExpanded;

  const CollapsibleLocationCard({
    super.key,
    required this.locationState,
    this.onCopyForCall,
    this.onUpdateLocation,
    this.onUseGps,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleLocationCard> createState() =>
      _CollapsibleLocationCardState();
}

class _CollapsibleLocationCardState extends State<CollapsibleLocationCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

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
        color: cs.surfaceContainerHigh,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cs.outlineVariant,
            width: 1,
          ),
        ),
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
              _buildLocationContent(theme, cs),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header row with title and expand button
  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location pin icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: cs.onSecondaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Title
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Your location for the call',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ),

        // Expand/collapse button (only when there's location data)
        if (widget.locationState is LocationDisplaySuccess)
          Semantics(
            button: true,
            label: _isExpanded ? 'Collapse details' : 'Expand details',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: cs.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
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
        const SizedBox(height: 12),

        // Action buttons (always visible)
        _buildActionButtons(
          theme,
          cs,
          hasLocation: true,
          showUseGps: source == LocationSource.manual,
        ),

        // Expandable details section
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Divider(color: cs.outlineVariant, height: 1),
              const SizedBox(height: 16),

              // Coordinates with 5dp precision
              _buildDetailRow(
                theme,
                cs,
                icon: Icons.grid_on,
                label: 'Coordinates',
                value:
                    '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}',
              ),

              // What3words
              if (what3words != null || isWhat3wordsLoading) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  theme,
                  cs,
                  icon: Icons.tag,
                  label: 'what3words',
                  value: isWhat3wordsLoading ? 'Loading...' : what3words ?? '',
                  isLoading: isWhat3wordsLoading,
                ),
              ],

              // Mini map preview (only if API key available)
              _buildMapPreview(coordinates),
            ],
          ),
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

  /// Builds the summary row with place name and source badge
  Widget _buildSummaryRow(
    ThemeData theme,
    ColorScheme cs,
    String? placeName,
    LocationSource source,
    String? formattedLocation,
  ) {
    // Determine display text
    final displayText = placeName ?? formattedLocation ?? 'Location set';

    // Source badge text and icon
    final (badgeText, badgeIcon) = switch (source) {
      LocationSource.gps => ('GPS', Icons.gps_fixed),
      LocationSource.manual => ('Manual', Icons.edit_location_outlined),
      LocationSource.cached => ('Cached', Icons.cached),
      LocationSource.defaultFallback => ('Default', Icons.public),
    };

    return Row(
      children: [
        Expanded(
          child: Text(
            displayText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Source badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                badgeIcon,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                badgeText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the action buttons row (always visible)
  Widget _buildActionButtons(
    ThemeData theme,
    ColorScheme cs, {
    required bool hasLocation,
    bool showUseGps = false,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Copy for your call button (primary when location available)
        if (hasLocation)
          _ActionButton(
            icon: Icons.copy,
            label: 'Copy for your call',
            onPressed: widget.onCopyForCall ?? _copyLocationToClipboard,
            isPrimary: true,
          ),

        // Update location button
        _ActionButton(
          icon: Icons.edit_location_outlined,
          label: hasLocation ? 'Update location' : 'Set location',
          onPressed: widget.onUpdateLocation,
          isPrimary: !hasLocation,
        ),

        // Use GPS button (only when manual location)
        if (showUseGps && widget.onUseGps != null)
          _ActionButton(
            icon: Icons.gps_fixed,
            label: 'Use GPS',
            onPressed: widget.onUseGps,
            isPrimary: false,
          ),
      ],
    );
  }

  /// Builds a detail row in the expanded section
  Widget _buildDetailRow(
    ThemeData theme,
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
    bool isLoading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              if (isLoading)
                SizedBox(
                  width: 80,
                  height: 16,
                  child: LinearProgressIndicator(
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                  ),
                )
              else
                SelectableText(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ),
      ],
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
      ),
    );
  }
}
