import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';

/// Abstract interface for GWIS Hotspot Service
///
/// Provides contract for retrieving VIIRS hotspot data from GWIS
/// (Global Wildfire Information System) WMS GetFeatureInfo service.
///
/// Part of 021-live-fire-data feature implementation.
abstract class GwisHotspotService {
  /// Retrieves active fire hotspots from GWIS WMS for given viewport
  ///
  /// Returns Either<ApiError, List<Hotspot>> where:
  /// - Left: Structured error for all failure cases
  /// - Right: List of hotspots from VIIRS satellite detections
  ///
  /// Parameters:
  /// - [bounds]: Geographic bounding box to query for hotspots
  /// - [timeFilter]: Time range filter (today or thisWeek)
  /// - [timeout]: Request timeout duration (default: 8 seconds for map loads)
  /// - [maxRetries]: Maximum retry attempts for retriable errors (default: 3)
  ///
  /// GWIS WMS Layers:
  /// - HotspotTimeFilter.today → viirs.hs.today (last 24 hours)
  /// - HotspotTimeFilter.thisWeek → viirs.hs.week (last 7 days)
  ///
  /// Retry Logic:
  /// - Retries on: 408, 503, 504 (timeout and service unavailable)
  /// - No retries on: 400, 404 (client errors)
  ///
  /// Privacy:
  /// - All coordinate logging limited to 2 decimal places (C2 compliance)
  ///
  /// Example:
  /// ```dart
  /// final service = GwisHotspotServiceImpl(httpClient: http.Client());
  /// final result = await service.getHotspots(
  ///   bounds: LatLngBounds(
  ///     southwest: LatLng(54.5, -8.0),
  ///     northeast: LatLng(61.0, 0.0),
  ///   ),
  ///   timeFilter: HotspotTimeFilter.today,
  /// );
  ///
  /// result.fold(
  ///   (error) => print('Error: ${error.message}'),
  ///   (hotspots) => print('Found ${hotspots.length} hotspots'),
  /// );
  /// ```
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
    int maxRetries = 3,
  });
}
