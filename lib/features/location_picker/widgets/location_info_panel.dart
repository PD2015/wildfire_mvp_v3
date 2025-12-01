import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/location_models.dart';
import '../../../models/what3words_models.dart';
import '../../../utils/location_utils.dart';

/// LocationInfoPanel: Bottom panel for map-based location picker
///
/// **Purpose**: Displays current crosshair coordinates, what3words address,
/// and action buttons for the map-first location picker experience.
///
/// **Features**:
/// - "Pin location" header to clarify crosshair represents selected location
/// - Coordinates display (2dp precision per C2 privacy)
/// - what3words address with loading/error states
/// - Copy button for what3words (≥48dp per C3)
/// - Confirm and Cancel action buttons (≥48dp per C3)
///
/// **Constitution Compliance**:
/// - C2: Coordinates displayed at 2dp precision
/// - C3: All buttons ≥48dp touch target
/// - C3: Semantic labels for accessibility
class LocationInfoPanel extends StatelessWidget {
  /// Creates a location info panel.
  ///
  /// [coordinates] - Current map center coordinates
  /// [what3words] - Resolved what3words address (null if not yet resolved)
  /// [isLoadingWhat3words] - Whether what3words is being resolved
  /// [what3wordsError] - Error message if what3words resolution failed
  /// [canConfirm] - Whether confirm button should be enabled
  /// [onCopyWhat3words] - Callback when copy button is tapped
  /// [onConfirm] - Callback when Confirm button is tapped
  /// [onCancel] - Callback when Cancel button is tapped
  const LocationInfoPanel({
    super.key,
    required this.coordinates,
    this.what3words,
    this.isLoadingWhat3words = false,
    this.what3wordsError,
    this.canConfirm = true,
    this.onCopyWhat3words,
    this.onConfirm,
    this.onCancel,
  });

  /// Current map center coordinates
  final LatLng coordinates;

  /// Resolved what3words address
  final What3wordsAddress? what3words;

  /// Whether what3words is being resolved
  final bool isLoadingWhat3words;

  /// Error message if what3words resolution failed
  final String? what3wordsError;

  /// Whether the Confirm button should be enabled
  final bool canConfirm;

  /// Callback when copy button is tapped
  final VoidCallback? onCopyWhat3words;

  /// Callback when Confirm button is tapped
  final VoidCallback? onConfirm;

  /// Callback when Cancel button is tapped
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Pin location" header
            _buildHeader(theme, colorScheme),
            const SizedBox(height: 8),

            // Coordinates row
            _buildCoordinatesRow(theme, colorScheme),
            const SizedBox(height: 12),

            // what3words row
            _buildWhat3wordsRow(theme, colorScheme),

            // Action buttons (Confirm and Cancel)
            const SizedBox(height: 16),
            _buildActionButtons(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.push_pin,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Pin location',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinatesRow(ThemeData theme, ColorScheme colorScheme) {
    // Use 2dp precision for display per C2 compliance
    final coordText = LocationUtils.logRedact(
      coordinates.latitude,
      coordinates.longitude,
    );

    return Semantics(
      label:
          'Pin location coordinates: ${coordinates.latitude.toStringAsFixed(2)} latitude, ${coordinates.longitude.toStringAsFixed(2)} longitude',
      child: Row(
        children: [
          Icon(
            Icons.my_location,
            size: 20,
            color: colorScheme.onSurfaceVariant,
            semanticLabel: 'Coordinates',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              coordText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhat3wordsRow(ThemeData theme, ColorScheme colorScheme) {
    // Loading state
    if (isLoadingWhat3words && what3words == null) {
      return Semantics(
        label: 'Loading what3words address',
        child: Row(
          children: [
            Text(
              '///',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
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
              'Loading...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (what3wordsError != null && what3words == null) {
      return Semantics(
        label: 'what3words unavailable: $what3wordsError',
        child: Row(
          children: [
            Text(
              '///',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unavailable',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Success state with what3words
    if (what3words != null) {
      return Row(
        children: [
          Text(
            '///',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              label: 'what3words address: ${what3words!.words}',
              child: Text(
                what3words!.words,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // Copy button - ≥48dp per C3
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const Key('copy_what3words_button'),
              icon: Icon(
                Icons.copy,
                size: 20,
                color: colorScheme.primary,
              ),
              onPressed: onCopyWhat3words != null
                  ? () {
                      // Copy to clipboard
                      Clipboard.setData(ClipboardData(text: what3words!.words));
                      onCopyWhat3words?.call();
                    }
                  : null,
              tooltip: 'Copy what3words address',
            ),
          ),
        ],
      );
    }

    // Default state (no what3words yet, not loading)
    return Row(
      children: [
        Text(
          '///',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Pan map to get address',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Cancel button
        Expanded(
          child: SizedBox(
            height: 48, // C3 compliance: ≥48dp
            child: OutlinedButton(
              key: const Key('cancel_button'),
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Confirm button
        Expanded(
          flex: 2, // Make Confirm button larger
          child: SizedBox(
            height: 48, // C3 compliance: ≥48dp
            child: FilledButton.icon(
              key: const Key('confirm_location_button'),
              onPressed: canConfirm ? onConfirm : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm Location'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
