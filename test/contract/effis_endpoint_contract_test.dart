/// Contract test to validate EFFIS endpoint compatibility
///
/// This test makes REAL HTTP requests to the EFFIS API to verify:
/// 1. The endpoint URL is correct and reachable
/// 2. Required parameters (including STYLES) are accepted
/// 3. Response format matches expected structure
///
/// Run with: flutter test test/contract/effis_endpoint_contract_test.dart
/// Note: Requires network access. Skip in CI if needed with @Tags(['contract'])
@Tags(['contract'])
library effis_endpoint_contract_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('EFFIS Endpoint Contract Tests', () {
    late http.Client httpClient;

    setUp(() {
      httpClient = http.Client();
    });

    tearDown(() {
      httpClient.close();
    });

    test(
      'WMS GetFeatureInfo endpoint accepts required parameters including STYLES',
      () async {
        // Test coordinates: Aviemore, Scotland
        const lat = 57.2;
        const lon = -3.8;
        const buffer = 0.1;

        final now = DateTime.now().toUtc();
        final currentDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final uri = Uri.parse(
          'https://maps.effis.emergency.copernicus.eu/gwis',
        ).replace(
          queryParameters: {
            'SERVICE': 'WMS',
            'VERSION': '1.3.0',
            'REQUEST': 'GetFeatureInfo',
            'LAYERS': 'nasa_geos5.query',
            'QUERY_LAYERS': 'nasa_geos5.query',
            'CRS': 'EPSG:4326',
            'BBOX':
                '${lat - buffer},${lon - buffer},${lat + buffer},${lon + buffer}',
            'WIDTH': '256',
            'HEIGHT': '256',
            'STYLES': '', // Required by MapServer 8.0+
            'I': '128',
            'J': '128',
            'INFO_FORMAT': 'text/plain',
            'FEATURE_COUNT': '1',
            'TIME': currentDate,
          },
        );

        final response = await httpClient.get(
          uri,
          headers: {
            'User-Agent': 'WildFire/0.1 (contract-test)',
            'Accept': 'text/plain,*/*;q=0.8',
          },
        ).timeout(const Duration(seconds: 10));

        // Verify successful response (not a ServiceException)
        expect(response.statusCode, equals(200),
            reason: 'EFFIS should return 200 OK');

        // Verify response is NOT an error
        expect(response.body, isNot(contains('ServiceException')),
            reason: 'Response should not be a ServiceException XML');

        // Verify response contains expected structure
        expect(response.body, contains('GetFeatureInfo results:'),
            reason: 'Response should contain GetFeatureInfo results header');

        // Verify response contains FWI data structure
        expect(response.body, contains('value_0'),
            reason: 'Response should contain value_0 (FWI value)');

        print('✅ EFFIS endpoint contract test passed');
        print('   Response length: ${response.body.length} chars');
        print('   Contains FWI data: ${response.body.contains("value_0")}');
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'WMS GetFeatureInfo fails WITHOUT STYLES parameter (MapServer 8.0+ requirement)',
      () async {
        // Test coordinates: Aviemore, Scotland
        const lat = 57.2;
        const lon = -3.8;
        const buffer = 0.1;

        final now = DateTime.now().toUtc();
        final currentDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        // Intentionally OMIT STYLES parameter
        final uri = Uri.parse(
          'https://maps.effis.emergency.copernicus.eu/gwis',
        ).replace(
          queryParameters: {
            'SERVICE': 'WMS',
            'VERSION': '1.3.0',
            'REQUEST': 'GetFeatureInfo',
            'LAYERS': 'nasa_geos5.query',
            'QUERY_LAYERS': 'nasa_geos5.query',
            'CRS': 'EPSG:4326',
            'BBOX':
                '${lat - buffer},${lon - buffer},${lat + buffer},${lon + buffer}',
            'WIDTH': '256',
            'HEIGHT': '256',
            // NO STYLES parameter!
            'I': '128',
            'J': '128',
            'INFO_FORMAT': 'text/plain',
            'FEATURE_COUNT': '1',
            'TIME': currentDate,
          },
        );

        final response = await httpClient.get(
          uri,
          headers: {
            'User-Agent': 'WildFire/0.1 (contract-test)',
            'Accept': 'text/plain,*/*;q=0.8',
          },
        ).timeout(const Duration(seconds: 10));

        // Verify this returns a ServiceException (missing STYLES)
        expect(response.body, contains('ServiceException'),
            reason: 'Missing STYLES should cause ServiceException');
        expect(response.body, contains('MissingParameterValue'),
            reason: 'Error should indicate missing parameter');
        expect(response.body.toLowerCase(), contains('styles'),
            reason: 'Error should mention STYLES parameter');

        print('✅ Verified: STYLES parameter is required');
        print('   Error correctly returned for missing STYLES');
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'EFFIS endpoint returns valid FWI value format',
      () async {
        // Use Portugal coordinates (more likely to have active fire data)
        const lat = 39.6;
        const lon = -9.1;
        const buffer = 0.1;

        final now = DateTime.now().toUtc();
        final currentDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final uri = Uri.parse(
          'https://maps.effis.emergency.copernicus.eu/gwis',
        ).replace(
          queryParameters: {
            'SERVICE': 'WMS',
            'VERSION': '1.3.0',
            'REQUEST': 'GetFeatureInfo',
            'LAYERS': 'nasa_geos5.query',
            'QUERY_LAYERS': 'nasa_geos5.query',
            'CRS': 'EPSG:4326',
            'BBOX':
                '${lat - buffer},${lon - buffer},${lat + buffer},${lon + buffer}',
            'WIDTH': '256',
            'HEIGHT': '256',
            'STYLES': '',
            'I': '128',
            'J': '128',
            'INFO_FORMAT': 'text/plain',
            'FEATURE_COUNT': '1',
            'TIME': currentDate,
          },
        );

        final response = await httpClient.get(
          uri,
          headers: {
            'User-Agent': 'WildFire/0.1 (contract-test)',
            'Accept': 'text/plain,*/*;q=0.8',
          },
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, equals(200));

        // Parse FWI value from response
        final fwiMatch =
            RegExp(r"value_0 = '([0-9.]+)'").firstMatch(response.body);
        expect(fwiMatch, isNotNull,
            reason: 'Response should contain parseable FWI value');

        if (fwiMatch != null) {
          final fwiString = fwiMatch.group(1)!;
          final fwiValue = double.tryParse(fwiString);
          expect(fwiValue, isNotNull,
              reason: 'FWI value should be a valid number');
          expect(fwiValue, greaterThanOrEqualTo(0),
              reason: 'FWI should be non-negative');
          expect(fwiValue, lessThan(200),
              reason: 'FWI should be in reasonable range (<200)');

          print('✅ FWI value parsed successfully: $fwiValue');
        }
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });
}
