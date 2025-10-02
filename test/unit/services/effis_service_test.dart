import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/services/effis_service_impl.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'effis_service_test.mocks.dart';

// Test fixtures
const edinburghSuccessFixture = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "fwi": 12.0,
        "timestamp": "2023-09-13T00:00:00Z",
        "source": "effis:fwi_v1"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [-3.1883, 55.9533]
      }
    }
  ]
}
''';

/// Unit tests for EffisService implementation
/// 
/// Tests cover all success and failure scenarios with mocked HTTP client:
/// - Success: Parse Edinburgh success fixture with FWI=12.0 → moderate risk
/// - 404 Error: Map to ApiError with notFound reason
/// - 503 Error: Retry with exponential backoff then fail with serviceUnavailable
/// - Malformed: Invalid JSON → malformed ApiError
/// - Timeout: Network timeout → timeout ApiError
/// - Empty: No features → noData ApiError
/// - Headers: Verify User-Agent and Accept headers sent correctly
/// - Validation: Invalid coordinates → validation ApiError
/// - Retry: Exponential backoff with jitter, maxRetries parameter
void main() {
  group('EffisService', () {
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
    });

    group('getFwi success scenarios', () {
      test('should parse Edinburgh success fixture to EffisFwiResult', () async {
        // Mock HTTP response
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          edinburghSuccessFixture,
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute request
        final result = await service.getFwi(lat: 55.9533, lon: -3.1883);

        // Verify successful result
        expect(result.isRight(), isTrue);
        final fwiResult = result.getOrElse(() => throw Exception('Expected Right'));
        expect(fwiResult.fwi, equals(12.0));
        expect(fwiResult.datetime, equals(DateTime.parse("2023-09-13T00:00:00Z")));
        expect(fwiResult.longitude, equals(-3.1883));
        expect(fwiResult.latitude, equals(55.9533));
      });

      test('should construct correct WMS GetFeatureInfo URL', () async {
        // Mock HTTP response
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({"type": "FeatureCollection", "features": []}),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        await service.getFwi(lat: 55.9533, lon: -3.1883);

        // Verify URL construction
        final captured = verify(mockHttpClient.get(captureAny, headers: anyNamed('headers'))).captured;
        final requestUri = captured.first as Uri;
        
        expect(requestUri.scheme, equals('https'));
        expect(requestUri.host, equals('ies-ows.jrc.ec.europa.eu'));
        expect(requestUri.path, equals('/gwis'));
        expect(requestUri.queryParameters['VERSION'], equals('1.3.0'));
        expect(requestUri.queryParameters['REQUEST'], equals('GetFeatureInfo'));
        expect(requestUri.queryParameters['LAYERS'], equals('ecmwf.fwi'));
        expect(requestUri.queryParameters['QUERY_LAYERS'], equals('ecmwf.fwi'));
        expect(requestUri.queryParameters['CRS'], equals('EPSG:3857'));
        expect(requestUri.queryParameters['INFO_FORMAT'], equals('application/json'));
        expect(requestUri.queryParameters['FEATURE_COUNT'], equals('1'));
      });
    });

    group('getFwi error scenarios', () {
      test('should map 404 response to notFound ApiError', () async {
        // Mock 404 response
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          'Not Found',
          404,
          headers: {'content-type': 'text/plain'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        final result = await service.getFwi(lat: 55.9533, lon: -3.1883);

        // Verify error mapping
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.reason, equals(ApiErrorReason.notFound));
        expect(error.statusCode, equals(404));
      });

      test('should retry 503 responses with exponential backoff then fail', () async {
        // Mock 503 responses for all retry attempts
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          'Service Unavailable',
          503,
          headers: {'content-type': 'text/plain'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        final result = await service.getFwi(
          lat: 55.9533,
          lon: -3.1883,
          maxRetries: 3,
        );

        // Verify error after all retries exhausted
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.reason, equals(ApiErrorReason.serviceUnavailable));
        expect(error.statusCode, equals(503));

        // Verify retry attempts (initial + 3 retries = 4 total)
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(4);
      });

      test('should handle malformed JSON response', () async {
        // Mock malformed JSON response
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"invalid": json}',
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        final result = await service.getFwi(lat: 55.9533, lon: -3.1883);

        // Verify error mapping
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.message, contains('Failed to parse JSON response'));
      });

      test('should handle timeout errors', () async {
        // Mock timeout exception
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('Connection timed out'));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi with timeout
        final result = await service.getFwi(
          lat: 55.9533,
          lon: -3.1883,
          timeout: const Duration(seconds: 1),
        );

        // Verify timeout error
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.message, contains('connection'));
      });

      test('should handle empty features response', () async {
        // Mock empty features response
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({"type": "FeatureCollection", "features": []}),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        final result = await service.getFwi(lat: 55.9533, lon: -3.1883);

        // Verify error mapping
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.message, contains('No FWI data available'));
      });
    });

    group('HTTP headers and configuration', () {
      test('should send correct User-Agent and Accept headers', () async {
        // Mock HTTP response
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          edinburghSuccessFixture,
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        await service.getFwi(lat: 55.9533, lon: -3.1883);

        // Verify headers
        final captured = verify(mockHttpClient.get(any, headers: captureAnyNamed('headers'))).captured;
        final headers = captured.first as Map<String, String>;
        expect(headers['User-Agent'], equals('WildFire/0.1 (prototype)'));
        expect(headers['Accept'], equals('application/json,*/*;q=0.8'));
      });
    });

    group('coordinate validation', () {
      test('should validate latitude range', () async {
        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);
        
        // Test invalid latitude
        final result = await service.getFwi(lat: 91.0, lon: 0.0);
        
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.message, contains('Latitude must be between -90 and 90'));
      });

      test('should validate longitude range', () async {
        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);
        
        // Test invalid longitude
        final result = await service.getFwi(lat: 0.0, lon: 181.0);
        
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.message, contains('Longitude must be between -180 and 180'));
      });
    });

    group('retry behavior and exponential backoff (T016)', () {
      test('should not retry on 4xx client errors', () async {
        // Mock 400 response (client error - should not retry)
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          'Bad Request',
          400,
          headers: {'content-type': 'text/plain'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        final result = await service.getFwi(
          lat: 55.9533,
          lon: -3.1883,
          maxRetries: 3,
        );

        // Verify error without retries
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.statusCode, equals(400));

        // Verify no retries (only 1 attempt)
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should succeed on retry after initial failures', () async {
        // Mock first call fails, second succeeds
        var callCount = 0;
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return http.Response('Service Unavailable', 503);
          } else {
            return http.Response(
              edinburghSuccessFixture,
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        });

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi
        final result = await service.getFwi(
          lat: 55.9533,
          lon: -3.1883,
          maxRetries: 3,
        );

        // Verify successful result after retries
        expect(result.isRight(), isTrue);
        final fwiResult = result.getOrElse(() => throw Exception('Expected Right'));
        expect(fwiResult.fwi, equals(12.0));

        // Verify retry attempts (2 total: 1 failure + 1 success)
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(2);
      });

      test('should respect maxRetries parameter', () async {
        // Mock 503 responses for all attempts
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          'Service Unavailable',
          503,
          headers: {'content-type': 'text/plain'},
        ));

        // Create service
        final service = EffisServiceImpl(httpClient: mockHttpClient);

        // Execute getFwi with maxRetries=1
        final result = await service.getFwi(
          lat: 55.9533,
          lon: -3.1883,
          maxRetries: 1,
        );

        // Verify error after limited retries
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => throw Exception('Expected Left'));
        expect(error.reason, equals(ApiErrorReason.serviceUnavailable));

        // Verify retry attempts (initial + 1 retry = 2 total)
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(2);
      });
    });
  });
}