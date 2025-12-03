import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildfire_mvp_v3/features/report/models/report_fire_state.dart';

/// Location helper card for Report Fire screen
///
/// Displays fire location to help users communicate with 999/101/Crimestoppers.
/// Shows coordinates (5dp), what3words, and nearest place name.
///
/// **Important**: This does NOT contact emergency services or submit reports.
/// Users must make their own phone calls.
///
/// Features:
/// - Header with icon and explanatory subtitle
/// - Location details when set (place, coordinates, what3words)
/// - Empty state with instructional text
/// - "Open map" / "Update location" button
/// - Copy button for clipboard
/// - Clear disclaimer about not contacting services
///
/// Constitutional compliance:
/// - C3: All buttons ≥48dp touch target
/// - C3: Semantic labels for accessibility
/// - C4: Clear disclaimer that app doesn't contact services
class ReportFireLocationHelperCard extends StatelessWidget {
  const ReportFireLocationHelperCard({
    super.key,
    this.location,
    required this.onSelectLocation,
  });

  /// Current fire location (null if not set)
  final ReportFireLocation? location;

  /// Callback when user taps to select/update location
  final VoidCallback onSelectLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasLocation = location != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon
            _buildHeader(theme, colors),
            const SizedBox(height: 12),

            // Content: either location details or empty state
            if (hasLocation)
              _buildLocationDetails(theme, colors)
            else
              _buildEmptyState(theme, colors),

            const SizedBox(height: 12),

            // Action buttons
            _buildActionButtons(context, hasLocation),

            const SizedBox(height: 12),

            // Safety disclaimer
            _buildDisclaimer(theme, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.my_location,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
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
                  ),
                ),
              ),
              Text(
                'Optional — helps you tell 999 where the fire is.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDetails(ThemeData theme, ColorScheme colors) {
    final loc = location!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nearest place (if available)
        if (loc.nearestPlaceName != null) ...[
          _buildLabel(theme, colors, 'Nearest place'),
          const SizedBox(height: 4),
          Text(
            loc.nearestPlaceName!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Coordinates with helper text
        _buildLabel(theme, colors, 'Coordinates'),
        const SizedBox(height: 4),
        Semantics(
          label: 'GPS coordinates: ${loc.formattedCoordinates}',
          child: Text(
            loc.formattedCoordinates,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Exact coordinates recommended for fire service',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),

        // what3words
        _buildLabel(theme, colors, 'what3words'),
        const SizedBox(height: 4),
        _buildWhat3wordsDisplay(theme, colors),
      ],
    );
  }

  Widget _buildLabel(ThemeData theme, ColorScheme colors, String text) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildWhat3wordsDisplay(ThemeData theme, ColorScheme colors) {
    final w3w = location?.what3words;

    if (w3w != null) {
      return Semantics(
        label: 'what3words address: ${w3w.words}',
        child: Text(
          w3w.displayFormat,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
      );
    }

    return Text(
      '/// Unavailable',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    return Semantics(
      label: 'No location set. Use the map to pick where the fire is.',
      child: Text(
        'Use the map to pick where the fire is. Your location will appear here so you can read it out when you call.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool hasLocation) {
    return Row(
      children: [
        // Primary action: Open/Update map
        Expanded(
          child: SizedBox(
            height: 48, // C3: ≥48dp touch target
            child: OutlinedButton.icon(
              key: const Key('open_location_picker_button'),
              onPressed: onSelectLocation,
              icon: Icon(hasLocation
                  ? Icons.edit_location_alt
                  : Icons.add_location_alt),
              label: Text(
                hasLocation ? 'Update location' : 'Open map to set location',
              ),
            ),
          ),
        ),

        // Secondary action: Copy (only when location set)
        if (hasLocation) ...[
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            width: 48,
            child: Tooltip(
              message: 'Copy location details',
              child: OutlinedButton(
                key: const Key('copy_location_button'),
                onPressed: () => _copyToClipboard(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.copy),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    if (location == null) return;

    await Clipboard.setData(
      ClipboardData(text: location!.toClipboardText()),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location copied. You can paste it into notes before calling.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildDisclaimer(ThemeData theme, ColorScheme colors) {
    return Semantics(
      label:
          'Important: This app does not contact emergency services. Always phone 999, 101 or Crimestoppers yourself.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'This app does not contact emergency services. Always phone 999, 101 or Crimestoppers yourself.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
