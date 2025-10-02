import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/effis_fwi_result.dart';

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
}