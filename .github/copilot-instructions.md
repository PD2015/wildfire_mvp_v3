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
- Dart 3.9.2, Flutter 3.35.5 stable + Flutter SDK, go_router (navigation/routing), Material Design Icons (Icons.warning_amber) (015-rename-home-fire)
- No new storage requirements - UI/routing changes only (015-rename-home-fire)
- Dart 3.9.2, Flutter 3.35.5 stable + Flutter SDK, Material Design, existing RiskPalette, CachedBadge widge (016-016-a14-riskbanner)
- N/A (UI-only changes, no data persistence) (016-016-a14-riskbanner)
- **A15** (Polygon Visualization): google_maps_flutter ^2.5.0 (Polygon overlays), RiskPalette (intensity colors), PolygonStyleHelper, MarkerIconHelper, PolygonToggleChip widget

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

## Documentation Guidelines

All documentation follows the **Divio Documentation System** with 4 categories organized in structured folders:

### Documentation Structure
```
docs/
├── README.md                    # Main navigation hub (start here)
├── guides/                      # How-to guides (problem-oriented)
│   ├── setup/                   # Setup & configuration guides
│   ├── testing/                 # Testing methodologies
│   └── security/                # Security best practices
├── reference/                   # Reference material (information-oriented)
│   └── Technical specs, API docs, test data
├── explanation/                 # Explanation (understanding-oriented)
│   └── Architecture, decisions, concepts
├── tutorials/                   # Tutorials (learning-oriented)
│   └── Step-by-step learning paths
├── runbooks/                    # Operational procedures
│   └── incident-response/       # Emergency response procedures
└── history/                     # Archived & deprecated docs
    ├── sessions/                # Historical session summaries
    └── deprecated/              # Superseded documentation
```

### When Creating/Updating Documentation

**1. Choose the Right Category** (Divio System):
- **Guides (How-To)**: "How do I configure Google Maps?" → `guides/setup/google-maps.md`
- **Reference**: "What are the FWI thresholds?" → `reference/test-regions.md`
- **Explanation**: "Why do we use worktrees?" → `WORKTREE_WORKFLOW.md`
- **Tutorials**: "Learn Flutter testing step-by-step" → `tutorials/` (future)
- **Runbooks**: "Security incident response" → `runbooks/incident-response/security-incidents.md`

**2. Always Add Frontmatter**:
```markdown
---
title: Google Maps Setup Guide
status: active
last_updated: 2025-11-01
category: guides
subcategory: setup
related:
  - guides/security/api-key-management.md
  - reference/test-regions.md
replaces:
  - ../history/deprecated/GOOGLE_MAPS_API_SETUP.md
---
```

**3. Use Existing Docs as Templates**:
- Setup guides: See `guides/setup/google-maps.md`
- Testing guides: See `guides/testing/integration-tests.md`
- Security guides: See `guides/security/api-key-management.md`
- Reference docs: See `reference/test-coverage.md`

**4. Link Related Documentation**:
- Use relative paths in `related:` frontmatter section
- Cross-reference in document body with relative links
- Update `docs/README.md` navigation if adding major new doc

**5. Archive, Don't Delete**:
- Move deprecated docs to `history/deprecated/`
- Move session summaries to `history/sessions/`
- Track archived files in new doc's `replaces:` frontmatter
- Preserve git history (use `git mv`, not delete + create)

**6. Documentation Anti-Patterns (Avoid)**:
- ❌ Creating duplicate docs with similar content
- ❌ Documentation in root `docs/` without category
- ❌ Missing frontmatter on active documentation
- ❌ Deleting old docs (archive them instead)
- ❌ Breaking internal links without updating references

**7. Key Documentation Principles**:
- ✅ Single source of truth (consolidate, don't duplicate)
- ✅ Clear categorization (users can find what they need)
- ✅ Maintained history (archived docs preserve context)
- ✅ Living documents (update `last_updated` when editing)
- ✅ Discoverable (proper linking and navigation)

### Quick Reference for Agents

**Creating new doc?**
1. Choose category folder (`guides/`, `reference/`, etc.)
2. Add frontmatter with title, status, category, related docs
3. Follow existing doc structure in that category
4. Update `docs/README.md` if it's a major addition

**Updating existing doc?**
1. Update `last_updated` in frontmatter
2. Preserve existing structure and style
3. Check if related docs need updates
4. Update links if moving/renaming

**Consolidating docs?**
1. Create new comprehensive doc in proper category folder
2. Add `replaces:` frontmatter listing archived files
3. Use `git mv` to archive old docs to `history/`
4. Update internal links in related documents
5. Commit with clear consolidation message

**Full strategy**: See `docs/DOCUMENTATION_STRATEGY.md`

## Recent Changes
- **Burnt Area Polygon Visualization** (A15, Issue #54):
  - Extended FireIncident model with `boundaryPoints: List<LatLng>?` for polygon boundaries
  - Added GeoJSON Polygon geometry parsing in `fromJson()` with validation (>= 3 points)
  - Created PolygonStyleHelper for intensity-based colors (35% fill opacity, RiskPalette colors)
  - Created MarkerIconHelper for programmatic flame icon generation
  - Implemented PolygonToggleChip widget for show/hide toggle with accessibility
  - Zoom threshold: polygons visible only at zoom >= 8.0
  - 96 tests covering model, styling, widget, and performance (50 polygons < 1ms)
  - See "Polygon Visualization Patterns" section for implementation details
- **Location Tracking Enhancements** (commits 71547bf, b8daaed, 0a24c37):
  - Added LocationSource enum (gps, manual, cached, defaultFallback) for UI attribution
  - Implemented timestamp tracking with 1-hour staleness threshold (HomeStateLoading.isLocationStale)
  - Added dual-layer validation: widget format checks + utility range/NaN/Infinity checks
  - Implemented trust-building UX: combination approach with icons, place names, positive framing
  - Comprehensive test coverage: 101 tests (21 LocationCard, 26 HomeState, 24 HomeController, 30 LocationUtils)
  - See "Location Tracking and Validation Patterns" section for implementation details
- 016-016-a14-riskbanner: Added Dart 3.9.2, Flutter 3.35.5 stable + Flutter SDK, Material Design, existing RiskPalette, CachedBadge widge

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

## Location Tracking and Validation Patterns

### LocationSource Enum for UI Attribution
Track location provenance through the stack for transparent UX:

```dart
// lib/models/location_models.dart
enum LocationSource {
  gps,              // Obtained via device GPS
  manual,           // Set by user (lat/lon or place search)
  cached,           // Loaded from cache/SharedPreferences
  defaultFallback,  // Scotland centroid fallback
}

// Usage in HomeController
Future<void> _performLoad() async {
  final locationResult = await _locationResolver.getLatLon();

  late final LocationSource locationSource;
  switch (locationResult) {
    case Right(:final value):
      if (_isManualLocation) {
        locationSource = LocationSource.manual;
      } else {
        locationSource = LocationSource.gps;  // GPS or cached from resolver
      }
  }

  // Create success state with source attribution
  _updateState(HomeStateSuccess(
    riskData: riskData,
    location: location,
    lastUpdated: DateTime.now(),
    locationSource: locationSource,      // Pass through for UI
    placeName: _isManualLocation ? _manualPlaceName : null,
  ));
}

// Usage in UI
Widget _buildLocationCard(HomeStateSuccess state) {
  // Dynamic icons based on source
  final icon = switch (state.locationSource) {
    LocationSource.gps => Icons.gps_fixed,
    LocationSource.manual => Icons.location_pin,
    LocationSource.cached => Icons.cached,
    LocationSource.defaultFallback => Icons.public,
  };

  // Contextual subtitles
  final subtitle = switch (state.locationSource) {
    LocationSource.gps => 'Current location (GPS)',
    LocationSource.manual when state.placeName != null => '${state.placeName} (set by you)',
    LocationSource.manual => 'Your chosen location',
    LocationSource.cached => 'Cached location',
    LocationSource.defaultFallback => 'Default location',
  };
}
```

### Timestamp Tracking for Staleness Detection
Implement 1-hour staleness threshold with visible warnings:

```dart
// lib/models/home_state.dart
sealed class HomeStateLoading {
  final DateTime? lastKnownLocationTimestamp;

  /// Staleness threshold: >1 hour
  bool get isLocationStale {
    if (lastKnownLocationTimestamp == null) return false;
    return DateTime.now().difference(lastKnownLocationTimestamp!) >
        const Duration(hours: 1);
  }
}

// lib/controllers/home_controller.dart
Future<void> _performLoad({required bool isRetry}) async {
  // Capture timestamp from previous success state
  final DateTime? lastKnownLocationTimestamp;
  switch (_state) {
    case HomeStateSuccess(:final location, :final lastUpdated):
      lastKnownLocation = location;
      lastKnownLocationTimestamp = lastUpdated;  // Exact timestamp capture
    case HomeStateError(:final cachedLocation):
      lastKnownLocation = cachedLocation;
      lastKnownLocationTimestamp = null;  // No reliable timestamp
    default:
      lastKnownLocation = null;
      lastKnownLocationTimestamp = null;  // First load
  }

  // Update loading state with captured values
  _updateState(HomeStateLoading(
    isRetry: isRetry,
    startTime: DateTime.now(),
    lastKnownLocation: lastKnownLocation,
    lastKnownLocationTimestamp: lastKnownLocationTimestamp,
  ));
}

// UI staleness warning
Widget _buildLocationCard(HomeStateLoading state) {
  final subtitle = state.isLocationStale
    ? 'Location may be outdated (${_formatAge(state.lastKnownLocationTimestamp)})'
    : 'Last updated: ${_formatTimestamp(state.lastKnownLocationTimestamp)}';
}
```

### Dual-Layer Input Validation
Validate at both widget (format) and utility (ranges) layers:

```dart
// lib/widgets/location_card.dart (Widget layer)
class LocationCard extends StatelessWidget {
  bool _hasValidLocation() {
    if (locationCoordinates == null || locationCoordinates!.isEmpty) {
      return false;
    }

    // Format validation: "XX.XX, YY.YY"
    if (!locationCoordinates!.contains(',')) {
      return false;
    }

    final parts = locationCoordinates!.split(',');
    if (parts.length != 2) return false;

    // Double parsing check
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());

    return lat != null && lon != null;
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = _hasValidLocation() ? 'Change' : 'Set';
    final displayText = _hasValidLocation()
      ? locationCoordinates
      : 'Location not set';
  }
}

// lib/utils/location_utils.dart (Utility layer)
class LocationUtils {
  static String logRedact(double lat, double lon) {
    try {
      // Validate NaN/Infinity
      if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite) {
        return 'Invalid location';
      }

      // Validate ranges: [-90, 90] x [-180, 180]
      if (!isValidCoordinate(lat, lon)) {
        return 'Invalid location';
      }

      // C2-compliant 2-decimal redaction
      return '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    } catch (e) {
      return 'Invalid location';  // Catch unexpected errors
    }
  }

  static bool isValidCoordinate(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
}
```

### Trust-Building UX Patterns
Combination approach: icons + place names + positive framing

```dart
// lib/screens/home_screen.dart
Widget _buildLocationCard(HomeStateSuccess state) {
  return LocationCard(
    locationCoordinates: LocationUtils.logRedact(
      state.location.latitude,
      state.location.longitude,
    ),
    locationSource: state.locationSource,  // Dynamic icon
    subtitle: _buildSubtitle(state),       // Contextual messaging
    onChangeLocation: () => _handleManualLocationEntry(),
  );
}

String _buildSubtitle(HomeStateSuccess state) {
  // Positive framing for manual locations
  if (state.locationSource == LocationSource.manual) {
    if (state.placeName != null) {
      return '${state.placeName} (set by you)';  // Place name + attribution
    }
    return 'Your chosen location';  // Positive framing (not "manual entry")
  }

  // GPS: Clear attribution
  if (state.locationSource == LocationSource.gps) {
    return 'Current location (GPS)';
  }

  // Cache: Transparency
  if (state.locationSource == LocationSource.cached) {
    return 'Cached location';
  }

  // Default: Clarity
  return 'Default location';
}

// Staleness warning (append to subtitle when needed)
Widget _buildLocationCard(HomeStateLoading state) {
  if (state.isLocationStale) {
    final baseSubtitle = _buildSubtitle(state);
    return '$baseSubtitle (may be outdated)';  // Non-alarming warning
  }
}
```

### Testing Location Tracking Patterns
Comprehensive test coverage for validation, timestamps, and source tracking:

```dart
// test/widget/location_card_test.dart
group('LocationCard validation', () {
  testWidgets('shows "Set" button when coordinates malformed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationCard(
            locationCoordinates: '55.9533',  // Missing comma
            onChangeLocation: () {},
          ),
        ),
      ),
    );

    expect(find.text('Set'), findsOneWidget);
    expect(find.text('Change'), findsNothing);
  });

  testWidgets('shows correct icon per LocationSource', (tester) async {
    for (final source in LocationSource.values) {
      await tester.pumpWidget(MaterialApp(
        home: LocationCard(
          locationCoordinates: '55.95, -3.19',
          locationSource: source,
        ),
      ));

      switch (source) {
        case LocationSource.gps:
          expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
        case LocationSource.manual:
          expect(find.byIcon(Icons.location_pin), findsOneWidget);
        case LocationSource.cached:
          expect(find.byIcon(Icons.cached), findsOneWidget);
        case LocationSource.defaultFallback:
          expect(find.byIcon(Icons.public), findsOneWidget);
      }
    }
  });
});

// test/unit/models/home_state_test.dart
test('isLocationStale returns true when >1 hour old', () {
  final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
  final state = HomeStateLoading(
    startTime: DateTime.now(),
    lastKnownLocationTimestamp: twoHoursAgo,
  );

  expect(state.isLocationStale, isTrue);
});

test('timestamp is captured exactly from lastUpdated', () async {
  // First load succeeds
  await controller.load();
  final successState = controller.state as HomeStateSuccess;
  final exactTimestamp = successState.lastUpdated;

  // Trigger second load
  final loadFuture = controller.load();
  await Future.delayed(const Duration(milliseconds: 10));

  // Loading state has exact timestamp
  final loadingState = controller.state as HomeStateLoading;
  expect(loadingState.lastKnownLocationTimestamp, equals(exactTimestamp));
});

// test/unit/utils/location_utils_test.dart
test('handles NaN latitude gracefully', () {
  final result = LocationUtils.logRedact(double.nan, -3.1883);
  expect(result, equals('Invalid location'));
});

test('handles out-of-range latitude (>90)', () {
  final result = LocationUtils.logRedact(91.0, -3.1883);
  expect(result, equals('Invalid location'));
});
```

### Location Tracking Anti-Patterns (Avoid)
```dart
// ❌ WRONG: No source attribution
HomeStateSuccess(
  riskData: risk,
  location: location,
  lastUpdated: DateTime.now(),
  // Missing locationSource and placeName
);

// ❌ WRONG: Raw coordinates in logs
_logger.info('Manual location: $lat, $lon');  // Violates C2

// ❌ WRONG: No timestamp tracking
HomeStateLoading(
  startTime: DateTime.now(),
  // Missing lastKnownLocationTimestamp for staleness detection
);

// ❌ WRONG: Widget validation only
if (coordinates.contains(',')) {  // Format check only
  display(coordinates);  // Doesn't validate NaN, Infinity, ranges
}

// ❌ WRONG: Utility validation only
final redacted = LocationUtils.logRedact(lat, lon);  // Range check
widget.display(redacted);  // Doesn't validate string format "XX.XX,YY.YY"

// ✅ CORRECT: Dual-layer validation
// Widget layer validates format
if (_hasValidLocation()) {
  // Utility layer validates ranges/NaN/Infinity
  final redacted = LocationUtils.logRedact(lat, lon);
  widget.display(redacted);
}
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

## Polygon Visualization Patterns

### FireIncident Model with Boundary Points
```dart
// Extended FireIncident supports both point markers and polygon overlays
class FireIncident extends Equatable {
  final String id;
  final LatLng location;        // Centroid for marker positioning
  final String intensity;       // "low" | "moderate" | "high"
  final List<LatLng>? boundaryPoints;  // Polygon vertices (>= 3 required)

  // Validation: boundaryPoints must have >= 3 points if provided
  void _validate() {
    if (boundaryPoints != null && boundaryPoints!.length < 3) {
      throw ArgumentError('boundaryPoints must have at least 3 points');
    }
  }
}

// JSON parsing for GeoJSON Polygon geometry
factory FireIncident.fromJson(Map<String, dynamic> json) {
  List<LatLng>? boundaryPoints;
  final geometry = json['geometry'];
  if (geometry != null && geometry['type'] == 'Polygon') {
    final coords = geometry['coordinates'][0] as List;
    if (coords.length >= 3) {
      boundaryPoints = coords.map((c) => LatLng(c[1], c[0])).toList();
    }
  }
  return FireIncident(..., boundaryPoints: boundaryPoints);
}
```

### PolygonStyleHelper Usage
```dart
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';

// Get fill color with 35% opacity for intensity level
final fillColor = PolygonStyleHelper.getFillColor('high');  // RiskPalette.veryHigh @ 35%

// Get stroke color (full opacity) for intensity level
final strokeColor = PolygonStyleHelper.getStrokeColor('moderate');  // RiskPalette.high

// Check if zoom level allows polygon display
final showPolygons = PolygonStyleHelper.shouldShowPolygonsAtZoom(currentZoom);
// Returns true when zoom >= 8.0

// Constants
PolygonStyleHelper.fillOpacity;       // 0.35
PolygonStyleHelper.strokeWidth;       // 2
PolygonStyleHelper.minZoomForPolygons;  // 8.0
```

### Building Polygons for GoogleMap
```dart
Set<Polygon> _buildPolygons(List<FireIncident> incidents, bool showPolygons, double zoom) {
  if (!showPolygons || !PolygonStyleHelper.shouldShowPolygonsAtZoom(zoom)) {
    return {};
  }

  return incidents
    .where((i) => i.boundaryPoints != null && i.boundaryPoints!.length >= 3)
    .map((incident) => Polygon(
      polygonId: PolygonId('polygon_${incident.id}'),
      points: incident.boundaryPoints!
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(),
      fillColor: PolygonStyleHelper.getFillColor(incident.intensity),
      strokeColor: PolygonStyleHelper.getStrokeColor(incident.intensity),
      strokeWidth: PolygonStyleHelper.strokeWidth,
      consumeTapEvents: true,
      onTap: () => _showIncidentDetails(incident),
    ))
    .toSet();
}
```

### MarkerIconHelper for Flame Icons
```dart
import 'package:wildfire_mvp_v3/features/map/utils/marker_icon_helper.dart';

// Initialize once at app startup
await MarkerIconHelper.initialize();

// Get marker icon by intensity
final icon = MarkerIconHelper.getIcon('high');  // Returns BitmapDescriptor

// Falls back to default red marker if not initialized
// Logs warning: "MarkerIconHelper: Icons not initialized, using default marker"
```

### PolygonToggleChip Widget
```dart
import 'package:wildfire_mvp_v3/features/map/widgets/polygon_toggle_chip.dart';

PolygonToggleChip(
  showPolygons: _showPolygons,
  enabled: PolygonStyleHelper.shouldShowPolygonsAtZoom(_currentZoom),
  onToggle: () => setState(() => _showPolygons = !_showPolygons),
)

// Features:
// - Material Design chip styling
// - Disabled when zoom < 8.0 (polygons not visible anyway)
// - Accessible: proper semantics labels for screen readers
// - Minimum 44dp touch target
```

### MapScreen Integration Pattern
```dart
class _MapScreenState extends State<MapScreen> {
  bool _showPolygons = true;
  double _currentZoom = 6.5;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          markers: _buildMarkers(incidents),
          polygons: _buildPolygons(incidents, _showPolygons, _currentZoom),
          onCameraMove: (position) {
            setState(() => _currentZoom = position.zoom);
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: PolygonToggleChip(
            showPolygons: _showPolygons,
            enabled: PolygonStyleHelper.shouldShowPolygonsAtZoom(_currentZoom),
            onToggle: () => setState(() => _showPolygons = !_showPolygons),
          ),
        ),
      ],
    );
  }
}
```

### Testing Polygon Features
```dart
// Performance test: 50 polygons should generate in <100ms
test('generates 50 polygons within 100ms', () {
  final stopwatch = Stopwatch()..start();
  final polygons = incidents.map((i) => buildPolygon(i)).toSet();
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});

// Widget test: toggle changes polygon visibility
testWidgets('toggle hides polygons', (tester) async {
  await tester.tap(find.byType(PolygonToggleChip));
  await tester.pump();
  expect(controller.showPolygons, isFalse);
});
```

### Polygon Visualization Anti-Patterns (Avoid)
```dart
// ❌ WRONG: Allow polygons with < 3 points
FireIncident(boundaryPoints: [LatLng(55.0, -3.0)]); // Throws ArgumentError

// ❌ WRONG: Show polygons at low zoom (they appear as tiny specks)
if (zoom >= 5.0) showPolygons();  // Use 8.0 threshold instead

// ❌ WRONG: Hardcode polygon colors
Polygon(fillColor: Colors.red.withOpacity(0.35));  // Use PolygonStyleHelper

// ❌ WRONG: Missing accessibility on toggle
GestureDetector(onTap: toggle);  // Use PolygonToggleChip with semantics

// ✅ CORRECT: Use helpers for consistent styling
Polygon(
  fillColor: PolygonStyleHelper.getFillColor(intensity),
  strokeColor: PolygonStyleHelper.getStrokeColor(intensity),
);
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
- Google Maps: `YOUR_GOOGLE_MAPS_API_KEY_HERE` (use actual key format in production)
- AWS: `YOUR_AWS_ACCESS_KEY_HERE` (20 chars)
- GitHub: `YOUR_GITHUB_TOKEN_HERE` (40 chars)

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
# Check for Google Maps API keys (starts with AIza followed by 35 chars)
grep -rE "AIza[A-Za-z0-9_-]{35}" <your-files>

# Check for AWS access keys (starts with AKIA followed by 16 uppercase chars)
grep -rE "AKIA[A-Z0-9]{16}" <your-files>

# Check for GitHub tokens (starts with ghp_ followed by 36 chars)
grep -rE "ghp_[A-Za-z0-9]{36}" <your-files>
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
