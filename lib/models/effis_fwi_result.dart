import 'package:equatable/equatable.dart';
import 'risk_level.dart';

/// Represents a single EFFIS Fire Weather Index result from the GeoJSON API
/// 
/// Parses and validates EFFIS API response data per docs/data-model.md:
/// - FWI and related fire weather indices (DC, DMC, FFMC, ISI, BUI)
/// - UTC timestamp parsing (2023-09-13T00:00:00Z format)
/// - GeoJSON Point geometry with latitude/longitude coordinates
/// - Automatic risk level classification from FWI value
class EffisFwiResult extends Equatable {
  final double fwi;
  final double dc;
  final double dmc;
  final double ffmc;
  final double isi;
  final double bui;
  final DateTime datetime;
  final double longitude;
  final double latitude;
  final RiskLevel riskLevel;

  /// Creates an EffisFwiResult with validation
  /// 
  /// All fire weather index values must be non-negative.
  /// Coordinates must be within valid ranges: longitude [-180, 180], latitude [-90, 90].
  /// DateTime must be in UTC.
  EffisFwiResult({
    required this.fwi,
    required this.dc,
    required this.dmc,
    required this.ffmc,
    required this.isi,
    required this.bui,
    required this.datetime,
    required this.longitude,
    required this.latitude,
  }) : riskLevel = RiskLevel.fromFwi(fwi) {
    // Validate FWI values are non-negative
    if (fwi < 0.0) throw ArgumentError('FWI cannot be negative: $fwi');
    if (dc < 0.0) throw ArgumentError('DC cannot be negative: $dc');
    if (dmc < 0.0) throw ArgumentError('DMC cannot be negative: $dmc');
    if (ffmc < 0.0) throw ArgumentError('FFMC cannot be negative: $ffmc');
    if (isi < 0.0) throw ArgumentError('ISI cannot be negative: $isi');
    if (bui < 0.0) throw ArgumentError('BUI cannot be negative: $bui');

    // Validate coordinate ranges
    if (longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError('Longitude must be between -180 and 180: $longitude');
    }
    if (latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError('Latitude must be between -90 and 90: $latitude');
    }

    // Ensure datetime is UTC
    if (!datetime.isUtc) {
      throw ArgumentError('DateTime must be in UTC: $datetime');
    }
  }

  /// Creates an EffisFwiResult from EFFIS GeoJSON Feature JSON
  /// 
  /// Expects GeoJSON Feature format with:
  /// - properties: fwi, dc, dmc, ffmc, isi, bui, datetime (UTC ISO string)
  /// - geometry: Point with coordinates [longitude, latitude]
  /// 
  /// Throws [ArgumentError] for invalid or missing data.
  factory EffisFwiResult.fromJson(Map<String, dynamic> json) {
    try {
      // Extract properties
      final properties = json['properties'] as Map<String, dynamic>?;
      if (properties == null) {
        throw ArgumentError('Missing properties in GeoJSON Feature');
      }

      // Extract geometry
      final geometry = json['geometry'] as Map<String, dynamic>?;
      if (geometry == null) {
        throw ArgumentError('Missing geometry in GeoJSON Feature');
      }

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.length != 2) {
        throw ArgumentError('Invalid or missing coordinates in geometry');
      }

      // Validate and extract required properties
      final fwi = _extractDouble(properties, 'fwi');
      final dc = _extractDouble(properties, 'dc');
      final dmc = _extractDouble(properties, 'dmc');
      final ffmc = _extractDouble(properties, 'ffmc');
      final isi = _extractDouble(properties, 'isi');
      final bui = _extractDouble(properties, 'bui');

      // Parse UTC datetime
      final datetimeStr = properties['datetime'] as String?;
      if (datetimeStr == null || datetimeStr.isEmpty) {
        throw ArgumentError('Missing or empty datetime field');
      }

      late DateTime datetime;
      try {
        datetime = DateTime.parse(datetimeStr);
        if (!datetime.isUtc) {
          throw ArgumentError('DateTime must be in UTC format (end with Z): $datetimeStr');
        }
      } catch (e) {
        throw ArgumentError('Invalid datetime format: $datetimeStr. Expected UTC ISO format like 2023-09-13T00:00:00Z');
      }

      // Extract coordinates
      final longitude = (coordinates[0] as num).toDouble();
      final latitude = (coordinates[1] as num).toDouble();

      return EffisFwiResult(
        fwi: fwi,
        dc: dc,
        dmc: dmc,
        ffmc: ffmc,
        isi: isi,
        bui: bui,
        datetime: datetime,
        longitude: longitude,
        latitude: latitude,
      );
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw ArgumentError('Failed to parse EffisFwiResult from JSON: $e');
    }
  }

  /// Extracts and validates a double value from properties
  static double _extractDouble(Map<String, dynamic> properties, String key) {
    final value = properties[key];
    if (value == null) {
      throw ArgumentError('Missing required field: $key');
    }
    if (value is! num) {
      throw ArgumentError('Field $key must be a number, got: ${value.runtimeType}');
    }
    return value.toDouble();
  }

  @override
  List<Object?> get props => [
        fwi,
        dc,
        dmc,
        ffmc,
        isi,
        bui,
        datetime,
        longitude,
        latitude,
        riskLevel,
      ];
}