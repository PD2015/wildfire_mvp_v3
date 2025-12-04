import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Map type selector with dropdown menu matching location picker style
///
/// **Purpose**: Allows users to switch between terrain, satellite, hybrid,
/// and normal map views using a popup menu.
///
/// **Styling**: Matches the location picker's map type selector with
/// surface color background, rounded corners, and drop shadow.
///
/// **Constitution Compliance**:
/// - C3: Button is ≥48dp touch target
/// - C3: Semantic labels for accessibility
class MapTypeSelector extends StatelessWidget {
  /// Creates a map type selector dropdown.
  ///
  /// [currentMapType] - The currently selected map type
  /// [onMapTypeChanged] - Callback when map type should change
  const MapTypeSelector({
    super.key,
    required this.currentMapType,
    required this.onMapTypeChanged,
  });

  /// Current map type being displayed
  final MapType currentMapType;

  /// Callback when user selects a new map type
  final ValueChanged<MapType> onMapTypeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Change map type, currently ${_getMapTypeLabel(currentMapType)}',
      child: Container(
        key: const Key('map_type_selector_container'),
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
        child: PopupMenuButton<MapType>(
          key: const Key('map_type_selector'),
          icon: Icon(
            _getMapTypeIcon(currentMapType),
            color: colorScheme.onSurfaceVariant,
            semanticLabel: 'Change map type',
          ),
          tooltip: 'Change map type',
          onSelected: onMapTypeChanged,
          itemBuilder: (context) => [
            _buildMapTypeMenuItem(
                context, MapType.terrain, 'Terrain', Icons.terrain),
            _buildMapTypeMenuItem(
                context, MapType.satellite, 'Satellite', Icons.satellite_alt),
            _buildMapTypeMenuItem(
                context, MapType.hybrid, 'Hybrid', Icons.layers),
            _buildMapTypeMenuItem(context, MapType.normal, 'Normal', Icons.map),
          ],
        ),
      ),
    );
  }

  /// Build a menu item for a map type option
  PopupMenuItem<MapType> _buildMapTypeMenuItem(
    BuildContext context,
    MapType type,
    String label,
    IconData icon,
  ) {
    final isSelected = currentMapType == type;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopupMenuItem<MapType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? primaryColor : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryColor : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              color: primaryColor,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  /// Get the icon for a map type
  IconData _getMapTypeIcon(MapType type) {
    switch (type) {
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

  /// Get the label for a map type (for accessibility)
  String _getMapTypeLabel(MapType type) {
    switch (type) {
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
}
