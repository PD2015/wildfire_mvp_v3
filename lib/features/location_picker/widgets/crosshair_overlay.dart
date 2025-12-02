import 'package:flutter/material.dart';

import '../../../theme/brand_palette.dart';

/// CrosshairOverlay: Fixed center marker for map-based location picking
///
/// **Purpose**: Visual indicator showing the exact center point where
/// coordinates will be captured when the user confirms their selection.
///
/// **Design**:
/// - Positioned at absolute center of parent (ignores safe area)
/// - Uses location pin icon for immediate recognition
/// - Drop shadow ensures visibility on all map backgrounds
/// - Decorative only - no semantic meaning (map provides context)
///
/// **Usage**:
/// ```dart
/// Stack(
///   children: [
///     GoogleMap(...),
///     const CrosshairOverlay(),
///   ],
/// )
/// ```
///
/// **Constitution Compliance**:
/// - C3: Not interactive, so no tap target requirement
/// - C4: Uses BrandPalette.forest600 (not RiskPalette)
class CrosshairOverlay extends StatelessWidget {
  /// Creates a crosshair overlay widget.
  ///
  /// [size] - Total size of the crosshair area (default 48dp)
  /// [iconSize] - Size of the icon within the area (default 36dp)
  const CrosshairOverlay({
    super.key,
    this.size = 48.0,
    this.iconSize = 36.0,
  });

  /// Total size of the crosshair container
  final double size;

  /// Size of the location pin icon
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IgnorePointer(
        // Don't intercept touch events - let map handle them
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow layer for visibility on light map backgrounds
              Icon(
                Icons.location_pin,
                size: iconSize,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              // Offset the shadow slightly down and right
              Positioned(
                top: 2,
                left: 2,
                child: Icon(
                  Icons.location_pin,
                  size: iconSize,
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
              // Main icon layer
              Icon(
                Icons.location_pin,
                size: iconSize,
                color: BrandPalette.forest600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
