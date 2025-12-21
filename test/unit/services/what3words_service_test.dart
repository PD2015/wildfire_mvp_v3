import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/what3words_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/what3words_service_impl.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

void main() {
  group('What3wordsServiceImpl', () {
    const testApiKey = 'test-api-key';
    const testLat = 55.9533;
    const testLon = -3.1883;
    const testWords = 'index.home.raft';

    group('convertTo3wa', () {
      test('returns address on successful response', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, equals('api.what3words.com'));
          expect(request.url.path, equals('/v3/convert-to-3wa'));
          expect(
            request.url.queryParameters['coordinates'],
            equals('$testLat,$testLon'),
          );
          expect(request.url.queryParameters['key'], equals(testApiKey));

          return http.Response(
            jsonEncode({
              'country': 'GB',
              'words': testWords,
              'nearestPlace': 'Edinburgh, Scotland',
              'coordinates': {'lng': testLon, 'lat': testLat},
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success, got error: $error'), (
          address,
        ) {
          expect(address.words, equals(testWords));
          expect(address.displayFormat, equals('///$testWords'));
        });
      });

      test('returns error when API key is empty', () async {
        // Mock should never be called - empty key returns early
        var clientCalled = false;
        final mockClient = MockClient((request) async {
          clientCalled = true;
          return http.Response('', 500);
        });

        final service = What3wordsServiceImpl(client: mockClient, apiKey: '');

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(clientCalled, isFalse);
        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          expect((error as What3wordsApiError).code, equals('NoApiKey'));
        }, (address) => fail('Expected error, got address: $address'));
      });

      test('returns error on 401 unauthorized', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          final apiError = error as What3wordsApiError;
          expect(apiError.code, equals('InvalidKey'));
          expect(apiError.statusCode, equals(401));
        }, (address) => fail('Expected error'));
      });

      test('returns error on 429 rate limit', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Rate limited', 429);
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          final apiError = error as What3wordsApiError;
          expect(apiError.code, equals('QuotaExceeded'));
          expect(apiError.statusCode, equals(429));
        }, (address) => fail('Expected error'));
      });

      test('returns error on API error response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'BadCoordinates',
                'message': 'Invalid coordinates',
              },
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          final apiError = error as What3wordsApiError;
          expect(apiError.code, equals('BadCoordinates'));
          expect(apiError.message, equals('Invalid coordinates'));
        }, (address) => fail('Expected error'));
      });

      test('returns error on missing words in response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'country': 'GB',
              // 'words' missing
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          expect((error as What3wordsApiError).code, equals('InvalidResponse'));
        }, (address) => fail('Expected error'));
      });

      test('returns network error on HTTP exception', () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsNetworkError>());
          expect(
            (error as What3wordsNetworkError).details,
            contains('Connection refused'),
          );
        }, (address) => fail('Expected error'));
      });

      test('returns error on generic HTTP errors', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 503);
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertTo3wa(lat: testLat, lon: testLon);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          final apiError = error as What3wordsApiError;
          expect(apiError.code, equals('HttpError'));
          expect(apiError.statusCode, equals(503));
        }, (address) => fail('Expected error'));
      });
    });

    group('convertToCoordinates', () {
      test('returns coordinates on successful response', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, equals('api.what3words.com'));
          expect(request.url.path, equals('/v3/convert-to-coordinates'));
          expect(request.url.queryParameters['words'], equals(testWords));
          expect(request.url.queryParameters['key'], equals(testApiKey));

          return http.Response(
            jsonEncode({
              'country': 'GB',
              'words': testWords,
              'coordinates': {'lat': testLat, 'lng': testLon},
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertToCoordinates(words: testWords);

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected success, got error: $error'), (
          coords,
        ) {
          expect(coords.latitude, equals(testLat));
          expect(coords.longitude, equals(testLon));
        });
      });

      test('validates format before API call', () async {
        // Mock should never be called - invalid format returns early
        var clientCalled = false;
        final mockClient = MockClient((request) async {
          clientCalled = true;
          return http.Response('', 500);
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertToCoordinates(words: 'invalid');

        expect(clientCalled, isFalse);
        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsInvalidAddressError>());
          expect(
            (error as What3wordsInvalidAddressError).input,
            equals('invalid'),
          );
        }, (coords) => fail('Expected error'));
      });

      test('normalizes address with slashes before API call', () async {
        final mockClient = MockClient((request) async {
          // Should strip the slashes before sending
          expect(request.url.queryParameters['words'], equals(testWords));
          return http.Response(
            jsonEncode({
              'coordinates': {'lat': testLat, 'lng': testLon},
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertToCoordinates(
          words: '///$testWords',
        );
        expect(result.isRight(), isTrue);
      });

      test('returns error when API key is empty', () async {
        // Mock should never be called - empty key returns early
        var clientCalled = false;
        final mockClient = MockClient((request) async {
          clientCalled = true;
          return http.Response('', 500);
        });

        final service = What3wordsServiceImpl(client: mockClient, apiKey: '');

        final result = await service.convertToCoordinates(words: testWords);

        expect(clientCalled, isFalse);
        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          expect((error as What3wordsApiError).code, equals('NoApiKey'));
        }, (coords) => fail('Expected error'));
      });

      test('returns error on BadWords API response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'BadWords',
                'message': 'what3words address not found',
              },
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        // Valid format but nonexistent address
        final result = await service.convertToCoordinates(
          words: 'fake.fake.fake',
        );

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          // BadWords should be converted to InvalidAddressError
          expect(error, isA<What3wordsInvalidAddressError>());
        }, (coords) => fail('Expected error'));
      });

      test('returns error on 401 unauthorized', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertToCoordinates(words: testWords);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          final apiError = error as What3wordsApiError;
          expect(apiError.code, equals('InvalidKey'));
          expect(apiError.statusCode, equals(401));
        }, (coords) => fail('Expected error'));
      });

      test('returns error on missing coordinates in response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'words': testWords,
              // 'coordinates' missing
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertToCoordinates(words: testWords);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          expect((error as What3wordsApiError).code, equals('InvalidResponse'));
        }, (coords) => fail('Expected error'));
      });

      test('returns error on missing lat/lng in coordinates', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'coordinates': {'lat': testLat}, // missing lng
            }),
            200,
          );
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertToCoordinates(words: testWords);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsApiError>());
          expect((error as What3wordsApiError).code, equals('InvalidResponse'));
        }, (coords) => fail('Expected error'));
      });

      test('returns network error on HTTP exception', () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Network timeout');
        });

        final service = What3wordsServiceImpl(
          client: mockClient,
          apiKey: testApiKey,
        );

        final result = await service.convertToCoordinates(words: testWords);

        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, isA<What3wordsNetworkError>());
        }, (coords) => fail('Expected error'));
      });
    });

    group('interface contract', () {
      test('What3wordsServiceImpl implements What3wordsService', () {
        final service = What3wordsServiceImpl(apiKey: testApiKey);
        expect(service, isA<What3wordsService>());
      });
    });
  });
}
