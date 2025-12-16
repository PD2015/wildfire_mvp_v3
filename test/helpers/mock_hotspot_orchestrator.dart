import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/services/hotspot_service_orchestrator.dart';

/// Mock HotspotServiceOrchestrator for testing.
///
/// Provides controllable responses for testing MapController behavior.
class MockHotspotOrchestrator implements HotspotServiceOrchestrator {
  /// Hotspots to return on getHotspots()
  List<Hotspot> hotspotsToReturn;

  /// Data source to report
  HotspotDataSource sourceToReturn;

  /// Error to simulate (if non-null, throws instead of returning)
  Exception? errorToThrow;

  /// Whether to simulate slow response
  Duration? responseDelay;

  /// Track number of calls
  int callCount = 0;

  /// Last bounds requested
  LatLngBounds? lastRequestedBounds;

  /// Last filter requested
  HotspotTimeFilter? lastRequestedFilter;

  MockHotspotOrchestrator({
    this.hotspotsToReturn = const [],
    this.sourceToReturn = HotspotDataSource.mock,
    this.errorToThrow,
    this.responseDelay,
  });

  @override
  Future<HotspotResult> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    callCount++;
    lastRequestedBounds = bounds;
    lastRequestedFilter = timeFilter;

    if (responseDelay != null) {
      await Future.delayed(responseDelay!);
    }

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    return HotspotResult(
      hotspots: hotspotsToReturn,
      source: sourceToReturn,
    );
  }

  @override
  bool get hasLiveService => sourceToReturn != HotspotDataSource.mock;

  @override
  List<String> get availableServices {
    final services = <String>[];
    if (sourceToReturn == HotspotDataSource.firms) {
      services.add('NASA FIRMS');
    }
    if (sourceToReturn == HotspotDataSource.gwis) {
      services.add('GWIS WMS');
    }
    services.add('Mock');
    return services;
  }

  /// Reset state between tests
  void reset() {
    callCount = 0;
    lastRequestedBounds = null;
    lastRequestedFilter = null;
    errorToThrow = null;
  }
}
