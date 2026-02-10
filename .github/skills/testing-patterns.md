# Skill: Testing Patterns — WildFire MVP

> Teaches the agent how to write tests that follow this project's established conventions.

## Test Directory Structure

Tests mirror the source tree:

```
test/
├── unit/                          # Pure logic (no Flutter widgets)
│   ├── features/<name>/           # Feature-specific unit tests
│   │   ├── models/                # State class tests
│   │   └── widgets/               # Widget logic tests (if pure)
│   ├── controllers/               # Shared controller tests
│   ├── models/                    # Shared model tests
│   ├── services/                  # Service unit tests
│   └── utils/                     # Utility tests
├── widget/                        # Widget render/interaction tests
│   ├── <name>/                    # Feature widget tests
│   ├── screens/                   # Screen tests
│   └── theme/                     # Theme tests
├── integration/                   # Multi-component integration tests
│   ├── <name>/                    # Feature integration tests
│   ├── cache/                     # Cache integration
│   └── map/                       # Map integration
├── contract/                      # API contract tests
├── performance/                   # Performance benchmarks
├── fixtures/                      # Shared test data files
├── helpers/                       # Shared test utilities
└── support/                       # Test infrastructure
```

## Test File Conventions

### Naming

```
test/unit/features/report/models/report_fire_state_test.dart
test/widget/onboarding/onboarding_screen_test.dart
test/integration/onboarding_flow_test.dart
```

Pattern: `<source_file_name>_test.dart`

### Imports

```dart
// Framework first
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Third-party
import 'package:dartz/dartz.dart';

// Project imports
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
```

## Const Test Data

Use `const` for all compile-time constant test data:

```dart
// ✅ CORRECT — const for literals and immutable constructors
const testLat = 55.9533;
const testLon = -3.1883;
const testLocation = LatLng(55.9533, -3.1883);
const testBounds = LatLngBounds(
  southwest: LatLng(55.0, -4.0),
  northeast: LatLng(56.0, -3.0),
);
const emptyIncidents = <FireIncident>[];

// ✅ CORRECT — final for runtime values
final testTimestamp = DateTime.now();
final testState = FeatureSuccess(data: data, lastUpdated: DateTime.now());

// ❌ WRONG — non-const when value is constant
final testLocation = LatLng(55.9533, -3.1883);  // Should be const
```

### Const in Constructor Arguments

```dart
// ✅ CORRECT
final state = MapSuccess(
  incidents: const [],              // const empty list
  centerLocation: const LatLng(55.9, -3.2),
  freshness: Freshness.mock,
  lastUpdated: DateTime.now(),      // Runtime — final is correct
);

// ❌ WRONG
final state = MapSuccess(
  incidents: [],                    // Missing const
  centerLocation: LatLng(55.9, -3.2),  // Missing const
);
```

## Widget Test Pattern

Always wrap in `MaterialApp` with theme:

```dart
testWidgets('shows risk level correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: WildfireA11yTheme.light,
      darkTheme: WildfireA11yTheme.dark,
      home: Scaffold(
        body: FeatureWidget(data: testData),
      ),
    ),
  );

  expect(find.text('Moderate'), findsOneWidget);
});
```

### Animation Handling

Use `pump()` + `pump(Duration)` instead of `pumpAndSettle()` when animations are present (e.g., `CircularProgressIndicator`):

```dart
// ✅ CORRECT — avoids pumpAndSettle timeout from animations
await tester.pumpWidget(widget);
await tester.pump();
await tester.pump(const Duration(milliseconds: 100));

// ❌ RISKY — may timeout with infinite animations
await tester.pumpAndSettle();
```

## Mock Service Pattern

Mocks must match production interface exactly:

```dart
// ✅ CORRECT — matches interface signature exactly
class MockFireRiskService implements FireRiskService {
  Either<ApiError, FireRisk>? _result;

  void setResult(Either<ApiError, FireRisk> result) => _result = result;

  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    return _result ?? Right(FireRisk(
      level: RiskLevel.low,
      fwi: 5.0,
      source: DataSource.mock,
      observedAt: DateTime.now().toUtc(),
      freshness: Freshness.live,
    ));
  }
}
```

**Checklist for mocks**:
1. Check production interface signature (return type, parameter names)
2. Match `Either<ApiError, T>` — not `Either<dynamic, T>`
3. Use `@override` to catch mismatches at compile time
4. Include all required parameters (check named params like `deadline`)

## Binding Initialization

Tests using platform channels need binding setup:

```dart
void main() {
  // REQUIRED before accessing SharedPreferences, Geolocator, etc.
  WidgetsFlutterBinding.ensureInitialized();

  test('cache stores data', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // ...
  });
}
```

**When needed**: SharedPreferences, Geolocator, url_launcher, any native plugin.
**Not needed**: Pure unit tests, widget tests using `testWidgets()` (auto-initialized).

## Privacy-Compliant Test Logging

```dart
// ✅ CORRECT — redacted coordinates in test assertions
expect(
  LocationUtils.logRedact(55.9533, -3.1883),
  equals('55.95,-3.19'),
);

// ✅ CORRECT — test validates redaction works
test('handles NaN gracefully', () {
  expect(LocationUtils.logRedact(double.nan, -3.1883), equals('Invalid location'));
});

// ❌ WRONG — full-precision coordinates in test output
print('Testing location: $lat, $lon');  // C2 violation + avoid_print
```

## Print Statements

```dart
// ❌ WRONG in production code (lib/)
print('Processing...');  // avoid_print violation

// ✅ CORRECT in production code
debugPrint('Processing...');
developer.log('Processing...', name: 'Service');

// ✅ ALLOWED in performance tests (with file-level ignore)
// ignore_for_file: avoid_print
test('Map loads within 3s', () {
  print('✅ Map load time: ${stopwatch.elapsedMilliseconds}ms');
});
```

## Test Group Organization

```dart
void main() {
  group('FeatureController', () {
    late MockService mockService;
    late FeatureController controller;

    setUp(() {
      mockService = MockService();
      controller = FeatureController(service: mockService);
    });

    group('initialization', () {
      test('starts in loading state', () {
        expect(controller.state, isA<FeatureLoading>());
      });

      test('transitions to success on valid data', () async {
        mockService.setResult(Right(testData));
        await controller.initialize();
        expect(controller.state, isA<FeatureSuccess>());
      });

      test('transitions to error on failure', () async {
        mockService.setResult(Left(ApiError(message: 'Network error')));
        await controller.initialize();
        expect(controller.state, isA<FeatureError>());
      });
    });

    group('state properties', () {
      // Test computed properties on state classes
    });
  });
}
```

## Test Checklist for New Features

- [ ] Unit test for every state class (construction, props, computed properties)
- [ ] Unit test for controller (initialization, state transitions, error handling)
- [ ] Widget test for screen (renders each state correctly)
- [ ] Widget test for custom widgets (interaction, accessibility)
- [ ] Integration test for full flow (service → controller → UI)
- [ ] Mock services implement production interface exactly
- [ ] `const` used for all constant test data
- [ ] No `print()` (use `debugPrint()` or file-level ignore for perf tests)
- [ ] `WidgetsFlutterBinding.ensureInitialized()` where needed
- [ ] Tests work on web platform (`--platform=chrome`)
