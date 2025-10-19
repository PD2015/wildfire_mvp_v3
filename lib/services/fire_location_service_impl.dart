import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/mock_fire_service.dart';
import 'package:wildfire_mvp_v3/services/effis_service.dart';
import 'package:wildfire_mvp_v3/services/utils/geo_utils.dart';
import 'dart:developer' as developer;

/// FireLocationService implementation with 2-tier fallback (MVP)
///
/// Tier 1: EFFIS WFS (8s timeout, GeoJSON bbox queries)
/// Tier 2: Mock (never fails)
///
/// Future tiers (T017-T018):
/// - SEPA (Scotland-only, 2s timeout)
/// - Cache (6h TTL, 200ms timeout)
class FireLocationServiceImpl implements FireLocationService {
  final EffisService _effisService;
  final MockFireService _mockService;

  FireLocationServiceImpl({
    required EffisService effisService,
    MockFireService? mockService,
  })  : _effisService = effisService,
        _mockService = mockService ?? MockFireService();

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    final center = bounds.center;
    developer.log(
      'FireLocationService: Starting fallback chain for bbox center ${GeographicUtils.logRedact(center.latitude, center.longitude)}',
      name: 'FireLocationService',
    );

    // Feature flag check: Skip to mock if MAP_LIVE_DATA=false
    if (!FeatureFlags.mapLiveData) {
      developer.log(
        'MAP_LIVE_DATA=false - using mock data',
        name: 'FireLocationService',
      );
      return await _mockService.getActiveFires(bounds);
    }

    // Tier 1: EFFIS WFS (8s timeout)
    developer.log(
      'Tier 1: Attempting EFFIS WFS for bbox ${bounds.toBboxString()}',
      name: 'FireLocationService',
    );

    final effisResult = await _effisService.getActiveFires(
      bounds,
      timeout: const Duration(seconds: 8),
    );

    final Either<ApiError, List<FireIncident>>? tierResult =
        effisResult.fold<Either<ApiError, List<FireIncident>>?>(
      (error) {
        developer.log(
          'Tier 1 (EFFIS WFS) failed: ${error.message}',
          name: 'FireLocationService',
          level: 900, // Warning
        );
        return null; // Signal to try next tier
      },
      (effisFires) {
        // Convert EffisFire → FireIncident
        final incidents =
            effisFires.map((fire) => fire.toFireIncident()).toList();

        developer.log(
          'Tier 1 (EFFIS WFS) success: ${incidents.length} fires',
          name: 'FireLocationService',
        );

        return Right(incidents);
      },
    );

    // If EFFIS succeeded, return result
    if (tierResult != null) {
      return tierResult;
    }

    // Tier 2: Mock (never fails)
    developer.log(
      'Tier 2: Falling back to Mock service',
      name: 'FireLocationService',
      level: 900,
    );

    final mockResult = await _mockService.getActiveFires(bounds);

    return mockResult.fold(
      (error) {
        // This should never happen (mock never fails)
        developer.log(
          'Tier 2 (Mock) unexpected failure: ${error.message}',
          name: 'FireLocationService',
          level: 1000, // Error
        );
        return Left(error);
      },
      (incidents) {
        developer.log(
          'Tier 2 (Mock) success: ${incidents.length} fires',
          name: 'FireLocationService',
        );
        return Right(incidents);
      },
    );
  }
}
