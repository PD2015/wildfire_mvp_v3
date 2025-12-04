import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// Fire incident data model for map markers and polygon overlays
///
/// Represents active fire or burnt area incident from EFFIS WFS,
/// SEPA, Cache, or Mock sources.
///
/// Enhanced with satellite sensor data for comprehensive fire information sheet.
/// Optionally includes polygon boundary for burnt area visualization.
class FireIncident extends Equatable {
  final String id;
  final LatLng location; // Centroid for marker positioning
  final DataSource source;
  final Freshness freshness;
  final DateTime timestamp; // Kept for backward compatibility
  final String intensity; // "low" | "moderate" | "high"
  final String? description;
  final double? areaHectares;

  // Polygon boundary for burnt area visualization (Phase 1: A11)
  // null = point marker only, non-empty = render polygon overlay
  final List<LatLng>? boundaryPoints;

  // Satellite sensor fields for fire information sheet
  final DateTime?
      detectedAt; // When fire was first detected (defaults to timestamp)
  final String?
      sensorSource; // Satellite sensor: VIIRS, MODIS, etc (defaults to 'UNKNOWN')
  final double? confidence; // Detection confidence percentage 0-100
  final double? frp; // Fire Radiative Power in MW
  final DateTime? lastUpdate; // Most recent data update

  FireIncident({
    required this.id,
    required this.location,
    required this.source,
    required this.freshness,
    required this.timestamp,
    required this.intensity,
    DateTime? detectedAt,
    String? sensorSource,
    this.description,
    this.areaHectares,
    this.boundaryPoints,
    this.confidence,
    this.frp,
    this.lastUpdate,
  })  : detectedAt = detectedAt ?? timestamp,
        sensorSource = sensorSource ?? 'UNKNOWN' {
    _validate();
  }

  /// Factory for test data with reasonable defaults
  factory FireIncident.test({
    required String id,
    required LatLng location,
    DataSource source = DataSource.mock,
    Freshness freshness = Freshness.live,
    DateTime? timestamp,
    String intensity = 'moderate',
    DateTime? detectedAt,
    String sensorSource = 'VIIRS',
    String? description,
    double? areaHectares,
    List<LatLng>? boundaryPoints,
    double? confidence,
    double? frp,
    DateTime? lastUpdate,
  }) {
    final now = DateTime.now().toUtc();
    return FireIncident(
      id: id,
      location: location,
      source: source,
      freshness: freshness,
      timestamp: timestamp ?? now,
      intensity: intensity,
      detectedAt: detectedAt ?? now,
      sensorSource: sensorSource,
      description: description,
      areaHectares: areaHectares,
      boundaryPoints: boundaryPoints,
      confidence: confidence,
      frp: frp,
      lastUpdate: lastUpdate,
    );
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
    if (detectedAt != null && detectedAt!.isAfter(DateTime.now())) {
      throw ArgumentError('FireIncident detectedAt must not be in the future');
    }
    if (!['low', 'moderate', 'high'].contains(intensity)) {
      throw ArgumentError(
        'FireIncident intensity must be "low", "moderate", or "high"',
      );
    }
    if (areaHectares != null && areaHectares! <= 0) {
      throw ArgumentError('FireIncident areaHectares must be > 0');
    }
    if (sensorSource != null && sensorSource!.isEmpty) {
      throw ArgumentError('FireIncident sensorSource must be non-empty');
    }
    if (confidence != null && (confidence! < 0 || confidence! > 100)) {
      throw ArgumentError('FireIncident confidence must be between 0-100%');
    }
    if (frp != null && frp! < 0) {
      throw ArgumentError('FireIncident frp must be non-negative');
    }
    if (lastUpdate != null &&
        detectedAt != null &&
        lastUpdate!.isBefore(detectedAt!)) {
      throw ArgumentError('FireIncident lastUpdate must be >= detectedAt');
    }
    // Validate boundaryPoints if provided
    if (boundaryPoints != null && boundaryPoints!.isNotEmpty) {
      // Valid polygon requires at least 3 distinct points
      if (boundaryPoints!.length < 3) {
        throw ArgumentError(
          'FireIncident boundaryPoints must have at least 3 points for a valid polygon',
        );
      }
      // All boundary points must have valid coordinates
      for (final point in boundaryPoints!) {
        if (!point.isValid) {
          throw ArgumentError(
            'FireIncident boundaryPoints contains invalid coordinates',
          );
        }
      }
    }
  }

  /// Check if this incident has a valid polygon boundary for rendering
  ///
  /// Returns true if boundaryPoints is non-null and has >= 3 valid points.
  /// Used for graceful degradation: incidents without valid polygons
  /// fall back to marker-only display.
  bool get hasValidPolygon =>
      boundaryPoints != null && boundaryPoints!.length >= 3;

  /// Parse EFFIS WFS GeoJSON Feature or Mock data
  ///
  /// Handles both Point and Polygon geometry types:
  /// - Point: extracts centroid, boundaryPoints = null
  /// - Polygon: extracts centroid from first coordinate, boundaryPoints from ring
  factory FireIncident.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final geometryType = geometry['type'] as String;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;

    late final double lat;
    late final double lon;
    List<LatLng>? boundaryPoints;

    if (geometryType == 'Polygon') {
      // Polygon: coordinates is [[[lon, lat], [lon, lat], ...]]
      // First array is the outer ring, subsequent arrays are holes (ignored)
      final outerRing = coordinates[0] as List<dynamic>;

      // Extract boundary points from outer ring
      boundaryPoints = <LatLng>[];
      for (final coord in outerRing) {
        final coordList = coord as List<dynamic>;
        final pLon = (coordList[0] as num).toDouble();
        final pLat = (coordList[1] as num).toDouble();
        boundaryPoints.add(LatLng(pLat, pLon));
      }

      // Calculate centroid as average of all points (simple centroid)
      if (boundaryPoints.isNotEmpty) {
        double sumLat = 0, sumLon = 0;
        for (final point in boundaryPoints) {
          sumLat += point.latitude;
          sumLon += point.longitude;
        }
        lat = sumLat / boundaryPoints.length;
        lon = sumLon / boundaryPoints.length;
      } else {
        // Fallback: use first coordinate
        final firstCoord = outerRing[0] as List<dynamic>;
        lon = (firstCoord[0] as num).toDouble();
        lat = (firstCoord[1] as num).toDouble();
      }
    } else {
      // Point: coordinates is [lon, lat]
      // EFFIS WFS uses [lon, lat] order in GeoJSON
      lon = (coordinates[0] as num).toDouble();
      lat = (coordinates[1] as num).toDouble();
      boundaryPoints = null;
    }

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
    final areaHa =
        properties['area_ha'] as num? ?? properties['areaHectares'] as num?;

    return FireIncident(
      id: json['id']?.toString() ?? properties['fid']?.toString() ?? 'unknown',
      location: LatLng(lat, lon),
      boundaryPoints: boundaryPoints,
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
      detectedAt: DateTime.parse(
        properties['detected_at']?.toString() ??
            properties['timestamp']?.toString() ??
            properties['firedate']?.toString() ??
            DateTime.now().toIso8601String(),
      ).toUtc(),
      sensorSource: properties['sensor']?.toString() ??
          properties['sensor_source']?.toString() ??
          'MODIS', // Default fallback
      confidence: (properties['confidence'] as num?)?.toDouble(),
      frp: (properties['frp'] as num?)?.toDouble(),
      lastUpdate: properties['last_update'] != null
          ? DateTime.parse(properties['last_update'].toString()).toUtc()
          : null,
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
      'boundaryPoints': boundaryPoints
          ?.map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
          .toList(),
      'detectedAt': detectedAt?.toIso8601String(),
      'sensorSource': sensorSource,
      'confidence': confidence,
      'frp': frp,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  /// Deserialize from cache format
  factory FireIncident.fromCacheJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;

    // Parse boundaryPoints if present
    List<LatLng>? boundaryPoints;
    if (json['boundaryPoints'] != null) {
      final pointsList = json['boundaryPoints'] as List<dynamic>;
      boundaryPoints = pointsList
          .map((p) => LatLng(
                (p as Map<String, dynamic>)['latitude'] as double,
                p['longitude'] as double,
              ))
          .toList();
    }

    return FireIncident(
      id: json['id'] as String,
      location: LatLng(
        location['latitude'] as double,
        location['longitude'] as double,
      ),
      boundaryPoints: boundaryPoints,
      source: DataSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['source'],
        orElse: () => DataSource.mock,
      ),
      freshness: Freshness.values.firstWhere(
        (e) => e.toString().split('.').last == json['freshness'],
        orElse: () => Freshness.live,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      intensity: json['intensity'] as String,
      description: json['description'] as String?,
      areaHectares: json['areaHectares'] as double?,
      detectedAt: DateTime.parse(json['detectedAt'] as String).toUtc(),
      sensorSource: json['sensorSource'] as String,
      confidence: json['confidence'] as double?,
      frp: json['frp'] as double?,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String).toUtc()
          : null,
    );
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
    List<LatLng>? boundaryPoints,
    DateTime? detectedAt,
    String? sensorSource,
    double? confidence,
    double? frp,
    DateTime? lastUpdate,
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
      boundaryPoints: boundaryPoints ?? this.boundaryPoints,
      detectedAt: detectedAt ?? this.detectedAt,
      sensorSource: sensorSource ?? this.sensorSource,
      confidence: confidence ?? this.confidence,
      frp: frp ?? this.frp,
      lastUpdate: lastUpdate ?? this.lastUpdate,
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
        boundaryPoints,
        detectedAt,
        sensorSource,
        confidence,
        frp,
        lastUpdate,
      ];
}
