# RiskBanner Widget Contract

## Widget Interface Contract

### RiskBannerWidget

**Purpose**: Home screen widget displaying current wildfire risk level

```dart
class RiskBannerWidget extends StatelessWidget {
  /// Creates a RiskBanner widget
  /// 
  /// [latitude] and [longitude] specify the location for risk assessment
  /// [onTap] optional callback when widget is tapped
  /// [config] optional configuration for widget appearance
  const RiskBannerWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.onTap,
    this.config = const RiskBannerConfig(),
  }) : super(key: key);

  final double latitude;
  final double longitude;
  final VoidCallback? onTap;
  final RiskBannerConfig config;

  @override
  Widget build(BuildContext context);
}
```

**Pre-conditions**:
- `latitude` must be between -90.0 and 90.0
- `longitude` must be between -180.0 and 180.0

**Post-conditions**:
- Widget displays appropriate color for risk level
- Widget is minimum 44dp height for accessibility
- Widget includes semantic labels for screen readers
- Widget shows loading state during data fetch
- Widget shows error state with cached data if available

### Expected Widget States

#### Loading State
```dart
// Visual: Loading spinner with gray background
// Semantic: "Loading wildfire risk data"
// Height: Minimum 44dp
```

#### Loaded State
```dart
// Visual: Colored background matching risk level + risk text + timestamp
// Semantic: "{level} wildfire risk, last updated {timestamp}, data from {source}"
// Height: Content height, minimum 44dp
// Tap: Triggers onTap callback if provided
```

#### Error State (with cached data)
```dart
// Visual: Faded cached data + error indicator
// Semantic: "Error loading current data, showing cached {level} wildfire risk from {timestamp}"  
// Height: Content height, minimum 44dp
// Tap: Triggers onTap callback if provided
```

#### Error State (no cached data)
```dart
// Visual: Gray background + error message
// Semantic: "Unable to load wildfire risk data"
// Height: Minimum 44dp
// Tap: Triggers onTap callback if provided  
```

## BLoC Interface Contract

### RiskBannerCubit

```dart
class RiskBannerCubit extends Cubit<RiskBannerState> {
  /// Creates a RiskBannerCubit with repository dependency
  RiskBannerCubit({
    required FireRiskRepository repository,
  }) : _repository = repository, super(const RiskBannerInitial());

  /// Loads risk data for specified coordinates
  /// Emits loading state, then success or error state
  Future<void> loadRiskData(double latitude, double longitude);
  
  /// Refreshes current risk data
  /// Only available when in loaded state
  Future<void> refresh();
}
```

**Method Contracts**:

#### loadRiskData(latitude, longitude)
- **Pre-conditions**: Valid coordinate values
- **Post-conditions**: State transitions from current → Loading → (Loaded | Error)
- **Side effects**: Calls repository.getRiskData()
- **Exceptions**: None (errors captured in state)

#### refresh()
- **Pre-conditions**: Current state is RiskBannerLoaded
- **Post-conditions**: State transitions Loading → (Loaded | Error)
- **Side effects**: Calls repository.getRiskData() with force refresh
- **Exceptions**: None if precondition violated (no-op)

## Repository Interface Contract

### FireRiskRepository

```dart
abstract class FireRiskRepository {
  /// Gets current fire risk data for specified coordinates
  /// 
  /// Returns cached data if network fails
  /// [forceRefresh] bypasses cache when available
  Future<Either<FireRiskFailure, FireRisk>> getRiskData({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  });
}
```

**Method Contracts**:

#### getRiskData({latitude, longitude, forceRefresh})
- **Pre-conditions**: Valid coordinate ranges
- **Post-conditions**: Returns Either<Failure, FireRisk>
- **Success case**: FireRisk with valid data and timestamp
- **Failure case**: FireRiskFailure with error details
- **Side effects**: May cache successful results
- **Timeout**: Inherits from A2 FireRiskService (30 seconds)

## Error Interface Contract

### FireRiskFailure

```dart
sealed class FireRiskFailure extends Equatable {
  const FireRiskFailure();
}

class NetworkFailure extends FireRiskFailure {
  final String message;
  const NetworkFailure(this.message);
}

class ServiceFailure extends FireRiskFailure {
  final String service; // 'EFFIS', 'SEPA', etc.
  final String message;
  const ServiceFailure(this.service, this.message);
}

class ValidationFailure extends FireRiskFailure {
  final String field;
  final String message;
  const ValidationFailure(this.field, this.message);
}
```

## Integration Points

### A2 FireRiskService Integration
- Repository wraps A2 service calls 
- Maps A2 Either<ApiError, FireRisk> to local Either<FireRiskFailure, FireRisk>
- Preserves A2 fallback chain behavior (EFFIS → SEPA → Cache → Mock)
- Inherits A2 geographic utilities and telemetry

### Flutter Framework Integration  
- Widget registered with BlocProvider for dependency injection
- State changes trigger automatic rebuilds
- Accessibility services integration via Semantics widgets
- Theme integration for text styles (colors from constants)

## Testing Contracts

### Widget Tests
```dart
testWidgets('displays loading state initially', (tester) async {
  // Arrange: Mock repository returning delayed response
  // Act: Pump widget
  // Assert: Loading indicator visible, semantic label correct
});

testWidgets('displays risk level with correct color', (tester) async {
  // Arrange: Mock repository returning high risk
  // Act: Pump widget and wait for data
  // Assert: Red background, "High wildfire risk" text
});

testWidgets('meets accessibility requirements', (tester) async {
  // Arrange: Widget with typical data
  // Act: Pump widget
  // Assert: Minimum size 44dp, semantic labels present
});
```

### BLoC Tests  
```dart
blocTest<RiskBannerCubit, RiskBannerState>(
  'emits loading then loaded when data fetch succeeds',
  build: () => RiskBannerCubit(repository: mockRepository),
  act: (cubit) => cubit.loadRiskData(55.9533, -3.1883),
  expect: () => [
    isA<RiskBannerLoading>(),
    isA<RiskBannerLoaded>(),
  ],
);
```

### Integration Tests
```dart
testWidgets('end-to-end risk display flow', (tester) async {
  // Arrange: Real services with controlled responses
  // Act: User opens screen, data loads
  // Assert: Correct risk level displayed with all metadata
});
```