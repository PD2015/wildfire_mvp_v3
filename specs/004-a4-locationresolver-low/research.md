# Research: LocationResolver Implementation

## Decision: Flutter Location Architecture

### GPS and Permissions
**Chosen**: `geolocator` package (^9.0.0+) + `permission_handler` (^11.0.0+)
**Rationale**: 
- Geolocator provides unified GPS access across iOS/Android with built-in permission handling
- Permission_handler gives granular control over permission states (granted/denied/deniedForever)
- Both packages handle platform differences and have strong community support
- Flutter team recommends geolocator for location services

**Alternatives Considered**:
- `location` package: Less comprehensive permission handling
- Platform channels: Too much boilerplate for basic GPS access
- Built-in Flutter location: Doesn't exist, would need platform-specific code

### Persistence Strategy  
**Chosen**: `shared_preferences` for manual location storage
**Rationale**:
- Lightweight key-value storage perfect for single LatLng persistence
- Cross-platform, no database overhead needed
- Easy JSON serialization for ManualLocation object
- Already in use by many Flutter apps, minimal dependency impact

**Alternatives Considered**:
- SQLite/drift: Overkill for single record storage
- Hive: More complex than needed for simple coordinates
- File storage: Platform path differences, manual JSON handling

### Geocoding Support
**Chosen**: `geocoding` package (^2.1.0+) with first-result-only strategy
**Rationale**:
- Simple place name → coordinates conversion for user convenience
- Can stub out implementation for MVP, add later if needed
- Lightweight, doesn't require UI complexity of search results
- Works offline with cached results where available

**Alternatives Considered**:
- Google Places API: Requires API keys, billing setup
- Here Maps: Commercial licensing needed
- MapBox: Too complex for simple "first result" requirement

### Error Handling Pattern
**Chosen**: `dartz` Either<LocationError, LatLng> return type (consistent with A1-A3)
**Rationale**:
- Consistent with existing FireRisk service architecture
- Forces explicit error handling at call sites
- Clear distinction between error types and successful coordinates
- No exceptions thrown, predictable control flow

**Alternatives Considered**:
- Exception throwing: Inconsistent with project pattern
- Nullable returns: Loss of error information
- Callback patterns: More complex than needed

### Permission Flow Strategy
**Chosen**: Non-blocking permission requests with immediate fallback
**Rationale**:
- User experience prioritizes immediate access to wildfire info
- Permission denial doesn't create app-blocking error states  
- Graceful degradation maintains app functionality
- Follows "low-friction" requirement from specification

**Permission State Handling**:
- `granted`: Use GPS with 2s timeout
- `denied`: Immediate fallback to cached/manual/default
- `deniedForever`: Direct user to manual entry, no system dialog
- `restricted`: Treat as denied, fallback chain continues

### Scotland Centroid Default
**Chosen**: Fixed coordinate constant (55.8642, -4.2518) - Glasgow area
**Rationale**:
- Represents geographic center of Scotland for reasonable wildfire context
- Provides meaningful default when no other location available
- Simple constant, no computation required
- Covers major population centers for risk assessment relevance

**Alternatives Considered**:
- Edinburgh: More eastern, less central
- Dynamic centroid calculation: Unnecessary complexity
- User's last known general area: Privacy concerns, complexity

### Validation Strategy
**Chosen**: Input clamping + validation with user feedback
**Rationale**:
- Clamp latitude to [-90, 90], longitude to [-180, 180]
- Show helper text for invalid ranges
- Parse failure → show error message, don't crash
- Prevent bad data entry rather than silent correction

**Validation Rules**:
- Latitude: -90.0 ≤ lat ≤ 90.0
- Longitude: -180.0 ≤ lon ≤ 180.0  
- Precision: Accept up to 6 decimal places
- Format: Accept decimal degrees only (no DMS)

## Implementation Patterns

### Service Interface
```dart
abstract class LocationResolver {
  Future<Either<LocationError, LatLng>> getLatLon();
  Future<void> saveManual(LatLng location, {String? placeName});
  Future<Option<ManualLocation>> getManualLocation();
}
```

### Error Types
```dart
enum LocationErrorType {
  permissionDenied,
  gpsUnavailable,
  timeout,
  invalidInput,
  persistenceFailure
}
```

### Fallback Chain Logic
1. **GPS Attempt**: Check permissions → request if needed → get location with 2s timeout
2. **Cached Fallback**: Load last manual location from SharedPreferences  
3. **Manual Entry**: Show simple dialog for coordinate input
4. **Default Fallback**: Return Scotland centroid constant

### Testing Strategy
- **Unit Tests**: Mock geolocator, SharedPreferences, test all fallback paths
- **Widget Tests**: Dialog validation, accessibility targets
- **Integration Tests**: Permission flow scenarios, persistence across app restarts
- **Golden Tests**: Dialog UI consistency

## Technical Constraints
- No background location tracking (battery, privacy)
- No complex geocoding UI (keep dialog simple)
- 2-second GPS timeout (don't block UI)
- Coordinate precision limited to 2-3 decimals in logs (privacy)
- Works offline (no network dependencies in fallback chain)