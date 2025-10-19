import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/effis_fwi_result.dart';
import '../models/effis_fire.dart';
import '../models/lat_lng_bounds.dart';

/// Abstract interface for EFFIS Fire Weather Index service
///
/// Provides contract for retrieving FWI data from EFFIS (European Forest Fire Information System)
/// with comprehensive error handling and retry capabilities.
///
/// All implementations must use constructor injection for http.Client to enable
/// deterministic testing without live HTTP requests.
abstract class EffisService {
  /// Retrieves Fire Weather Index for given coordinates from EFFIS WMS service
  ///
  /// Returns Either<ApiError, EffisFwiResult> where:
  /// - Left: Structured error information for all failure cases
  /// - Right: Successful FWI result with risk level mapping and metadata
  ///
  /// Parameters:
  /// - [lat]: Latitude in decimal degrees (-90 to 90)
  /// - [lon]: Longitude in decimal degrees (-180 to 180)
  /// - [timeout]: Request timeout duration (default: 30 seconds)
  /// - [maxRetries]: Maximum retry attempts for retriable errors (default: 3)
  ///
  /// Retry Logic:
  /// - Retries on: 5xx server errors, network timeouts, connection failures
  /// - No retries on: 4xx client errors (invalid coordinates, not found)
  /// - Uses exponential backoff with jitter for retry delays
  /// - Total time including retries: <2 minutes worst case
  ///
  /// Error Categorization:
  /// - 404 → ApiError with notFound reason
  /// - 503/5xx → ApiError with serviceUnavailable reason (after retries)
  /// - Timeout → ApiError with general reason
  /// - Malformed JSON → ApiError with general reason
  /// - Empty features → ApiError with general reason
  ///
  /// Preconditions:
  /// - lat must be in range [-90, 90]
  /// - lon must be in range [-180, 180]
  /// - timeout must be positive duration
  /// - maxRetries must be >= 0 and <= 10
  ///
  /// Postconditions:
  /// - Never throws exceptions - all errors returned as ApiError
  /// - Network requests respect timeout parameter
  /// - Coordinates in logs limited to 3 decimal places for privacy
  /// - Successful requests complete in <3 seconds (95th percentile)
  ///
  /// Example:
  /// ```dart
  /// final effisService = EffisServiceImpl(httpClient: http.Client());
  /// final result = await effisService.getFwi(
  ///   lat: 55.9533,  // Edinburgh
  ///   lon: -3.1883,
  /// );
  ///
  /// result.fold(
  ///   (error) => print('Error: ${error.message}'),
  ///   (fwiResult) => print('FWI: ${fwiResult.fwi} (${fwiResult.riskLevel})'),
  /// );
  /// ```
  Future<Either<ApiError, EffisFwiResult>> getFwi({
    required double lat,
    required double lon,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  });

  /// Retrieves active fires from EFFIS WFS (Web Feature Service) for given bounding box
  ///
  /// Returns Either<ApiError, List<EffisFire>> where:
  /// - Left: Structured error information for all failure cases
  /// - Right: List of active fires from EFFIS burnt areas layer
  ///
  /// Parameters:
  /// - [bounds]: Geographic bounding box to query for fires
  /// - [timeout]: Request timeout duration (default: 8 seconds for map loads)
  ///
  /// WFS Query Details:
  /// - Endpoint: ies-ows.jrc.ec.europa.eu/wfs
  /// - Layer: burnt_areas_current_year (updated daily)
  /// - Format: GeoJSON FeatureCollection
  /// - Projection: EPSG:4326 (WGS84 lat/lon)
  ///
  /// Error Handling:
  /// - 404/Empty → Returns Right([]) (no fires in region, not an error)
  /// - 503/5xx → ApiError with serviceUnavailable reason
  /// - Timeout → ApiError with general reason
  /// - Malformed JSON → ApiError with general reason
  ///
  /// Preconditions:
  /// - bounds must be valid (southwest < northeast)
  /// - timeout must be positive duration
  ///
  /// Postconditions:
  /// - Never throws exceptions - all errors returned as ApiError
  /// - Network requests respect timeout parameter
  /// - Coordinates in logs limited to 2 decimal places for privacy (C2)
  /// - Empty results return Right([]), not Left (valid state)
  ///
  /// Example:
  /// ```dart
  /// final bounds = LatLngBounds(
  ///   southwest: LatLng(55.0, -5.0),
  ///   northeast: LatLng(59.0, -1.0),
  /// );
  /// final result = await effisService.getActiveFires(bounds);
  ///
  /// result.fold(
  ///   (error) => print('Error: ${error.message}'),
  ///   (fires) => print('Found ${fires.length} fires'),
  /// );
  /// ```
  Future<Either<ApiError, List<EffisFire>>> getActiveFires(
    LatLngBounds bounds, {
    Duration timeout = const Duration(seconds: 8),
  });
}