import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/burnt_area.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';

/// Abstract interface for EFFIS Burnt Area Service
///
/// Provides contract for retrieving burnt area polygons from EFFIS WFS
/// (Web Feature Service) MODIS burnt areas layer.
///
/// Part of 021-live-fire-data feature implementation.
abstract class EffisBurntAreaService {
  /// Retrieves burnt area polygons from EFFIS WFS for given viewport and season
  ///
  /// Returns Either<ApiError, List<BurntArea>> where:
  /// - Left: Structured error for all failure cases
  /// - Right: List of burnt area polygons from MODIS detections
  ///
  /// Parameters:
  /// - [bounds]: Geographic bounding box to query for burnt areas
  /// - [seasonFilter]: Season filter (thisSeason or lastSeason)
  /// - [timeout]: Request timeout duration (default: 10 seconds for larger polygons)
  /// - [maxRetries]: Maximum retry attempts for retriable errors (default: 3)
  ///
  /// EFFIS WFS Query:
  /// - Layer: modis.ba.poly
  /// - Filter: year = seasonFilter.year
  /// - Output: GeoJSON format
  ///
  /// Polygon Simplification:
  /// - Douglas-Peucker algorithm applied for polygons > 500 points
  /// - Tolerance: ~100m at 56°N latitude
  /// - isSimplified flag set to true when simplification applied
  /// - originalPointCount preserved for reference
  ///
  /// Retry Logic:
  /// - Retries on: 408, 503, 504 (timeout and service unavailable)
  /// - No retries on: 400, 404 (client errors)
  ///
  /// Privacy:
  /// - All coordinate logging limited to 2 decimal places (C2 compliance)
  ///
  /// Response Size Management:
  /// - maxFeatures parameter limits WFS response to prevent mobile network timeouts
  /// - Recommended: 100 for overview zooms, null for detailed zooms
  /// - Response scales ~4KB per feature (polygon GML data)
  ///
  /// Example:
  /// ```dart
  /// final service = EffisBurntAreaServiceImpl(httpClient: http.Client());
  /// final result = await service.getBurntAreas(
  ///   bounds: LatLngBounds(
  ///     southwest: LatLng(54.5, -8.0),
  ///     northeast: LatLng(61.0, 0.0),
  ///   ),
  ///   seasonFilter: BurntAreaSeasonFilter.thisSeason,
  ///   maxFeatures: 100, // Limit for mobile reliability
  /// );
  ///
  /// result.fold(
  ///   (error) => print('Error: ${error.message}'),
  ///   (burntAreas) => print('Found ${burntAreas.length} burnt areas'),
  /// );
  /// ```
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
    bool skipLiveApi = false, // For demo mode: use cached data only
  });
}
