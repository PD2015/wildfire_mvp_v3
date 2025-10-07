# Cache Clearing Test Contract

**Contract Type**: Unit Test Interface  
**Target**: Enhanced cache clearing functionality in main.dart  
**Coverage Requirement**: 95%

## Test Interface Contract

### Method Under Test
```dart
Future<void> _clearCachedLocation()
```

### Test Contract Requirements

#### Complete Cache Clearing
**Contract**: All 5 SharedPreferences keys are cleared
```dart
// GIVEN: SharedPreferences contains cached location data
// WHEN: _clearCachedLocation() is called
// THEN: All keys are removed:
//   - 'manual_location_lat'
//   - 'manual_location_lon' 
//   - 'manual_location_place'
//   - 'location_timestamp'
//   - 'location_source'
// AND: Test mode setting is preserved
```

#### State Validation Before Clearing
**Contract**: Cache state is validated before clearing operation
```dart
// GIVEN: Populated cache with location data
// WHEN: _clearCachedLocation() is called
// THEN: Pre-clearing state is logged
// AND: Cache population status is verified
// AND: Key count is validated (5 keys expected)
```

#### State Validation After Clearing
**Contract**: Cache state is validated after clearing operation
```dart
// GIVEN: _clearCachedLocation() has completed
// WHEN: Cache state is checked
// THEN: All location keys return null
// AND: Post-clearing state is logged
// AND: Clear operation success is confirmed
```

#### Test Mode Preservation
**Contract**: Test mode settings are not affected by cache clearing
```dart
// GIVEN: Test mode is active ('test_mode': true)
// WHEN: _clearCachedLocation() is called
// THEN: Test mode setting remains unchanged
// AND: Debug logging configuration preserved
// AND: Other non-location settings unaffected
```

### Error Scenarios

#### SharedPreferences Access Error
**Contract**: Handle SharedPreferences access failures gracefully
```dart
// GIVEN: SharedPreferences.getInstance() throws exception
// WHEN: _clearCachedLocation() is called
// THEN: Error is caught and logged
// AND: Method completes without throwing
// AND: Error recovery is attempted (retry logic)
```

#### Individual Key Removal Error
**Contract**: Handle individual key removal failures
```dart
// GIVEN: One key removal fails
// WHEN: _clearCachedLocation() processes all keys
// THEN: Other keys are still cleared successfully
// AND: Partial failure is logged with specific key
// AND: Overall operation continues
```

### Mock Requirements

#### Required Mocks
- `MockSharedPreferences` - Storage simulation
- `MockLogger` - Debug logging validation

#### Mock Behavior Contracts
```dart
// SharedPreferences Mock Setup
when(mockPreferences.remove('manual_location_lat'))
  .thenAnswer((_) async => true);
when(mockPreferences.remove('manual_location_lon'))
  .thenAnswer((_) async => true);
when(mockPreferences.remove('manual_location_place'))
  .thenAnswer((_) async => true);
when(mockPreferences.remove('location_timestamp'))
  .thenAnswer((_) async => true);
when(mockPreferences.remove('location_source'))
  .thenAnswer((_) async => true);

// Verification Contract
verify(mockPreferences.remove('manual_location_lat')).called(1);
verify(mockPreferences.remove('manual_location_lon')).called(1);
verify(mockPreferences.remove('manual_location_place')).called(1);
verify(mockPreferences.remove('location_timestamp')).called(1);
verify(mockPreferences.remove('location_source')).called(1);
```

### Performance Contracts

#### Response Time
- Cache clearing operation: <100ms
- State validation: <50ms per validation
- Error recovery: <200ms

#### Resource Usage
- Minimal memory allocation during clearing
- Single SharedPreferences instance usage
- No unnecessary object creation

### Integration Contracts

#### LocationResolver Integration
**Contract**: Cache clearing integrates with LocationResolver fallback
```dart
// GIVEN: Cache has been cleared via _clearCachedLocation()
// WHEN: LocationResolver.getLatLon() is called
// THEN: Cache fallback returns None()
// AND: LocationResolver falls back to next tier (manual entry or default)
// AND: No stale cache data influences location resolution
```

#### Home Screen Integration  
**Contract**: Cache clearing triggered from home screen works correctly
```dart
// GIVEN: Home screen cache clear button is pressed
// WHEN: _clearCachedLocation() is called from UI context
// THEN: Cache clearing completes successfully
// AND: UI state is updated to reflect cleared cache
// AND: User receives confirmation of cache clearing
```

### State Validation Contracts

#### Pre-Clearing State
```dart
// Expected cache state before clearing:
// - At least 1 location key has non-null value
// - Timestamp indicates recent cache activity
// - Source indicates cache origin (GPS/manual/default)
```

#### Post-Clearing State
```dart
// Expected cache state after clearing:
// - All 5 location keys return null
// - No location-related SharedPreferences entries
// - Test mode and other settings preserved
```

---
*Contract defines behavioral requirements for enhanced cache clearing testing implementation*