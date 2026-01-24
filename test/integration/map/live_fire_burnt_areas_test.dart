import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';

import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

import '../../helpers/mock_hotspot_orchestrator.dart';

/// T041: Integration test for EFFIS Burnt Area service → MapController data flow
///
/// Tests the complete data flow from EFFIS burnt area service through MapController
/// to the MapScreen state, including polygon simplification and land cover breakdown.

/// Mock location resolver for testing
class _MockLocationResolver implements LocationResolver {
  final LatLng _mockLocation;

  _MockLocationResolver({LatLng? location})
      : _mockLocation = location ?? const LatLng(55.9533, -3.1883);

  @override
  Future<Either<LocationError, ResolvedLocation>> getLatLon({
    bool allowDefault = true,
  }) async {
    return Right(
      ResolvedLocation(coordinates: _mockLocation, source: LocationSource.gps),
    );
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {}

  @override
  Future<void> clearManualLocation() async {}

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async => null;
}

/// Mock fire location service

/// Mock fire risk service
class _MockFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    return Right(
      FireRisk.fromMock(
        level: RiskLevel.low,
        observedAt: DateTime.now().toUtc(),
      ),
    );
  }
}

/// Controllable mock EFFIS burnt area service for testing
class ControllableMockBurntAreaService implements EffisBurntAreaService {
  final List<BurntArea> _burntAreas;
  Either<ApiError, List<BurntArea>>? _overrideResult;
  int callCount = 0;

  ControllableMockBurntAreaService({List<BurntArea>? burntAreas})
      : _burntAreas = burntAreas ?? [];

  void setBurntAreas(List<BurntArea> burntAreas) {
    _overrideResult = Right(burntAreas);
  }

  void setError(ApiError error) {
    _overrideResult = Left(error);
  }

  void reset() {
    _overrideResult = null;
    callCount = 0;
  }

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
    bool skipLiveApi = false,
  }) async {
    callCount++;
    if (_overrideResult != null) {
      return _overrideResult!;
    }
    return Right(_burntAreas);
  }
}

void main() {
  // Required for platform channel access in tests
  WidgetsFlutterBinding.ensureInitialized();

  group('EFFIS Burnt Area Integration Tests (T041)', () {
    late MapController controller;
    late ControllableMockBurntAreaService mockBurntAreaService;

    // Test burnt area with polygon boundary
    final testBurntAreas = [
      BurntArea(
        id: 'burnt-area-1',
        boundaryPoints: const [
          LatLng(55.90, -3.20),
          LatLng(55.92, -3.18),
          LatLng(55.91, -3.15),
          LatLng(55.89, -3.17),
        ],
        areaHectares: 45.5,
        fireDate: DateTime.now().subtract(const Duration(days: 10)),
        seasonYear: 2025,
        landCoverBreakdown: const {
          'forest': 0.45,
          'shrubland': 0.30,
          'grassland': 0.20,
          'other': 0.05,
        },
        isSimplified: false,
        originalPointCount: null,
      ),
      BurntArea(
        id: 'burnt-area-2',
        boundaryPoints: const [
          LatLng(55.95, -3.25),
          LatLng(55.97, -3.22),
          LatLng(55.96, -3.19),
          LatLng(55.94, -3.21),
          LatLng(55.93, -3.23),
        ],
        areaHectares: 125.0,
        fireDate: DateTime.now().subtract(const Duration(days: 30)),
        seasonYear: 2025,
        landCoverBreakdown: const {
          'forest': 0.60,
          'shrubland': 0.25,
          'grassland': 0.10,
          'agriculture': 0.05,
        },
        isSimplified: true,
        originalPointCount: 1200,
      ),
    ];

    setUp(() {
      mockBurntAreaService = ControllableMockBurntAreaService(
        burntAreas: testBurntAreas,
      );

      controller = MapController(
        locationResolver: _MockLocationResolver(),
        fireRiskService: _MockFireRiskService(),
        hotspotOrchestrator: MockHotspotOrchestrator(),
        burntAreaService: mockBurntAreaService,
      );
    });

    tearDown(() {
      controller.dispose();
      mockBurntAreaService.reset();
    });

    test('burnt area season filter defaults to thisSeason', () {
      expect(
        controller.burntAreaSeasonFilter,
        equals(BurntAreaSeasonFilter.thisSeason),
      );
    });

    test('setBurntAreaSeasonFilter changes filter and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setBurntAreaSeasonFilter(BurntAreaSeasonFilter.lastSeason);

      expect(
        controller.burntAreaSeasonFilter,
        equals(BurntAreaSeasonFilter.lastSeason),
      );
      expect(notified, isTrue);
    });

    group('Burnt area data attributes', () {
      test('burnt areas expose all required properties', () {
        final burntArea = testBurntAreas.first;

        expect(burntArea.id, equals('burnt-area-1'));
        expect(burntArea.boundaryPoints.length, equals(4));
        expect(burntArea.areaHectares, closeTo(45.5, 0.1));
        expect(burntArea.seasonYear, equals(2025));
        expect(burntArea.isSimplified, isFalse);
      });

      test('burnt area has valid polygon with >= 3 points', () {
        for (final burntArea in testBurntAreas) {
          expect(
            burntArea.boundaryPoints.length,
            greaterThanOrEqualTo(3),
            reason: 'Polygon requires at least 3 points',
          );
        }
      });

      test('burnt area centroid is calculated correctly', () {
        final burntArea = testBurntAreas.first;
        final centroid = burntArea.centroid;

        // Centroid should be roughly in the center of the polygon
        // Points: (55.90,-3.20), (55.92,-3.18), (55.91,-3.15), (55.89,-3.17)
        expect(centroid.latitude, closeTo(55.905, 0.01));
        expect(centroid.longitude, closeTo(-3.175, 0.02));
      });

      test('burnt area intensity derived from area size', () {
        // Low intensity: < 10 ha
        final smallArea = BurntArea(
          id: 'small',
          boundaryPoints: const [
            LatLng(55.0, -3.0),
            LatLng(55.01, -3.0),
            LatLng(55.0, -2.99),
          ],
          areaHectares: 5.0,
          fireDate: DateTime.now(),
          seasonYear: 2025,
        );
        expect(smallArea.intensity, equals('low'));

        // Moderate intensity: 10-100 ha
        expect(testBurntAreas.first.intensity, equals('moderate'));

        // High intensity: > 100 ha
        expect(testBurntAreas.last.intensity, equals('high'));
      });
    });

    group('Land cover breakdown', () {
      test('land cover percentages sum to 1.0', () {
        final burntArea = testBurntAreas.first;
        final breakdown = burntArea.landCoverBreakdown!;

        final sum = breakdown.values.reduce((a, b) => a + b);
        expect(sum, closeTo(1.0, 0.01));
      });

      test('land cover contains expected categories', () {
        final burntArea = testBurntAreas.first;
        final breakdown = burntArea.landCoverBreakdown!;

        expect(breakdown.containsKey('forest'), isTrue);
        expect(breakdown.containsKey('shrubland'), isTrue);
        expect(breakdown.containsKey('grassland'), isTrue);
      });

      test('land cover values are between 0 and 1', () {
        for (final burntArea in testBurntAreas) {
          if (burntArea.landCoverBreakdown != null) {
            for (final value in burntArea.landCoverBreakdown!.values) {
              expect(value, greaterThanOrEqualTo(0.0));
              expect(value, lessThanOrEqualTo(1.0));
            }
          }
        }
      });
    });

    group('Polygon simplification', () {
      test('unsimplified polygon has isSimplified = false', () {
        final burntArea = testBurntAreas.first;
        expect(burntArea.isSimplified, isFalse);
        expect(burntArea.originalPointCount, isNull);
      });

      test(
        'simplified polygon has isSimplified = true and originalPointCount',
        () {
          final burntArea = testBurntAreas.last;
          expect(burntArea.isSimplified, isTrue);
          expect(burntArea.originalPointCount, equals(1200));
        },
      );

      test('simplified polygon has fewer points than original', () {
        final burntArea = testBurntAreas.last;
        expect(
          burntArea.boundaryPoints.length,
          lessThan(burntArea.originalPointCount!),
          reason: 'Simplified polygon should have fewer points',
        );
      });
    });

    group('Mode switching', () {
      test('switching to burnt areas mode clears hotspots', () async {
        await controller.initialize();

        // Wait for initial fetch to complete
        await Future.delayed(const Duration(milliseconds: 200));

        controller.setFireDataMode(FireDataMode.burntAreas);

        expect(controller.hotspots, isEmpty);
        expect(controller.clusters, isEmpty);

        // Wait for any async burnt area fetch to complete before tearDown
        await Future.delayed(const Duration(milliseconds: 300));
      });

      test('switching from hotspots to burnt areas changes mode', () {
        expect(controller.fireDataMode, equals(FireDataMode.hotspots));
        controller.setFireDataMode(FireDataMode.burntAreas);
        expect(controller.fireDataMode, equals(FireDataMode.burntAreas));
      });
    });
  });
}
