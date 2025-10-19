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

  FireIncident({
    required this.id,
    required this.location,
    required this.source,
    required this.freshness,
    required this.timestamp,
    required this.intensity,
    this.description,
    this.areaHectares,
  }) {
    _validate();
  }

  /// Validation rules per data-model.md
  void _validate() {
    if (id.isEmpty) {
      throw ArgumentError('FireIncident id must be non-empty');
    }
    if (!location.isValid) {
      throw ArgumentError('FireIncident location must have valid coordinates');
    }
    if (timestamp.isAfter(DateTime.now())) {
      throw ArgumentError('FireIncident timestamp must not be in the future');
    }
    if (!['low', 'moderate', 'high'].contains(intensity)) {
      throw ArgumentError(
          'FireIncident intensity must be "low", "moderate", or "high"');
    }
    if (areaHectares != null && areaHectares! <= 0) {
      throw ArgumentError('FireIncident areaHectares must be > 0');
    }
  }

  /// Parse EFFIS WFS GeoJSON Feature or Mock data
  factory FireIncident.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;

    // EFFIS WFS uses [lon, lat] order in GeoJSON
    final lon = (coordinates[0] as num).toDouble();
    final lat = (coordinates[1] as num).toDouble();

    // Parse intensity - prefer explicit intensity field, fallback to area calculation
    String intensity;
    if (properties.containsKey('intensity')) {
      // Mock data has explicit intensity field
      intensity = properties['intensity'] as String;
    } else {
      // EFFIS data - calculate from area_ha
      final areaHa = properties['area_ha'] as num?;
      if (areaHa != null) {
        if (areaHa < 10) {
          intensity = 'low';
        } else if (areaHa < 30) {
          intensity = 'moderate';
        } else {
          intensity = 'high';
        }
      } else {
        intensity = 'moderate'; // Default if no area data
      }
    }

    // Parse area - support both EFFIS (area_ha) and Mock (areaHectares) formats
    final areaHa = properties['area_ha'] as num? ?? 
                   properties['areaHectares'] as num?;

    return FireIncident(
      id: json['id']?.toString() ?? properties['fid']?.toString() ?? 'unknown',
      location: LatLng(lat, lon),
      source: DataSource.effis, // Will be overridden by service layer
      freshness: Freshness.live,
      timestamp: DateTime.parse(
        properties['timestamp']?.toString() ??
            properties['lastupdate']?.toString() ??
            properties['firedate']?.toString() ??
            DateTime.now().toIso8601String(),
      ),
      intensity: intensity,
      description: properties['description']?.toString() ?? 
                   properties['country']?.toString(),
      areaHectares: areaHa?.toDouble(),
    );
  }

  /// Serialize for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'source': source.toString().split('.').last,
      'freshness': freshness.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'intensity': intensity,
      'description': description,
      'areaHectares': areaHectares,
    };
  }

  /// Create a copy with updated fields
  FireIncident copyWith({
    String? id,
    LatLng? location,
    DataSource? source,
    Freshness? freshness,
    DateTime? timestamp,
    String? intensity,
    String? description,
    double? areaHectares,
  }) {
    return FireIncident(
      id: id ?? this.id,
      location: location ?? this.location,
      source: source ?? this.source,
      freshness: freshness ?? this.freshness,
      timestamp: timestamp ?? this.timestamp,
      intensity: intensity ?? this.intensity,
      description: description ?? this.description,
      areaHectares: areaHectares ?? this.areaHectares,
    );
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
