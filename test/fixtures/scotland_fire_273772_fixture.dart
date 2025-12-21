/// Test fixture for Scotland fire incident 273772 (June 28, 2025)
///
/// Real historical data from EFFIS WFS `ms:modis.ba.poly.season` layer.
/// Contains 24 polygon rings representing burnt areas in West Moray region.
///
/// Source: https://maps.effis.emergency.copernicus.eu/effis
/// Query: WFS GetFeature with bbox filter for Scotland
///
/// Usage:
/// ```dart
/// final incident = ScotlandFire273772Fixture.incident;
/// final polygons = ScotlandFire273772Fixture.firstPolygonPoints;
/// ```
library;

import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// Fixture for Scotland fire 273772 - June 28, 2025
///
/// A significant moorland fire in the Cairngorms/West Moray region.
/// - Area: 9,809 hectares (24,236 acres)
/// - Land cover: 93% moorland, 4% transitional woodland
/// - Location: Inverness & Nairn and Moray, Badenoch & Strathspey
class ScotlandFire273772Fixture {
  ScotlandFire273772Fixture._();

  /// Fire metadata
  static const String id = '273772';
  static const String province =
      'Inverness & Nairn and Moray, Badenoch & Strathspey';
  static const String commune = 'West Moray';
  static const double areaHectares = 9809.46;

  /// Fire timestamp
  static final DateTime fireDate = DateTime.utc(2025, 6, 28, 11, 53, 0);
  static final DateTime lastUpdate = DateTime.utc(2025, 7, 9);

  /// Centroid location (average of main polygon points)
  static const LatLng centroid = LatLng(57.43, -3.72);

  /// Simplified polygon for testing (first 20 points of main ring)
  /// Use this for unit tests to avoid loading full 18,000+ point polygon
  static const List<LatLng> simplifiedPolygon = [
    LatLng(57.472033, -3.622999),
    LatLng(57.472131, -3.622877),
    LatLng(57.472249, -3.622810),
    LatLng(57.472387, -3.622797),
    LatLng(57.472545, -3.622840),
    LatLng(57.472723, -3.622938),
    LatLng(57.472868, -3.623032),
    LatLng(57.472980, -3.623122),
    LatLng(57.473060, -3.623207),
    LatLng(57.473107, -3.623288),
    LatLng(57.473170, -3.623339),
    LatLng(57.473249, -3.623361),
    LatLng(57.473344, -3.623353),
    LatLng(57.473455, -3.623314),
    LatLng(57.473533, -3.623331),
    LatLng(57.473579, -3.623404),
    LatLng(57.473593, -3.623532),
    LatLng(57.473574, -3.623716),
    LatLng(57.473611, -3.623873),
    LatLng(57.473704, -3.624003),
  ];

  /// Sample polygon ring 2 (333 points simplified to 10)
  static const List<LatLng> ring2Simplified = [
    LatLng(57.352039, -3.786145),
    LatLng(57.352350, -3.786667),
    LatLng(57.352552, -3.789087),
    LatLng(57.352757, -3.794524),
    LatLng(57.351212, -3.798248),
    LatLng(57.350492, -3.799351),
    LatLng(57.349790, -3.802387),
    LatLng(57.348449, -3.800724),
    LatLng(57.347960, -3.800455),
    LatLng(57.352039, -3.786145), // Closed ring
  ];

  /// Full FireIncident object for integration tests
  static FireIncident get incident => FireIncident(
    id: id,
    location: centroid,
    source: DataSource.effis,
    freshness: Freshness.live,
    timestamp: fireDate,
    intensity: 'high', // 9,809 ha is a significant fire
    detectedAt: fireDate,
    sensorSource: 'MODIS',
    description: 'Moorland fire in West Moray, Cairngorms region',
    areaHectares: areaHectares,
    boundaryPoints: simplifiedPolygon,
    confidence: 95.0,
    lastUpdate: lastUpdate,
  );

  /// FireIncident with full polygon (use sparingly - large data)
  /// For performance testing polygon rendering
  static FireIncident incidentWithPolygon(List<LatLng> fullPolygon) =>
      FireIncident(
        id: id,
        location: centroid,
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: fireDate,
        intensity: 'high',
        detectedAt: fireDate,
        sensorSource: 'MODIS',
        description: 'Moorland fire in West Moray, Cairngorms region',
        areaHectares: areaHectares,
        boundaryPoints: fullPolygon,
        confidence: 95.0,
        lastUpdate: lastUpdate,
      );

  /// GeoJSON-style feature for testing fromJson parsing
  static Map<String, dynamic> get geoJsonFeature => {
    'type': 'Feature',
    'properties': {
      'id': id,
      'FIREDATE': '2025-06-28T11:53:00Z',
      'AREA_HA': areaHectares,
      'COUNTRY': 'UK',
      'PROVINCE': province,
      'COMMUNE': commune,
      'LASTUPDATE': '2025-07-09',
      'BROADLEAVED': 0.0,
      'CONIFEROUS': 0.0,
      'MIXED': 0.0,
      'SCLEROPHYLLOUS': 0.0,
      'TRANSITIONAL': 4.24,
      'OTHER_NATURAL': 93.24,
      'OTHER': 2.52,
    },
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        // Simplified outer ring (GeoJSON uses [lon, lat] order)
        [
          [-3.622999, 57.472033],
          [-3.622877, 57.472131],
          [-3.622810, 57.472249],
          [-3.622797, 57.472387],
          [-3.622840, 57.472545],
          [-3.622938, 57.472723],
          [-3.623032, 57.472868],
          [-3.623122, 57.472980],
          [-3.622999, 57.472033], // Closed ring
        ],
      ],
    },
  };
}
