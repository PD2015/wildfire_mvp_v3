import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

/// Preview panel showing selected location details (T020)
///
/// Displays:
/// - Coordinates (redacted for display)
/// - what3words address (if available)
/// - Place name (if available)
/// - Loading indicators for pending resolutions
class LocationPreview extends StatelessWidget {
  final LatLng coordinates;
  final What3wordsAddress? what3words;
  final String? placeName;
  final bool isResolvingWhat3words;
  final bool isResolvingPlaceName;

  const LocationPreview({
    super.key,
    required this.coordinates,
    this.what3words,
    this.placeName,
    this.isResolvingWhat3words = false,
    this.isResolvingPlaceName = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Place name or coordinates header
          _buildHeader(theme, colorScheme),
          const SizedBox(height: 12),

          // what3words address
          _buildWhat3wordsRow(theme, colorScheme),
          const SizedBox(height: 8),

          // Coordinates
          _buildCoordinatesRow(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    if (isResolvingPlaceName && placeName == null) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Finding location...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final headerText = placeName ?? 'Selected Location';
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            headerText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWhat3wordsRow(ThemeData theme, ColorScheme colorScheme) {
    if (isResolvingWhat3words && what3words == null) {
      return Row(
        children: [
          Text(
            '///',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Getting what3words...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (what3words != null) {
      return Row(
        children: [
          Text(
            '///',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SelectableText(
              what3words!.words,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            key: const Key('copy_what3words_button'),
            icon: Icon(Icons.copy, size: 18, color: colorScheme.primary),
            onPressed: () {
              // Copy handled by parent
            },
            tooltip: 'Copy what3words',
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    return Text(
      'what3words unavailable',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCoordinatesRow(ThemeData theme, ColorScheme colorScheme) {
    final coordText =
        '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';

    return Row(
      children: [
        Icon(
          Icons.my_location,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        SelectableText(
          coordText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
