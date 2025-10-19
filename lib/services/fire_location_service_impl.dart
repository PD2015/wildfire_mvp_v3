import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/mock_fire_service.dart';
import 'package:wildfire_mvp_v3/services/utils/geo_utils.dart';

/// FireLocationService implementation with 3-tier fallback
///
/// Tier 1: EFFIS WFS (skipped in MVP - would need new WFS endpoint)
/// Tier 2: Cache (6h TTL)
/// Tier 3: Mock (never fails)
///
/// Note: SEPA integration requires separate service implementation (future work)
class FireLocationServiceImpl implements FireLocationService {
  final MockFireService _mockService;

  FireLocationServiceImpl({
    MockFireService? mockService,
  }) : _mockService = mockService ?? MockFireService();

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    // Feature flag check: Skip to mock if MAP_LIVE_DATA=false
    if (!FeatureFlags.mapLiveData) {
      return await _mockService.getActiveFires(bounds);
    }

    // MVP: Direct to mock service
    // TODO: T016 - Add EFFIS WFS tier
    // TODO: T018 - Add Cache tier
    // For now, just use mock
    final mockResult = await _mockService.getActiveFires(bounds);

    return mockResult.fold(
      (error) => Left(error),
      (incidents) {
        // Log redacted coordinates (C2 compliance)
        final center = bounds.center;
        print(
            'FireLocationService: Fetched ${incidents.length} incidents for ${GeographicUtils.logRedact(center.latitude, center.longitude)}');
        return Right(incidents);
      },
    );
  }
}
