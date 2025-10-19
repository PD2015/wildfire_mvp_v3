import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';

/// Mock fire service that loads data from assets/mock/active_fires.json
/// 
/// Never-fail fallback for development and offline testing.
/// 
/// Implementation: TBD in T012
class MockFireService implements FireLocationService {
  /// TODO: T012 - Load assets/mock/active_fires.json
  /// TODO: T012 - Parse GeoJSON to List<FireIncident>
  /// TODO: T012 - Filter by bbox if provided
  /// TODO: T012 - Always return Right (never fails)
  
  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    throw UnimplementedError('TBD in T012');
  }
}
