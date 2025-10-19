import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Geographic bounding box for map viewport queries
///
/// Used for EFFIS WFS bbox queries and spatial filtering.
class LatLngBounds extends Equatable {
  final LatLng southwest;
  final LatLng northeast;

  LatLngBounds({
    required this.southwest,
    required this.northeast,
  }) {
    _validate();
  }

  /// Validation per data-model.md
  void _validate() {
    if (!southwest.isValid || !northeast.isValid) {
      throw ArgumentError('LatLngBounds coordinates must be valid');
    }
    if (southwest.latitude >= northeast.latitude) {
      throw ArgumentError(
          'LatLngBounds southwest.latitude must be < northeast.latitude');
    }
    if (southwest.longitude >= northeast.longitude) {
      throw ArgumentError(
          'LatLngBounds southwest.longitude must be < northeast.longitude');
    }
  }

  /// Computed properties
  LatLng get center => LatLng(
        (southwest.latitude + northeast.latitude) / 2,
        (southwest.longitude + northeast.longitude) / 2,
      );

  double get width => northeast.longitude - southwest.longitude;
  double get height => northeast.latitude - southwest.latitude;

  /// Format for EFFIS WFS bbox query
  /// Format: "{minLon},{minLat},{maxLon},{maxLat}"
  String toBboxString() {
    return '${southwest.longitude},${southwest.latitude},${northeast.longitude},${northeast.latitude}';
  }

  /// Check if point is within bounds
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  /// Check if this bounds intersects with another
  bool intersects(LatLngBounds other) {
    // Bounding boxes intersect if they don't NOT intersect
    // (easier to check the negative case)
    return !(northeast.latitude < other.southwest.latitude ||
        southwest.latitude > other.northeast.latitude ||
        northeast.longitude < other.southwest.longitude ||
        southwest.longitude > other.northeast.longitude);
  }

  @override
  List<Object?> get props => [southwest, northeast];
}
