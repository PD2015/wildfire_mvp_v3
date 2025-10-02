# Quickstart: LocationResolver Integration

## Prerequisites
- Flutter 3.0+ with Dart 3.0+
- Android API 23+ / iOS 15+ for location permissions
- Existing A1-A3 codebase with dartz Either pattern established

## Quick Integration (5 minutes)

### 1. Add Dependencies
```yaml
# pubspec.yaml
dependencies:
  geolocator: ^9.0.2
  permission_handler: ^11.0.1
  shared_preferences: ^2.2.2
  geocoding: ^2.1.1  # Optional for place search
```

### 2. Basic Service Setup
```dart
// lib/services/location_resolver.dart
import 'package:dartz/dartz.dart';

abstract class LocationResolver {
  Future<Either<LocationError, LatLng>> getLatLon();
  Future<void> saveManual(LatLng location, {String? placeName});
}

// lib/services/location_resolver_impl.dart
class LocationResolverImpl implements LocationResolver {
  static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);
  
  @override
  Future<Either<LocationError, LatLng>> getLatLon() async {
    // GPS attempt
    final gpsResult = await _tryGps();
    if (gpsResult.isRight()) return gpsResult;
    
    // Manual cache check
    final cachedResult = await _loadCachedLocation();
    if (cachedResult.isSome()) {
      return Right(cachedResult.getOrElse(() => _scotlandCentroid));
    }
    
    // Manual entry (trigger dialog)
    final manualResult = await _requestManualEntry();
    if (manualResult.isRight()) return manualResult;
    
    // Default fallback
    return Right(_scotlandCentroid);
  }
}
```

### 3. Simple Integration Point
```dart
// In your existing FireRiskService or similar
class HomeController {
  final LocationResolver _locationResolver;
  
  Future<void> loadWildfireRisk() async {
    final locationResult = await _locationResolver.getLatLon();
    
    locationResult.fold(
      (error) => print('Location error: ${error.message}'),
      (coords) async {
        // Use coords.latitude, coords.longitude for risk assessment
        final riskResult = await fireRiskService.getCurrent(
          lat: coords.latitude, 
          lon: coords.longitude,
        );
        // Handle risk result...
      },
    );
  }
}
```

## Complete User Stories Validation

### Story 1: First App Launch (GPS Available)
**Test Steps**:
1. Fresh app install, no previous location data
2. App requests location for wildfire risk
3. System prompts for GPS permission
4. User grants permission
5. GPS returns coordinates within 2 seconds

**Expected Result**: `getLatLon()` returns `Right(LatLng)` with GPS coordinates
**Verification**: Check that coordinates are reasonable (Scotland area) and risk assessment proceeds

### Story 2: GPS Permission Denied
**Test Steps**:
1. App requests location
2. User denies GPS permission
3. No manual location previously saved
4. App should continue functioning

**Expected Result**: `getLatLon()` returns `Right(LatLng)` with Scotland centroid (55.8642, -4.2518)
**Verification**: App shows wildfire risk for central Scotland, no error dialogs or crashes

### Story 3: Manual Location Entry
**Test Steps**:
1. GPS denied or unavailable
2. User wants to specify custom location
3. Trigger manual entry dialog
4. User enters "55.9533, -3.1883" (Edinburgh)
5. User saves location

**Expected Result**: 
- Dialog validates input and accepts coordinates
- `saveManual()` persists location to SharedPreferences
- `getLatLon()` returns saved location on future calls
**Verification**: Restart app, location should persist and be used immediately

### Story 4: Manual Location Persistence
**Test Steps**:
1. User enters manual location (from Story 3)
2. Force close and restart app
3. App requests location (GPS still denied)

**Expected Result**: `getLatLon()` returns previously saved manual location without showing dialog
**Verification**: Check SharedPreferences contains correct lat/lon values

### Story 5: Invalid Input Handling
**Test Steps**:
1. Open manual location dialog
2. Enter invalid coordinates: "invalid, text" or "999, 999"
3. Attempt to save

**Expected Result**: 
- Dialog shows validation error
- Input fields highlight invalid values
- Save button remains disabled or shows error
- User can correct input and retry
**Verification**: No crash, clear error messages, ability to retry

### Story 6: Mid-Session Permission Changes
**Test Steps**:
1. App running with GPS permission granted
2. User goes to system settings and revokes location permission
3. App requests location again (without restart)

**Expected Result**: `getLatLon()` gracefully handles permission change and falls back to manual/default
**Verification**: No crash, immediate fallback, no permission dialogs shown

## Performance Validation

### GPS Timeout Testing
```dart
// Test that GPS requests timeout after 2 seconds
void testGpsTimeout() async {
  final stopwatch = Stopwatch()..start();
  final result = await locationResolver.getLatLon();
  stopwatch.stop();
  
  // Should complete within 3 seconds total (2s GPS + 1s fallback)
  assert(stopwatch.elapsedMilliseconds < 3000);
  assert(result.isRight()); // Should have fallback result
}
```

### SharedPreferences Performance
```dart
// Test that persistence operations complete quickly
void testPersistenceSpeed() async {
  final location = LatLng(55.9533, -3.1883);
  
  final stopwatch = Stopwatch()..start();
  await locationResolver.saveManual(location);
  final result = await locationResolver.getLatLon();
  stopwatch.stop();
  
  // Should complete within 200ms
  assert(stopwatch.elapsedMilliseconds < 200);
  assert(result.getOrElse(() => LatLng(0, 0)) == location);
}
```

## Dialog UI Validation

### Manual Entry Dialog Test
```dart
// Widget test for dialog functionality
testWidgets('Manual location dialog accepts valid coordinates', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => ManualLocationDialog(),
          ),
          child: Text('Open Dialog'),
        ),
      ),
    ),
  ));
  
  // Open dialog
  await tester.tap(find.text('Open Dialog'));
  await tester.pumpAndSettle();
  
  // Enter valid coordinates
  await tester.enterText(find.byKey(Key('latitude_field')), '55.9533');
  await tester.enterText(find.byKey(Key('longitude_field')), '-3.1883');
  
  // Verify save button is enabled and tap it
  final saveButton = find.text('Save Location');
  expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNotNull);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
  
  // Dialog should close with success result
  expect(find.byType(ManualLocationDialog), findsNothing);
});
```

### Accessibility Validation
```dart
testWidgets('Dialog meets accessibility requirements', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: ManualLocationDialog(),
  ));
  
  // Check touch target sizes (≥44dp)
  final saveButton = find.byKey(Key('save_button'));
  final saveButtonSize = tester.getSize(saveButton);
  expect(saveButtonSize.width, greaterThanOrEqualTo(44.0));
  expect(saveButtonSize.height, greaterThanOrEqualTo(44.0));
  
  // Check semantic labels
  expect(find.bySemanticsLabel(RegExp(r'latitude')), findsOneWidget);
  expect(find.bySemanticsLabel(RegExp(r'longitude')), findsOneWidget);
  expect(find.bySemanticsLabel(RegExp(r'save')), findsOneWidget);
});
```

## Error Scenario Testing

### Network/GPS Unavailable
```dart
void testOfflineScenario() async {
  // Mock GPS as unavailable
  when(mockGeolocator.getCurrentPosition()).thenThrow(
    LocationServiceDisabledException(),
  );
  
  final result = await locationResolver.getLatLon();
  
  // Should fallback to Scotland centroid
  expect(result.isRight(), true);
  final coords = result.getOrElse(() => LatLng(0, 0));
  expect(coords.latitude, closeTo(55.8642, 0.1));
  expect(coords.longitude, closeTo(-4.2518, 0.1));
}
```

### SharedPreferences Corruption
```dart
void testCorruptedCache() async {
  // Simulate corrupted data
  when(mockPreferences.getDouble('manual_location_lat')).thenReturn(null);
  when(mockPreferences.getDouble('manual_location_lon')).thenReturn(999.999);
  
  final result = await locationResolver.getLatLon();
  
  // Should gracefully handle corruption and use default
  expect(result.isRight(), true);
}
```

## Integration Checklist

### Pre-Implementation
- [ ] Dependencies added to pubspec.yaml
- [ ] iOS Info.plist includes location usage descriptions
- [ ] Android manifest includes location permissions

### Core Implementation
- [ ] LocationResolver interface matches contract
- [ ] Fallback chain follows GPS → cache → manual → default order
- [ ] Either<LocationError, LatLng> return type consistent with A1-A3
- [ ] Scotland centroid constant defined correctly

### Permission Handling
- [ ] No blocking permission requests on app startup
- [ ] Graceful handling of denied/deniedForever states
- [ ] Mid-session permission changes handled without crash
- [ ] No multiple permission dialogs shown in sequence

### Manual Entry
- [ ] Dialog accepts lat/lon coordinate input
- [ ] Input validation rejects invalid ranges
- [ ] Optional place search returns first result only
- [ ] Persistence works across app restarts

### Testing Coverage
- [ ] Unit tests for all fallback scenarios
- [ ] Widget tests for dialog validation and accessibility
- [ ] Integration tests for permission flows
- [ ] Performance tests for GPS timeout and persistence speed

### Constitutional Compliance
- [ ] C1: flutter analyze passes, comprehensive tests included
- [ ] C2: Coordinate logging limited to 2-3 decimal places
- [ ] C3: Dialog meets ≥44dp touch targets and semantic labels
- [ ] C5: All error cases handled, no silent failures

## Quick Verification Commands

```bash
# Run all location-related tests
flutter test test/unit/services/location_resolver_test.dart
flutter test test/widget/dialogs/manual_location_dialog_test.dart
flutter test test/integration/location_flow_test.dart

# Check code quality
flutter analyze --no-pub
dart format --set-exit-if-changed .

# Verify GPS timeout performance (requires device/simulator)
flutter run --debug
# Trigger location request and observe console timing logs
```

## Common Issues and Solutions

### Issue: GPS Takes Too Long
**Solution**: Ensure geolocator timeout is set to 2 seconds maximum
```dart
await Geolocator.getCurrentPosition(
  timeLimit: Duration(seconds: 2),
);
```

### Issue: Dialog Doesn't Show
**Solution**: Check that manual entry is triggered only after GPS and cache failures
```dart
// Only show dialog if GPS denied AND no cached location
if (gpsResult.isLeft() && cachedResult.isNone()) {
  // Show manual entry dialog
}
```

### Issue: Coordinates Don't Persist
**Solution**: Verify SharedPreferences initialization and error handling
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setDouble('manual_location_lat', location.latitude);
await prefs.setDouble('manual_location_lon', location.longitude);
```

This quickstart provides immediate integration capability while ensuring all user stories are validatable and the implementation follows constitutional requirements.