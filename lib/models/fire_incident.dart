import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// Fire incident data model for map markers
///
/// Represents active fire or burnt area incident from EFFIS WFS,
/// SEPA, Cache, or Mock sources.
///
/// Enhanced with satellite sensor data for comprehensive fire information sheet
class FireIncident extends Equatable {
  final String id;
  final LatLng location;
  final DataSource source;
  final Freshness freshness;
  final DateTime timestamp; // Kept for backward compatibility
  final String intensity; // "low" | "moderate" | "high"
  final String? description;
  final double? areaHectares;
  
  // New satellite sensor fields for fire information sheet
  final DateTime detectedAt; // When fire was first detected
  final String sensorSource; // Satellite sensor: VIIRS, MODIS, etc
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
    required this.detectedAt,
    required this.sensorSource,
    this.description,
    this.areaHectares,
    this.confidence,
    this.frp,
    this.lastUpdate,
  }) {
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
    if (detectedAt.isAfter(DateTime.now())) {
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
    if (sensorSource.isEmpty) {
      throw ArgumentError('FireIncident sensorSource must be non-empty');
    }
    if (confidence != null && (confidence! < 0 || confidence! > 100)) {
      throw ArgumentError('FireIncident confidence must be between 0-100%');
    }
    if (frp != null && frp! < 0) {
      throw ArgumentError('FireIncident frp must be non-negative');
    }
    if (lastUpdate != null && lastUpdate!.isBefore(detectedAt)) {
      throw ArgumentError('FireIncident lastUpdate must be >= detectedAt');
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
    final areaHa =
        properties['area_ha'] as num? ?? properties['areaHectares'] as num?;

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
      'detectedAt': detectedAt.toIso8601String(),
      'sensorSource': sensorSource,
      'confidence': confidence,
      'frp': frp,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  /// Deserialize from cache format
  factory FireIncident.fromCacheJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    return FireIncident(
      id: json['id'] as String,
      location: LatLng(
        location['latitude'] as double,
        location['longitude'] as double,
      ),
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
        detectedAt,
        sensorSource,
        confidence,
        frp,
        lastUpdate,
      ];
}
