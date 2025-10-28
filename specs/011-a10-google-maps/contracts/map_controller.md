# Service Contract: MapController

**Purpose**: State management for MapScreen, orchestrating location resolution, fire data fetching, and map interactions.

**Implementation**: `lib/features/map/controllers/map_controller.dart`

---

## Interface Definition

```dart
class MapController extends ChangeNotifier {
  /// Current state of the map screen
  MapState get state;
  
  /// Initialize controller and load initial map data
  ///
  /// Called from MapScreen.initState()
  /// Resolves user location → fetches fires in default bbox → emits MapSuccess
  Future<void> initialize();
  
  /// Refresh fire data for current visible region
  ///
  /// Called on camera idle (debounced 1s) or manual pull-to-refresh
  /// Uses GoogleMapController.getVisibleRegion() for bbox
  Future<void> refreshMapData(LatLngBounds visibleBounds);
  
  /// Perform point-based risk assessment at specific location
  ///
  /// Called on map long-press or "Check risk here" button tap
  /// Returns RiskAssessmentResult via FireRiskService (A2)
  Future<Either<ServiceError, RiskAssessmentResult>> checkRiskAt(LatLng location);
  
  /// Clean up resources
  ///
  /// Called from MapScreen.dispose()
  @override
  void dispose();
}
```

---

## Constructor

```dart
MapController({
  required LocationResolver locationResolver,        // A4
  required FireLocationService fireLocationService,  // New (A10)
  required FireRiskService fireRiskService,          // A2
  CacheService? cacheService,                        // A5 (optional)
  ConstitutionLogger? logger,
}) : _locationResolver = locationResolver,
     _fireLocationService = fireLocationService,
     _fireRiskService = fireRiskService,
     _cacheService = cacheService,
     _logger = logger ?? ConstitutionLogger();
```

**Validation**:
- `locationResolver`, `fireLocationService`, `fireRiskService` must not be null
- `cacheService` optional (tests may omit)
- `logger` defaults to ConstitutionLogger if not provided

---

## State Machine

### State Transitions

```
Initial (MapLoading)
  ↓ initialize()
MapLoading
  ↓ Location resolved + Fires fetched successfully
MapSuccess(incidents, location, freshness=live)
  ↓ refreshMapData() called
MapLoading
  ↓ Fires fetched from cache
MapSuccess(incidents, location, freshness=cached)
  ↓ All services fail
MapError(message, cachedIncidents?)
  ↓ Manual refresh
MapLoading
  ↓ Services recover
MapSuccess(incidents, location, freshness=live)
```

### State Emission Rules

1. **Always emit MapLoading** before async operations
2. **Always emit MapSuccess or MapError** after operations complete
3. **Never leave in MapLoading** > 10 seconds (timeout to MapError)
4. **Preserve cached data** in MapError.cachedIncidents for graceful degradation

---

## Method Specifications

### `initialize()`

**Purpose**: Load initial map data on screen mount.

**Flow**:
```dart
Future<void> initialize() async {
  _state = MapLoading();
  notifyListeners();
  
  try {
    // Step 1: Resolve user location (A4)
    final locationResult = await _locationResolver.getLatLng();
    final location = locationResult.getOrElse(() => LatLng(57.2, -3.8)); // Scotland centroid fallback
    
    // Step 2: Calculate default bbox (zoom level ~8, ~50km radius)
    final bounds = LatLngBounds.fromCenter(location, radiusKm: 50);
    
    // Step 3: Fetch fires in bbox
    final firesResult = await _fireLocationService.getActiveFires(bounds: bounds);
    
    firesResult.fold(
      (error) {
        _state = MapError(message: error.message);
        _logger.logError('MapController.initialize', error);
      },
      (incidents) {
        _state = MapSuccess(
          incidents: incidents,
          centerLocation: location,
          freshness: _determineFreshness(incidents),
          lastUpdated: DateTime.now(),
        );
        _logger.logInfo('MapController.initialize', {
          'incidents': incidents.length,
          'location': LocationUtils.logRedact(location.latitude, location.longitude),
        });
      },
    );
  } catch (e) {
    _state = MapError(message: 'Failed to initialize map: $e');
    _logger.logError('MapController.initialize', e);
  } finally {
    notifyListeners();
  }
}
```

**Performance Requirements**:
- Must complete within 3 seconds (FR-009 from spec)
- Location resolution: ≤2s (A4 timeout)
- Fire fetch: ≤8s (service timeout)
- Total: ≤10s before MapError timeout

**Error Handling**:
- LocationResolver failure → use Scotland centroid (57.2, -3.8)
- FireLocationService failure → MapError (but mock fallback should prevent this)
- Exceptions → catch and emit MapError

---

### `refreshMapData(LatLngBounds visibleBounds)`

**Purpose**: Update fire data when user pans/zooms map.

**Trigger**: Called from MapScreen after camera idle (debounced 1s).

**Flow**:
```dart
Future<void> refreshMapData(LatLngBounds visibleBounds) async {
  final previousState = _state;
  _state = MapLoading();
  notifyListeners();
  
  try {
    // Fetch fires for new visible region
    final firesResult = await _fireLocationService.getActiveFires(
      bounds: visibleBounds,
      timeout: Duration(seconds: 8),
    );
    
    firesResult.fold(
      (error) {
        // Graceful degradation: keep previous incidents if available
        if (previousState is MapSuccess) {
          _state = MapError(
            message: error.message,
            cachedIncidents: previousState.incidents,
            lastKnownLocation: previousState.centerLocation,
          );
        } else {
          _state = MapError(message: error.message);
        }
        _logger.logError('MapController.refreshMapData', error);
      },
      (incidents) {
        _state = MapSuccess(
          incidents: incidents,
          centerLocation: visibleBounds.center,
          freshness: _determineFreshness(incidents),
          lastUpdated: DateTime.now(),
        );
        _logger.logInfo('MapController.refreshMapData', {
          'incidents': incidents.length,
          'bbox': LocationUtils.logRedact(visibleBounds.center.latitude, visibleBounds.center.longitude),
        });
      },
    );
  } catch (e) {
    _state = MapError(message: 'Failed to refresh map: $e');
    _logger.logError('MapController.refreshMapData', e);
  } finally {
    notifyListeners();
  }
}
```

**Debouncing Logic** (in MapScreen):
```dart
Timer? _debounceTimer;

void _onCameraIdle() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(seconds: 1), () async {
    final visibleRegion = await _mapController?.getVisibleRegion();
    if (visibleRegion != null) {
      _controller.refreshMapData(visibleRegion);
    }
  });
}
```

**Performance Requirements**:
- Debounce 1s prevents excessive API calls during pan/zoom
- Refresh must complete within 9s (service timeout chain)
- Show loading indicator during refresh

---

### `checkRiskAt(LatLng location)`

**Purpose**: Get fire weather index risk assessment for tapped location.

**Trigger**: Called on map long-press or "Check risk here" button.

**Flow**:
```dart
Future<Either<ServiceError, RiskAssessmentResult>> checkRiskAt(LatLng location) async {
  _logger.logInfo('MapController.checkRiskAt', {
    'location': LocationUtils.logRedact(location.latitude, location.longitude),
  });
  
  // Use existing FireRiskService (A2)
  final riskResult = await _fireRiskService.getCurrent(
    lat: location.latitude,
    lon: location.longitude,
  );
  
  return riskResult.map((fireRisk) {
    return RiskAssessmentResult(
      location: location,
      fwiValue: fireRisk.fwiValue,
      riskLevel: fireRisk.riskLevel,
      source: fireRisk.source,
      freshness: fireRisk.freshness,
      timestamp: fireRisk.timestamp,
    );
  });
}
```

**UI Integration**:
```dart
// In MapScreen
void _onMapLongPress(LatLng position) async {
  final result = await _controller.checkRiskAt(position);
  
  result.fold(
    (error) => _showErrorSnackBar(error.message),
    (assessment) => _showRiskAssessmentChip(assessment),
  );
}
```

**Performance Requirements**:
- Must complete within 9s (FireRiskService timeout chain)
- Show loading indicator while fetching
- Display result in RiskAssessmentChip widget

---

### `dispose()`

**Purpose**: Clean up resources and listeners.

**Flow**:
```dart
@override
void dispose() {
  _logger.logInfo('MapController.dispose', {'finalState': _state.runtimeType});
  // Cancel any pending timers
  _debounceTimer?.cancel();
  super.dispose();
}
```

---

## Helper Methods (Private)

### `_determineFreshness(List<FireIncident> incidents)`

```dart
Freshness _determineFreshness(List<FireIncident> incidents) {
  if (incidents.isEmpty) return Freshness.live;
  
  // If any incident is mock, entire set is mock
  if (incidents.any((i) => i.freshness == Freshness.mock)) {
    return Freshness.mock;
  }
  
  // If any incident is cached, entire set is cached
  if (incidents.any((i) => i.freshness == Freshness.cached)) {
    return Freshness.cached;
  }
  
  // All incidents are live
  return Freshness.live;
}
```

---

## Widget Integration

### MapScreen Usage

```dart
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _controller;
  GoogleMapController? _mapController;
  
  @override
  void initState() {
    super.initState();
    
    // Inject dependencies
    _controller = MapController(
      locationResolver: context.read<LocationResolver>(),
      fireLocationService: context.read<FireLocationService>(),
      fireRiskService: context.read<FireRiskService>(),
      cacheService: context.read<CacheService>(),
    );
    
    // Initialize map data
    _controller.initialize();
    
    // Listen to state changes
    _controller.addListener(_onStateChanged);
  }
  
  void _onStateChanged() {
    setState(() {}); // Rebuild UI on state change
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    
    return Scaffold(
      body: switch (state) {
        MapLoading() => Center(child: CircularProgressIndicator()),
        MapSuccess(incidents: final incidents, centerLocation: final location) =>
          GoogleMap(
            initialCameraPosition: CameraPosition(target: location, zoom: 8),
            markers: _buildMarkers(incidents),
            onCameraIdle: _onCameraIdle,
            onLongPress: _controller.checkRiskAt,
            onMapCreated: (controller) => _mapController = controller,
          ),
        MapError(message: final msg, cachedIncidents: final cached) =>
          _buildErrorView(msg, cached),
      },
    );
  }
}
```

---

## Performance Monitoring

### Metrics to Track

1. **Initialize duration**: `performance_timer('map_controller_init')`
   - Target: < 3s (FR-009)
   - Alert if > 5s on 3 consecutive calls

2. **Refresh duration**: `performance_timer('map_controller_refresh')`
   - Target: < 9s (service timeout chain)
   - Alert if > 10s

3. **State transition counts**: Track MapLoading → MapSuccess vs MapError ratio
   - Target: > 95% success rate
   - Alert if < 90% (indicates service issues)

4. **Memory usage**: Track heap size before/after initialize()
   - Target: Δ < 75MB (FR-011)
   - Alert if Δ > 100MB

---

## Testing Requirements

### Unit Tests

1. ✅ `initialize()` success → emits MapSuccess
2. ✅ `initialize()` LocationResolver fails → uses Scotland centroid fallback
3. ✅ `initialize()` FireLocationService fails → emits MapError
4. ✅ `refreshMapData()` success → updates MapSuccess with new incidents
5. ✅ `refreshMapData()` fails but has previous state → emits MapError with cached incidents
6. ✅ `checkRiskAt()` success → returns RiskAssessmentResult
7. ✅ `checkRiskAt()` fails → returns ServiceError
8. ✅ `_determineFreshness()` with mixed incidents → returns most stale freshness
9. ✅ `dispose()` cancels timers and cleans up

### Widget Tests

1. ✅ MapScreen renders CircularProgressIndicator during MapLoading
2. ✅ MapScreen renders GoogleMap with markers during MapSuccess
3. ✅ MapScreen renders error view with cached data during MapError
4. ✅ Camera idle triggers refreshMapData() after 1s debounce
5. ✅ Long press triggers checkRiskAt() and shows RiskAssessmentChip

### Integration Tests

1. ✅ Full flow: initialize → render → camera move → refresh → display updated markers
2. ✅ Fallback chain: EFFIS fails → SEPA → Cache → Mock, UI updates correctly
3. ✅ Performance: initialize completes within 3s on average device

---

## Constitutional Compliance

- **C1 (Code Quality)**: Unit tests for all public methods, widget tests for UI integration
- **C2 (Secrets & Logging)**: Coordinates redacted via LocationUtils.logRedact() in all logs
- **C3 (Accessibility)**: N/A (controller layer, accessibility in MapScreen widgets)
- **C4 (Transparency)**: State includes source (effis/sepa/cache/mock) and lastUpdated timestamp
- **C5 (Resilience)**: Graceful degradation to cached data on errors, never-fail via mock fallback

---

**Contract Version**: 1.0  
**Last Updated**: October 19, 2025  
**Status**: Ready for implementation
