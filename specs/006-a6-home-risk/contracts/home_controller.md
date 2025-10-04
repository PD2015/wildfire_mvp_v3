# HomeController Contract

## Overview
HomeController manages the state of the home screen, orchestrating LocationResolver and FireRiskService to provide fire risk information to users.

## API Contract

### Class Definition
```dart
class HomeController extends ChangeNotifier {
  HomeController({
    required LocationResolver locationResolver,
    required FireRiskService fireRiskService,
  });
}
```

### State Management
```dart
// Current state accessor
HomeState get state;

// State change notifications via ChangeNotifier
void addListener(VoidCallback listener);
void removeListener(VoidCallback listener);
```

### Core Operations
```dart
// Initialize and load risk data
Future<void> load({bool isRetry = false});

// Retry after error
Future<void> retry();

// Update location manually
Future<void> setManualLocation(LatLng coordinates, [String? placeName]);

// Refresh current data
Future<void> refresh();

// Cleanup resources
@override
void dispose();
```

### State Transitions
```dart
// Initial → Loading
Initial state → HomeStateLoading(isRetry: false, startTime: now)

// Loading → Success
HomeStateLoading → HomeStateSuccess(
  riskData: FireRisk,
  location: LocationInfo, 
  lastUpdated: DateTime,
  source: DataSource
)

// Loading → Error
HomeStateLoading → HomeStateError(
  errorMessage: String,
  cachedData: FireRisk?,
  location: LocationInfo?,
  lastUpdated: DateTime?,
  canRetry: true
)

// Error → Loading (retry)
HomeStateError → HomeStateLoading(isRetry: true, startTime: now)

// Success → Loading (refresh)
HomeStateSuccess → HomeStateLoading(isRetry: false, startTime: now)
```

## Service Dependencies

### LocationResolver Integration
```dart
// Get current location with fallback chain
final locationResult = await _locationResolver.getLatLon();

// Handle location errors
if (locationResult.isLeft()) {
  // Use default Scotland location or prompt for manual entry
}
```

### FireRiskService Integration  
```dart
// Get risk data for location
final riskResult = await _fireRiskService.getCurrent(
  lat: location.latitude, 
  lon: location.longitude
);

// Handle service fallback chain (EFFIS → SEPA → Cache → Mock)
// Service handles timeouts and error states internally
```

## Error Handling Contract

### Error Categories
1. **Location Errors**: GPS denied, service unavailable, timeout
2. **Risk Data Errors**: All services failed, network unavailable
3. **Validation Errors**: Invalid manual coordinates

### Error Response Format
```dart
HomeStateError(
  errorMessage: "User-friendly error description",
  cachedData: riskData,      // if available
  location: lastKnownLocation,
  lastUpdated: cacheTimestamp,
  canRetry: true
)
```

### Retry Capability
- Retry MUST be available unless explicitly disabled
- Retry attempts MUST have loading state indication  
- Retry MUST not spam services (debounced)

## Performance Requirements

### Loading Performance
- Initial load MUST start within 100ms of controller creation
- State updates MUST trigger UI rebuilds within 16ms (60fps)
- Memory cleanup MUST occur on dispose

### Resilience Requirements
- Service timeouts handled gracefully (via existing service implementations)
- Network failures MUST show cached data when available
- All async operations MUST be cancellable on dispose

## Testing Contract

### Mock Requirements
```dart
// Constructor must accept mock services for testing
HomeController({
  required LocationResolver locationResolver,  // mockable
  required FireRiskService fireRiskService,   // mockable
});
```

### Test Scenarios (6 required)
1. **EFFIS Success**: Location found, EFFIS returns data
2. **SEPA Success**: Scotland location, SEPA returns data  
3. **Cache Fallback**: Services fail, cache returns data
4. **Mock Fallback**: All services fail, mock returns data
5. **Location Denied → Manual**: GPS denied, manual coordinates entered
6. **Retry Flow**: Error state, retry succeeds

### State Verification
```dart
// Each test must verify exact state transitions
expect(controller.state, isA<HomeStateLoading>());
// ... trigger action
expect(controller.state, isA<HomeStateSuccess>());

// Error states must include retry capability
expect((controller.state as HomeStateError).canRetry, isTrue);

// Success states must include all required data
final success = controller.state as HomeStateSuccess;
expect(success.riskData, isNotNull);
expect(success.location, isNotNull);
expect(success.lastUpdated, isNotNull);
expect(success.source, isNotNull);
```

## Constitutional Compliance

### C1: Code Quality
- All methods MUST be documented with dartdoc comments
- Error states MUST be explicit, no silent failures
- Unit tests required for all public methods

### C3: Accessibility  
- State changes MUST be compatible with screen readers
- Loading states MUST provide progress indication

### C4: Trust & Transparency
- All success states MUST include timestamp and source
- Data source MUST be clearly indicated (live/cached/mock)

### C5: Resilience
- All async operations MUST handle errors gracefully
- Service integration MUST use existing timeout/retry logic  
- Controller MUST be disposable without resource leaks

---

**Status**: Contract defined for HomeController with state management, service integration, and testing requirements
**Dependencies**: LocationResolver (A4), FireRiskService (A2)  
**Next**: HomeScreen widget contract