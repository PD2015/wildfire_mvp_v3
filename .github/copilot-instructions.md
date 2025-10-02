# wildfire_mvp_v3 Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-02

## Active Technologies
- Dart 3.0+ with Flutter SDK + http package, dartz (Either type), equatable (value objects) (001-spec-a1-effisservice)
- Dart 3.0+ with Flutter SDK + flutter_bloc, equatable, http (inherited from A2), dartz (Either type from A2) (003-a3-riskbanner-home)
- N/A (widget consumes A2 FireRiskService data) (003-a3-riskbanner-home)
- Dart 3.0+ with Flutter SDK + geolocator, permission_handler, shared_preferences, dartz (Either type from A1-A3) (004-a4-locationresolver-low)

## Project Structure
```
src/
tests/
```

## Commands
# Add commands for Dart 3.0+ with Flutter SDK

## Code Style
Dart 3.0+ with Flutter SDK: Follow standard conventions

## Recent Changes
- 004-a4-locationresolver-low: Added LocationResolver with GPS→cached→manual→default fallback, SharedPreferences persistence, permission handling
- 003-a3-riskbanner-home: Added Dart 3.0+ with Flutter SDK + flutter_bloc, equatable, http (inherited from A2), dartz (Either type from A2)
- 001-spec-a1-effisservice: Added Dart 3.0+ with Flutter SDK + http package, dartz (Either type), equatable (value objects)
- 002-spec-a2-fireriskservice: Added FireRiskService orchestration with fallback chain, geographic utilities, telemetry, privacy compliance

## FireRiskService Implementation Patterns

### Orchestration Service Architecture
```dart
// Dependency injection with optional services
FireRiskServiceImpl({
  required EffisService effisService,     // A1 implementation - always required
  SepaService? sepaService,               // Optional Scotland-specific service
  CacheService? cacheService,             // Optional caching layer
  required MockService mockService,       // Required never-fail fallback
  OrchestratorTelemetry? telemetry,       // Optional observability
});
```

### Testing Orchestration Services
Use controllable mocks for integration testing:
```dart
// Setup controllable timing and failures
when(mockEffisService.getFwi(lat: anyNamed('lat'), lon: anyNamed('lon')))
  .thenAnswer((_) async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network
    return Left(ApiError(message: 'Service unavailable'));
  });

// Verify exact fallback sequence with SpyTelemetry
final telemetry = SpyTelemetry();
final service = FireRiskServiceImpl(..., telemetry: telemetry);

await service.getCurrent(lat: lat, lon: lon);

final attempts = telemetry.eventsOfType<AttemptStartEvent>();
expect(attempts.map((e) => e.source), [
  TelemetrySource.effis,
  TelemetrySource.sepa,  // Only if Scotland coordinates
  TelemetrySource.cache, // Only if cache service provided
  TelemetrySource.mock,  // Always final fallback
]);
```

### Privacy-Compliant Logging
Always use coordinate redaction in logs:
```dart
// CORRECT: Privacy-preserving logging
_logger.info('Attempting EFFIS for ${GeographicUtils.logRedact(lat, lon)}');
// Outputs: "Attempting EFFIS for 55.95,-3.19"

// WRONG: Raw coordinates expose PII
_logger.info('Attempting EFFIS for $lat,$lon'); // Violates C2 gate
```

### Geographic Boundary Testing
Test Scotland boundary detection with edge cases:
```dart
// Major cities
expect(GeographicUtils.isInScotland(55.9533, -3.1883), isTrue);  // Edinburgh
expect(GeographicUtils.isInScotland(51.5074, -0.1278), isFalse); // London

// Boundary edge cases  
expect(GeographicUtils.isInScotland(54.6, -4.0), isTrue);   // Exact boundary
expect(GeographicUtils.isInScotland(57.8, -8.6), isTrue);   // St Kilda
expect(GeographicUtils.isInScotland(60.9, -1.0), isTrue);   // Shetland
```

### Stable Dependency Contracts
Define clear interfaces for orchestrated services:
```dart
abstract class EffisService { 
  Future<Either<ApiError, EffisFwiResult>> getFwi({required double lat, required double lon});
}

abstract class SepaService {
  Future<Either<ApiError, FireRisk>> getCurrent({required double lat, required double lon});
}

abstract class CacheService {
  Future<Option<FireRisk>> get({required String key});
  Future<void> set({required String key, required FireRisk value, Duration ttl});
}
```

## LocationResolver Implementation Patterns

### Fallback Chain Architecture
```dart
// LocationResolver implements 4-tier fallback strategy
class LocationResolverImpl implements LocationResolver {
  static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);
  
  @override
  Future<Either<LocationError, LatLng>> getLatLon() async {
    // 1. GPS attempt (2s timeout)
    final gpsResult = await _tryGps();
    if (gpsResult.isRight()) return gpsResult;
    
    // 2. Manual cache check
    final cachedResult = await _loadCachedLocation();
    if (cachedResult.isSome()) {
      return Right(cachedResult.getOrElse(() => _scotlandCentroid));
    }
    
    // 3. Manual entry dialog (if needed)
    final manualResult = await _requestManualEntry();
    if (manualResult.isRight()) return manualResult;
    
    // 4. Never-fail default
    return Right(_scotlandCentroid);
  }
}
```

### GPS Timeout and Permission Handling
```dart
Future<Either<LocationError, LatLng>> _tryGps() async {
  try {
    // Check if location services are enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      return Left(LocationError.serviceDisabled());
    }
    
    // Check permission status
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied || 
          requested == LocationPermission.deniedForever) {
        return Left(LocationError.permissionDenied());
      }
    }
    
    // Get position with strict timeout
    final position = await Geolocator.getCurrentPosition(
      timeLimit: Duration(seconds: 2),
      desiredAccuracy: LocationAccuracy.medium,
    );
    
    return Right(LatLng(position.latitude, position.longitude));
  } catch (e) {
    return Left(LocationError.gpsUnavailable(e.toString()));
  }
}
```

### SharedPreferences Persistence
```dart
Future<Option<LatLng>> _loadCachedLocation() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('manual_location_lat');
    final lon = prefs.getDouble('manual_location_lon');
    
    if (lat != null && lon != null && _isValidCoordinate(lat, lon)) {
      return Some(LatLng(lat, lon));
    }
    return None();
  } catch (e) {
    return None(); // Graceful degradation on cache corruption
  }
}

Future<void> saveManual(LatLng location, {String? placeName}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('manual_location_lat', location.latitude);
  await prefs.setDouble('manual_location_lon', location.longitude);
  if (placeName != null) {
    await prefs.setString('manual_location_place', placeName);
  }
}
```

### Manual Entry Dialog with Validation
```dart
class ManualLocationDialog extends StatefulWidget {
  @override
  _ManualLocationDialogState createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  String? _validationError;
  
  bool _isValidCoordinate(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
  
  void _validateAndSave() {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    
    if (lat == null || lon == null || !_isValidCoordinate(lat, lon)) {
      setState(() {
        _validationError = 'Please enter valid coordinates (-90 to 90 for latitude, -180 to 180 for longitude)';
      });
      return;
    }
    
    Navigator.of(context).pop(LatLng(lat, lon));
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: Key('latitude_field'),
            controller: _latController,
            decoration: InputDecoration(
              labelText: 'Latitude',
              semanticCounterText: 'Latitude coordinate',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 16),
          TextField(
            key: Key('longitude_field'),
            controller: _lonController,
            decoration: InputDecoration(
              labelText: 'Longitude',
              semanticCounterText: 'Longitude coordinate',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          if (_validationError != null) ...[
            SizedBox(height: 8),
            Text(_validationError!, style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          key: Key('save_button'),
          onPressed: _validateAndSave,
          child: Text('Save Location'),
        ),
      ],
    );
  }
}
```

### Testing Location Fallback Chain
```dart
// Test all fallback scenarios
group('LocationResolver Fallback Chain', () {
  testWidgets('GPS success returns coordinates immediately', (tester) async {
    when(mockGeolocator.getCurrentPosition()).thenAnswer((_) async => 
      Position(latitude: 55.9533, longitude: -3.1883, ...));
    
    final result = await locationResolver.getLatLon();
    expect(result.isRight(), true);
    expect(result.getOrElse(() => LatLng(0, 0)).latitude, 55.9533);
  });
  
  testWidgets('GPS denied falls back to cache', (tester) async {
    when(mockGeolocator.checkPermission()).thenAnswer((_) async => 
      LocationPermission.deniedForever);
    when(mockPreferences.getDouble('manual_location_lat')).thenReturn(56.0);
    when(mockPreferences.getDouble('manual_location_lon')).thenReturn(-4.0);
    
    final result = await locationResolver.getLatLon();
    expect(result.isRight(), true);
    expect(result.getOrElse(() => LatLng(0, 0)).latitude, 56.0);
  });
  
  testWidgets('No cache falls back to Scotland centroid', (tester) async {
    when(mockGeolocator.checkPermission()).thenAnswer((_) async => 
      LocationPermission.deniedForever);
    when(mockPreferences.getDouble('manual_location_lat')).thenReturn(null);
    
    final result = await locationResolver.getLatLon();
    expect(result.isRight(), true);
    final coords = result.getOrElse(() => LatLng(0, 0));
    expect(coords.latitude, closeTo(55.8642, 0.1));
    expect(coords.longitude, closeTo(-4.2518, 0.1));
  });
});
```

### Privacy-Compliant Location Logging
```dart
// CORRECT: Limited precision logging
_logger.info('Location resolved: ${_logRedact(coords.latitude, coords.longitude)}');
// Outputs: "Location resolved: 55.95,-3.19"

String _logRedact(double lat, double lon) {
  return '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
}

// WRONG: Full precision exposes PII
_logger.info('Location: $lat,$lon'); // Violates C2 constitutional gate
```

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
