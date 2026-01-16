import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// EFFIS WFS fire incident data from modis.ba.poly layer
///
/// Represents active fire or burnt area from European Forest Fire Information System.
/// Used as intermediate model between EFFIS WFS GeoJSON/GML → FireIncident.
class EffisFire extends Equatable {
  final String id;
  final LatLng location;
  final DateTime fireDate;
  final double areaHectares;
  final String? country;

  /// Polygon boundary points for burnt area visualization (GML3 format only)
  final List<LatLng>? boundaryPoints;

  const EffisFire({
    required this.id,
    required this.location,
    required this.fireDate,
    required this.areaHectares,
    this.country,
    this.boundaryPoints,
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
    final fireDateStr = properties['firedate']?.toString() ??
        properties['lastupdate']?.toString() ??
        DateTime.now().toIso8601String();

    return EffisFire(
      id: json['id']?.toString() ??
          properties['fid']?.toString() ??
          'effis_fire_${DateTime.now().millisecondsSinceEpoch}',
      location: LatLng(lat, lon),
      fireDate: DateTime.parse(fireDateStr),
      areaHectares: (properties['area_ha'] as num?)?.toDouble() ?? 0.0,
      country: properties['country']?.toString(),
    );
  }

  /// Parse EFFIS WFS GML3 member element (new endpoint format)
  ///
  /// Expected format from maps.effis.emergency.copernicus.eu/effis:
  /// ```xml
  /// <ms:modis.ba.poly gml:id="modis.ba.poly.2">
  ///   <gml:boundedBy>...</gml:boundedBy>
  ///   <ms:msGeometry>
  ///     <gml:Polygon>
  ///       <gml:exterior>
  ///         <gml:LinearRing>
  ///           <gml:posList>lat1 lon1 lat2 lon2 ...</gml:posList>
  ///         </gml:LinearRing>
  ///       </gml:exterior>
  ///     </gml:Polygon>
  ///   </ms:msGeometry>
  ///   <ms:id>2</ms:id>
  ///   <ms:FIREDATE>2024-08-28 00:00:00</ms:FIREDATE>
  ///   <ms:COUNTRY>PT</ms:COUNTRY>
  ///   <ms:AREA_HA>67</ms:AREA_HA>
  /// </ms:modis.ba.poly>
  /// ```
  factory EffisFire.fromGml(XmlElement member) {
    // Extract ID from gml:id attribute
    final gmlId = member.getAttribute('gml:id') ??
        member.getAttribute('id') ??
        'effis_${DateTime.now().millisecondsSinceEpoch}';

    // Extract properties - GML uses element names with ms: prefix
    String? getElementText(String localName) {
      final element = member.findAllElements('ms:$localName').firstOrNull;
      return element?.innerText;
    }

    // Parse fire date - EFFIS uses "YYYY-MM-DD HH:MM:SS" format
    final fireDateStr = getElementText('FIREDATE') ??
        getElementText('LASTUPDATE') ??
        DateTime.now().toIso8601String();
    final fireDate = _parseEffisDate(fireDateStr);

    // Parse area in hectares
    final areaStr = getElementText('AREA_HA') ?? '0';
    final areaHectares = double.tryParse(areaStr) ?? 0.0;

    // Extract polygon centroid from boundedBy or posList
    final centroid = _extractCentroid(member);

    // Extract polygon boundary points
    final boundaryPoints = _extractBoundaryPoints(member);

    return EffisFire(
      id: gmlId,
      location: centroid,
      fireDate: fireDate,
      areaHectares: areaHectares,
      country: getElementText('COUNTRY'),
      boundaryPoints: boundaryPoints,
    );
  }

  /// Parse EFFIS date format "YYYY-MM-DD HH:MM:SS" or ISO 8601
  static DateTime _parseEffisDate(String dateStr) {
    try {
      // Try ISO 8601 first
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Try EFFIS format "YYYY-MM-DD HH:MM:SS"
        final parts = dateStr.split(' ');
        if (parts.isNotEmpty) {
          final datePart = parts[0];
          final timePart = parts.length > 1 ? parts[1] : '00:00:00';
          return DateTime.parse('${datePart}T$timePart');
        }
      } catch (_) {
        // Ignore parse errors
      }
    }
    return DateTime.now();
  }

  /// Extract centroid from GML boundedBy element
  static LatLng _extractCentroid(XmlElement member) {
    // Try to get from boundedBy/Envelope
    final envelope = member.findAllElements('gml:Envelope').firstOrNull;
    if (envelope != null) {
      final lowerCorner =
          envelope.findAllElements('gml:lowerCorner').firstOrNull;
      final upperCorner =
          envelope.findAllElements('gml:upperCorner').firstOrNull;

      if (lowerCorner != null && upperCorner != null) {
        final lower = lowerCorner.innerText.split(' ');
        final upper = upperCorner.innerText.split(' ');

        if (lower.length >= 2 && upper.length >= 2) {
          // GML uses lat lon order in EPSG:4326
          final minLat = double.tryParse(lower[0]) ?? 0;
          final minLon = double.tryParse(lower[1]) ?? 0;
          final maxLat = double.tryParse(upper[0]) ?? 0;
          final maxLon = double.tryParse(upper[1]) ?? 0;

          return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
        }
      }
    }

    // Fallback: try to get first point from posList
    final posList = member.findAllElements('gml:posList').firstOrNull;
    if (posList != null) {
      final coords = posList.innerText.trim().split(RegExp(r'\s+'));
      if (coords.length >= 2) {
        // GML posList uses lat lon pairs
        final lat = double.tryParse(coords[0]) ?? 0;
        final lon = double.tryParse(coords[1]) ?? 0;
        return LatLng(lat, lon);
      }
    }

    return const LatLng(0, 0);
  }

  /// Extract polygon boundary points from GML posList
  static List<LatLng>? _extractBoundaryPoints(XmlElement member) {
    final posList = member.findAllElements('gml:posList').firstOrNull;
    if (posList == null) return null;

    final coords = posList.innerText.trim().split(RegExp(r'\s+'));
    if (coords.length < 6) return null; // Need at least 3 points (6 values)

    final points = <LatLng>[];
    for (var i = 0; i < coords.length - 1; i += 2) {
      final lat = double.tryParse(coords[i]);
      final lon = double.tryParse(coords[i + 1]);
      if (lat != null && lon != null) {
        points.add(LatLng(lat, lon));
      }
    }

    return points.length >= 3 ? points : null;
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
      boundaryPoints: boundaryPoints,
    );
  }

  @override
  List<Object?> get props => [
        id,
        location,
        fireDate,
        areaHectares,
        country,
        boundaryPoints,
      ];
}
