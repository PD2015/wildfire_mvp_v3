import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// MapTypeToggle: Cycling button for map type selection
///
/// **Purpose**: Allows users to switch between terrain, satellite, and hybrid
/// map views in the location picker.
///
/// **Behavior**: Single button that cycles through map types on tap:
/// terrain → satellite → hybrid → terrain
///
/// **Constitution Compliance**:
/// - C3: Button is ≥48dp touch target
/// - C3: Semantic label describes current state
class MapTypeToggle extends StatelessWidget {
  /// Creates a map type toggle button.
  ///
  /// [currentMapType] - The currently selected map type
  /// [onMapTypeChanged] - Callback when map type should change
  const MapTypeToggle({
    super.key,
    required this.currentMapType,
    required this.onMapTypeChanged,
  });

  /// Current map type being displayed
  final MapType currentMapType;

  /// Callback when user wants to change map type
  final ValueChanged<MapType> onMapTypeChanged;

  /// Gets the next map type in the cycle
  MapType get _nextMapType {
    switch (currentMapType) {
      case MapType.terrain:
        return MapType.satellite;
      case MapType.satellite:
        return MapType.hybrid;
      case MapType.hybrid:
        return MapType.terrain;
      case MapType.normal:
        return MapType.terrain;
      case MapType.none:
        return MapType.terrain;
    }
  }

  /// Gets the icon for the current map type
  IconData get _currentIcon {
    switch (currentMapType) {
      case MapType.terrain:
        return Icons.terrain;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.hybrid:
        return Icons.layers;
      case MapType.normal:
        return Icons.map;
      case MapType.none:
        return Icons.map_outlined;
    }
  }

  /// Gets the label for the current map type (for accessibility)
  String get _currentLabel {
    switch (currentMapType) {
      case MapType.terrain:
        return 'Terrain';
      case MapType.satellite:
        return 'Satellite';
      case MapType.hybrid:
        return 'Hybrid';
      case MapType.normal:
        return 'Normal';
      case MapType.none:
        return 'None';
    }
  }

  /// Gets the label for the next map type (for tooltip)
  String get _nextLabel {
    switch (_nextMapType) {
      case MapType.terrain:
        return 'Terrain';
      case MapType.satellite:
        return 'Satellite';
      case MapType.hybrid:
        return 'Hybrid';
      case MapType.normal:
        return 'Normal';
      case MapType.none:
        return 'None';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Map type: $_currentLabel. Tap to switch to $_nextLabel',
      button: true,
      child: Material(
        color: colorScheme.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: const Key('map_type_toggle'),
          onTap: () => onMapTypeChanged(_nextMapType),
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48, // C3 compliance: ≥48dp
            height: 48, // C3 compliance: ≥48dp
            child: Tooltip(
              message: 'Switch to $_nextLabel view',
              child: Icon(
                _currentIcon,
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
