import 'package:equatable/equatable.dart';

/// Level of detail available for a resolved location name
enum LocationNameDetailLevel {
  /// Town or city name (most specific)
  locality,

  /// Postal town (e.g. Aviemore for PH22)
  postalTown,

  /// Sub-area of a locality (e.g. neighbourhood)
  sublocality,

  /// Natural feature like mountain, glen, loch
  naturalFeature,

  /// Large administrative area (council, county) - least specific
  adminArea,

  /// Only raw coordinates available (fallback)
  coordinatesFallback,
}

/// Structured location name result from reverse geocoding
///
/// Provides both a user-friendly display name and metadata about
/// the detail level, allowing UI to adapt formatting.
///
/// Example usage:
/// ```dart
/// final name = LocationName(
///   displayName: 'Aviemore',
///   rawAddress: 'Aviemore, Highland PH22 1RH, UK',
///   detailLevel: LocationNameDetailLevel.locality,
/// );
/// print(name.displayName); // "Aviemore"
/// ```
class LocationName extends Equatable {
  /// User-friendly name for display
  ///
  /// May be formatted as:
  /// - "Aviemore" (locality)
  /// - "Near Ben Wyvis" (natural feature)
  /// - "Highland" (admin area fallback)
  final String displayName;

  /// Full formatted address from Google (if available)
  ///
  /// Useful for debugging or detailed views.
  /// C2: This should NOT be logged in production.
  final String? rawAddress;

  /// Indicates how specific the location name is
  ///
  /// UI can use this to show confidence indicators or
  /// suggest manual location entry for low-detail results.
  final LocationNameDetailLevel detailLevel;

  const LocationName({
    required this.displayName,
    this.rawAddress,
    required this.detailLevel,
  });

  /// Whether this is a high-confidence, specific location
  bool get isSpecific =>
      detailLevel == LocationNameDetailLevel.locality ||
      detailLevel == LocationNameDetailLevel.postalTown ||
      detailLevel == LocationNameDetailLevel.sublocality;

  /// Whether this is a natural feature (shown as "Near X")
  bool get isNaturalFeature =>
      detailLevel == LocationNameDetailLevel.naturalFeature;

  /// Whether this fell back to a low-detail admin area
  bool get isAdminAreaFallback =>
      detailLevel == LocationNameDetailLevel.adminArea;

  /// Whether we only have coordinates (no geocoding result)
  bool get isCoordinatesFallback =>
      detailLevel == LocationNameDetailLevel.coordinatesFallback;

  @override
  List<Object?> get props => [displayName, rawAddress, detailLevel];

  @override
  String toString() =>
      'LocationName(displayName: $displayName, detailLevel: $detailLevel)';

  /// Create a fallback location name from coordinates
  ///
  /// Used when geocoding fails or returns no results.
  /// Coordinates are rounded for privacy (C2 compliance).
  factory LocationName.fromCoordinates(double lat, double lon) {
    // Round to 2 decimal places for privacy
    final roundedLat = lat.toStringAsFixed(2);
    final roundedLon = lon.toStringAsFixed(2);
    return LocationName(
      displayName: '$roundedLat, $roundedLon',
      rawAddress: null,
      detailLevel: LocationNameDetailLevel.coordinatesFallback,
    );
  }
}
