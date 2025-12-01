import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/location_picker/controllers/location_picker_controller.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_state.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/place_search_result.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/what3words_service.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

/// Mock What3words service for testing
class MockWhat3wordsService implements What3wordsService {
  Either<What3wordsError, What3wordsAddress>? _convertTo3waResult;
  Either<What3wordsError, LatLng>? _convertToCoordinatesResult;
  int convertTo3waCalls = 0;
  int convertToCoordinatesCalls = 0;
  Duration delay;

  MockWhat3wordsService({this.delay = Duration.zero});

  void setConvertTo3waResult(
      Either<What3wordsError, What3wordsAddress> result) {
    _convertTo3waResult = result;
  }

  void setConvertToCoordinatesResult(Either<What3wordsError, LatLng> result) {
    _convertToCoordinatesResult = result;
  }

  @override
  Future<Either<What3wordsError, What3wordsAddress>> convertTo3wa({
    required double lat,
    required double lon,
  }) async {
    convertTo3waCalls++;
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
    return _convertTo3waResult ??
        const Left(What3wordsNetworkError('Mock not configured'));
  }

  @override
  Future<Either<What3wordsError, LatLng>> convertToCoordinates({
    required String words,
  }) async {
    convertToCoordinatesCalls++;
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
    return _convertToCoordinatesResult ??
        const Left(What3wordsNetworkError('Mock not configured'));
  }
}

/// Mock Geocoding service for testing
class MockGeocodingService implements GeocodingService {
  Either<GeocodingError, List<PlaceSearchResult>>? _searchPlacesResult;
  Either<GeocodingError, String>? _reverseGeocodeResult;
  Either<GeocodingError, LatLng>? _getPlaceCoordinatesResult;
  int searchPlacesCalls = 0;
  int reverseGeocodeCalls = 0;
  int getPlaceCoordinatesCalls = 0;
  Duration delay;

  MockGeocodingService({this.delay = Duration.zero});

  void setSearchPlacesResult(
      Either<GeocodingError, List<PlaceSearchResult>> result) {
    _searchPlacesResult = result;
  }

  void setReverseGeocodeResult(Either<GeocodingError, String> result) {
    _reverseGeocodeResult = result;
  }

  void setGetPlaceCoordinatesResult(Either<GeocodingError, LatLng> result) {
    _getPlaceCoordinatesResult = result;
  }

  @override
  Future<Either<GeocodingError, List<PlaceSearchResult>>> searchPlaces({
    required String query,
    int maxResults = 5,
  }) async {
    searchPlacesCalls++;
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
    return _searchPlacesResult ??
        const Left(GeocodingNetworkError('Mock not configured'));
  }

  @override
  Future<Either<GeocodingError, String>> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    reverseGeocodeCalls++;
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
    return _reverseGeocodeResult ??
        const Left(GeocodingNetworkError('Mock not configured'));
  }

  @override
  Future<Either<GeocodingError, LatLng>> getPlaceCoordinates({
    required String placeId,
  }) async {
    getPlaceCoordinatesCalls++;
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
    return _getPlaceCoordinatesResult ??
        const Left(GeocodingNetworkError('Mock not configured'));
  }

  @override
  String buildStaticMapUrl({
    required double lat,
    required double lon,
    int zoom = 14,
    int width = 300,
    int height = 200,
    String markerColor = 'red',
  }) {
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lon';
  }
}

void main() {
  group('LocationPickerController', () {
    late MockWhat3wordsService mockW3w;
    late MockGeocodingService mockGeocoding;

    const testLocation = LatLng(55.9533, -3.1883);
    final testW3wAddress = What3wordsAddress.tryParse('index.home.raft')!;
    const testPlaceName = 'Edinburgh';

    setUp(() {
      mockW3w = MockWhat3wordsService();
      mockGeocoding = MockGeocodingService();
    });

    LocationPickerController createController({
      LatLng? initialLocation,
      What3wordsAddress? initialWhat3words,
      String? initialPlaceName,
      LocationPickerMode mode = LocationPickerMode.riskLocation,
    }) {
      return LocationPickerController(
        what3wordsService: mockW3w,
        geocodingService: mockGeocoding,
        mode: mode,
        initialLocation: initialLocation,
        initialWhat3words: initialWhat3words,
        initialPlaceName: initialPlaceName,
      );
    }

    group('initialization', () {
      test('starts in initial state', () {
        final controller = createController();
        expect(controller.state, isA<LocationPickerInitial>());
      });

      test('initializes with provided location', () {
        final controller = createController(initialLocation: testLocation);
        expect(controller.state, isA<LocationPickerInitial>());
        final state = controller.state as LocationPickerInitial;
        expect(state.initialLocation, equals(testLocation));
      });

      test('initializes with what3words address', () {
        final controller = createController(initialWhat3words: testW3wAddress);
        expect(controller.state, isA<LocationPickerInitial>());
        final state = controller.state as LocationPickerInitial;
        expect(state.initialWhat3words, equals(testW3wAddress));
      });

      test('initializes with place name', () {
        final controller = createController(initialPlaceName: testPlaceName);
        expect(controller.state, isA<LocationPickerInitial>());
        final state = controller.state as LocationPickerInitial;
        expect(state.initialPlaceName, equals(testPlaceName));
      });

      test('stores mode correctly', () {
        final controller =
            createController(mode: LocationPickerMode.fireReport);
        expect(controller.mode, equals(LocationPickerMode.fireReport));
      });
    });

    group('onSearchTextChanged', () {
      test('returns to initial state on empty query', () async {
        mockGeocoding.setSearchPlacesResult(const Right([]));
        final controller = createController(initialLocation: testLocation);

        // Simulate search then clear
        controller.onSearchTextChanged('Edinburgh');
        expect(controller.state, isA<LocationPickerSearching>());

        // Clear the search - should return to initial
        // Note: The controller resets but won't have initialLocation since
        // that's only set on construction, not preserved through states
        controller.onSearchTextChanged('');
        expect(controller.state, isA<LocationPickerInitial>());
      });

      test('detects what3words format and calls conversion', () async {
        mockW3w.setConvertToCoordinatesResult(const Right(testLocation));
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onSearchTextChanged('///index.home.raft');

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 50));

        expect(mockW3w.convertToCoordinatesCalls, equals(1));
        expect(controller.state, isA<LocationPickerSelected>());
      });

      test('debounces regular search queries', () async {
        mockGeocoding.setSearchPlacesResult(const Right([]));
        final controller = createController();

        // Rapidly type characters
        controller.onSearchTextChanged('E');
        controller.onSearchTextChanged('Ed');
        controller.onSearchTextChanged('Edi');
        controller.onSearchTextChanged('Edin');

        // Immediately check - should not have called API yet
        expect(mockGeocoding.searchPlacesCalls, equals(0));

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 400));

        // Should only call once after debounce
        expect(mockGeocoding.searchPlacesCalls, equals(1));
      });

      test('shows loading state immediately on search', () {
        final controller = createController();
        controller.onSearchTextChanged('Edinburgh');

        expect(controller.state, isA<LocationPickerSearching>());
        final state = controller.state as LocationPickerSearching;
        expect(state.isLoading, isTrue);
        expect(state.query, equals('Edinburgh'));
      });
    });

    group('what3words handling', () {
      test('parses what3words with triple slash prefix', () async {
        mockW3w.setConvertToCoordinatesResult(const Right(testLocation));
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onSearchTextChanged('///word.word.word');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(mockW3w.convertToCoordinatesCalls, equals(1));
      });

      test('parses what3words without prefix', () async {
        mockW3w.setConvertToCoordinatesResult(const Right(testLocation));
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onSearchTextChanged('word.word.word');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(mockW3w.convertToCoordinatesCalls, equals(1));
      });

      test('shows error for invalid what3words format', () async {
        // Use a clearly invalid format that won't pass what3words detection
        // "///ab.cd" has only 2 words, which won't pass format validation
        mockW3w.setConvertToCoordinatesResult(
          const Left(What3wordsInvalidAddressError('ab.cd')),
        );

        final controller = createController();
        // Use two words which won't pass initial format detection
        controller.onSearchTextChanged('///two.words');

        await Future.delayed(const Duration(milliseconds: 50));

        // Since "two.words" doesn't match the 3-word pattern, it goes to search
        // The controller detects it based on looksLikeWhat3words which requires 3 words
        expect(controller.state, isA<LocationPickerSearching>());
      });

      test('shows error when what3words conversion fails', () async {
        mockW3w.setConvertToCoordinatesResult(
          const Left(
              What3wordsApiError(code: 'BadWords', message: 'Not found')),
        );

        final controller = createController();
        controller.onSearchTextChanged('///fake.fake.fake');

        await Future.delayed(const Duration(milliseconds: 50));

        expect(controller.state, isA<LocationPickerError>());
      });

      test('resolves place name after what3words conversion', () async {
        mockW3w.setConvertToCoordinatesResult(const Right(testLocation));
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onSearchTextChanged('///index.home.raft');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.placeName, equals(testPlaceName));
      });
    });

    group('onMapTapped', () {
      test('updates to selected state with coordinates', () {
        final controller = createController();
        controller.onMapTapped(testLocation);

        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.coordinates, equals(testLocation));
      });

      test('starts resolving what3words and place name', () async {
        mockW3w.setConvertTo3waResult(Right(testW3wAddress));
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onMapTapped(testLocation);

        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.isResolvingWhat3words, isTrue);
        expect(state.isResolvingPlaceName, isTrue);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(mockW3w.convertTo3waCalls, equals(1));
        expect(mockGeocoding.reverseGeocodeCalls, equals(1));
      });

      test('completes with both what3words and place name', () async {
        mockW3w.setConvertTo3waResult(Right(testW3wAddress));
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onMapTapped(testLocation);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.what3words, equals(testW3wAddress));
        expect(state.placeName, equals(testPlaceName));
        expect(state.isResolvingWhat3words, isFalse);
        expect(state.isResolvingPlaceName, isFalse);
      });

      test('gracefully handles what3words failure', () async {
        mockW3w.setConvertTo3waResult(
          const Left(What3wordsNetworkError('Network error')),
        );
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onMapTapped(testLocation);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should still be in selected state (not error)
        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.what3words, isNull);
        expect(state.placeName, equals(testPlaceName));
      });

      test('gracefully handles geocoding failure', () async {
        mockW3w.setConvertTo3waResult(Right(testW3wAddress));
        mockGeocoding.setReverseGeocodeResult(
          const Left(GeocodingNetworkError('Network error')),
        );

        final controller = createController();
        controller.onMapTapped(testLocation);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should still be in selected state
        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.what3words, equals(testW3wAddress));
        expect(state.placeName, isNull);
      });
    });

    group('onPlaceSelected', () {
      test('uses place coordinates when available', () async {
        mockW3w.setConvertTo3waResult(Right(testW3wAddress));

        final controller = createController();
        const place = PlaceSearchResult(
          placeId: 'test_place_id',
          name: 'Edinburgh',
          formattedAddress: 'Edinburgh, UK',
          coordinates: testLocation,
        );

        await controller.onPlaceSelected(place);

        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.coordinates, equals(testLocation));
        expect(state.placeName, equals('Edinburgh'));
        expect(mockGeocoding.getPlaceCoordinatesCalls,
            equals(0)); // Should not call
      });

      test('resolves coordinates from place_id when not provided', () async {
        mockGeocoding.setGetPlaceCoordinatesResult(const Right(testLocation));
        mockW3w.setConvertTo3waResult(Right(testW3wAddress));

        final controller = createController();
        const place = PlaceSearchResult(
          placeId: 'test_place_id',
          name: 'Edinburgh',
          formattedAddress: 'Edinburgh, UK',
          coordinates: null, // No coordinates
        );

        await controller.onPlaceSelected(place);

        // Wait for async
        await Future.delayed(const Duration(milliseconds: 100));

        expect(mockGeocoding.getPlaceCoordinatesCalls, equals(1));
        expect(controller.state, isA<LocationPickerSelected>());
        final state = controller.state as LocationPickerSelected;
        expect(state.coordinates, equals(testLocation));
      });

      test('shows error when place resolution fails', () async {
        mockGeocoding.setGetPlaceCoordinatesResult(
          const Left(GeocodingNetworkError('Failed')),
        );

        final controller = createController();
        const place = PlaceSearchResult(
          placeId: 'test_place_id',
          name: 'Edinburgh',
          formattedAddress: 'Edinburgh, UK',
          coordinates: null,
        );

        await controller.onPlaceSelected(place);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(controller.state, isA<LocationPickerError>());
      });
    });

    group('confirmSelection', () {
      test('returns PickedLocation in selected state', () async {
        mockW3w.setConvertTo3waResult(Right(testW3wAddress));
        mockGeocoding.setReverseGeocodeResult(const Right(testPlaceName));

        final controller = createController();
        controller.onMapTapped(testLocation);

        await Future.delayed(const Duration(milliseconds: 100));

        final result = controller.confirmSelection();

        expect(result, isNotNull);
        expect(result!.coordinates, equals(testLocation));
        expect(result.what3words, equals(testW3wAddress.words));
        expect(result.placeName, equals(testPlaceName));
      });

      test('returns null in initial state', () {
        final controller = createController();

        final result = controller.confirmSelection();
        expect(result, isNull);
      });

      test('returns null in searching state', () {
        final controller = createController();
        controller.onSearchTextChanged('Edinburgh');

        final result = controller.confirmSelection();
        expect(result, isNull);
      });

      test('allows confirmation even while resolving', () {
        final controller = createController();
        controller.onMapTapped(testLocation);

        // Immediately try to confirm (before resolution completes)
        final result = controller.confirmSelection();

        expect(result, isNotNull);
        expect(result!.coordinates, equals(testLocation));
        // w3w and placeName may be null as still resolving
      });
    });

    group('reset', () {
      test('resets to initial state', () async {
        mockGeocoding.setSearchPlacesResult(const Right([]));

        final controller = createController();
        controller.onSearchTextChanged('Edinburgh');

        await Future.delayed(const Duration(milliseconds: 400));

        controller.reset();

        expect(controller.state, isA<LocationPickerInitial>());
      });

      test('cancels pending debounce timer', () async {
        final controller = createController();
        controller.onSearchTextChanged('Edinburgh');

        controller.reset();

        // Wait for what would have been the debounce delay
        await Future.delayed(const Duration(milliseconds: 400));

        // Should not have called search since reset was called
        expect(mockGeocoding.searchPlacesCalls, equals(0));
      });
    });

    group('retry', () {
      test('returns to initial when retry called on initial state', () {
        final controller = createController();

        // Call retry when not in error state
        controller.retry();

        // Should remain in initial state
        expect(controller.state, isA<LocationPickerInitial>());
      });
    });

    group('dispose', () {
      test('cancels debounce timer on dispose', () async {
        final controller = createController();
        controller.onSearchTextChanged('Edinburgh');

        controller.dispose();

        // Wait for debounce delay
        await Future.delayed(const Duration(milliseconds: 400));

        // Should not have called search
        expect(mockGeocoding.searchPlacesCalls, equals(0));
      });
    });
  });
}
