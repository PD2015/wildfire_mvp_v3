import 'package:flutter/material.dart';

/// Custom zoom controls widget matching the app's theme
///
/// **Purpose**: Provides zoom in/out buttons that respect Flutter's theme,
/// unlike Google Maps' native controls which are always white.
///
/// **Styling**: Matches other map control buttons (GPS, map type selector)
/// with surface color background, rounded corners, and drop shadow.
///
/// **Constitution Compliance**:
/// - C3: Buttons are ≥48dp touch targets
/// - C3: Semantic labels for accessibility
class MapZoomControls extends StatelessWidget {
  /// Creates custom zoom controls.
  ///
  /// [onZoomIn] - Callback when zoom in button is pressed
  /// [onZoomOut] - Callback when zoom out button is pressed
  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  /// Callback when user taps zoom in
  final VoidCallback onZoomIn;

  /// Callback when user taps zoom out
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in button
          Semantics(
            button: true,
            label: 'Zoom in',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onZoomIn,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          // Divider between buttons
          // Uses `outline` instead of `outlineVariant` for visibility in dark theme
          // (outlineVariant in dark theme is same as surface color)
          Container(
            width: 32,
            height: 1,
            color: colorScheme.outline,
          ),
          // Zoom out button
          Semantics(
            button: true,
            label: 'Zoom out',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onZoomOut,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
