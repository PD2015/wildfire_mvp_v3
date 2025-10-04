# WildFire Prototype — Context Pack

## What We’re Building
WildFire MVP prototype for Scotland. **Phase-0 goal**: display current wildfire risk on the Home screen.
- Primary data: EFFIS Fire Weather Index (FWI)
- Fallbacks: SEPA (Scotland only) → Cache → Mock
- Focus: proving data feeds + hooks, not emergency-grade reliability yet.

## Scope for Phase-0
- Risk data service + simple Home screen banner
- No notifications, authentication, or advanced map features
- Map overlays and reporting deferred to later phases

## Guardrails (from Constitution)
- No secrets in repo; env/runtime config only
- All data must show **Last updated** timestamp + source label
- Use official wildfire risk color scale only
- A11y: semantic labels + ≥44dp targets
- Clear offline/error/cached states (no silent fails)

## Data Chain (for Phase-0)
**FireRiskService Fallback Decision Tree**:
```
getCurrent(lat, lon) → FireRisk
    ↓
[Validate coordinates] → Left(ApiError) if invalid
    ↓
[1. EFFIS] (3s timeout) → Success? → FireRisk{source: effis, freshness: live}
    ↓ Fail
[2. SEPA] (2s timeout, Scotland only) → Success? → FireRisk{source: sepa, freshness: live}  
    ↓ Fail
[3. Cache] (1s timeout) → Hit? → FireRisk{source: original, freshness: cached}
    ↓ Miss
[4. Mock] (<100ms, never fails) → FireRisk{source: mock, freshness: mock}
```

**Service Details**:
1. **EFFIS** — Fire Weather Index via WMS GetFeatureInfo (A1 implementation)
   - Global coverage, primary data source
   - Returns EffisFwiResult → converted to FireRisk
   - 3-second timeout within 8-second total budget
2. **SEPA** — Scotland Environment Protection Agency fallback
   - **Geographic bounds**: 54.6-60.9°N, -9.0-1.0°E (includes St Kilda, Orkney, Shetland)
   - Only attempted when `isInScotland(lat, lon) == true` AND EFFIS fails
   - 2-second timeout for Scottish-specific fire risk data
3. **Cache** — TTL 6h for resilience
   - Preserves original source attribution in cached FireRisk
   - 1-second timeout for cache lookups
4. **Mock** — clearly tagged as fallback when no data available
   - **Never-fail guarantee**: Always succeeds within 100ms
   - Uses deterministic geohash-based risk levels for consistency

**Privacy Compliance (C2)**:
- All logging uses `GeographicUtils.logRedact(lat, lon)` → rounds to 2dp
- No raw coordinates or place names in logs or telemetry
- Geographic resolution ~1.1km prevents exact location identification

## LocationResolver Service (A4)
**Headless Location Architecture** — service provides coordinates, UI handles prompts:

**5-Tier Fallback Chain** (2.5s total budget):
```
getLatLon(allowDefault) → Either<LocationError, LatLng>
    ↓
[1. Last Known Position] (<100ms) → Available? → Return immediately
    ↓ Unavailable
[2. GPS Fix] (2s timeout) → Permission granted? → GPS coordinates
    ↓ Denied/Failed
[3. SharedPreferences Cache] (<100ms) → Manual location cached? → Return cached
    ↓ No cache
[4. Manual Entry] → allowDefault=false? → Left(LocationError) → Caller opens dialog
    ↓ allowDefault=true
[5. Scotland Centroid] → LatLng(56.5, -4.2) [rural/central bias avoidance]
```

**Scotland Centroid Choice**: `LatLng(56.5, -4.2)` represents central rural location, avoiding urban bias toward Edinburgh/Glasgow while remaining within Scotland's geographic center for representative wildfire risk data.

**Privacy & Logging (C2)**:
```dart
// CORRECT: Privacy-preserving coordinate logging
_logger.info('Location resolved: ${LocationUtils.logRedact(lat, lon)}');
// Outputs: "Location resolved: 56.50,-4.20"

// WRONG: Raw coordinates expose PII - violates C2 gate
_logger.info('Location: $lat,$lon'); // NEVER do this
```

**Integration Pattern** (A6/Home responsibility):
- LocationResolver returns `Left(LocationError)` when manual entry needed
- A6/Home opens `ManualLocationDialog` on receiving `Left(...)`
- User enters coordinates → A6/Home calls `saveManual(LatLng, placeName?)`
- Subsequent calls use cached coordinates from tier 3

**Persistence & Resilience (C5)**:
- SharedPreferences with version compatibility (`manual_location_version: '1.0'`)
- Graceful corruption handling → never crash, fallback to Scotland centroid
- Web/emulator platform detection → skip GPS attempts, use cache/manual/default

## CacheService (A5)

Local cache for FireRisk data with 6-hour TTL and geohash spatial keying.

**Architecture**:
- **Storage**: SharedPreferences with JSON serialization
- **Keying**: Geohash precision 5 (~4.9km spatial resolution)
- **TTL**: 6-hour expiration with lazy cleanup
- **Size**: Max 100 entries with LRU eviction
- **Timestamps**: UTC discipline prevents timezone corruption
- **Privacy**: Geohash keys provide inherent coordinate obfuscation

**Integration** (FireRiskService fallback tier 3):
```dart
// Cache lookup in fallback chain
final geohash = GeohashUtils.encode(lat, lon, precision: 5);
final cached = await cacheService.get(geohash);
if (cached.isSome()) {
  return cached.value; // Already marked freshness=cached
}
// Continue to mock fallback...
```

**Performance Targets**:
- Read operations: <200ms target
- Write operations: <100ms target
- Non-blocking UI thread operations

**Privacy Compliance (C2)**:
- Geohash keys in SharedPreferences (no raw coordinates)
- ~4.9km spatial resolution prevents precise location identification
- All cache operations use geohash logging instead of raw lat/lon

**Resilience (C5)**:
- Corruption-safe JSON parsing with graceful cache miss fallback
- Version field in stored entries prevents deserialization errors
- Clock injection enables deterministic TTL testing

## Non-Goals
- Emergency compliance or alert certification
- Push notifications
- Fire polygon rendering
- Multi-user accounts

# A6 Home Screen Architecture

## HomeState Management

**State Model (Sealed Class Hierarchy)**:
```dart
sealed class HomeState extends Equatable {
  const HomeState();
}

class HomeLoading extends HomeState {
  const HomeLoading();
  // Display: Loading indicator with skeleton UI
}

class HomeSuccess extends HomeState {  
  final FireRisk fireRisk;
  final LatLng location;
  final String formattedLocation;
  
  // Display: RiskBanner with live data, timestamp, source chip
}

class HomeError extends HomeState {
  final String message;
  final FireRisk? cachedRisk;  // May have cached data despite error
  final LatLng? location;
  
  // Display: Error message + cached data (if available) + retry button
}
```

## HomeController (ChangeNotifier Pattern)

**State Management**:  
- Extends `ChangeNotifier` for reactive UI updates
- Constructor injection: `LocationResolver`, `FireRiskService`  
- Methods: `load()`, `retry()`, `setManualLocation(LatLng)`
- 8-second global deadline inherited from FireRiskService (A2)
- Re-entrancy protection: disable retry during loading

**Controller Lifecycle**:
```dart
HomeController({
  required LocationResolver locationResolver,
  required FireRiskService fireRiskService,
}) {
  // Auto-load on initialization
  WidgetsBinding.instance.addPostFrameCallback((_) => load());
}

Future<void> load() async {
  if (_isLoading) return; // Re-entrancy protection
  
  state = HomeLoading();
  notifyListeners();
  
  try {
    // Step 1: Resolve location
    final locationResult = await locationResolver.getLatLon();
    final location = locationResult.fold(
      (error) => throw LocationException(error.toString()),
      (latLng) => latLng,
    );
    
    // Step 2: Get fire risk data  
    final riskResult = await fireRiskService.getCurrent(
      lat: location.latitude,
      lon: location.longitude,
    );
    
    riskResult.fold(
      (error) => state = HomeError(
        message: error.message,
        cachedRisk: error.cachedData, // May include cached FireRisk
        location: location,
      ),
      (fireRisk) => state = HomeSuccess(
        fireRisk: fireRisk,
        location: location,
        formattedLocation: _formatLocation(location),
      ),
    );
  } catch (e) {
    state = HomeError(message: e.toString(), location: null);
  }
  
  notifyListeners();
}
```

**Privacy Compliance (C2)**:
- All location logging uses `logRedact()` helper
- No raw coordinates in logs or user-facing strings
- Location formatting rounds to 2 decimal places maximum

## HomeScreen UI Rendering Rules

**State-Based Rendering**:
```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Wildfire Risk')),
    body: Consumer<HomeController>(
      builder: (context, controller, child) {
        return switch (controller.state) {
          HomeLoading() => _buildLoadingState(),
          HomeSuccess(fireRisk: final risk, location: final loc) => 
            _buildSuccessState(risk, loc),
          HomeError(message: final msg, cachedRisk: final cached, location: final loc) => 
            _buildErrorState(msg, cached, loc),
        };
      },
    ),
  );
}
```

**Loading State**:
- Skeleton UI with RiskBanner placeholder
- Loading indicator with semantic label "Loading wildfire risk data"
- No interactive elements during loading

**Success State**:
- RiskBanner component with live FireRisk data
- Timestamp display: "Updated {relative time}" (e.g., "Updated 2 minutes ago")
- Source chip: "Live", "EFFIS", "SEPA" based on `fireRisk.source`
- Manual location button (44dp minimum) with semantic label

**Error State with Cached Data**:
- Error message at top with retry button (44dp minimum)
- RiskBanner displays cached data with "Cached" badge
- Clear visual distinction between error message and cached data
- Timestamp shows cache age: "Cached data from {relative time}"

**Error State without Cache**:
- Error message with retry button
- Mock data displayed with "Mock data" label
- Clear indication this is fallback/sample data

## Accessibility Compliance (C3)

**Touch Targets**:
- All interactive elements ≥44dp (iOS) / ≥48dp (Android) 
- Retry button, manual location button, RiskBanner (if tappable)

**Semantic Labels**:
- Loading: "Loading wildfire risk data"
- Retry: "Retry loading wildfire risk"
- Manual location: "Set manual location"
- RiskBanner includes: risk level, relative time, data source

**Screen Reader Support**:
- State announcements on loading/success/error transitions
- Structured heading hierarchy in error states
- Context-aware descriptions for cached vs live data

## Manual Location Flow

**Integration with LocationResolver (A4)**:
1. GPS/cached location fails → `LocationResolver.getLatLng()` returns `Left(LocationError)`
2. HomeController catches error → sets state to show manual entry option
3. User taps "Set Manual Location" → opens `ManualLocationDialog`
4. Dialog validates coordinates (-90≤lat≤90, -180≤lon≤180)
5. On success → calls `LocationResolver.saveManual(LatLng, placeName?)`
6. HomeController calls `load()` again → uses cached manual location

**Manual Location Dialog**:
- Two text inputs: Latitude, Longitude
- Real-time validation with error messages
- Save button disabled until valid coordinates entered
- Cancel option returns to previous state

## Retry and Timeout Handling

**Retry Logic**:
- Retry button available in all error states
- Calls `HomeController.retry()` → identical to `load()`
- Button disabled during loading to prevent re-entrancy
- No limit on retry attempts (user-controlled)

**Timeout Enforcement**:
- 8-second global deadline from FireRiskService
- No additional timeout at HomeController level
- Loading state shows indefinitely until service responds or times out
- Service timeout becomes HomeError state with retry option

**Refresh on App Resume**:
- AppLifecycleObserver in main.dart detects app resume
- Debounced call to `HomeController.refresh()` after 500ms delay
- Prevents excessive API calls during rapid app switching

## Performance and Memory

**Memory Management**:
- HomeController properly disposed via widget lifecycle
- Service instances shared via composition root (singleton pattern)
- No memory leaks from listeners or streams

**Performance Targets**:
- Time to first skeleton: <100ms
- Data loading deadline: 8s (service budget)
- UI animations: 60fps
- Memory usage: <50MB for home screen

**Caching Strategy**:
- FireRisk data cached automatically by CacheService (A5)
- Location coordinates cached by LocationResolver (A4)
- No additional UI-level caching required

## Integration Testing Coverage

**6 Core Scenarios**:
1. **EFFIS Success**: Live data from EFFIS with proper source labeling
2. **SEPA Success**: Scotland location → SEPA fallback with source chip
3. **Cache Fallback**: Services fail → error state with cached data badge
4. **Mock Fallback**: All fail → error state with mock data clearly labeled
5. **Manual Location**: GPS denied → manual entry flow → success
6. **Retry Flow**: Error state → retry button → loading → success

**Additional Test Coverage**:
- Dark mode rendering for all risk levels
- Accessibility semantic labels and touch targets
- Privacy compliance (no raw coordinates in logs)
- Controller lifecycle (dispose without leaks)
- Re-entrancy protection during loading
- Scotland boundary detection accuracy

## Constitutional Compliance Verification

**C1: Code Quality**: 
- `flutter analyze` passes with zero warnings
- `dart format` enforced in CI
- Test coverage >90% for HomeController and HomeScreen

**C3: Accessibility**:
- Widget tests verify ≥44dp touch targets
- Semantic labels tested for screen readers
- Color contrast meets WCAG AA standards

**C4: Trust & Transparency**:
- Timestamp visible in all success states
- Source labeling (Live/Cached/Mock) always displayed
- Official Scottish wildfire colors only
- Clear error messages with context

**C5: Resilience**:
- Error states always provide retry mechanism
- No silent failures (all errors surfaced to user)
- Graceful degradation with cached/mock data
- Re-entrancy protection prevents race conditions

## References
- Constitution v1.0 (root)
- `docs/DATA-SOURCES.md`
- `scripts/allowed_colors.txt` (palette)
- `lib/theme/risk_palette.dart` (when added)

