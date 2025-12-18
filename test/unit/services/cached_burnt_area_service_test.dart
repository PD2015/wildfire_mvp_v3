import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/cached_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';

/// Mock live service for testing
class MockLiveBurntAreaService implements EffisBurntAreaService {
  int callCount = 0;
  List<BurntArea> mockAreas = [];

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
  }) async {
    callCount++;
    return Right(mockAreas);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CachedBurntAreaService', () {
    late MockLiveBurntAreaService mockLiveService;
    late CachedBurntAreaService cachedService;

    setUp(() {
      mockLiveService = MockLiveBurntAreaService();
      cachedService = CachedBurntAreaService(liveService: mockLiveService);
    });

    group('Historical year detection', () {
      test('2024 is a historical year (bundled)', () {
        expect(CachedBurntAreaService.hasCachedData(2024), isTrue);
      });

      test('2025 is not a historical year (live)', () {
        expect(CachedBurntAreaService.hasCachedData(2025), isFalse);
      });

      test('2023 is not a historical year (not yet bundled)', () {
        expect(CachedBurntAreaService.hasCachedData(2023), isFalse);
      });
    });

    group('Current season (live service)', () {
      test('thisSeason (2025) uses live service', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(56.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        );

        mockLiveService.mockAreas = [
          BurntArea(
            id: '1',
            boundaryPoints: const [
              LatLng(57.0, -3.5),
              LatLng(57.1, -3.5),
              LatLng(57.1, -3.4),
            ],
            areaHectares: 50,
            fireDate: DateTime(2025, 3, 15),
            seasonYear: 2025,
          ),
        ];

        final result = await cachedService.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason, // 2025
        );

        expect(mockLiveService.callCount, 1);
        expect(result.isRight(), isTrue);
        result.fold(
          (error) => fail('Expected success'),
          (areas) => expect(areas.length, 1),
        );
      });

      test('does not call live service for 2024 (bundled)', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(56.0, -4.0),
          northeast: LatLng(58.0, -3.0),
        );

        // This will fail to load asset (no mock) but won't call live service
        await cachedService.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.lastSeason, // 2024
        );

        // Should NOT call live service for historical year
        expect(mockLiveService.callCount, 0);
      });
    });

    group('Season filter year calculation', () {
      test('thisSeason returns current year (2025)', () {
        expect(BurntAreaSeasonFilter.thisSeason.year, 2025);
      });

      test('lastSeason returns previous year (2024)', () {
        expect(BurntAreaSeasonFilter.lastSeason.year, 2024);
      });
    });
  });
}
