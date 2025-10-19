import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// Fire incident data model for map markers
/// 
/// Represents active fire or burnt area incident from EFFIS WFS,
/// SEPA, Cache, or Mock sources.
/// 
/// Implementation: TBD in T009
class FireIncident extends Equatable {
  final String id;
  final LatLng location;
  final DataSource source;
  final Freshness freshness;
  final DateTime timestamp;
  final String intensity; // "low" | "moderate" | "high"
  final String? description;
  final double? areaHectares;

  const FireIncident({
    required this.id,
    required this.location,
    required this.source,
    required this.freshness,
    required this.timestamp,
    required this.intensity,
    this.description,
    this.areaHectares,
  });

  /// TODO: T009 - Implement fromJson for EFFIS WFS GeoJSON parsing
  factory FireIncident.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('TBD in T009');
  }

  /// TODO: T009 - Implement toJson for caching
  Map<String, dynamic> toJson() {
    throw UnimplementedError('TBD in T009');
  }

  @override
  List<Object?> get props => [
        id,
        location,
        source,
        freshness,
        timestamp,
        intensity,
        description,
        areaHectares,
      ];
}
