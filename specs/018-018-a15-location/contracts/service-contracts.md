# Service Contracts: 018-A15 Location Picker

**Branch**: `018-018-a15-location` | **Date**: 2025-11-27

---

## 1. What3wordsService

### Interface Contract

```dart
/// what3words coordinate conversion service
///
/// Provides bidirectional conversion between what3words addresses
/// and geographic coordinates using the what3words API.
///
/// C2 Compliance:
/// - Coordinates logged with 2-decimal redaction via LocationUtils.logRedact()
/// - what3words addresses NEVER logged (can identify precise locations)
///
/// C5 Compliance:
/// - All operations return Either<What3wordsError, T>
/// - Network calls have configurable timeout
/// - Graceful degradation when API unavailable
abstract class What3wordsService {
  /// Convert what3words address to coordinates
  ///
  /// [words] - what3words address (with or without /// prefix)
  /// [timeout] - Request timeout (default: 5 seconds)
  ///
  /// Returns:
  /// - Right(LatLng) on success
  /// - Left(What3wordsInvalidAddressError) if format invalid
  /// - Left(What3wordsApiError) if API returns error
  /// - Left(What3wordsNetworkError) on connectivity issues
  Future<Either<What3wordsError, LatLng>> convertToCoordinates(
    String words, {
    Duration timeout = const Duration(seconds: 5),
  });

  /// Convert coordinates to what3words address
  ///
  /// [lat] - Latitude (-90 to 90)
  /// [lon] - Longitude (-180 to 180)
  /// [timeout] - Request timeout (default: 5 seconds)
  ///
  /// Returns:
  /// - Right(What3wordsAddress) on success
  /// - Left(What3wordsApiError) if API returns error
  /// - Left(What3wordsNetworkError) on connectivity issues
  Future<Either<What3wordsError, What3wordsAddress>> convertToWords({
    required double lat,
    required double lon,
    Duration timeout = const Duration(seconds: 5),
  });
}
```

### API Specification

**Base URL**: `https://api.what3words.com/v3`

**Authentication**: `X-Api-Key` header

#### Convert to Coordinates

```
POST /convert-to-coordinates
Content-Type: application/json
X-Api-Key: {WHAT3WORDS_API_KEY}

Request:
{
  "words": "slurs.this.name"
}

Response (200 OK):
{
  "country": "GB",
  "square": {
    "southwest": { "lng": -3.188291, "lat": 55.953138 },
    "northeast": { "lng": -3.188246, "lat": 55.953165 }
  },
  "nearestPlace": "Edinburgh",
  "coordinates": {
    "lng": -3.188268,
    "lat": 55.953152
  },
  "words": "slurs.this.name",
  "language": "en",
  "map": "https://w3w.co/slurs.this.name"
}

Error Response (400):
{
  "error": {
    "code": "BadWords",
    "message": "words must be valid what3words"
  }
}
```

#### Convert to Words

```
GET /convert-to-3wa?coordinates={lat},{lon}&language=en
X-Api-Key: {WHAT3WORDS_API_KEY}

Response (200 OK):
{
  "country": "GB",
  "square": { ... },
  "nearestPlace": "Edinburgh",
  "coordinates": {
    "lng": -3.188268,
    "lat": 55.953152
  },
  "words": "slurs.this.name",
  "language": "en",
  "map": "https://w3w.co/slurs.this.name"
}
```

### Implementation Contract

```dart
/// HTTP implementation of What3wordsService
class What3wordsServiceImpl implements What3wordsService {
  final http.Client _client;
  final String _apiKey;

  What3wordsServiceImpl({
    required http.Client client,
    required String apiKey,
  }) : _client = client,
       _apiKey = apiKey;

  @override
  Future<Either<What3wordsError, LatLng>> convertToCoordinates(
    String words, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // 1. Validate format locally first
    final address = What3wordsAddress.tryParse(words);
    if (address == null) {
      return Left(What3wordsInvalidAddressError(words));
    }

    // 2. Make API request
    try {
      final uri = Uri.parse('https://api.what3words.com/v3/convert-to-coordinates');
      final response = await _client.post(
        uri,
        headers: {
          'X-Api-Key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'words': address.words}),
      ).timeout(timeout);

      // 3. Parse response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['coordinates'];
        return Right(LatLng(coords['lat'], coords['lng']));
      } else {
        final error = jsonDecode(response.body)['error'];
        return Left(What3wordsApiError(
          code: error['code'],
          message: error['message'],
          statusCode: response.statusCode,
        ));
      }
    } on TimeoutException {
      return Left(const What3wordsNetworkError('Request timed out'));
    } catch (e) {
      return Left(What3wordsNetworkError(e.toString()));
    }
  }

  @override
  Future<Either<What3wordsError, What3wordsAddress>> convertToWords({
    required double lat,
    required double lon,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.what3words.com/v3/convert-to-3wa'
        '?coordinates=$lat,$lon&language=en'
      );
      final response = await _client.get(
        uri,
        headers: {'X-Api-Key': _apiKey},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = What3wordsAddress.tryParse(data['words']);
        if (address != null) {
          return Right(address);
        }
        return Left(const What3wordsApiError(
          code: 'InvalidResponse',
          message: 'Invalid words in response',
        ));
      } else {
        final error = jsonDecode(response.body)['error'];
        return Left(What3wordsApiError(
          code: error['code'],
          message: error['message'],
          statusCode: response.statusCode,
        ));
      }
    } on TimeoutException {
      return Left(const What3wordsNetworkError('Request timed out'));
    } catch (e) {
      return Left(What3wordsNetworkError(e.toString()));
    }
  }
}
```

### Test Contract

```dart
group('What3wordsService', () {
  late MockClient mockClient;
  late What3wordsService service;

  setUp(() {
    mockClient = MockClient();
    service = What3wordsServiceImpl(
      client: mockClient,
      apiKey: 'test-key',
    );
  });

  group('convertToCoordinates', () {
    test('returns LatLng for valid what3words', () async {
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
          '{"coordinates": {"lat": 55.953152, "lng": -3.188268}}',
          200,
        ));

      final result = await service.convertToCoordinates('slurs.this.name');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (latLng) {
          expect(latLng.latitude, closeTo(55.953, 0.001));
          expect(latLng.longitude, closeTo(-3.188, 0.001));
        },
      );
    });

    test('returns InvalidAddressError for malformed input', () async {
      final result = await service.convertToCoordinates('invalid');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<What3wordsInvalidAddressError>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns ApiError for API error response', () async {
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
          '{"error": {"code": "BadWords", "message": "invalid"}}',
          400,
        ));

      final result = await service.convertToCoordinates('///bad.words.here');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) {
          expect(error, isA<What3wordsApiError>());
          expect((error as What3wordsApiError).code, equals('BadWords'));
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns NetworkError on timeout', () async {
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => throw TimeoutException('timeout'));

      final result = await service.convertToCoordinates(
        '///slurs.this.name',
        timeout: const Duration(milliseconds: 100),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<What3wordsNetworkError>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('convertToWords', () {
    test('returns What3wordsAddress for valid coordinates', () async {
      when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(
          '{"words": "slurs.this.name"}',
          200,
        ));

      final result = await service.convertToWords(lat: 55.953, lon: -3.188);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (address) => expect(address.displayFormat, equals('///slurs.this.name')),
      );
    });
  });
});
```

---

## 2. LocationPickerController

### Interface Contract

```dart
/// Controller for LocationPickerScreen state management
///
/// Manages:
/// - Selected location (map crosshair position)
/// - what3words address (async fetch on location change)
/// - Search state (query, suggestions)
/// - GPS availability
///
/// C2 Compliance: Coordinates logged via LocationUtils.logRedact()
class LocationPickerController extends ChangeNotifier {
  final What3wordsService _what3wordsService;
  final LocationResolver _locationResolver;
  final PlacesService? _placesService;

  LocationPickerController({
    required What3wordsService what3wordsService,
    required LocationResolver locationResolver,
    PlacesService? placesService,
  });

  /// Current state
  LocationPickerState get state;

  /// Initialize with optional starting location
  Future<void> initialize({LatLng? initialLocation});

  /// Update selected location (called on camera idle)
  Future<void> setLocation(LatLng location);

  /// Search for places
  Future<void> search(String query);

  /// Select a search result
  Future<void> selectSearchResult(PlaceSearchResult result);

  /// Search for what3words address
  Future<void> searchWhat3words(String words);

  /// Use current GPS location
  Future<void> useCurrentGps();

  /// Build final PickedLocation for return
  PickedLocation? buildResult();

  /// Clear search state
  void clearSearch();
}
```

### State Transitions

```dart
// Initialize
initialize() → LocationPickerReady(selectedLocation, isLoadingWhat3words: true)
             → LocationPickerReady(selectedLocation, what3words: address)

// Camera move
setLocation(newLocation) 
  → LocationPickerReady(newLocation, isLoadingWhat3words: true)
  → LocationPickerReady(newLocation, what3words: newAddress)

// Search
search(query) 
  → LocationPickerReady(..., searchQuery: query, suggestions: null)
  → LocationPickerReady(..., suggestions: results)

// Select result
selectSearchResult(result)
  → Animate camera to result.coordinates
  → setLocation() triggered by camera idle

// GPS
useCurrentGps()
  → LocationPickerReady(...) with GPS coordinates
  → setLocation() triggered
```

### Test Contract

```dart
group('LocationPickerController', () {
  late MockWhat3wordsService mockW3w;
  late MockLocationResolver mockResolver;
  late LocationPickerController controller;

  setUp(() {
    mockW3w = MockWhat3wordsService();
    mockResolver = MockLocationResolver();
    controller = LocationPickerController(
      what3wordsService: mockW3w,
      locationResolver: mockResolver,
    );
  });

  test('initialize fetches what3words for initial location', () async {
    when(mockW3w.convertToWords(lat: anyNamed('lat'), lon: anyNamed('lon')))
      .thenAnswer((_) async => Right(What3wordsAddress.tryParse('a.b.c')!));

    await controller.initialize(initialLocation: const LatLng(55.9, -3.2));

    expect(controller.state, isA<LocationPickerReady>());
    final state = controller.state as LocationPickerReady;
    expect(state.selectedLocation.latitude, equals(55.9));
    expect(state.what3words?.words, equals('a.b.c'));
  });

  test('setLocation triggers what3words fetch', () async {
    when(mockW3w.convertToWords(lat: anyNamed('lat'), lon: anyNamed('lon')))
      .thenAnswer((_) async => Right(What3wordsAddress.tryParse('x.y.z')!));

    await controller.initialize(initialLocation: const LatLng(55.9, -3.2));
    await controller.setLocation(const LatLng(56.0, -3.5));

    final state = controller.state as LocationPickerReady;
    expect(state.selectedLocation.latitude, equals(56.0));
    expect(state.what3words?.words, equals('x.y.z'));
  });

  test('what3words error sets errorMessage not crash', () async {
    when(mockW3w.convertToWords(lat: anyNamed('lat'), lon: anyNamed('lon')))
      .thenAnswer((_) async => Left(const What3wordsNetworkError()));

    await controller.initialize(initialLocation: const LatLng(55.9, -3.2));

    final state = controller.state as LocationPickerReady;
    expect(state.what3words, isNull);
    // Coordinates still valid - picker still usable
    expect(state.selectedLocation.latitude, equals(55.9));
  });

  test('buildResult returns PickedLocation with current state', () async {
    when(mockW3w.convertToWords(lat: anyNamed('lat'), lon: anyNamed('lon')))
      .thenAnswer((_) async => Right(What3wordsAddress.tryParse('a.b.c')!));

    await controller.initialize(initialLocation: const LatLng(55.9, -3.2));

    final result = controller.buildResult();
    expect(result, isNotNull);
    expect(result!.coordinates.latitude, equals(55.9));
    expect(result.what3words, equals('a.b.c'));
  });
});
```

---

## 3. Integration with Existing Services

### LocationResolver Integration

```dart
// In HomeScreen - after picker returns
Future<void> _openLocationPicker() async {
  final result = await Navigator.push<PickedLocation>(
    context,
    MaterialPageRoute(
      builder: (_) => LocationPickerScreen(
        initialLocation: _getCurrentLocation(),
        mode: LocationPickerMode.riskLocation,
      ),
    ),
  );

  if (result != null && mounted) {
    // Save via existing LocationResolver (A4)
    await _controller.setManualLocation(
      result.coordinates,
      placeName: result.placeName,
    );
  }
}
```

### ReportFireScreen Integration

```dart
// In ReportFireScreen - new button handler
Future<void> _openLocationPicker(BuildContext context) async {
  final result = await Navigator.push<PickedLocation>(
    context,
    MaterialPageRoute(
      builder: (_) => const LocationPickerScreen(
        mode: LocationPickerMode.fireReport,
      ),
    ),
  );

  if (result != null && context.mounted) {
    // Copy what3words to clipboard for emergency call
    if (result.what3words != null) {
      await Clipboard.setData(ClipboardData(text: result.what3words!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('what3words copied to clipboard')),
      );
    }
  }
}
```

---

*Service contracts complete. See widget-contracts.md for UI contracts.*
