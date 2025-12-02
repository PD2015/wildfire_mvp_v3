import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/place_search_result.dart';

/// Error types for geocoding operations
sealed class GeocodingError {
  const GeocodingError();
}

/// Network connectivity or timeout error
class GeocodingNetworkError extends GeocodingError {
  final String message;
  const GeocodingNetworkError(this.message);
  @override
  String toString() => 'GeocodingNetworkError: $message';
}

/// API returned an error response
class GeocodingApiError extends GeocodingError {
  final String message;
  final int? statusCode;
  const GeocodingApiError(this.message, {this.statusCode});
  @override
  String toString() => 'GeocodingApiError: $message (status: $statusCode)';
}

/// No results found for the query
class GeocodingNoResultsError extends GeocodingError {
  final String query;
  const GeocodingNoResultsError(this.query);
  @override
  String toString() => 'GeocodingNoResultsError: No results for "$query"';
}

/// Service interface for Google Geocoding API operations
///
/// Provides place search (forward geocoding) and reverse geocoding.
/// Uses Google Geocoding API for autocomplete suggestions and coordinate resolution.
abstract class GeocodingService {
  /// Search for places matching the query text
  ///
  /// Returns list of [PlaceSearchResult] suggestions for autocomplete.
  /// Results are biased toward UK locations.
  ///
  /// Example:
  /// ```dart
  /// final result = await service.searchPlaces('Edinburgh Castle');
  /// result.fold(
  ///   (error) => print('Failed: $error'),
  ///   (places) => places.forEach((p) => print(p.formattedAddress)),
  /// );
  /// ```
  Future<Either<GeocodingError, List<PlaceSearchResult>>> searchPlaces({
    required String query,
    int maxResults = 5,
  });

  /// Get place name from coordinates (reverse geocoding)
  ///
  /// Returns human-readable place name for display.
  ///
  /// Example:
  /// ```dart
  /// final result = await service.reverseGeocode(lat: 55.9533, lon: -3.1883);
  /// result.fold(
  ///   (error) => print('Failed: $error'),
  ///   (name) => print('Place: $name'), // e.g., "Edinburgh, Scotland"
  /// );
  /// ```
  Future<Either<GeocodingError, String>> reverseGeocode({
    required double lat,
    required double lon,
  });

  /// Get coordinates for a place ID
  ///
  /// Resolves Google Places API place_id to exact coordinates.
  Future<Either<GeocodingError, LatLng>> getPlaceCoordinates({
    required String placeId,
  });

  /// Build a Static Maps API URL for the given coordinates
  ///
  /// Returns a URL for displaying a static map thumbnail.
  /// Used in LocationCard preview and confirmation screens.
  ///
  /// Parameters:
  /// - [lat], [lon]: Center coordinates
  /// - [zoom]: Map zoom level (default 14)
  /// - [width], [height]: Image dimensions in pixels
  /// - [markerColor]: Marker color (default 'red')
  String buildStaticMapUrl({
    required double lat,
    required double lon,
    int zoom = 14,
    int width = 300,
    int height = 200,
    String markerColor = 'red',
  });
}
