import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/mock_fire_service.dart';
import 'package:wildfire_mvp_v3/services/effis_service.dart';
import 'package:wildfire_mvp_v3/services/fire_incident_cache.dart';
import 'package:wildfire_mvp_v3/services/utils/geo_utils.dart';
import 'package:wildfire_mvp_v3/utils/geohash_utils.dart';
import 'dart:developer' as developer;

/// FireLocationService implementation with 3-tier fallback (T018)
///
/// Tier 1: EFFIS WFS (8s timeout, GeoJSON bbox queries)
/// Tier 2: Cache (6h TTL, 200ms timeout, geohash keys)
/// Tier 3: Mock (never fails)
///
/// Cache integration (T018):
/// - Cache key: geohash of bbox center (precision 5 = ~4.9km)
/// - TTL: 6 hours for fire incident data freshness
/// - Capacity: 100 entries with LRU eviction
/// - Freshness: Cached incidents marked with Freshness.cached
class FireLocationServiceImpl implements FireLocationService {
  final EffisService _effisService;
  final FireIncidentCache? _cache;
  final MockFireService _mockService;

  FireLocationServiceImpl({
    required EffisService effisService,
    FireIncidentCache? cache,
    MockFireService? mockService,
  })  : _effisService = effisService,
        _cache = cache,
        _mockService = mockService ?? MockFireService();

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    final center = bounds.center;
    debugPrint(
      '🔥 FireLocationService: Starting fallback chain for bbox center ${GeographicUtils.logRedact(center.latitude, center.longitude)}',
    );
    developer.log(
      'FireLocationService: Starting fallback chain for bbox center ${GeographicUtils.logRedact(center.latitude, center.longitude)}',
      name: 'FireLocationService',
    );

    // Generate cache key from bbox center
    final geohash = GeohashUtils.encode(
      center.latitude,
      center.longitude,
      precision: 5,
    );

    // Feature flag check: Skip to mock if MAP_LIVE_DATA=false
    if (!FeatureFlags.mapLiveData) {
      debugPrint('🔥 MAP_LIVE_DATA=false - using mock data');
      developer.log(
        'MAP_LIVE_DATA=false - using mock data',
        name: 'FireLocationService',
      );
      return await _mockService.getActiveFires(bounds);
    }

    // Tier 1: EFFIS WFS (8s timeout)
    debugPrint(
        '🔥 Tier 1: Attempting EFFIS WFS for bbox ${bounds.toBboxString()}');
    developer.log(
      'Tier 1: Attempting EFFIS WFS for bbox ${bounds.toBboxString()}',
      name: 'FireLocationService',
    );

    final effisResult = await _effisService.getActiveFires(
      bounds,
      timeout: const Duration(seconds: 8),
    );

    final Either<ApiError, List<FireIncident>>? effisSuccess =
        effisResult.fold<Either<ApiError, List<FireIncident>>?>(
      (error) {
        debugPrint('🔥 Tier 1 (EFFIS WFS) failed: ${error.message}');
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

        debugPrint('🔥 Tier 1 (EFFIS WFS) success: ${incidents.length} fires');
        developer.log(
          'Tier 1 (EFFIS WFS) success: ${incidents.length} fires',
          name: 'FireLocationService',
        );

        return Right(incidents);
      },
    );

    // If EFFIS succeeded, cache the result and return
    if (effisSuccess != null) {
      if (_cache != null) {
        effisSuccess.fold(
          (_) {}, // Already handled error case
          (incidents) async {
            // Cache successful EFFIS response
            await _cache!.set(
              lat: center.latitude,
              lon: center.longitude,
              data: incidents,
            );
            debugPrint('🔥 Cached EFFIS result at geohash $geohash');
            developer.log(
              'Cached EFFIS result at geohash $geohash',
              name: 'FireLocationService',
            );
          },
        );
      }
      return effisSuccess;
    }

    // Tier 2: Cache (200ms timeout)
    if (_cache != null) {
      debugPrint('🔥 Tier 2: Attempting cache lookup for geohash $geohash');
      developer.log(
        'Tier 2: Attempting cache lookup for geohash $geohash',
        name: 'FireLocationService',
      );

      try {
        final cacheResult = await _cache!
            .get(geohash)
            .timeout(const Duration(milliseconds: 200));

        if (cacheResult.isSome()) {
          final incidents = cacheResult.getOrElse(() => []);
          debugPrint('🔥 Tier 2 (Cache) hit: ${incidents.length} cached fires');
          developer.log(
            'Tier 2 (Cache) hit: ${incidents.length} cached fires',
            name: 'FireLocationService',
          );
          return Right(incidents);
        }

        debugPrint('🔥 Tier 2 (Cache) miss');
        developer.log(
          'Tier 2 (Cache) miss',
          name: 'FireLocationService',
          level: 900,
        );
      } catch (e) {
        debugPrint('🔥 Tier 2 (Cache) timeout or error: $e');
        developer.log(
          'Tier 2 (Cache) timeout or error: $e',
          name: 'FireLocationService',
          level: 900,
        );
      }
    }

    // Tier 3: Mock (never fails)
    debugPrint('🔥 Tier 3: Falling back to Mock service');
    developer.log(
      'Tier 3: Falling back to Mock service',
      name: 'FireLocationService',
      level: 900,
    );

    final mockResult = await _mockService.getActiveFires(bounds);

    return mockResult.fold(
      (error) {
        // This should never happen (mock never fails)
        debugPrint('🔥 Tier 3 (Mock) unexpected failure: ${error.message}');
        developer.log(
          'Tier 3 (Mock) unexpected failure: ${error.message}',
          name: 'FireLocationService',
          level: 1000, // Error
        );
        return Left(error);
      },
      (incidents) {
        debugPrint('🔥 Tier 3 (Mock) success: ${incidents.length} fires');
        developer.log(
          'Tier 3 (Mock) success: ${incidents.length} fires',
          name: 'FireLocationService',
        );
        return Right(incidents);
      },
    );
  }
}
