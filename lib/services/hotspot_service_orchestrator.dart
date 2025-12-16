import 'dart:developer' as developer;

import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';
import 'hotspot_service.dart';

/// Data source attribution for UI display
enum HotspotDataSource {
  /// NASA FIRMS (primary, fastest)
  firms('NASA FIRMS'),

  /// GWIS WMS (fallback, same underlying data)
  gwis('GWIS'),

  /// Mock data (offline fallback)
  mock('Demo');

  final String displayName;
  const HotspotDataSource(this.displayName);
}

/// Result from hotspot service orchestrator including data source attribution
class HotspotResult {
  /// List of hotspots (may be empty)
  final List<Hotspot> hotspots;

  /// Which service provided the data
  final HotspotDataSource source;

  /// Whether this is fallback/mock data
  bool get isMockData => source == HotspotDataSource.mock;

  /// Whether data is from a live service
  bool get isLiveData =>
      source == HotspotDataSource.firms || source == HotspotDataSource.gwis;

  const HotspotResult({
    required this.hotspots,
    required this.source,
  });
}

/// Orchestrates hotspot data fetching with automatic fallback chain.
///
/// Fallback order:
/// 1. **FIRMS** (primary) - NASA FIRMS REST API, fastest (~2s rural)
/// 2. **GWIS WMS** (fallback) - Same underlying data, slower (~5s rural, 9 queries)
/// 3. **Mock** (offline) - Static demo data for offline/failure scenarios
///
/// ## Usage
///
/// ```dart
/// final orchestrator = HotspotServiceOrchestrator(
///   firmsService: FirmsHotspotService(...),
///   gwisService: GwisWmsHotspotService(...),
///   mockService: MockHotspotService(...),
/// );
///
/// final result = await orchestrator.getHotspots(
///   bounds: viewportBounds,
///   timeFilter: HotspotTimeFilter.today,
/// );
///
/// // Check source for UI display
/// if (result.isMockData) {
///   showDemoDataChip();
/// }
/// ```
///
/// Part of 021-live-fire-data feature implementation.
class HotspotServiceOrchestrator {
  final HotspotService? _firmsService;
  final HotspotService? _gwisService;
  final HotspotService _mockService;

  /// Creates orchestrator with service instances
  ///
  /// [firmsService] - Primary service (NASA FIRMS). Optional if no API key.
  /// [gwisService] - Secondary service (GWIS WMS). Optional.
  /// [mockService] - Required fallback for offline scenarios.
  HotspotServiceOrchestrator({
    HotspotService? firmsService,
    HotspotService? gwisService,
    required HotspotService mockService,
  })  : _firmsService = firmsService,
        _gwisService = gwisService,
        _mockService = mockService;

  /// Fetch hotspots with automatic fallback
  ///
  /// Tries services in order: FIRMS → GWIS WMS → Mock
  /// Returns first successful result with source attribution.
  Future<HotspotResult> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final errors = <String>[];

    // Tier 1: Try FIRMS (if available)
    if (_firmsService != null) {
      developer.log(
        'HotspotOrchestrator: Attempting ${_firmsService!.serviceName}',
        name: 'HotspotOrchestrator',
      );

      final result = await _firmsService!.getHotspots(
        bounds: bounds,
        timeFilter: timeFilter,
        timeout: timeout,
      );

      if (result.isRight()) {
        final hotspots = result.getOrElse(() => []);
        developer.log(
          'HotspotOrchestrator: ${_firmsService!.serviceName} returned ${hotspots.length} hotspots',
          name: 'HotspotOrchestrator',
        );
        return HotspotResult(
          hotspots: hotspots,
          source: HotspotDataSource.firms,
        );
      }

      // Log error and continue to fallback
      final error = result.fold((l) => l.message, (_) => 'Unknown error');
      errors.add('${_firmsService!.serviceName}: $error');
      developer.log(
        'HotspotOrchestrator: ${_firmsService!.serviceName} failed: $error',
        name: 'HotspotOrchestrator',
      );
    }

    // Tier 2: Try GWIS WMS (if available)
    if (_gwisService != null) {
      developer.log(
        'HotspotOrchestrator: Attempting ${_gwisService!.serviceName}',
        name: 'HotspotOrchestrator',
      );

      final result = await _gwisService!.getHotspots(
        bounds: bounds,
        timeFilter: timeFilter,
        timeout: timeout,
      );

      if (result.isRight()) {
        final hotspots = result.getOrElse(() => []);
        developer.log(
          'HotspotOrchestrator: ${_gwisService!.serviceName} returned ${hotspots.length} hotspots',
          name: 'HotspotOrchestrator',
        );
        return HotspotResult(
          hotspots: hotspots,
          source: HotspotDataSource.gwis,
        );
      }

      // Log error and continue to fallback
      final error = result.fold((l) => l.message, (_) => 'Unknown error');
      errors.add('${_gwisService!.serviceName}: $error');
      developer.log(
        'HotspotOrchestrator: ${_gwisService!.serviceName} failed: $error',
        name: 'HotspotOrchestrator',
      );
    }

    // Tier 3: Mock fallback (always available)
    developer.log(
      'HotspotOrchestrator: All live services failed, using mock data. '
      'Errors: ${errors.join("; ")}',
      name: 'HotspotOrchestrator',
    );

    final result = await _mockService.getHotspots(
      bounds: bounds,
      timeFilter: timeFilter,
      timeout: timeout,
    );

    final hotspots = result.getOrElse(() => []);
    return HotspotResult(
      hotspots: hotspots,
      source: HotspotDataSource.mock,
    );
  }

  /// Check if any live service is available
  bool get hasLiveService => _firmsService != null || _gwisService != null;

  /// Get list of available services for debugging
  List<String> get availableServices {
    final services = <String>[];
    if (_firmsService != null) services.add(_firmsService!.serviceName);
    if (_gwisService != null) services.add(_gwisService!.serviceName);
    services.add(_mockService.serviceName);
    return services;
  }
}
