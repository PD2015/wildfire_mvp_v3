import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Geographic bounding box for map viewport queries
/// 
/// Used for EFFIS WFS bbox queries and spatial filtering.
/// 
/// Implementation: TBD in T011
class LatLngBounds extends Equatable {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  /// TODO: T011 - Implement validation (southwest < northeast in both dimensions)

  /// TODO: T011 - Implement toBboxString() for EFFIS WFS format
  /// Format: "{minLon},{minLat},{maxLon},{maxLat}"
  String toBboxString() {
    throw UnimplementedError('TBD in T011');
  }

  /// TODO: T011 - Implement contains check
  bool contains(LatLng point) {
    throw UnimplementedError('TBD in T011');
  }

  /// TODO: T011 - Implement intersects check
  bool intersects(LatLngBounds other) {
    throw UnimplementedError('TBD in T011');
  }

  @override
  List<Object?> get props => [southwest, northeast];
}
