import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import '../../fixtures/scotland_fire_273772_fixture.dart';

void main() {
  group('ScotlandFire273772Fixture', () {
    test('creates valid FireIncident from fixture', () {
      final incident = ScotlandFire273772Fixture.incident;

      expect(incident.id, equals('273772'));
      expect(incident.source, equals(DataSource.effis));
      expect(incident.intensity, equals('high'));
      expect(incident.areaHectares, equals(9809.46));
      expect(incident.sensorSource, equals('MODIS'));
    });

    test('simplified polygon has at least 3 points for valid polygon', () {
      final polygon = ScotlandFire273772Fixture.simplifiedPolygon;

      expect(polygon.length, greaterThanOrEqualTo(3));
      expect(polygon.first.isValid, isTrue);
      expect(polygon.last.isValid, isTrue);
    });

    test('centroid is within Scotland bounds', () {
      const centroid = ScotlandFire273772Fixture.centroid;

      // Scotland bounds: lat 54.5-61°N, lon -9-0°W
      expect(centroid.latitude, greaterThanOrEqualTo(54.5));
      expect(centroid.latitude, lessThanOrEqualTo(61.0));
      expect(centroid.longitude, greaterThanOrEqualTo(-9.0));
      expect(centroid.longitude, lessThanOrEqualTo(0.0));
    });

    test('incident hasValidPolygon returns true', () {
      final incident = ScotlandFire273772Fixture.incident;

      expect(incident.hasValidPolygon, isTrue);
      expect(incident.boundaryPoints!.length, greaterThanOrEqualTo(3));
    });

    test('geoJsonFeature can be parsed by FireIncident.fromJson', () {
      final json = ScotlandFire273772Fixture.geoJsonFeature;
      final incident = FireIncident.fromJson(json);

      expect(incident.id, isNotEmpty);
      expect(incident.hasValidPolygon, isTrue);
      expect(incident.location.isValid, isTrue);
    });

    test('fire date is June 28, 2025', () {
      final fireDate = ScotlandFire273772Fixture.fireDate;

      expect(fireDate.year, equals(2025));
      expect(fireDate.month, equals(6));
      expect(fireDate.day, equals(28));
    });

    test('ring2Simplified forms closed polygon', () {
      final ring = ScotlandFire273772Fixture.ring2Simplified;

      // A closed polygon should have first point == last point
      expect(ring.first.latitude, equals(ring.last.latitude));
      expect(ring.first.longitude, equals(ring.last.longitude));
    });

    test('incidentWithPolygon creates incident with custom polygon', () {
      const customPolygon = [
        LatLng(57.0, -3.0),
        LatLng(57.1, -3.0),
        LatLng(57.1, -3.1),
        LatLng(57.0, -3.1),
      ];

      final incident =
          ScotlandFire273772Fixture.incidentWithPolygon(customPolygon);

      expect(incident.boundaryPoints, equals(customPolygon));
      expect(incident.hasValidPolygon, isTrue);
    });
  });
}
