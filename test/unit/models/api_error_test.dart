import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';

/// Unit tests for ApiError categorization
///
/// Tests verify correct HTTP status code mapping to error reasons
/// per docs/data-model.md error categorization:
/// - 404 → notFound
/// - 503 → serviceUnavailable
/// - Other errors → general
void main() {
  group('ApiError', () {
    group('reason categorization from HTTP status codes', () {
      test('404 status should map to notFound reason', () {
        // Test 404 status maps to notFound
        final error = ApiError(
          message: 'Service endpoint not found',
          statusCode: 404,
        );
        expect(error.reason, equals(ApiErrorReason.notFound));
      });

      test('503 status should map to serviceUnavailable reason', () {
        // Test 503 status maps to serviceUnavailable
        final error = ApiError(
          message: 'Service temporarily unavailable',
          statusCode: 503,
        );
        expect(error.reason, equals(ApiErrorReason.serviceUnavailable));
      });

      test('other status codes should map to general reason', () {
        // Test various non-404/503 codes map to general
        final error500 = ApiError(
          message: 'Internal server error',
          statusCode: 500,
        );
        expect(error500.reason, equals(ApiErrorReason.general));

        final error400 = ApiError(
          message: 'Bad request',
          statusCode: 400,
        );
        expect(error400.reason, equals(ApiErrorReason.general));
      });
    });

    group('error creation from fixture scenarios', () {
      test('should create 404 error matching test fixture', () {
        // Create error matching our 404.json fixture
        final error = ApiError(
          message: 'Not Found',
          statusCode: 404,
        );
        expect(error.message, equals('Not Found'));
        expect(error.statusCode, equals(404));
        expect(error.reason, equals(ApiErrorReason.notFound));
      });

      test('should create 503 error matching test fixture', () {
        // Create error matching our 503.json fixture
        final error = ApiError(
          message: 'Service Unavailable',
          statusCode: 503,
        );
        expect(error.message, equals('Service Unavailable'));
        expect(error.statusCode, equals(503));
        expect(error.reason, equals(ApiErrorReason.serviceUnavailable));
      });

      test('should create malformed data error', () {
        // Error for malformed JSON responses
        final error = ApiError(
          message: 'Invalid JSON format in response',
          statusCode: 200, // Valid HTTP but invalid data
        );
        expect(error.reason, equals(ApiErrorReason.general));
      });
    });

    group('validation and edge cases', () {
      test('should require non-empty message', () {
        // Empty message should be invalid
        expect(
            () => ApiError(message: '', statusCode: 404), throwsArgumentError);
      });

      test('should accept null status code for non-HTTP errors', () {
        // Non-HTTP errors might not have status codes
        final error = ApiError(
          message: 'Network connection failed',
          statusCode: null,
        );
        expect(error.reason, equals(ApiErrorReason.general));
      });

      test('should handle unknown status codes gracefully', () {
        // Unusual status codes should not crash
        final error = ApiError(
          message: 'Unknown error',
          statusCode: 999,
        );
        expect(error.reason, equals(ApiErrorReason.general));
      });
    });

    group('enum values and string representation', () {
      test('should have correct ApiErrorReason enum values', () {
        // Verify all expected error reasons exist
        expect(ApiErrorReason.values.length, equals(3));
        expect(ApiErrorReason.values, contains(ApiErrorReason.notFound));
        expect(
            ApiErrorReason.values, contains(ApiErrorReason.serviceUnavailable));
        expect(ApiErrorReason.values, contains(ApiErrorReason.general));
      });

      test('should provide useful toString() representation', () {
        // Error should have readable string representation
        final error = ApiError(
          message: 'Test error',
          statusCode: 404,
        );
        final errorString = error.toString();
        expect(errorString, contains('Test error'));
        expect(errorString, contains('404'));
      });
    });

    group('equatable behavior', () {
      test('should be equal when all properties match', () {
        // Same errors should be equal (for testing and caching)
        final error1 = ApiError(message: 'Not Found', statusCode: 404);
        final error2 = ApiError(message: 'Not Found', statusCode: 404);
        expect(error1, equals(error2));
        expect(error1.hashCode, equals(error2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Different errors should not be equal
        final error1 = ApiError(message: 'Not Found', statusCode: 404);
        final error2 = ApiError(message: 'Server Error', statusCode: 500);
        expect(error1, isNot(equals(error2)));
      });
    });
  });
}
