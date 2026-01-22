import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

import '../../helpers/mock_hotspot_orchestrator.dart';

/// Mock LocationResolver for fire data mode tests
class _MockLocationResolver implements LocationResolver {
  @override
  Future<Either<LocationError, ResolvedLocation>> getLatLon({
    bool allowDefault = true,
  }) async {
    return const Right(
      ResolvedLocation(
        coordinates: LatLng(55.9533, -3.1883),
        source: LocationSource.gps,
      ),
    );
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {}

  @override
  Future<void> clearManualLocation() async {}

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async => null;
}

/// Mock FireRiskService for fire data mode tests
class _MockFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    return Right(
      FireRisk(
        level: RiskLevel.low,
        fwi: 5.0,
        source: DataSource.mock,
        observedAt: DateTime.now().toUtc(),
        freshness: Freshness.mock,
      ),
    );
  }
}

void main() {
  group('MapController Fire Data Mode', () {
    late MapController controller;
    late _MockLocationResolver mockLocationResolver;
    late _MockFireRiskService mockFireRiskService;

    setUp(() {
      mockLocationResolver = _MockLocationResolver();
      mockFireRiskService = _MockFireRiskService();

      controller = MapController(
        locationResolver: mockLocationResolver,
        fireRiskService: mockFireRiskService,
        hotspotOrchestrator: MockHotspotOrchestrator(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('initial state', () {
      test('defaults to hotspots mode', () {
        expect(controller.fireDataMode, FireDataMode.hotspots);
      });

      test('defaults to today filter for hotspots', () {
        expect(controller.hotspotTimeFilter, HotspotTimeFilter.today);
      });

      test('defaults to this season filter for burnt areas', () {
        expect(
          controller.burntAreaSeasonFilter,
          BurntAreaSeasonFilter.thisSeason,
        );
      });

      test('starts with empty hotspots list', () {
        expect(controller.hotspots, isEmpty);
      });

      test('starts with empty burnt areas list', () {
        expect(controller.burntAreas, isEmpty);
      });

      test('starts with empty clusters list', () {
        expect(controller.clusters, isEmpty);
      });

      test('isUsingMockData matches inverse of useLiveData initially', () {
        // isUsingMockData should be true when useLiveData is false (demo mode)
        // isUsingMockData should be false when useLiveData is true (live mode)
        expect(controller.isUsingMockData, !controller.useLiveData);
      });
    });

    group('setFireDataMode', () {
      test('changes mode from hotspots to burnt areas', () {
        controller.setFireDataMode(FireDataMode.burntAreas);
        expect(controller.fireDataMode, FireDataMode.burntAreas);
      });

      test('changes mode from burnt areas to hotspots', () {
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.setFireDataMode(FireDataMode.hotspots);
        expect(controller.fireDataMode, FireDataMode.hotspots);
      });

      test('notifies listeners on mode change', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setFireDataMode(FireDataMode.burntAreas);

        expect(notifyCount, 1);
      });

      test('does not notify if mode unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setFireDataMode(FireDataMode.hotspots); // Same as default

        expect(notifyCount, 0);
      });

      test('clears burnt areas when switching to hotspots', () {
        // Simulate having burnt areas
        controller.setFireDataMode(FireDataMode.burntAreas);

        // Switch back to hotspots
        controller.setFireDataMode(FireDataMode.hotspots);

        expect(controller.burntAreas, isEmpty);
      });

      test('clears hotspots and clusters when switching to burnt areas', () {
        // Switch to burnt areas (from default hotspots)
        controller.setFireDataMode(FireDataMode.burntAreas);

        expect(controller.hotspots, isEmpty);
        expect(controller.clusters, isEmpty);
      });
    });

    group('setHotspotTimeFilter', () {
      test('changes filter from today to thisWeek', () {
        controller.setHotspotTimeFilter(HotspotTimeFilter.thisWeek);
        expect(controller.hotspotTimeFilter, HotspotTimeFilter.thisWeek);
      });

      test('notifies listeners on filter change', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setHotspotTimeFilter(HotspotTimeFilter.thisWeek);

        expect(notifyCount, 1);
      });

      test('does not notify if filter unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setHotspotTimeFilter(
          HotspotTimeFilter.today,
        ); // Same as default

        expect(notifyCount, 0);
      });
    });

    group('setBurntAreaSeasonFilter', () {
      test('changes filter from thisSeason to lastSeason', () {
        controller.setBurntAreaSeasonFilter(BurntAreaSeasonFilter.lastSeason);
        expect(
          controller.burntAreaSeasonFilter,
          BurntAreaSeasonFilter.lastSeason,
        );
      });

      test('notifies listeners on filter change', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setBurntAreaSeasonFilter(BurntAreaSeasonFilter.lastSeason);

        expect(notifyCount, 1);
      });

      test('does not notify if filter unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.setBurntAreaSeasonFilter(
          BurntAreaSeasonFilter.thisSeason,
        ); // Same

        expect(notifyCount, 0);
      });
    });

    group('updateZoom and clustering', () {
      test('shouldShowClusters is true at low zoom', () {
        controller.updateZoom(8.0);
        expect(controller.shouldShowClusters, isTrue);
      });

      test('shouldShowClusters is false at high zoom', () {
        controller.updateZoom(12.0);
        expect(controller.shouldShowClusters, isFalse);
      });

      test('shouldShowClusters is false when in burnt areas mode', () {
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateZoom(8.0);
        expect(controller.shouldShowClusters, isFalse);
      });

      test('crossing zoom threshold 10 triggers recluster', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Initial update (below threshold)
        controller.updateZoom(8.0);
        final countAfterFirst = notifyCount;

        // Cross threshold (go above)
        controller.updateZoom(12.0);

        // Should have notified once more for reclustering
        expect(notifyCount, greaterThan(countAfterFirst));
      });
    });

    group('dataFreshness in demo mode', () {
      test('returns Freshness.mock when demo mode is active', () {
        // Demo mode is default when FeatureFlags.mapLiveData=false
        // Verify controller starts in demo mode
        controller.setUseLiveData(false);

        // In demo mode, dataFreshness should report mock
        expect(controller.dataFreshness, Freshness.mock);
      });

      test('returns Freshness.live when live mode is active and not offline',
          () {
        // Enable live mode
        controller.setUseLiveData(true);

        // Without any fetch failures, should report live
        expect(controller.dataFreshness, Freshness.live);
      });

      test('preserves demo mode state after mode switch to burnt areas', () {
        // Ensure demo mode
        controller.setUseLiveData(false);

        // Switch to burnt areas mode
        controller.setFireDataMode(FireDataMode.burntAreas);

        // dataFreshness should still report mock
        expect(controller.dataFreshness, Freshness.mock);
      });

      test('preserves demo mode state after mode switch to hotspots', () {
        // Ensure demo mode
        controller.setUseLiveData(false);

        // Switch to burnt areas then back to hotspots
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.setFireDataMode(FireDataMode.hotspots);

        // dataFreshness should still report mock
        expect(controller.dataFreshness, Freshness.mock);
      });

      test('useLiveData getter reflects current mode', () {
        // Start by explicitly setting to true
        controller.setUseLiveData(true);
        expect(controller.useLiveData, isTrue);

        controller.setUseLiveData(false);
        expect(controller.useLiveData, isFalse);

        controller.setUseLiveData(true);
        expect(controller.useLiveData, isTrue);
      });

      test('setUseLiveData notifies listeners when changing to different value',
          () {
        // First ensure we're in a known state
        controller.setUseLiveData(true);

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Change to different value
        controller.setUseLiveData(false);

        expect(notifyCount, greaterThanOrEqualTo(1));
      });

      test('setUseLiveData does not notify if value unchanged', () {
        // First set to false
        controller.setUseLiveData(false);

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Set to same value
        controller.setUseLiveData(false);

        expect(notifyCount, 0);
      });
    });
  });
}
