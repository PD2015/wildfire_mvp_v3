import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// EFFIS WFS fire incident data from burnt_areas_current_year layer
///
/// Represents active fire or burnt area from European Forest Fire Information System.
/// Used as intermediate model between EFFIS WFS GeoJSON → FireIncident.
class EffisFire extends Equatable {
  final String id;
  final LatLng location;
  final DateTime fireDate;
  final double areaHectares;
  final String? country;

  const EffisFire({
    required this.id,
    required this.location,
    required this.fireDate,
    required this.areaHectares,
    this.country,
  });

  /// Parse EFFIS WFS GeoJSON Feature
  ///
  /// Expected format:
  /// ```json
  /// {
  ///   "type": "Feature",
  ///   "id": "burnt_areas_current_year.12345",
  ///   "geometry": {
  ///     "type": "Point",
  ///     "coordinates": [-3.1883, 55.9533]  // [lon, lat] order
  ///   },
  ///   "properties": {
  ///     "fid": "12345",
  ///     "area_ha": 45.2,
  ///     "firedate": "2024-10-15T14:30:00Z",
  ///     "country": "United Kingdom"
  ///   }
  /// }
  /// ```
  factory EffisFire.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;

    // GeoJSON uses [lon, lat] order (per RFC 7946)
    final lon = (coordinates[0] as num).toDouble();
    final lat = (coordinates[1] as num).toDouble();

    // Parse fire date - EFFIS uses ISO 8601 format
    final fireDateStr =
        properties['firedate']?.toString() ??
        properties['lastupdate']?.toString() ??
        DateTime.now().toIso8601String();

    return EffisFire(
      id:
          json['id']?.toString() ??
          properties['fid']?.toString() ??
          'effis_fire_${DateTime.now().millisecondsSinceEpoch}',
      location: LatLng(lat, lon),
      fireDate: DateTime.parse(fireDateStr),
      areaHectares: (properties['area_ha'] as num?)?.toDouble() ?? 0.0,
      country: properties['country']?.toString(),
    );
  }

  /// Convert to FireIncident for map display
  ///
  /// Maps EFFIS data to application domain model with:
  /// - source: DataSource.effis
  /// - freshness: Freshness.live
  /// - intensity: Calculated from areaHectares
  ///   * < 10 ha → "low"
  ///   * 10-30 ha → "moderate"
  ///   * > 30 ha → "high"
  FireIncident toFireIncident() {
    // Calculate intensity from area
    final String intensity;
    if (areaHectares < 10) {
      intensity = 'low';
    } else if (areaHectares < 30) {
      intensity = 'moderate';
    } else {
      intensity = 'high';
    }

    return FireIncident(
      id: id,
      location: location,
      source: DataSource.effis,
      freshness: Freshness.live,
      timestamp: fireDate,
      intensity: intensity,
      description: country != null ? 'Fire in $country' : 'Active fire',
      areaHectares: areaHectares,
    );
  }

  @override
  List<Object?> get props => [id, location, fireDate, areaHectares, country];
}
