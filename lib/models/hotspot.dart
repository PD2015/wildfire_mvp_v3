import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Active fire hotspot from GWIS WMS VIIRS sensor data
///
/// Immutable value object representing a single fire detection.
/// Part of 021-live-fire-data feature implementation.
///
/// Data source: GWIS GetFeatureInfo WMS response
/// - Layer: viirs.hs.today or viirs.hs.week
/// - Sensor: VIIRS (Visible Infrared Imaging Radiometer Suite)
class Hotspot extends Equatable {
  /// Unique identifier for this hotspot
  final String id;

  /// Geographic location (centroid of detection pixel)
  final LatLng location;

  /// UTC timestamp when fire was first detected by satellite
  final DateTime detectedAt;

  /// Fire Radiative Power in megawatts (MW)
  ///
  /// Indicates fire intensity:
  /// - 0-10 MW: Low intensity
  /// - 10-50 MW: Moderate intensity
  /// - 50+ MW: High intensity
  final double frp;

  /// Detection confidence percentage (0-100)
  ///
  /// Based on VIIRS algorithm confidence levels:
  /// - < 30: Low confidence
  /// - 30-80: Nominal confidence
  /// - > 80: High confidence
  final double confidence;

  /// Intensity level derived from FRP
  ///
  /// "low" | "moderate" | "high"
  /// Calculated from frp thresholds.
  String get intensity {
    if (frp < 10) return 'low';
    if (frp < 50) return 'moderate';
    return 'high';
  }

  const Hotspot({
    required this.id,
    required this.location,
    required this.detectedAt,
    required this.frp,
    required this.confidence,
  });

  /// Factory for creating from GWIS GetFeatureInfo JSON response
  ///
  /// Expected JSON structure from GWIS WMS:
  /// ```json
  /// {
  ///   "id": "viirs_12345",
  ///   "geometry": { "coordinates": [-3.5, 56.2] },
  ///   "properties": {
  ///     "acq_date": "2025-07-15",
  ///     "acq_time": "1345",
  ///     "frp": 25.5,
  ///     "confidence": "nominal"
  ///   }
  /// }
  /// ```
  factory Hotspot.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? json;
    final geometry = json['geometry'] as Map<String, dynamic>?;

    // Parse location from geometry or top-level lat/lon
    LatLng location;
    if (geometry != null && geometry['coordinates'] != null) {
      final coords = geometry['coordinates'] as List;
      location = LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
    } else {
      location = LatLng(
        (properties['latitude'] as num?)?.toDouble() ?? 0.0,
        (properties['longitude'] as num?)?.toDouble() ?? 0.0,
      );
    }

    // Parse detection timestamp
    final acqDate = properties['acq_date'] as String? ?? '';
    final acqTime = properties['acq_time'] as String? ?? '0000';
    final detectedAt = _parseAcquisitionDateTime(acqDate, acqTime);

    // Parse FRP with fallback
    final frp = (properties['frp'] as num?)?.toDouble() ?? 0.0;

    // Parse confidence - can be string or number
    final confidence = _parseConfidence(properties['confidence']);

    // Generate ID from position and time if not provided
    final id = json['id']?.toString() ??
        'hotspot_${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}_${detectedAt.millisecondsSinceEpoch}';

    return Hotspot(
      id: id,
      location: location,
      detectedAt: detectedAt,
      frp: frp,
      confidence: confidence,
    );
  }

  /// Parse acquisition date and time strings to DateTime
  ///
  /// GWIS format: acq_date = "2025-07-15", acq_time = "1345" (HHMM)
  static DateTime _parseAcquisitionDateTime(String date, String time) {
    try {
      if (date.isEmpty) return DateTime.now().toUtc();

      final parts = date.split('-');
      if (parts.length != 3) return DateTime.now().toUtc();

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Parse time as HHMM format
      final hour =
          time.length >= 2 ? int.tryParse(time.substring(0, 2)) ?? 0 : 0;
      final minute =
          time.length >= 4 ? int.tryParse(time.substring(2, 4)) ?? 0 : 0;

      return DateTime.utc(year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now().toUtc();
    }
  }

  /// Parse confidence from various formats
  ///
  /// GWIS can return:
  /// - Number: 0-100 percentage
  /// - String: "low", "nominal", "high"
  static double _parseConfidence(dynamic confidence) {
    if (confidence == null) return 50.0;
    if (confidence is num) return confidence.toDouble().clamp(0.0, 100.0);
    if (confidence is String) {
      switch (confidence.toLowerCase()) {
        case 'low':
          return 25.0;
        case 'nominal':
        case 'normal':
          return 50.0;
        case 'high':
          return 85.0;
        default:
          return double.tryParse(confidence) ?? 50.0;
      }
    }
    return 50.0;
  }

  /// Convert to JSON for caching/serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'geometry': {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude],
        },
        'properties': {
          'acq_date':
              '${detectedAt.year.toString().padLeft(4, '0')}-${detectedAt.month.toString().padLeft(2, '0')}-${detectedAt.day.toString().padLeft(2, '0')}',
          'acq_time':
              '${detectedAt.hour.toString().padLeft(2, '0')}${detectedAt.minute.toString().padLeft(2, '0')}',
          'frp': frp,
          'confidence': confidence,
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      };

  /// Factory for test data with reasonable defaults
  factory Hotspot.test({
    String? id,
    required LatLng location,
    DateTime? detectedAt,
    double frp = 25.0,
    double confidence = 50.0,
  }) {
    return Hotspot(
      id: id ?? 'test_hotspot_${location.latitude}_${location.longitude}',
      location: location,
      detectedAt: detectedAt ?? DateTime.now().toUtc(),
      frp: frp,
      confidence: confidence,
    );
  }

  /// Create a copy with modified fields
  ///
  /// Used by MockHotspotService to transform dates at load time
  /// so mock data remains fresh (not filtered out by time filters).
  Hotspot copyWith({
    String? id,
    LatLng? location,
    DateTime? detectedAt,
    double? frp,
    double? confidence,
  }) {
    return Hotspot(
      id: id ?? this.id,
      location: location ?? this.location,
      detectedAt: detectedAt ?? this.detectedAt,
      frp: frp ?? this.frp,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [id, location, detectedAt, frp, confidence];
}
