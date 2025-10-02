import 'package:equatable/equatable.dart';
import '../../models/risk_level.dart';

/// Data source for fire risk information
enum DataSource {
  effis,
  sepa,
  cache,
  mock,
}

/// Freshness indicator for fire risk data
enum Freshness {
  live,
  cached,
  mock,
}

/// Fire risk assessment with source attribution and freshness indicators
///
/// Provides normalized fire risk data from various sources with consistent
/// structure for the fallback orchestrator system.
class FireRisk extends Equatable {
  /// Risk level classification
  final RiskLevel level;

  /// Fire Weather Index value (nullable for cached/mock sources)
  final double? fwi;

  /// Data source that provided this risk assessment
  final DataSource source;

  /// UTC timestamp when the data was originally observed/generated
  final DateTime observedAt;

  /// Freshness indicator showing data recency
  final Freshness freshness;

  /// Creates a FireRisk instance
  ///
  /// [observedAt] must be in UTC timezone
  FireRisk({
    required this.level,
    this.fwi,
    required this.source,
    required this.observedAt,
    required this.freshness,
  }) {
    if (!observedAt.isUtc) {
      throw ArgumentError('observedAt must be in UTC timezone');
    }
  }

  /// Creates FireRisk from EFFIS service data
  factory FireRisk.fromEffis({
    required RiskLevel level,
    required double fwi,
    required DateTime observedAt,
  }) {
    if (!observedAt.isUtc) {
      throw ArgumentError('observedAt must be in UTC timezone');
    }

    return FireRisk(
      level: level,
      fwi: fwi,
      source: DataSource.effis,
      observedAt: observedAt,
      freshness: Freshness.live,
    );
  }

  /// Creates FireRisk from SEPA service data
  factory FireRisk.fromSepa({
    required RiskLevel level,
    double? fwi,
    required DateTime observedAt,
  }) {
    if (!observedAt.isUtc) {
      throw ArgumentError('observedAt must be in UTC timezone');
    }

    return FireRisk(
      level: level,
      fwi: fwi,
      source: DataSource.sepa,
      observedAt: observedAt,
      freshness: Freshness.live,
    );
  }

  /// Creates FireRisk from cached data
  factory FireRisk.fromCache({
    required RiskLevel level,
    double? fwi,
    required DataSource originalSource,
    required DateTime observedAt,
  }) {
    if (!observedAt.isUtc) {
      throw ArgumentError('observedAt must be in UTC timezone');
    }

    // Preserve original source but mark as cached
    return FireRisk(
      level: level,
      fwi: fwi,
      source: originalSource,
      observedAt: observedAt,
      freshness: Freshness.cached,
    );
  }

  /// Creates FireRisk from mock service (guaranteed fallback)
  factory FireRisk.fromMock({
    required RiskLevel level,
    required DateTime observedAt,
  }) {
    if (!observedAt.isUtc) {
      throw ArgumentError('observedAt must be in UTC timezone');
    }

    return FireRisk(
      level: level,
      fwi: null, // Mock service doesn't provide FWI
      source: DataSource.mock,
      observedAt: observedAt,
      freshness: Freshness.mock,
    );
  }

  @override
  List<Object?> get props => [level, fwi, source, observedAt, freshness];

  @override
  String toString() {
    return 'FireRisk{level: $level, fwi: $fwi, source: $source, '
        'observedAt: $observedAt, freshness: $freshness}';
  }
}
