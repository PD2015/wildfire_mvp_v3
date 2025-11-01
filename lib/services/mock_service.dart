/// Mock fire risk service for testing and guaranteed fallback
///
/// Provides deterministic mock data for testing scenarios and serves as the
/// final fallback in the orchestration chain. Guarantees response within 100ms
/// and never fails, ensuring the never-fail promise of the orchestrator.
library mock_service;

import 'models/fire_risk.dart';
import 'utils/geo_utils.dart';
import '../models/risk_level.dart';

/// Strategy for mock data generation
abstract class MockStrategy {
  /// Generate mock fire risk data for given coordinates
  FireRisk generateRisk(double lat, double lon);

  /// Factory for fixed risk level strategy
  factory MockStrategy.fixed(RiskLevel level) => _FixedMockStrategy(level);

  /// Factory for deterministic geohash-based strategy (useful for testing)
  factory MockStrategy.deterministicFromGeohash({int precision = 5}) =>
      _GeohashMockStrategy(precision);
}

/// Mock service providing guaranteed fallback fire risk data
///
/// Designed to:
/// - Never fail or throw exceptions
/// - Always respond within 100ms
/// - Provide consistent mock data for testing
/// - Serve as final fallback in orchestration chain
///
/// Example usage:
/// ```dart
/// final mockService = MockService(MockStrategy.fixed(RiskLevel.moderate));
/// final result = await mockService.getCurrent(lat: 55.9533, lon: -3.1883);
/// // Always succeeds with mock data
/// ```
class MockService {
  final MockStrategy _strategy;

  /// Creates mock service with specified strategy
  ///
  /// [strategy] determines how mock data is generated
  const MockService(this._strategy);

  /// Creates mock service with fixed moderate risk level
  ///
  /// Default strategy for production use when all other services fail
  MockService.defaultStrategy()
    : _strategy = MockStrategy.fixed(RiskLevel.moderate);

  /// Get mock fire risk data for coordinates
  ///
  /// Always succeeds and returns mock data within 100ms.
  /// Coordinates are validated but invalid coordinates return mock data
  /// rather than throwing errors (never-fail guarantee).
  ///
  /// Returns [FireRisk] with:
  /// - source: DataSource.mock
  /// - freshness: Freshness.mock
  /// - observedAt: current UTC time
  /// - level: determined by strategy
  /// - fwi: null (mock doesn't provide FWI values)
  Future<FireRisk> getCurrent({
    required double lat,
    required double lon,
  }) async {
    // Simulate minimal processing time (but stay well under 100ms)
    await Future.delayed(const Duration(milliseconds: 10));

    // Generate mock data using strategy (never fails)
    try {
      return _strategy.generateRisk(lat, lon);
    } catch (e) {
      // Fallback to fixed moderate risk if strategy fails (never-fail guarantee)
      return FireRisk.fromMock(
        level: RiskLevel.moderate,
        observedAt: DateTime.now().toUtc(),
      );
    }
  }
}

/// Fixed risk level strategy - always returns the same risk level
class _FixedMockStrategy implements MockStrategy {
  final RiskLevel _level;

  const _FixedMockStrategy(this._level);

  @override
  FireRisk generateRisk(double lat, double lon) {
    return FireRisk.fromMock(level: _level, observedAt: DateTime.now().toUtc());
  }
}

/// Geohash-based deterministic strategy for testing
///
/// Generates consistent mock data based on location geohash,
/// useful for reproducible testing scenarios.
class _GeohashMockStrategy implements MockStrategy {
  final int _precision;

  const _GeohashMockStrategy(this._precision);

  @override
  FireRisk generateRisk(double lat, double lon) {
    try {
      // Use geohash to generate deterministic but location-specific data
      final geohash = GeographicUtils.geohash(lat, lon, precision: _precision);
      final hashCode = geohash.hashCode.abs();

      // Map hash to risk level deterministically
      const riskLevels = RiskLevel.values;
      final riskIndex = hashCode % riskLevels.length;
      final level = riskLevels[riskIndex];

      return FireRisk.fromMock(
        level: level,
        observedAt: DateTime.now().toUtc(),
      );
    } catch (e) {
      // Fallback if geohash generation fails
      return FireRisk.fromMock(
        level: RiskLevel.moderate,
        observedAt: DateTime.now().toUtc(),
      );
    }
  }
}
