import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';

import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';

import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/gwis_hotspot_service.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// T040: Integration test for GWIS Hotspot service → MapController data flow
///
/// Tests the complete data flow from GWIS service through MapController
/// to the MapScreen state, including mode toggling and zoom-based clustering.

/// Mock location resolver for testing
class _MockLocationResolver implements LocationResolver {
  final LatLng _mockLocation;

  _MockLocationResolver({
    LatLng? location,
  }) : _mockLocation = location ?? const LatLng(55.9533, -3.1883);

  @override
  Future<Either<LocationError, ResolvedLocation>> getLatLon({
    bool allowDefault = true,
  }) async {
    return Right(ResolvedLocation(
      coordinates: _mockLocation,
      source: LocationSource.gps,
    ));
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {}

  @override
  Future<void> clearManualLocation() async {}

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async => null;
}

/// Mock fire location service (basic incident support)

/// Mock fire risk service
class _MockFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    return Right(FireRisk.fromMock(
      level: RiskLevel.low,
      observedAt: DateTime.now().toUtc(),
    ));
  }
}

/// Controllable mock GWIS hotspot service for testing
class ControllableMockGwisService implements GwisHotspotService {
  final List<Hotspot> _hotspots;
  Either<ApiError, List<Hotspot>>? _overrideResult;
  int callCount = 0;

  ControllableMockGwisService({
    List<Hotspot>? hotspots,
  }) : _hotspots = hotspots ?? [];

  void setHotspots(List<Hotspot> hotspots) {
    _overrideResult = Right(hotspots);
  }

  void setError(ApiError error) {
    _overrideResult = Left(error);
  }

  void reset() {
    _overrideResult = null;
    callCount = 0;
  }

  @override
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
    int maxRetries = 3,
  }) async {
    callCount++;
    if (_overrideResult != null) {
      return _overrideResult!;
    }
    return Right(_hotspots);
  }
}

/// Mock burnt area service (not used in hotspot tests)
class _MockBurntAreaService implements EffisBurntAreaService {
  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
  }) async {
    return const Right([]);
  }
}

void main() {
  // Required for platform channel access in tests
  WidgetsFlutterBinding.ensureInitialized();

  group('GWIS Hotspot Integration Tests (T040)', () {
    late MapController controller;
    late ControllableMockGwisService mockGwisService;
    late _MockBurntAreaService mockBurntAreaService;

    final testHotspots = [
      Hotspot(
        id: 'hotspot-1',
        location: const LatLng(55.95, -3.18),
        detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
        confidence: 95.0,
        frp: 25.5,
      ),
      Hotspot(
        id: 'hotspot-2',
        location: const LatLng(55.96, -3.17),
        detectedAt: DateTime.now().subtract(const Duration(hours: 4)),
        confidence: 88.0,
        frp: 18.2,
      ),
      Hotspot(
        id: 'hotspot-3',
        location: const LatLng(55.94, -3.19),
        detectedAt: DateTime.now().subtract(const Duration(hours: 6)),
        confidence: 75.0,
        frp: 12.0,
      ),
    ];

    setUp(() {
      mockGwisService = ControllableMockGwisService(hotspots: testHotspots);
      mockBurntAreaService = _MockBurntAreaService();

      controller = MapController(
        locationResolver: _MockLocationResolver(),
        fireRiskService: _MockFireRiskService(),
        hotspotService: mockGwisService,
        burntAreaService: mockBurntAreaService,
      );
    });

    tearDown(() {
      controller.dispose();
      mockGwisService.reset();
    });

    test('starts in hotspots mode by default', () {
      expect(controller.fireDataMode, equals(FireDataMode.hotspots));
    });

    test('setFireDataMode switches to burnt areas mode', () {
      controller.setFireDataMode(FireDataMode.burntAreas);
      expect(controller.fireDataMode, equals(FireDataMode.burntAreas));
    });

    test('setFireDataMode switches back to hotspots mode', () {
      controller.setFireDataMode(FireDataMode.burntAreas);
      controller.setFireDataMode(FireDataMode.hotspots);
      expect(controller.fireDataMode, equals(FireDataMode.hotspots));
    });

    test('hotspot time filter defaults to today', () {
      expect(controller.hotspotTimeFilter, equals(HotspotTimeFilter.today));
    });

    test('setHotspotTimeFilter changes filter and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setHotspotTimeFilter(HotspotTimeFilter.thisWeek);

      expect(controller.hotspotTimeFilter, equals(HotspotTimeFilter.thisWeek));
      expect(notified, isTrue);
    });

    group('Zoom-based clustering', () {
      test('shouldShowClusters is true when zoom < 10 in hotspots mode', () {
        controller.updateZoom(8.0);
        expect(controller.shouldShowClusters, isTrue);
      });

      test('shouldShowClusters is false when zoom >= 10 in hotspots mode', () {
        controller.updateZoom(10.0);
        expect(controller.shouldShowClusters, isFalse);
      });

      test('shouldShowClusters is false in burnt areas mode', () {
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateZoom(8.0); // Low zoom, but wrong mode
        expect(controller.shouldShowClusters, isFalse);
      });

      test('crossing zoom threshold triggers notification', () {
        controller.updateZoom(8.0); // Below threshold

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Cross from below to above threshold
        controller.updateZoom(10.0);
        expect(notifyCount, equals(1),
            reason: 'Should notify when crossing threshold');

        // Stay above threshold
        controller.updateZoom(11.0);
        expect(notifyCount, equals(1),
            reason: 'Should not notify when staying above');

        // Cross from above to below threshold
        controller.updateZoom(9.0);
        expect(notifyCount, equals(2),
            reason: 'Should notify when crossing back');
      });
    });

    group('Mode toggle clears previous data', () {
      test('switching to burnt areas clears hotspots', () async {
        // First, ensure we have hotspots
        await controller.initialize();

        // Switch mode
        controller.setFireDataMode(FireDataMode.burntAreas);

        // Hotspots should be cleared
        expect(controller.hotspots, isEmpty);
        expect(controller.clusters, isEmpty);
      });

      test('switching back to hotspots clears burnt areas', () async {
        await controller.initialize();
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.setFireDataMode(FireDataMode.hotspots);

        expect(controller.burntAreas, isEmpty);
      });
    });

    group('Hotspot data attributes', () {
      test('hotspots expose all required properties', () {
        final hotspot = testHotspots.first;

        expect(hotspot.id, equals('hotspot-1'));
        expect(hotspot.location.latitude, closeTo(55.95, 0.01));
        expect(hotspot.location.longitude, closeTo(-3.18, 0.01));
        expect(hotspot.confidence, closeTo(95.0, 0.1));
        expect(hotspot.frp, closeTo(25.5, 0.1));
      });

      test('hotspot intensity derived from FRP', () {
        // Low intensity: frp < 10
        final lowHotspot = Hotspot.test(
          location: const LatLng(55.9, -3.2),
          frp: 5.0,
        );
        expect(lowHotspot.intensity, equals('low'));

        // Moderate intensity: 10 <= frp < 50
        final modHotspot = Hotspot.test(
          location: const LatLng(55.9, -3.2),
          frp: 25.0,
        );
        expect(modHotspot.intensity, equals('moderate'));

        // High intensity: frp >= 50
        final highHotspot = Hotspot.test(
          location: const LatLng(55.9, -3.2),
          frp: 75.0,
        );
        expect(highHotspot.intensity, equals('high'));
      });
    });

    group('Hotspot cluster behavior', () {
      test('clusters can be created from hotspots', () {
        // Create a cluster from test hotspots
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster-1',
          hotspots: testHotspots,
        );

        expect(cluster.count, equals(3));
        expect(cluster.hotspots.length, equals(3));
        expect(cluster.maxFrp, closeTo(25.5, 0.1));
      });

      test('cluster centroid is calculated correctly', () {
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster-1',
          hotspots: testHotspots,
        );

        // Centroid should be average of all locations
        const expectedLat = (55.95 + 55.96 + 55.94) / 3;
        const expectedLon = (-3.18 + -3.17 + -3.19) / 3;

        expect(cluster.center.latitude, closeTo(expectedLat, 0.001));
        expect(cluster.center.longitude, closeTo(expectedLon, 0.001));
      });

      test('cluster bounds contain all hotspots', () {
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster-1',
          hotspots: testHotspots,
        );

        // Check bounds contain all points (using larger tolerance for floating point)
        expect(cluster.bounds.southwest.latitude, closeTo(55.94, 0.01));
        expect(cluster.bounds.northeast.latitude, closeTo(55.96, 0.01));
        expect(cluster.bounds.southwest.longitude, closeTo(-3.19, 0.01));
        expect(cluster.bounds.northeast.longitude, closeTo(-3.17, 0.01));
      });

      test('cluster intensity based on max FRP', () {
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster-1',
          hotspots: testHotspots,
        );

        // Max FRP is 25.5 (moderate)
        expect(cluster.intensity, equals('moderate'));
      });
    });
  });
}
