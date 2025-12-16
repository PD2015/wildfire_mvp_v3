import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';

/// Abstract interface for Hotspot Services
///
/// Provides common contract for retrieving VIIRS hotspot data from
/// various sources (NASA FIRMS, GWIS WMS, Mock).
///
/// Part of 021-live-fire-data feature implementation.
abstract class HotspotService {
  /// Retrieves active fire hotspots for given viewport
  ///
  /// Returns Either<ApiError, List<Hotspot>> where:
  /// - Left: Structured error for all failure cases
  /// - Right: List of hotspots from VIIRS satellite detections
  ///
  /// Parameters:
  /// - [bounds]: Geographic bounding box to query for hotspots
  /// - [timeFilter]: Time range filter (today or thisWeek)
  /// - [timeout]: Request timeout duration (default: 8 seconds)
  ///
  /// Implementations:
  /// - FirmsHotspotService: NASA FIRMS REST API (primary, fast)
  /// - GwisWmsHotspotService: GWIS WMS GetFeatureInfo (fallback, filtered)
  /// - MockHotspotService: Local mock data (offline)
  ///
  /// Privacy:
  /// - All coordinate logging limited to 2 decimal places (C2 compliance)
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
  });

  /// Service name for logging and attribution
  String get serviceName;
}
