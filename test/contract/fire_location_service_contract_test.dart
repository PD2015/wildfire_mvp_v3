import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/effis_fire.dart';
import 'package:wildfire_mvp_v3/models/effis_fwi_result.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service_impl.dart';
import 'package:wildfire_mvp_v3/services/mock_fire_service.dart';
import 'package:wildfire_mvp_v3/services/effis_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// Mock EFFIS service that always returns empty (forces fallback to Mock)
class _MockEffisService implements EffisService {
  @override
  Future<Either<ApiError, EffisFwiResult>> getFwi({
    required double lat,
    required double lon,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    return Left(ApiError(message: 'Mock EFFIS always fails'));
  }

  @override
  Future<Either<ApiError, List<EffisFire>>> getActiveFires(
    LatLngBounds bounds, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Return empty to force fallback to MockFireService
    return Left(ApiError(message: 'Mock EFFIS always fails'));
  }
}

/// T004: Contract test for FireLocationService.getActiveFires()
///
/// Covers mock service, bbox queries, fallback chain behavior.
void main() {
  // Initialize Flutter binding for asset loading
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FireLocationService Contract Tests', () {
    late FireLocationService service;
    late MockFireService mockService;
    late _MockEffisService effisService;

    setUp(() {
      // Initialize with real implementation using mock services
      mockService = MockFireService();
      effisService = _MockEffisService();
      service = FireLocationServiceImpl(
        effisService: effisService,
        mockService: mockService,
      );
    });

    test('Mock service returns List<FireIncident>', () async {
      // Test with Scotland bounds (contains all 3 mock fires)
      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -5.0),
        northeast: LatLng(59.0, -1.0),
      );
      final result = await service.getActiveFires(bounds);

      expect(result.isRight(), isTrue);
      final incidents = result.getOrElse(() => []);
      expect(incidents, isA<List<FireIncident>>());
      expect(incidents.length, 3); // 3 mock fires in Scotland
    });

    test('Service filters fires by bbox (Scotland coordinates)', () async {
      // Test with bounds that only include Edinburgh area
      const edinburghBounds = LatLngBounds(
        southwest: LatLng(55.9, -3.3),
        northeast: LatLng(56.0, -3.1),
      );
      final result = await service.getActiveFires(edinburghBounds);

      expect(result.isRight(), isTrue);
      final incidents = result.getOrElse(() => []);
      // Should only get Edinburgh fire, not Glasgow or Aviemore
      expect(incidents.length, 1);
      expect(incidents.first.id, 'mock_fire_001');
    });

    test('Mock service returns FireIncident with freshness=mock', () async {
      // Test that mock service marks incidents correctly
      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -5.0),
        northeast: LatLng(59.0, -1.0),
      );
      final result = await service.getActiveFires(bounds);

      expect(result.isRight(), isTrue);
      final incidents = result.getOrElse(() => []);
      // Mock service marks all incidents as mock
      expect(incidents.every((i) => i.source == DataSource.mock), isTrue);
      expect(incidents.every((i) => i.freshness == Freshness.mock), isTrue);
    });

    test('Mock service never fails', () async {
      // Mock service should always return Right, even with empty results
      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -5.0),
        northeast: LatLng(59.0, -1.0),
      );
      final result = await service.getActiveFires(bounds);

      // Always returns Right (never Left/error)
      expect(result.isRight(), isTrue);
      final incidents = result.getOrElse(() => []);
      expect(incidents, isNotEmpty); // Mock data has 3 fires
    });

    test('bbox validation (southwest < northeast)', () {
      // Invalid bbox (northeast < southwest) should throw with validated constructor
      expect(
        () => LatLngBounds.validated(
          southwest: const LatLng(59.0, -1.0), // Higher latitude
          northeast: const LatLng(55.0, -5.0), // Lower latitude
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Valid bbox should not throw
      expect(
        () => const LatLngBounds(
          southwest: LatLng(55.0, -5.0),
          northeast: LatLng(59.0, -1.0),
        ),
        returnsNormally,
      );
    });

    test('Mock service responds quickly (performance check)', () async {
      // Mock service should be fast (no network calls)
      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -5.0),
        northeast: LatLng(59.0, -1.0),
      );

      final stopwatch = Stopwatch()..start();
      await service.getActiveFires(bounds);
      stopwatch.stop();

      // Mock service should complete in <100ms (asset loading)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('empty bbox returns empty list (no fires in region)', () async {
      // Test with bounds outside Scotland (no mock fires)
      const londonBounds = LatLngBounds(
        southwest: LatLng(51.0, -1.0),
        northeast: LatLng(52.0, 0.0),
      );
      final result = await service.getActiveFires(londonBounds);

      expect(result.isRight(), isTrue);
      final incidents = result.getOrElse(() => []);
      expect(incidents, isEmpty); // No mock fires in London area
    });
  });
}
