# wildfire_mvp_v3 Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-19

## Active Technologies
- **A1** (EffisService): Dart 3.0+, Flutter SDK, http, dartz (Either type), equatable (value objects)
- **A2** (FireRiskService): http, dartz (services only), equatable (inherits from A1)
- **A3** (RiskBanner): Widget layer consuming A2 FireRiskService data
- **A4** (LocationResolver): geolocator, permission_handler, shared_preferences, dartz
- **A5** (CacheService): shared_preferences, dartz, equatable, internal geohash encoder
- **A6** (HomeController): ChangeNotifier, LocationResolver (A4), FireRiskService (A2), CacheService (A5)
- **A9** (MapScreen): go_router, flutter_test (navigation scaffold)
- **A10** (Google Maps MVP): google_maps_flutter ^2.5.0 (Android/iOS/Web), google_maps_flutter_web ^0.5.14+2 (auto-included), go_router, http, dartz (services only), equatable, ChangeNotifier
- Dart 3.9.2, Flutter 3.35.5 stable + Firebase Hosting (deployment infrastructure), GitHub Actions (CI/CD orchestration), google_maps_flutter ^2.5.0 (mapping component), firebase-tools CLI (deployment tool) (012-a11-ci-cd)
- Firebase Hosting (web build artifacts), GitHub Secrets (API keys: FIREBASE_SERVICE_ACCOUNT, FIREBASE_PROJECT_ID, GOOGLE_MAPS_API_KEY_WEB_PREVIEW, GOOGLE_MAPS_API_KEY_WEB_PRODUCTION) (012-a11-ci-cd)

## Project Structure
```
lib/
├── features/        # Feature-based organization (map/, home/)
├── models/          # Data models (LatLng, FireRisk, etc.)
├── services/        # Business logic & API integration
│   └── utils/       # Service utilities (geo_utils.dart)
├── controllers/     # State management (ChangeNotifier)
├── utils/           # App-wide utilities (location_utils.dart)
├── widgets/         # Reusable UI components
└── theme/           # App theming & colors

test/
├── unit/            # Unit tests
├── widget/          # Widget tests
├── integration/     # Integration tests
└── contract/        # API contract tests
```

## Commands
```bash
# macOS has TWO deployment targets:
# 1. macOS Desktop App (native) - Does NOT support Google Maps (A1-A9 features only)
flutter run -d macos --dart-define=MAP_LIVE_DATA=true  # Live EFFIS data (no map)
flutter run -d macos --dart-define=MAP_LIVE_DATA=false # Mock data (no map)

# 2. macOS Web (Safari/Chrome) - DOES support Google Maps via google_maps_flutter_web
# RECOMMENDED: Use secure script that auto-injects API key from env/dev.env.json
./scripts/run_web.sh  # Development with API key (no watermark) ✅

# Alternative: Manual run (shows watermark without API key)
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false # Web in Chrome with map
flutter run -d chrome --dart-define=MAP_LIVE_DATA=true  # Web with live data

# Mobile platforms (full Google Maps support)
flutter run -d android --dart-define=MAP_LIVE_DATA=false # Android emulator
flutter run -d ios --dart-define=MAP_LIVE_DATA=false     # iOS simulator

# Environment file support (for secrets management)
flutter run --dart-define-from-file=env/dev.env.json

# Web deployment builds
./scripts/build_web.sh  # Secure build with API key injection

# Run all tests
flutter test

# Run specific test suite
flutter test test/integration/map/

# Format code
dart format lib/ test/

# Analyze code
flutter analyze

# Run constitution gates (C1-C5)
./.specify/scripts/bash/constitution-gates.sh

# Clean build artifacts
flutter clean && flutter pub get
```

## Code Style
Dart 3.0+ with Flutter SDK: Follow standard conventions
- Use sealed classes for state hierarchies (MapState, etc.)
- Prefer const constructors for immutable objects
- Use dartz Either<L,R> for error handling in **services only** (no exceptions in business logic)
- **UI layer never imports dartz**: Controllers unwrap Either to plain states, widgets receive plain data
- Always use GeographicUtils.logRedact() for coordinate logging (C2 compliance)
- Commit messages follow Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

## Recent Changes
- 012-a11-ci-cd: Added Dart 3.9.2, Flutter 3.35.5 stable + Firebase Hosting (deployment infrastructure), GitHub Actions (CI/CD orchestration), google_maps_flutter ^2.5.0 (mapping component), firebase-tools CLI (deployment tool)
- **2025-10-20**: A10 Web Support - Clarified macOS web (Chrome/Safari) vs macOS desktop distinction. Google Maps works on web via google_maps_flutter_web ^0.5.14+2. Updated platform detection comments and unsupported platform messaging.
- **2025-10-19**: A10 Google Maps MVP - Added google_maps_flutter ^2.5.0, MapController state management, FireLocationService with EFFIS WFS integration

## Utility Classes Reference

### GeographicUtils (lib/services/utils/geo_utils.dart)
Primary geographic utility class for service layer operations:
```dart
class GeographicUtils {
  // Privacy-compliant coordinate logging (C2 compliance)
  static String logRedact(double lat, double lon);  // "55.95,-3.19"
  
  // Scotland boundary detection (for SEPA service routing)
  static bool isInScotland(double lat, double lon);
  
  // Geohash encoding for spatial cache keys (uses GeohashUtils internal encoder)
  static String geohash(double lat, double lon, {int precision = 5});
}
```

### GeohashUtils (lib/utils/geohash_utils.dart)
Internal base32 geohash encoder (no external dependencies):
```dart
class GeohashUtils {
  // Standard geohash algorithm with base32 encoding
  static String encode(double lat, double lon, {int precision = 5});
  
  // Validate geohash string format
  static bool isValid(String geohash);
}
```
Edinburgh (55.9533, -3.1883) → "gcvwr" at precision 5 (~4.9km resolution)

### LocationUtils (lib/utils/location_utils.dart)
App-level location utilities:
```dart
class LocationUtils {
  // Coordinate validation
  static bool isValidCoordinate(double lat, double lon);
  
  // Privacy-compliant coordinate logging (C2 compliance) for app layer
  static String logRedact(double lat, double lon);  // "55.95,-3.19"
}
```

**Layer-Appropriate Usage**:
- Use `GeographicUtils.logRedact()` in **service layer** (`lib/services/**`)
- Use `LocationUtils.logRedact()` in **app layer** (`lib/controllers/**`, `lib/widgets/**`)
- Both provide identical C2-compliant 2-decimal precision logging
- This maintains clean architecture separation between service and app concerns

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
Always use coordinate redaction in logs (layer-appropriate utility):
```dart
// CORRECT: Service layer logging
_logger.info('Attempting EFFIS for ${GeographicUtils.logRedact(lat, lon)}');
// Outputs: "Attempting EFFIS for 55.95,-3.19"

// CORRECT: App layer logging  
_logger.info('User location: ${LocationUtils.logRedact(lat, lon)}');
// Outputs: "User location: 55.95,-3.19"

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
  /// Scotland centroid coordinates for default fallback location
  /// Production: LatLng(55.8642, -4.2518) - Glasgow area
  /// Test Override: LatLng(57.2, -3.8) - Aviemore (for UK fire risk testing)
  static const LatLng _scotlandCentroid = LatLng(57.2, -3.8);
  
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
// CORRECT: Service layer uses GeographicUtils
_logger.info('Location resolved: ${GeographicUtils.logRedact(coords.latitude, coords.longitude)}');
// Outputs: "Location resolved: 55.95,-3.19"

// CORRECT: App layer uses LocationUtils
_logger.info('Location resolved: ${LocationUtils.logRedact(coords.latitude, coords.longitude)}');
// Outputs: "Location resolved: 55.95,-3.19"

// WRONG: Full precision exposes PII
_logger.info('Location: $lat,$lon'); // Violates C2 constitutional gate
```

## CacheService Implementation Patterns

### Generic Cache Service Architecture
```dart
// Generic cache interface with TTL and spatial keying
abstract class CacheService<T> {
  Future<Option<T>> get(String geohashKey);
  Future<Either<CacheError, void>> set({required double lat, required double lon, required T data});
  Future<bool> remove(String geohashKey);
  Future<void> clear();
  Future<CacheMetadata> getMetadata();
  Future<int> cleanup(); // LRU eviction
}

// FireRisk-specific implementation
class FireRiskCacheImpl implements FireRiskCache {
  final SharedPreferences _prefs;
  final GeohashUtils _geohash;
  
  Future<Option<FireRisk>> get(String geohashKey) async {
    final entry = await _loadEntry(geohashKey);
    if (entry.isEmpty || entry.value.isExpired) return none();
    
    // Mark as cached freshness
    final cachedRisk = entry.value.data.copyWith(freshness: Freshness.cached);
    await _updateAccessTime(geohashKey); // LRU tracking
    return some(cachedRisk);
  }
}
```

### Geohash Spatial Keying
```dart
// Consistent spatial cache keys (precision 5 = ~4.9km resolution)
class GeohashUtils {
  static String encode(double lat, double lon, {int precision = 5}) {
    // Standard geohash algorithm implementation
    // Edinburgh (55.9533, -3.1883) → "gcpue"
    // Glasgow (55.8642, -4.2518) → "gcpuv"
  }
  
  static GeohashBounds bounds(String geohash) {
    // Decode geohash to bounding box for spatial queries
  }
}

// Usage in cache operations
final geohashKey = GeohashUtils.encode(lat, lon, precision: 5);
final cached = await cacheService.get(geohashKey);
_logger.debug('Cache lookup for ${LocationUtils.logRedact(lat, lon)} → $geohashKey');
```

### TTL Enforcement with LRU Eviction
```dart
// Cache entry with TTL checking
class CacheEntry<T> extends Equatable {
  final T data;
  final DateTime timestamp;
  final String geohash;
  
  Duration get age => DateTime.now().difference(timestamp);
  bool get isExpired => age > Duration(hours: 6);
  
  // JSON serialization with version field for migration support
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'version': '1.0',
      'timestamp': timestamp.millisecondsSinceEpoch,
      'geohash': geohash,
      'data': toJsonT(data),
    };
  }
}

// LRU eviction when cache reaches 100 entries
class CacheMetadata extends Equatable {
  final int totalEntries;
  final Map<String, DateTime> accessLog;
  
  bool get isFull => totalEntries >= 100;
  String? get lruKey => accessLog.entries
    .reduce((a, b) => a.value.isBefore(b.value) ? a : b).key;
}
```

### FireRiskService Cache Integration
```dart
// Optional cache dependency in FireRiskService fallback chain
FireRiskServiceImpl({
  required EffisService effisService,     // Tier 1: EFFIS (3s timeout)
  SepaService? sepaService,               // Tier 2: SEPA (2s timeout, Scotland only)
  CacheService<FireRisk>? cacheService,   // Tier 3: Cache (200ms timeout) ← A5
  required MockService mockService,       // Tier 4: Mock (never fails)
  OrchestratorTelemetry? telemetry,
});

// Cache integration in fallback chain
Future<Either<ServiceError, FireRisk>> getCurrent({required double lat, required double lon}) async {
  // ... EFFIS attempt fails, SEPA attempt fails ...
  
  // Tier 3: Cache attempt (A5 integration)
  if (cacheService != null) {
    final geohash = GeohashUtils.encode(lat, lon, precision: 5);
    final cached = await cacheService!.get(geohash).timeout(Duration(milliseconds: 200));
    
    if (cached.isSome()) {
      _telemetry?.recordSuccess(source: TelemetrySource.cache);
      _logger.info('Cache hit for ${GeographicUtils.logRedact(lat, lon)}');
      return Right(cached.value); // Already marked with Freshness.cached
    }
    
    _telemetry?.recordMiss(source: TelemetrySource.cache);
  }
  
  // Tier 4: Mock fallback (never fails)
  return await mockService.getCurrent(lat: lat, lon: lon);
}
```

### Testing Cache Services
```dart
group('CacheService TTL and LRU', () {
  testWidgets('expired entries return cache miss', (tester) async {
    // Store entry
    await cacheService.set(lat: 55.9533, lon: -3.1883, data: fireRisk);
    
    // Mock 7 hours later
    final mockTime = DateTime.now().add(Duration(hours: 7));
    when(mockClock.now()).thenReturn(mockTime);
    
    final result = await cacheService.get('gcpue');
    expect(result.isNone(), true);
  });
  
  testWidgets('LRU eviction removes oldest accessed entry', (tester) async {
    // Fill cache to 100 entries
    for (int i = 0; i < 100; i++) {
      await cacheService.set(lat: 55.0 + i * 0.01, lon: -3.0, data: fireRisk);
    }
    
    // Access first entry to make it recent
    await cacheService.get(GeohashUtils.encode(55.0, -3.0));
    
    // Add 101st entry (should trigger eviction)
    await cacheService.set(lat: 56.0, lon: -3.0, data: fireRisk);
    
    // Verify first entry still exists (was recently accessed)
    final firstEntry = await cacheService.get(GeohashUtils.encode(55.0, -3.0));
    expect(firstEntry.isSome(), true);
    
    // Verify oldest unaccessed entry was removed
    final metadata = await cacheService.getMetadata();
    expect(metadata.totalEntries, 100);
  });
});
```

### Privacy-Compliant Cache Logging
```dart
// CORRECT: Use geohash keys and coordinate redaction
final geohash = GeohashUtils.encode(lat, lon, precision: 5);
_logger.debug('Cache operation for ${GeographicUtils.logRedact(lat, lon)} → $geohash');
// Outputs: "Cache operation for 55.95,-3.19 → gcpue"

// CORRECT: Geohash provides inherent privacy (4.9km resolution)
_logger.info('Cache stored for geohash: $geohash');
// Safe: geohash resolution prevents precise location inference

// WRONG: Raw coordinates in cache logs
_logger.info('Cached data for $lat, $lon'); // Violates C2 gate
```

## FWI Accessibility & UI Requirements (C3/C4 Compliance)

Fire Weather Index must be displayed with accessible UI components following Scottish colour palette:

| FWI Range | Risk Level | UI Token | Requirements |
|----------:|------------|----------|--------------|
| 0-4.99 | Very Low | `riskVeryLow` | Risk chip + "Last updated: [UTC timestamp]" |
| 5-11.99 | Low | `riskLow` | Risk chip + "Last updated: [UTC timestamp]" |
| 12-20.99 | Moderate | `riskModerate` | Risk chip + "Last updated: [UTC timestamp]" |
| 21-37.99 | High | `riskHigh` | Risk chip + "Last updated: [UTC timestamp]" |
| 38-49.99 | Very High | `riskVeryHigh` | Risk chip + "Last updated: [UTC timestamp]" |
| ≥50 | Extreme | `riskExtreme` | Risk chip + "Last updated: [UTC timestamp]" |

**Accessibility Requirements**:
- All touch targets ≥44dp (iOS) / ≥48dp (Android)
- Sufficient color contrast for Scottish palette tokens
- Timestamp in UTC with clear timezone indicator
- Screen reader support via Semantics widgets

## Environment & Secrets Management

**No secrets in repository**: Use `--dart-define-from-file` for API keys and configuration:

```bash
# Development environment (local testing)
flutter run --dart-define-from-file=env/dev.env.json

# Production environment (release builds)
flutter build apk --dart-define-from-file=env/prod.env.json
```

**Example `env/dev.env.json`**:
```json
{
  "MAP_LIVE_DATA": "false",
  "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/",
  "GOOGLE_MAPS_API_KEY_ANDROID": "YOUR_KEY_HERE",
  "GOOGLE_MAPS_API_KEY_IOS": "YOUR_KEY_HERE"
}
```

**Security Rules**:
- Add `env/*.env.json` to `.gitignore`
- Restrict Google Maps API keys by package name (Android) and bundle ID (iOS)
- Set up billing alerts at 50% and 80% of free tier quotas

## Code Quality Best Practices (flutter analyze)

### Logging in Production Code

**Problem**: `avoid_print` analyzer warning  
**Solution**: Use `debugPrint()` instead of `print()` for production-safe logging

```dart
// ❌ WRONG: print() in production code triggers analyzer warning
print('🗺️ Using test region: ${FeatureFlags.testRegion}');

// ✅ CORRECT: debugPrint() is production-safe (automatically stripped in release builds)
debugPrint('🗺️ Using test region: ${FeatureFlags.testRegion}');

// Import required:
import 'package:flutter/foundation.dart';  // For debugPrint()
```

**When to use each**:
- `debugPrint()` - Production code (controllers, services, widgets) - preferred for most logging
- `developer.log()` - Structured logging with tags/levels: `developer.log('message', name: 'ServiceName')`
- `print()` - Tests only (performance tests, integration test output)

### Const Constructors and Declarations

**Problem**: `prefer_const_constructors`, `prefer_const_declarations` warnings  
**Solution**: Use `const` for compile-time constants to improve performance

```dart
// ❌ WRONG: Non-const when value is constant
final isTestRegionSet = FeatureFlags.testRegion != 'scotland';
final location = LatLng(55.9533, -3.1883);

// ✅ CORRECT: Const declarations for compile-time constants
const isTestRegionSet = FeatureFlags.testRegion != 'scotland';
const location = LatLng(55.9533, -3.1883);

// In tests:
// ❌ WRONG:
final bounds = LatLngBounds(southwest: LatLng(54.0, -8.0), northeast: LatLng(61.0, 0.0));

// ✅ CORRECT:
const bounds = LatLngBounds(southwest: LatLng(54.0, -8.0), northeast: LatLng(61.0, 0.0));
```

**Rules**:
- Use `const` for literals, constructors of immutable classes with constant values
- Use `final` for values assigned at runtime (API responses, DateTime.now(), etc.)
- Always use `const` in test data factories when possible

### Mock API Signatures

**Problem**: `invalid_override` - Mock services must match production API exactly  
**Solution**: Always check actual service signatures when creating mocks

```dart
// ❌ WRONG: Mock uses wrong return type and parameter names
class MockFireRiskService implements FireRiskService {
  Future<Either<dynamic, FireRisk>> getCurrent({required double lat, required double lon}) async {
    return Right(FireRisk(
      level: RiskLevel.low,
      fwi: 5.0,
      source: DataSource.mock,
      location: LatLng(lat, lon),      // ❌ Wrong parameter name
      timestamp: DateTime.now(),        // ❌ Wrong parameter name
      freshness: Freshness.live,
    ));
  }
}

// ✅ CORRECT: Match production signature exactly
class MockFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({  // ✅ Correct return type
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    return Right(FireRisk(
      level: RiskLevel.low,
      fwi: 5.0,
      source: DataSource.mock,
      observedAt: DateTime.now().toUtc(),  // ✅ Correct parameter name
      freshness: Freshness.live,
    ));
  }
}

// Import required:
import 'package:wildfire_mvp_v3/models/api_error.dart';  // For ApiError type
```

**Checklist for mocks**:
1. Check production service interface signature
2. Match return type exactly (`Either<ApiError, T>` not `Either<dynamic, T>`)
3. Match all parameter names (check constructors with required params)
4. Import all required types (ApiError, models, etc.)
5. Use `@override` annotation to catch signature mismatches early

### Import Organization

**Problem**: `unused_import` warnings  
**Solution**: Remove unused imports, organize logically

```dart
// ✅ CORRECT: Organized imports
import 'package:flutter_test/flutter_test.dart';  // Framework
import 'package:dartz/dartz.dart';                // Third-party

import 'package:wildfire_mvp_v3/models/api_error.dart';      // Models
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';  // Services
import 'package:wildfire_mvp_v3/config/feature_flags.dart';  // Config
```

**Order**:
1. Dart/Flutter framework imports
2. Third-party package imports
3. Blank line
4. Project imports (alphabetical by path)

### Running Analyzer

```bash
# Check all issues
flutter analyze

# Check specific file
flutter analyze lib/services/fire_location_service_impl.dart

# Auto-fix some issues (format only)
dart format lib/ test/
```

**Pre-commit checklist**:
1. Run `flutter analyze` - Should show 0 errors, minimize warnings
2. Run `dart format .` - Auto-format code
3. Run `flutter test` - All tests pass
4. Commit with conventional commit message

### Test-Specific Const Patterns

**Const Test Data**:
Use `const` for all compile-time constant test data to improve test performance and catch errors early.

```dart
// ❌ WRONG: Non-const test data when values are constant
final testBounds = LatLngBounds(
  southwest: LatLng(55.0, -4.0),
  northeast: LatLng(56.0, -3.0),
);
final testLocation = LatLng(55.9533, -3.1883);
final emptyIncidents = [];

// ✅ CORRECT: Const test data
const testBounds = LatLngBounds(
  southwest: LatLng(55.0, -4.0),
  northeast: LatLng(56.0, -3.0),
);
const testLocation = LatLng(55.9533, -3.1883);
const emptyIncidents = <FireIncident>[];

// ✅ CORRECT: Const in constructor arguments
final state = MapSuccess(
  incidents: const [],              // const empty list
  centerLocation: const LatLng(55.9, -3.2),  // const coordinates
  freshness: Freshness.mock,
  lastUpdated: DateTime.now(),      // Runtime value, not const
);
```

**Const vs Final in Tests**:
- Use `const` for test data that's truly constant (coordinates, bounds, etc.)
- Use `final` for values created at runtime (DateTime.now(), mock responses, etc.)

```dart
// ✅ CORRECT: const for compile-time constants
const testLat = 55.9533;
const testLon = -3.1883;
const testCoordinates = LatLng(55.9533, -3.1883);

// ✅ CORRECT: final for runtime values
final testTimestamp = DateTime.now();
final testState = MapSuccess(...);
final mockResponse = await service.getData();
```

**Model Const Constructors**:
Models should provide both const constructors (for test data) and validated factories (for runtime checks).

```dart
// Model design pattern:
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;
  
  // Const constructor for test data (no validation)
  const LatLngBounds({required this.southwest, required this.northeast});
  
  // Validated factory for production (throws on invalid data)
  factory LatLngBounds.validated({required LatLng southwest, required LatLng northeast}) {
    if (southwest.latitude >= northeast.latitude) {
      throw ArgumentError('Invalid bounds');
    }
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }
}

// Usage in tests:
const validBounds = LatLngBounds(southwest: LatLng(55.0, -4.0), northeast: LatLng(56.0, -3.0));

// Test validation logic:
expect(
  () => LatLngBounds.validated(southwest: const LatLng(56.0, -3.0), northeast: const LatLng(55.0, -4.0)),
  throwsArgumentError,
);
```

**Print Statements in Tests**:
`print()` is acceptable in performance tests and debug scripts, but must be documented with analyzer ignore directive.

```dart
// ✅ CORRECT: Performance test with print() for metrics reporting
// test/performance/map_performance_test.dart
// NOTE: print() statements are intentional in performance tests for reporting metrics
// ignore_for_file: avoid_print

testWidgets('Map loads within 3s', (tester) async {
  final stopwatch = Stopwatch()..start();
  // ... test code ...
  stopwatch.stop();
  print('✅ Map load time: ${stopwatch.elapsedMilliseconds}ms');  // OK with ignore directive
});

// ✅ CORRECT: Debug script
// test_ser.dart
// Debug script for testing serialization
// NOTE: print() is intentional for debug output
// ignore_for_file: avoid_print

void main() {
  final json = model.toJson();
  print('Serialized: $json');  // OK with ignore directive
}

// ❌ WRONG: print() in production code (lib/)
void processData() {
  print('Processing...');  // Use debugPrint() instead
}
```

**Empty List Literals**:
Always use `const []` for empty list literals in immutable constructors.

```dart
// ❌ WRONG: Non-const empty list
final state = MapSuccess(
  incidents: [],  // Triggers prefer_const_literals_to_create_immutables
  centerLocation: testLocation,
  freshness: Freshness.mock,
  lastUpdated: DateTime.now(),
);

// ✅ CORRECT: Const empty list
final state = MapSuccess(
  incidents: const [],  // or const <FireIncident>[] for explicit type
  centerLocation: testLocation,
  freshness: Freshness.mock,
  lastUpdated: DateTime.now(),
);
```

**Batch Fixing Const Issues**:
Use `sed` for batch const fixes when the pattern is repetitive.

```bash
# Replace all `incidents: []` with `incidents: const []`
sed -i '' 's/incidents: \[\],/incidents: const [],/g' test/widget/map_screen_test.dart

# Replace all `final testBounds = LatLngBounds` with `const testBounds = LatLngBounds`
sed -i '' 's/final testBounds = LatLngBounds/const testBounds = LatLngBounds/g' test/**/*.dart
```

<!-- MANUAL ADDITIONS START -->

## CI/CD Deployment Guidelines (A11)

### Build Scripts
```bash
# Local development build (uses env/dev.env.json)
./scripts/build_web.sh

# CI build with API key injection (requires MAPS_API_KEY_WEB env var)
export MAPS_API_KEY_WEB="your_api_key_here"
./scripts/build_web_ci.sh
```

### Deployment Workflow
- **PR Preview**: Automatic on pull_request (7-day expiry)
- **Production**: Manual approval required (GitHub Environment: production)
- **Job Flow**: build → build-web → deploy-preview|deploy-production

### Troubleshooting Deployments
- **Preview URL 404** → Check firebase.json rewrites configuration
- **Map watermark** → Check API key HTTP referrer restrictions in Google Cloud Console
- **Build fails "placeholder not found"** → Verify web/index.html has `%MAPS_API_KEY%`
- **Auth failed** → Check FIREBASE_SERVICE_ACCOUNT secret validity

### Secrets Management
- Never commit API keys (use `%MAPS_API_KEY%` placeholder in web/index.html)
- Log API keys as masked: `${MAPS_API_KEY_WEB:0:8}***` (first 8 chars only)
- Rotate keys every 90 days (generate new, update secret, test, revoke old)

### Rollback Procedures
1. **Firebase Console** (fastest - 30 sec): Hosting → Release history → Rollback
2. **Firebase CLI** (scriptable): `firebase hosting:rollback <release-id>`
3. **Git Revert** (audit trail): `git revert <sha>` → push → approve deployment

See **docs/FIREBASE_DEPLOYMENT.md** for complete runbook.

## Flutter Testing Best Practices

### Binding Initialization for Platform Channels

**Problem**: Tests that use platform channels fail with "Binding has not yet been initialized" error.

**Solution**: Call `WidgetsFlutterBinding.ensureInitialized()` at the start of `main()` in test files that use:
- SharedPreferences
- Geolocator or other location services
- URL launcher or external intents
- Any plugin with native platform code
- Flutter services that require binding (ServicesBinding, WidgetsBinding, etc.)

```dart
// ✅ CORRECT: Initialize binding for tests using platform channels
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Required before accessing any platform channels or Flutter services
  WidgetsFlutterBinding.ensureInitialized();
  
  test('cache stores data', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // ... test code
  });
}

// ❌ WRONG: Missing binding initialization
void main() {
  test('cache stores data', () async {
    // This will fail with "Binding has not yet been initialized"
    final prefs = await SharedPreferences.getInstance();
  });
}
```

**When to use**:
- Integration tests that use `SharedPreferences`, `Geolocator`, `url_launcher`, or other plugins
- Unit tests accessing platform channels directly
- Tests that instantiate services with plugin dependencies

**When NOT needed**:
- Pure unit tests with no Flutter dependencies
- Widget tests using `testWidgets()` (binding auto-initialized)
- Tests only using mocks/fakes with no real platform channels

### Platform Guards for Web and CI

**Problem**: Platform-specific code (GPS, file I/O, native features) breaks on web or CI environments.

**Solution**: Use `kIsWeb` and `Platform` guards to skip platform-specific logic:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

// ✅ CORRECT: Platform guard for mobile-only features
Future<LatLng> getLocation() async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    // Web or desktop - return default location
    return const LatLng(55.8642, -4.2518); // Scotland centroid
  }
  
  // Mobile only - use GPS
  final position = await Geolocator.getCurrentPosition();
  return LatLng(position.latitude, position.longitude);
}

// ✅ CORRECT: Test with platform detection
test('location resolver falls back on web', () async {
  final location = await locationResolver.getLatLon();
  
  if (kIsWeb) {
    expect(location, equals(TestData.scotlandCentroid));
  } else {
    expect(location.latitude, closeTo(55.9, 0.1));
  }
});

// ❌ WRONG: No platform guard - will fail on web
Future<LatLng> getLocation() async {
  final position = await Geolocator.getCurrentPosition(); // Crashes on web
  return LatLng(position.latitude, position.longitude);
}
```

### Summary: Testing Checklist

Before committing test changes, verify:

- [ ] All test files using platform channels call `WidgetsFlutterBinding.ensureInitialized()`
- [ ] Platform-specific code has `kIsWeb` or `Platform` guards
- [ ] Tests use mocks/fakes instead of real platform services
- [ ] `flutter analyze` shows zero errors
- [ ] `flutter test` passes on all platforms (run locally on web with `flutter test --platform=chrome`)

## API Key Safety Rules (AI Assistants)

### Rule 1: NEVER Write Real API Keys to Files
**What to do**: Always use placeholders in files you create/modify

**Placeholders**:
- Generic: `YOUR_API_KEY_HERE`, `YOUR_*_KEY_HERE`
- Google Maps: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` (39 chars, correct length)
- AWS: `AKIAXXXXXXXXXXXXXXXX` (20 chars)
- GitHub: `ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` (40 chars)

### Rule 2: Recognize Keys in Context
**If you see** an API key in chat history, file context, or previous messages:
- Replace with placeholder in any files you create
- Never echo the real key back
- Use `YOUR_*_KEY_HERE` format

### Rule 3: Reference Template Files
**Instead of**: Showing contents of `env/dev.env.json`  
**Do this**: Reference `env/dev.env.json.template`

```bash
# ❌ BAD
cat env/dev.env.json

# ✅ GOOD
cat env/dev.env.json.template
cp env/dev.env.json.template env/dev.env.json
# User manually adds their keys to env/dev.env.json
```

### Rule 4: Documentation Examples
```markdown
# ❌ BAD - Never do this:
{
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_WEB_API_KEY_HERE"
}

# ✅ GOOD - Always do this:
{
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_WEB_API_KEY_HERE"
}

See env/dev.env.json.template for structure.
```

### Rule 5: Code Generation Guards
```dart
// ❌ BAD - Never hardcode
const apiKey = 'YOUR_WEB_API_KEY_HERE';

// ✅ GOOD - Use environment variables
const apiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY_WEB',
  defaultValue: 'YOUR_API_KEY_HERE', // Safe placeholder
);
```

### Rule 6: Security-Sensitive Files
**Never directly read or output**:
- `env/dev.env.json`, `env/prod.env.json`
- `android/local.properties`
- `.env` or `.env.*`

**Instead**: Reference template files, show structure without values

### Rule 7: Pre-Commit Verification
Before running `git add` or `git commit`, scan files you created:
```bash
# Check for Google Maps API keys
grep -r "AIzaSy[A-Za-z0-9_-]{33}" <your-files>

# Check for other secrets
grep -r "AKIA[A-Z0-9]{16}" <your-files>
grep -r "ghp_[A-Za-z0-9]{36}" <your-files>
```

### Rule 8: Incident Response
If you accidentally write a real API key:
1. **Alert immediately**: "⚠️ I may have written a real API key"
2. **Provide removal**: `git reset`, `sed` replacement commands
3. **Recommend rotation**: "Rotate this key in Google Cloud Console"

### Additional Resources
- **Human Guide**: `docs/PREVENT_API_KEY_LEAKS.md` - Comprehensive prevention guide
- **Security Audit**: `docs/SECURITY_AUDIT_REPORT_2025-10-29.md` - Latest security scan
- **Multi-Layer Defense**: `docs/MULTI_LAYER_SECURITY_CONTROLS.md` - 8-layer security architecture
- **Incident Response**: `docs/SECURITY_INCIDENT_RESPONSE_2025-10-29.md` - Response procedures

<!-- MANUAL ADDITIONS END -->
