import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Result from Google Places/Geocoding API search
///
/// Used in search autocomplete dropdown. Coordinates may be null
/// if only a place_id is returned (requires geocoding to resolve).
class PlaceSearchResult extends Equatable {
  /// Unique identifier from Google Places API
  final String placeId;

  /// Human-readable place name (e.g., "Edinburgh Castle")
  final String name;

  /// Full address string for display
  final String formattedAddress;

  /// Resolved coordinates (null if not yet geocoded)
  final LatLng? coordinates;

  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.coordinates,
  });

  /// Create with resolved coordinates
  PlaceSearchResult withCoordinates(LatLng coords) => PlaceSearchResult(
    placeId: placeId,
    name: name,
    formattedAddress: formattedAddress,
    coordinates: coords,
  );

  /// Display string for autocomplete dropdown
  String get displayText =>
      formattedAddress.isNotEmpty ? formattedAddress : name;

  @override
  List<Object?> get props => [placeId, name, formattedAddress, coordinates];
}
