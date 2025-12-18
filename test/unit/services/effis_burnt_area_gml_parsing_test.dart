/// Unit tests for EFFIS burnt area GML3 parsing
///
/// Part of 021-live-fire-data feature implementation.
/// Tests GML3 response parsing after discovery that JSON output
/// fails silently with bbox filters on EFFIS WFS.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service_impl.dart';

/// Sample GML3 response from EFFIS WFS for Scotland
/// Fire ID 256624, 1 ha, Feb 2025, UK
const _sampleGmlResponse = '''<?xml version='1.0' encoding="UTF-8" ?>
<wfs:FeatureCollection
   xmlns:ms="http://mapserver.gis.umn.edu/mapserver"
   xmlns:gml="http://www.opengis.net/gml"
   xmlns:wfs="http://www.opengis.net/wfs"
   xmlns:ogc="http://www.opengis.net/ogc"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <gml:featureMember>
      <ms:modis.ba.poly.season gml:id="modis.ba.poly.season.256624">
        <ms:msGeometry>
          <gml:Polygon srsName="EPSG:4326">
            <gml:exterior>
              <gml:LinearRing>
                <gml:posList srsDimension="2">57.305996 -3.931427 57.305937 -3.931364 57.305866 -3.931332 57.305783 -3.931331 57.305689 -3.931362 57.305584 -3.931424 57.305532 -3.931519 57.305535 -3.931647 57.305592 -3.931809 57.305703 -3.932004 57.305996 -3.931427</gml:posList>
              </gml:LinearRing>
            </gml:exterior>
          </gml:Polygon>
        </ms:msGeometry>
        <ms:id>256624</ms:id>
        <ms:FIREDATE>2025-02-06 13:44:00</ms:FIREDATE>
        <ms:COUNTRY>UK</ms:COUNTRY>
        <ms:AREA_HA>1</ms:AREA_HA>
      </ms:modis.ba.poly.season>
    </gml:featureMember>
</wfs:FeatureCollection>''';

/// Sample GML3 response with multiple features
const _multipleFeatureGmlResponse = '''<?xml version='1.0' encoding="UTF-8" ?>
<wfs:FeatureCollection
   xmlns:ms="http://mapserver.gis.umn.edu/mapserver"
   xmlns:gml="http://www.opengis.net/gml"
   xmlns:wfs="http://www.opengis.net/wfs">
    <gml:featureMember>
      <ms:modis.ba.poly.season gml:id="modis.ba.poly.season.256624">
        <ms:msGeometry>
          <gml:Polygon srsName="EPSG:4326">
            <gml:exterior>
              <gml:LinearRing>
                <gml:posList srsDimension="2">57.3 -3.9 57.31 -3.9 57.31 -3.91 57.3 -3.91 57.3 -3.9</gml:posList>
              </gml:LinearRing>
            </gml:exterior>
          </gml:Polygon>
        </ms:msGeometry>
        <ms:id>256624</ms:id>
        <ms:FIREDATE>2025-02-06 13:44:00</ms:FIREDATE>
        <ms:AREA_HA>1</ms:AREA_HA>
      </ms:modis.ba.poly.season>
    </gml:featureMember>
    <gml:featureMember>
      <ms:modis.ba.poly.season gml:id="modis.ba.poly.season.273772">
        <ms:msGeometry>
          <gml:Polygon srsName="EPSG:4326">
            <gml:exterior>
              <gml:LinearRing>
                <gml:posList srsDimension="2">57.4 -3.7 57.5 -3.7 57.5 -3.8 57.4 -3.8 57.4 -3.7</gml:posList>
              </gml:LinearRing>
            </gml:exterior>
          </gml:Polygon>
        </ms:msGeometry>
        <ms:id>273772</ms:id>
        <ms:FIREDATE>2025-06-28 00:00:00</ms:FIREDATE>
        <ms:AREA_HA>9809</ms:AREA_HA>
      </ms:modis.ba.poly.season>
    </gml:featureMember>
</wfs:FeatureCollection>''';

/// Empty GML response (no features in bbox)
const _emptyGmlResponse = '''<?xml version='1.0' encoding="UTF-8" ?>
<wfs:FeatureCollection
   xmlns:ms="http://mapserver.gis.umn.edu/mapserver"
   xmlns:gml="http://www.opengis.net/gml"
   xmlns:wfs="http://www.opengis.net/wfs">
</wfs:FeatureCollection>''';

void main() {
  group('EffisBurntAreaServiceImpl GML3 Parsing', () {
    test('parses single feature from GML3 response', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['outputFormat'], 'GML3');
        return http.Response(_sampleGmlResponse, 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      final result = await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
      );

      expect(result.isRight(), true);
      final areas = result.getOrElse(() => []);
      expect(areas.length, 1);

      final area = areas.first;
      expect(area.id, '256624');
      expect(area.areaHectares, 1.0);
      expect(area.fireDate.year, 2025);
      expect(area.fireDate.month, 2);
      expect(area.fireDate.day, 6);
      expect(area.boundaryPoints.length, greaterThanOrEqualTo(3));

      // Verify coordinates are in Scotland
      expect(area.centroid.latitude, closeTo(57.3, 0.1));
      expect(area.centroid.longitude, closeTo(-3.9, 0.1));
    });

    test('parses multiple features from GML3 response', () async {
      final client = MockClient((request) async {
        return http.Response(_multipleFeatureGmlResponse, 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      final result = await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
      );

      expect(result.isRight(), true);
      final areas = result.getOrElse(() => []);
      expect(areas.length, 2);

      // Check fire 256624 (small fire)
      final smallFire = areas.firstWhere((a) => a.id == '256624');
      expect(smallFire.areaHectares, 1.0);
      expect(smallFire.intensity, 'low');

      // Check fire 273772 (large fire - West Moray)
      final largeFire = areas.firstWhere((a) => a.id == '273772');
      expect(largeFire.areaHectares, 9809.0);
      expect(largeFire.intensity, 'high');
      expect(largeFire.fireDate.month, 6); // June
    });

    test('handles empty GML response gracefully', () async {
      final client = MockClient((request) async {
        return http.Response(_emptyGmlResponse, 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      final result = await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(50.0, -10.0),
          northeast: LatLng(51.0, -9.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
      );

      expect(result.isRight(), true);
      final areas = result.getOrElse(() => []);
      expect(areas.length, 0);
    });

    test('uses GML3 output format not JSON', () async {
      String? capturedUrl;
      final client = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(_emptyGmlResponse, 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
      );

      expect(capturedUrl, contains('outputFormat=GML3'));
      expect(capturedUrl, isNot(contains('outputFormat=json')));
      expect(capturedUrl, isNot(contains('outputFormat=application/json')));
    });

    test('handles malformed GML gracefully', () async {
      final client = MockClient((request) async {
        return http.Response('<not valid xml', 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      final result = await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
      );

      expect(result.isLeft(), true);
    });

    test('selects correct layer for season filter', () async {
      String? capturedUrl;
      final client = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(_emptyGmlResponse, 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);

      // Test thisSeason - uses pre-filtered season layer
      await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
      );
      expect(capturedUrl, contains('modis.ba.poly.season'));
      expect(capturedUrl, isNot(contains('CQL_FILTER')));

      // Test lastSeason - uses generic layer + CQL filter for year
      await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.lastSeason,
      );
      // Should use generic modis.ba.poly layer with year filter
      expect(capturedUrl, contains('typeName=ms:modis.ba.poly'));
      expect(capturedUrl, isNot(contains('modis.ba.poly.season')));
      // Should include CQL filter for the previous year
      expect(capturedUrl, contains('CQL_FILTER'));
      final lastYear = BurntAreaSeasonFilter.lastSeason.year;
      expect(capturedUrl, contains('$lastYear'));
    });

    test('parses coordinates correctly from posList', () async {
      final client = MockClient((request) async {
        return http.Response(_sampleGmlResponse, 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      final result = await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
      );

      final area = result.getOrElse(() => []).first;

      // First point in posList: 57.305996 -3.931427
      final firstPoint = area.boundaryPoints.first;
      expect(firstPoint.latitude, closeTo(57.305996, 0.001));
      expect(firstPoint.longitude, closeTo(-3.931427, 0.001));
    });
  });

  group('EffisBurntAreaServiceImpl network error handling', () {
    test('handles timeout with retry', () async {
      int callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        if (callCount < 3) {
          throw const SocketException('Connection timeout');
        }
        return http.Response(_sampleGmlResponse, 200);
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      final result = await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
        maxRetries: 3,
      );

      expect(result.isRight(), true);
      expect(callCount, 3);
    });

    test('returns error after max retries exceeded', () async {
      int callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        throw const SocketException('Connection failed');
      });

      final service = EffisBurntAreaServiceImpl(httpClient: client);
      final result = await service.getBurntAreas(
        bounds: const LatLngBounds(
          southwest: LatLng(57.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        ),
        seasonFilter: BurntAreaSeasonFilter.thisSeason,
        maxRetries: 2,
      );

      expect(result.isLeft(), true);
      expect(callCount, 3); // Initial + 2 retries
    });
  });
}
