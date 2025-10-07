import 'package:equatable/equatable.dart';

/// Fire risk levels
enum FireRiskLevel {
  low,
  moderate,
  high,
  veryHigh,
  extreme,
}

/// Data freshness indicator
enum Freshness {
  fresh,    // Real-time from service
  cached,   // From local cache
  stale,    // Old cached data
  mock,     // Mock/fallback data
}

/// Fire risk assessment result
class FireRisk extends Equatable {
  final FireRiskLevel level;
  final double? fwiValue;
  final String source;
  final Freshness freshness;
  final DateTime timestamp;
  final String? error;

  const FireRisk({
    required this.level,
    this.fwiValue,
    required this.source,
    required this.freshness,
    required this.timestamp,
    this.error,
  });

  factory FireRisk.mock({
    FireRiskLevel level = FireRiskLevel.moderate,
    String source = 'mock',
  }) {
    return FireRisk(
      level: level,
      fwiValue: null,
      source: source,
      freshness: Freshness.mock,
      timestamp: DateTime.now(),
    );
  }

  FireRisk copyWith({
    FireRiskLevel? level,
    double? fwiValue,
    String? source,
    Freshness? freshness,
    DateTime? timestamp,
    String? error,
  }) {
    return FireRisk(
      level: level ?? this.level,
      fwiValue: fwiValue ?? this.fwiValue,
      source: source ?? this.source,
      freshness: freshness ?? this.freshness,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [level, fwiValue, source, freshness, timestamp, error];

  @override
  String toString() => 'FireRisk($level, source: $source, freshness: $freshness)';
}
