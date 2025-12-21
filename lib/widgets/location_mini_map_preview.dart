import 'package:flutter/material.dart';

/// A static map preview widget with loading and error states
///
/// Displays a Google Static Maps API image with:
/// - Loading spinner while fetching
/// - Error state if image fails to load
/// - Optional tappable overlay (when onTap is provided)
///
/// Note: In LocationCard, this is now view-only (no onTap).
/// The action to change location is handled by a dedicated button.
///
/// Constitutional compliance:
/// - C3: Full surface is tappable when onTap provided (≥48dp)
/// - C2: staticMapUrl should use rounded coordinates (privacy)
class LocationMiniMapPreview extends StatelessWidget {
  /// The static map URL from Google Static Maps API
  final String? staticMapUrl;

  /// Whether the map is currently loading
  final bool isLoading;

  /// Callback when the map preview is tapped
  final VoidCallback? onTap;

  /// Height of the preview (default 140px per spec)
  final double height;

  const LocationMiniMapPreview({
    super.key,
    required this.staticMapUrl,
    this.isLoading = false,
    this.onTap,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      button: onTap != null,
      label: 'Map preview. Tap to change location.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Map image or placeholder
              if (staticMapUrl != null && !isLoading)
                _buildMapImage(scheme)
              else if (isLoading)
                _buildLoadingState(scheme)
              else
                _buildErrorState(scheme, theme),

              // "Tap to change" overlay
              if (onTap != null)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to change',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapImage(ColorScheme scheme) {
    return Image.network(
      staticMapUrl!,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorState(scheme, Theme.of(context));
      },
    );
  }

  Widget _buildLoadingState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading map...',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme scheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 32,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Map preview unavailable',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
