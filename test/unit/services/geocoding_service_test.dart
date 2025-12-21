import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service_impl.dart';

void main() {
  group('GeocodingServiceImpl', () {
    const testApiKey = 'test-api-key';
    const testLat = 55.9533;
    const testLon = -3.1883;

    group('reverseGeocode', () {
      test('returns place name on successful response', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, equals('maps.googleapis.com'));
          expect(request.url.path, equals('/maps/api/geocode/json'));
          expect(
            request.url.queryParameters['latlng'],
            equals('$testLat,$testLon'),
          );
          expect(request.url.queryParameters['key'], equals(testApiKey));

          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'formatted_address': 'Edinburgh, Scotland, UK',
                  'address_components': [
                    {
                      'long_name': 'Edinburgh',
                      'short_name': 'Edinburgh',
                      'types': ['locality', 'political'],
                    },
                    {
                      'long_name': 'City of Edinburgh',
                      'short_name': 'City of Edinburgh',
                      'types': ['administrative_area_level_2', 'political'],
                    },
                    {
                      'long_name': 'Scotland',
                      'short_name': 'Scotland',
                      'types': ['administrative_area_level_1', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success, got error: $error'), (
          placeName,
        ) {
          expect(placeName, equals('Edinburgh'));
        });
      });

      test('prioritizes locality over admin areas', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'formatted_address': 'Somewhere, UK',
                  'address_components': [
                    {
                      'long_name': 'Highland',
                      'short_name': 'Highland',
                      'types': ['administrative_area_level_2', 'political'],
                    },
                    {
                      'long_name': 'Aviemore',
                      'short_name': 'Aviemore',
                      'types': ['locality', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (placeName) {
          expect(placeName, equals('Aviemore')); // locality first
        });
      });

      test('falls back to admin_area_level_2 when no locality', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'formatted_address': 'Somewhere, UK',
                  'address_components': [
                    {
                      'long_name': 'Highland',
                      'short_name': 'Highland',
                      'types': ['administrative_area_level_2', 'political'],
                    },
                    {
                      'long_name': 'Scotland',
                      'short_name': 'Scotland',
                      'types': ['administrative_area_level_1', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (placeName) {
          expect(placeName, equals('Highland'));
        });
      });

      test(
        'falls back to formatted_address when no components match',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response(
              jsonEncode({
                'status': 'OK',
                'results': [
                  {
                    'formatted_address': 'Middle of Nowhere, UK',
                    'address_components': [
                      {
                        'long_name': 'United Kingdom',
                        'short_name': 'UK',
                        'types': ['country', 'political'],
                      },
                    ],
                  },
                ],
              }),
              200,
            );
          });

          final service = GeocodingServiceImpl(
            client: mockClient,
            apiKey: testApiKey,
          );

          final result = await service.reverseGeocode(
            lat: testLat,
            lon: testLon,
          );

          expect(result.isRight(), isTrue);
          result.fold((error) => fail('Expected success'), (placeName) {
            expect(placeName, equals('Middle of Nowhere, UK'));
          });
        },
      );

      test('returns error when API key is empty', () async {
        var clientCalled = false;
        final mockClient = MockClient((request) async {
          clientCalled = true;
          return http.Response('', 500);
        });

        final service = GeocodingServiceImpl(client: mockClient, apiKey: '');

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(clientCalled, isFalse);
        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingApiError>());
        }, (name) => fail('Expected error'));
      });

      test('returns error on ZERO_RESULTS', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'status': 'ZERO_RESULTS', 'results': []}),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingNoResultsError>());
        }, (name) => fail('Expected error'));
      });

      test('returns error on REQUEST_DENIED', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'REQUEST_DENIED',
              'error_message': 'API key is invalid',
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingApiError>());
        }, (name) => fail('Expected error'));
      });

      test('returns network error on HTTP exception', () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingNetworkError>());
          expect(
            (error as GeocodingNetworkError).message,
            contains('Connection refused'),
          );
        }, (name) => fail('Expected error'));
      });

      test('returns error on HTTP errors', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 503);
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingApiError>());
          expect((error as GeocodingApiError).statusCode, equals(503));
        }, (name) => fail('Expected error'));
      });

      test('formats natural features with Near prefix', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'types': ['natural_feature'],
                  'formatted_address': 'Ben Wyvis, Highland, UK',
                  'address_components': [
                    {
                      'long_name': 'Ben Wyvis',
                      'short_name': 'Ben Wyvis',
                      'types': ['natural_feature'],
                    },
                    {
                      'long_name': 'Highland',
                      'short_name': 'Highland',
                      'types': ['administrative_area_level_2', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (placeName) {
          expect(placeName, equals('Near Ben Wyvis'));
        });
      });

      test('prefers postal_town over admin areas', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'types': ['postal_code'],
                  'formatted_address': 'PH22 1RH, Aviemore, UK',
                  'address_components': [
                    {
                      'long_name': 'Aviemore',
                      'short_name': 'Aviemore',
                      'types': ['postal_town'],
                    },
                    {
                      'long_name': 'Highland Council',
                      'short_name': 'Highland Council',
                      'types': ['administrative_area_level_2', 'political'],
                    },
                    {
                      'long_name': 'Scotland',
                      'short_name': 'Scotland',
                      'types': ['administrative_area_level_1', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (placeName) {
          expect(placeName, equals('Aviemore'));
        });
      });

      test('skips council-style admin names when Scotland available', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'types': ['administrative_area_level_2', 'political'],
                  'formatted_address': 'Highland Council, Scotland, UK',
                  'address_components': [
                    {
                      'long_name': 'Highland Council',
                      'short_name': 'Highland Council',
                      'types': ['administrative_area_level_2', 'political'],
                    },
                    {
                      'long_name': 'Scotland',
                      'short_name': 'Scotland',
                      'types': ['administrative_area_level_1', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (placeName) {
          // Should prefer "Scotland" over "Highland Council"
          expect(placeName, equals('Scotland'));
        });
      });

      test('extracts best name from multiple results', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                // First result: just admin areas
                {
                  'types': ['administrative_area_level_2', 'political'],
                  'formatted_address': 'Highland, Scotland, UK',
                  'address_components': [
                    {
                      'long_name': 'Highland',
                      'short_name': 'Highland',
                      'types': ['administrative_area_level_2', 'political'],
                    },
                  ],
                },
                // Second result: has locality - should be preferred
                {
                  'types': ['locality', 'political'],
                  'formatted_address': 'Aviemore, Highland, UK',
                  'address_components': [
                    {
                      'long_name': 'Aviemore',
                      'short_name': 'Aviemore',
                      'types': ['locality', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (placeName) {
          // Should extract locality from second result
          expect(placeName, equals('Aviemore'));
        });
      });
    });

    group('searchPlaces', () {
      test('returns results on successful response', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['address'], equals('Edinburgh'));
          expect(request.url.queryParameters['region'], equals('uk'));

          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'place_id': 'ChIJIyaYpQC4h0gRJxfnfHsU8mQ',
                  'formatted_address': 'Edinburgh, UK',
                  'geometry': {
                    'location': {'lat': 55.9533, 'lng': -3.1883},
                  },
                  'address_components': [
                    {
                      'long_name': 'Edinburgh',
                      'short_name': 'Edinburgh',
                      'types': ['locality', 'political'],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.searchPlaces(query: 'Edinburgh');

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success, got error: $error'), (
          places,
        ) {
          expect(places.length, equals(1));
          expect(places.first.name, equals('Edinburgh'));
          expect(places.first.coordinates?.latitude, equals(55.9533));
          expect(places.first.coordinates?.longitude, equals(-3.1883));
        });
      });

      test('returns empty list on ZERO_RESULTS', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'status': 'ZERO_RESULTS', 'results': []}),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.searchPlaces(query: 'nonexistent place');

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (places) {
          expect(places, isEmpty);
        });
      });

      test('returns empty list for empty query', () async {
        var clientCalled = false;
        final mockClient = MockClient((request) async {
          clientCalled = true;
          return http.Response('', 500);
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.searchPlaces(query: '');

        expect(clientCalled, isFalse);
        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (places) {
          expect(places, isEmpty);
        });
      });

      test('respects maxResults parameter', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {'place_id': '1', 'formatted_address': 'Place 1'},
                {'place_id': '2', 'formatted_address': 'Place 2'},
                {'place_id': '3', 'formatted_address': 'Place 3'},
                {'place_id': '4', 'formatted_address': 'Place 4'},
                {'place_id': '5', 'formatted_address': 'Place 5'},
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.searchPlaces(query: 'test', maxResults: 2);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success'), (places) {
          expect(places.length, equals(2));
        });
      });

      test('returns error on OVER_QUERY_LIMIT', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'OVER_QUERY_LIMIT',
              'error_message': 'Quota exceeded',
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.searchPlaces(query: 'test');

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingApiError>());
          expect(
            (error as GeocodingApiError).message,
            contains('quota exceeded'),
          );
        }, (places) => fail('Expected error'));
      });
    });

    group('getPlaceCoordinates', () {
      test('returns coordinates on successful response', () async {
        const placeId = 'ChIJIyaYpQC4h0gRJxfnfHsU8mQ';
        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['place_id'], equals(placeId));

          return http.Response(
            jsonEncode({
              'status': 'OK',
              'results': [
                {
                  'geometry': {
                    'location': {'lat': 55.9533, 'lng': -3.1883},
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.getPlaceCoordinates(placeId: placeId);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success, got error: $error'), (
          coords,
        ) {
          expect(coords.latitude, equals(55.9533));
          expect(coords.longitude, equals(-3.1883));
        });
      });

      test('returns error on ZERO_RESULTS', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'status': 'ZERO_RESULTS', 'results': []}),
            200,
          );
        });

        final service = GeocodingServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.getPlaceCoordinates(
          placeId: 'invalid_place_id',
        );

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingNoResultsError>());
        }, (coords) => fail('Expected error'));
      });

      test('returns error when API key is empty', () async {
        var clientCalled = false;
        final mockClient = MockClient((request) async {
          clientCalled = true;
          return http.Response('', 500);
        });

        final service = GeocodingServiceImpl(client: mockClient, apiKey: '');

        final result = await service.getPlaceCoordinates(placeId: 'test');

        expect(clientCalled, isFalse);
        expect(result.isLeft(), isTrue);
      });
    });

    group('buildStaticMapUrl', () {
      test('builds URL with required parameters', () {
        final service = GeocodingServiceImpl(apiKey: testApiKey);

        final url = service.buildStaticMapUrl(lat: testLat, lon: testLon);

        expect(url, contains('maps.googleapis.com'));
        expect(url, contains('staticmap'));
        expect(url, contains('center=$testLat%2C$testLon'));
        expect(url, contains('key=$testApiKey'));
      });

      test('builds URL with custom parameters', () {
        final service = GeocodingServiceImpl(apiKey: testApiKey);

        final url = service.buildStaticMapUrl(
          lat: testLat,
          lon: testLon,
          zoom: 16,
          width: 400,
          height: 300,
          markerColor: 'blue',
        );

        expect(url, contains('zoom=16'));
        expect(url, contains('size=400x300'));
        expect(url, contains('color%3Ablue'));
      });

      test('includes scale parameter for retina', () {
        final service = GeocodingServiceImpl(apiKey: testApiKey);

        final url = service.buildStaticMapUrl(lat: testLat, lon: testLon);

        expect(url, contains('scale=2'));
      });
    });

    group('interface contract', () {
      test('GeocodingServiceImpl implements GeocodingService', () {
        final service = GeocodingServiceImpl(apiKey: testApiKey);
        expect(service, isA<GeocodingService>());
      });
    });

    group('empty API key handling', () {
      test('reverseGeocode returns error when API key is empty', () async {
        final service = GeocodingServiceImpl(apiKey: '');

        final result = await service.reverseGeocode(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingApiError>());
          final apiError = error as GeocodingApiError;
          expect(apiError.message, contains('API key not configured'));
        }, (_) => fail('Expected error, got success'));
      });

      test('searchPlaces returns error when API key is empty', () async {
        final service = GeocodingServiceImpl(apiKey: '');

        final result = await service.searchPlaces(query: 'Edinburgh');

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<GeocodingApiError>());
          final apiError = error as GeocodingApiError;
          expect(apiError.message, contains('API key not configured'));
        }, (_) => fail('Expected error, got success'));
      });

      test('buildStaticMapUrl handles empty API key gracefully', () {
        final service = GeocodingServiceImpl(apiKey: '');

        // Static map URL should still be built but with empty key
        // This allows the UI to show a placeholder or error
        final url = service.buildStaticMapUrl(lat: testLat, lon: testLon);

        expect(url, isNotEmpty);
        // URL is still valid structure even with empty key
        expect(url, contains('staticmap'));
        expect(url, contains('center='));
      });
    });
  });
}
