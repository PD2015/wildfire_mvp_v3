import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final String? coordinatesLabel; // e.g. "57.20, -3.83"
  final String subtitle; // e.g. "Current location (GPS)"
  final bool isLoading;
  final VoidCallback? onChangeLocation;

  const LocationCard({
    super.key,
    required this.coordinatesLabel,
    required this.subtitle,
    this.isLoading = false,
    this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasLocation =
        coordinatesLabel != null && coordinatesLabel!.isNotEmpty;

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
          child: Row(
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
                  Icons.my_location,
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
                    Text(
                      'Location',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLocation ? coordinatesLabel! : 'Location not set',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

              // Change location button
              if (onChangeLocation != null)
                FilledButton.tonal(
                  onPressed: onChangeLocation,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize:
                        const Size(0, 36), // still ≥ 44dp tap area with padding
                  ),
                  child: Text(
                    hasLocation ? 'Change' : 'Set',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
