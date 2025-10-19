import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';

/// Fire location service interface for active fire data
/// 
/// Orchestrates 4-tier fallback: EFFIS WFS → SEPA → Cache → Mock
/// 
/// Implementation: TBD in T012
abstract class FireLocationService {
  /// Get active fires within bounding box
  /// 
  /// Returns Either<ApiError, List<FireIncident>>
  /// 
  /// Fallback chain:
  /// 1. EFFIS WFS (8s timeout)
  /// 2. SEPA (Scotland only, 8s timeout)
  /// 3. Cache (200ms timeout)
  /// 4. Mock (never fails)
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  );
}
