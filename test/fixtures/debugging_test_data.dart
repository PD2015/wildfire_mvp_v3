import 'package:equatable/equatable.dart';

/// Test data fixtures for debugging scenarios
class DebuggingTestData {
  
  /// GPS bypass test scenarios
  static final gpsBypassScenarios = [
    GpsBypassScenario(
      scenarioId: 'gps_bypass_active_aviemore',
      description: 'GPS bypass returns Aviemore coordinates',
      expectedLat: 57.2,
      expectedLon: -3.8,
      shouldCallGps: false,
      debugLogShouldContain: 'GPS bypassed for debugging',
    ),
    GpsBypassScenario(
      scenarioId: 'gps_bypass_fallback_error',
      description: 'GPS bypass error recovery to Scotland centroid',
      expectedLat: 55.8642,
      expectedLon: -4.2518,
      shouldCallGps: false,
      debugLogShouldContain: 'GPS bypass configuration invalid',
    ),
  ];

  /// Cache clearing test scenarios
  static final cacheClearingScenarios = [
    CacheClearingScenario(
      scenarioId: 'complete_cache_clearing',
      description: 'All 5 SharedPreferences keys cleared',
      keysToClear: [
        'manual_location_lat',
        'manual_location_lon',
        'manual_location_place',
        'location_timestamp',
        'location_source',
      ],
      keysToPreserve: ['test_mode'],
      expectedClearedCount: 5,
    ),
    CacheClearingScenario(
      scenarioId: 'cache_clearing_with_error',
      description: 'Cache clearing with SharedPreferences error handling',
      keysToClear: [
        'manual_location_lat',
        'manual_location_lon',
        'manual_location_place',
        'location_timestamp',
        'location_source',
      ],
      keysToPreserve: ['test_mode'],
      expectedClearedCount: 4, // One key fails
      simulateError: true,
      errorKey: 'manual_location_place',
    ),
  ];

  /// Integration test scenarios
  static final integrationScenarios = [
    IntegrationScenario(
      scenarioId: 'gps_bypass_to_fire_risk_service',
      description: 'GPS bypass coordinates work with FireRiskService',
      gpsBypassLat: 57.2,
      gpsBypassLon: -3.8,
      expectedFireRiskResult: true,
      expectedScotlandBoundary: true,
    ),
    IntegrationScenario(
      scenarioId: 'cache_clearing_to_location_resolver',
      description: 'Cache clearing integrates with LocationResolver fallback',
      cacheClearingEnabled: true,
      expectedFallbackToGps: true,
      expectedFallbackToCentroid: true,
    ),
  ];

  /// Production restoration test scenarios
  static final restorationScenarios = [
    RestorationScenario(
      scenarioId: 'gps_bypass_removal',
      description: 'GPS bypass can be cleanly removed',
      modificationType: 'gps_bypass',
      filePath: 'lib/services/location_resolver_impl.dart',
      canBeRestored: true,
      restorationSteps: [
        'Remove GPS bypass logic',
        'Restore normal GPS service calls',
        'Remove debugging coordinate constants',
      ],
    ),
    RestorationScenario(
      scenarioId: 'scotland_centroid_restoration',
      description: 'Scotland centroid restored to production coordinates',
      modificationType: 'coordinate_change',
      filePath: 'lib/services/location_resolver_impl.dart',
      canBeRestored: true,
      restorationSteps: [
        'Change Aviemore coordinates (57.2, -3.8) back to Scotland centroid (55.8642, -4.2518)',
        'Validate geographic calculations use production centroid',
      ],
    ),
  ];
}

/// GPS bypass test scenario data
class GpsBypassScenario extends Equatable {
  final String scenarioId;
  final String description;
  final double expectedLat;
  final double expectedLon;
  final bool shouldCallGps;
  final String debugLogShouldContain;

  const GpsBypassScenario({
    required this.scenarioId,
    required this.description,
    required this.expectedLat,
    required this.expectedLon,
    required this.shouldCallGps,
    required this.debugLogShouldContain,
  });

  @override
  List<Object?> get props => [
    scenarioId,
    description,
    expectedLat,
    expectedLon,
    shouldCallGps,
    debugLogShouldContain,
  ];
}

/// Cache clearing test scenario data
class CacheClearingScenario extends Equatable {
  final String scenarioId;
  final String description;
  final List<String> keysToClear;
  final List<String> keysToPreserve;
  final int expectedClearedCount;
  final bool simulateError;
  final String? errorKey;

  const CacheClearingScenario({
    required this.scenarioId,
    required this.description,
    required this.keysToClear,
    required this.keysToPreserve,
    required this.expectedClearedCount,
    this.simulateError = false,
    this.errorKey,
  });

  @override
  List<Object?> get props => [
    scenarioId,
    description,
    keysToClear,
    keysToPreserve,
    expectedClearedCount,
    simulateError,
    errorKey,
  ];
}

/// Integration test scenario data
class IntegrationScenario extends Equatable {
  final String scenarioId;
  final String description;
  final double? gpsBypassLat;
  final double? gpsBypassLon;
  final bool? expectedFireRiskResult;
  final bool? expectedScotlandBoundary;
  final bool? cacheClearingEnabled;
  final bool? expectedFallbackToGps;
  final bool? expectedFallbackToCentroid;

  const IntegrationScenario({
    required this.scenarioId,
    required this.description,
    this.gpsBypassLat,
    this.gpsBypassLon,
    this.expectedFireRiskResult,
    this.expectedScotlandBoundary,
    this.cacheClearingEnabled,
    this.expectedFallbackToGps,
    this.expectedFallbackToCentroid,
  });

  @override
  List<Object?> get props => [
    scenarioId,
    description,
    gpsBypassLat,
    gpsBypassLon,
    expectedFireRiskResult,
    expectedScotlandBoundary,
    cacheClearingEnabled,
    expectedFallbackToGps,
    expectedFallbackToCentroid,
  ];
}

/// Production restoration test scenario data
class RestorationScenario extends Equatable {
  final String scenarioId;
  final String description;
  final String modificationType;
  final String filePath;
  final bool canBeRestored;
  final List<String> restorationSteps;

  const RestorationScenario({
    required this.scenarioId,
    required this.description,
    required this.modificationType,
    required this.filePath,
    required this.canBeRestored,
    required this.restorationSteps,
  });

  @override
  List<Object?> get props => [
    scenarioId,
    description,
    modificationType,
    filePath,
    canBeRestored,
    restorationSteps,
  ];
}