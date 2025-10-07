# GPS Bypass Test Contract

**Contract Type**: Unit Test Interface  
**Target**: LocationResolverImpl GPS bypass logic  
**Coverage Requirement**: 100%

## Test Interface Contract

### Method Under Test
```dart
Future<Either<LocationError, LatLng>> getLatLon()
```

### Test Contract Requirements

#### GPS Bypass Activation
**Contract**: When GPS is bypassed, return hardcoded Aviemore coordinates
```dart
// GIVEN: GPS bypass is active (debugging mode)
// WHEN: getLatLon() is called
// THEN: Return Right(LatLng(57.2, -3.8))
// AND: No GPS service calls are made
// AND: Debug log contains "GPS bypassed for debugging"
```

#### GPS Service Not Called
**Contract**: GPS bypass prevents actual GPS service invocation
```dart
// GIVEN: GPS bypass is active
// WHEN: getLatLon() is called
// THEN: MockGeolocator.getCurrentPosition() is never called
// AND: LocationUtils.logRedact(57.2, -3.8) appears in logs
```

#### Bypass State Validation
**Contract**: GPS bypass state can be validated
```dart
// GIVEN: GPS bypass configuration
// WHEN: Bypass state is checked
// THEN: Return accurate bypass status
// AND: Coordinate source is identifiable as "DEBUG_BYPASS"
```

### Error Scenarios

#### Bypass Configuration Error
**Contract**: Invalid bypass configuration handled gracefully
```dart
// GIVEN: Malformed bypass configuration
// WHEN: getLatLon() is called with bypass active
// THEN: Fall back to Scotland centroid (55.8642, -4.2518)
// AND: Log error "GPS bypass configuration invalid"
```

### Mock Requirements

#### Required Mocks
- `MockGeolocator` - GPS service simulation
- `MockSharedPreferences` - Bypass state storage
- `MockLogger` - Debug logging validation

#### Mock Behavior Contracts
```dart
// GPS Service Mock
when(mockGeolocator.getCurrentPosition())
  .thenThrow(Exception('Should not be called during bypass'));

// SharedPreferences Mock  
when(mockPreferences.getBool('gps_bypass_active'))
  .thenReturn(true);

// Logger Mock
verify(mockLogger.info(contains('GPS bypassed for debugging'))).called(1);
```

### Performance Contracts

#### Response Time
- GPS bypass response: <10ms (no network calls)
- Bypass state check: <5ms (local configuration)

#### Resource Usage
- No GPS permission requests during bypass
- No location service activations during bypass
- Minimal memory allocation (hardcoded coordinates)

### Integration Contracts

#### FireRiskService Integration
**Contract**: GPS bypass coordinates work with fire risk services
```dart
// GIVEN: GPS bypass returns Aviemore coordinates (57.2, -3.8)
// WHEN: FireRiskService.getCurrent() is called with bypass coordinates
// THEN: Valid fire risk data is returned (Scotland boundaries)
// AND: No geographic boundary errors occur
```

#### Cache Integration
**Contract**: Bypass coordinates integrate with cache service
```dart
// GIVEN: GPS bypass coordinates (57.2, -3.8)
// WHEN: CacheService processes coordinates
// THEN: Valid geohash key is generated
// AND: Cache operations succeed without geographic errors
```

---
*Contract defines behavioral requirements for GPS bypass testing implementation*