# LocationResolver Service Contract

## Core Service Interface

```dart
abstract class LocationResolver {
  /// Primary method to get current location with fallback strategy
  /// Returns Either<LocationError, LatLng> following A1-A3 pattern
  /// Executes: GPS → cached → manual → default fallback chain
  Future<Either<LocationError, LatLng>> getLatLon();
  
  /// Save manually entered location for persistence across app restarts
  /// Used when user enters coordinates via dialog or place search
  Future<void> saveManual(LatLng location, {String? placeName});
  
  /// Retrieve last manually entered location from local storage
  /// Returns Option<ManualLocation> - Some if exists, None if not found
  Future<Option<ManualLocation>> getManualLocation();
  
  /// Clear any cached manual location (for testing or user reset)
  Future<void> clearManualLocation();
}
```

## Data Transfer Objects

### LatLng Contract
```dart
class LatLng extends Equatable {
  final double latitude;   // Range: [-90.0, 90.0]
  final double longitude;  // Range: [-180.0, 180.0]
  
  const LatLng(this.latitude, this.longitude);
  
  // Factory constructors
  factory LatLng.fromJson(Map<String, dynamic> json);
  factory LatLng.tryParse(String latStr, String lonStr);
  
  // Serialization
  Map<String, dynamic> toJson();
  
  // Validation
  bool get isValid;
  static bool isValidLatitude(double lat);
  static bool isValidLongitude(double lon);
  
  @override
  List<Object?> get props => [latitude, longitude];
}
```

### LocationError Contract
```dart
class LocationError extends Equatable {
  final LocationErrorType type;
  final String message;
  final Exception? originalException;
  
  const LocationError({
    required this.type,
    required this.message,
    this.originalException,
  });
  
  // Factory constructors for common error types
  factory LocationError.permissionDenied();
  factory LocationError.gpsUnavailable();
  factory LocationError.timeout();
  factory LocationError.invalidInput(String reason);
  factory LocationError.persistenceFailure(Exception cause);
  
  @override
  List<Object?> get props => [type, message, originalException];
}

enum LocationErrorType {
  permissionDenied,
  gpsUnavailable,
  timeout,
  invalidInput,
  persistenceFailure,
  geocodingFailure,
}
```

### ManualLocation Contract
```dart
class ManualLocation extends Equatable {
  final LatLng coordinates;
  final String? placeName;
  final DateTime timestamp;
  final ManualLocationSource source;
  
  const ManualLocation({
    required this.coordinates,
    this.placeName,
    required this.timestamp,
    required this.source,
  });
  
  // Factory constructors
  factory ManualLocation.fromCoordinates(LatLng coords);
  factory ManualLocation.fromPlace(LatLng coords, String placeName);
  factory ManualLocation.fromJson(Map<String, dynamic> json);
  
  // Serialization
  Map<String, dynamic> toJson();
  
  // Utility methods
  bool isExpired(Duration maxAge);
  
  @override
  List<Object?> get props => [coordinates, placeName, timestamp, source];
}

enum ManualLocationSource {
  coordinateEntry,  // Direct lat/lon input
  placeSearch,      // From place name lookup
}
```

## Service Implementation Contract

### LocationResolverImpl Requirements
```dart
class LocationResolverImpl implements LocationResolver {
  // Dependencies (constructor injection)
  final Geolocator geolocator;
  final SharedPreferences preferences;
  final Geocoding? geocoding;  // Optional for place search
  final LocationStrategy strategy;
  
  // Configuration constants
  static const Duration _gpsTimeout = Duration(seconds: 2);
  static const String _prefKeyLat = 'manual_location_lat';
  static const String _prefKeyLon = 'manual_location_lon';
  static const String _prefKeyPlace = 'manual_location_place';
  static const String _prefKeyTimestamp = 'manual_location_timestamp';
  static const String _prefKeySource = 'manual_location_source';
  
  // Scotland centroid fallback
  static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);
}
```

### Fallback Chain Contract
The implementation MUST follow this exact sequence:

1. **GPS Attempt**
   - Check location permissions
   - If denied/restricted: Skip to step 2
   - If granted: Request location with 2s timeout
   - On success: Return LatLng
   - On failure/timeout: Continue to step 2

2. **Manual Cache Check**
   - Query SharedPreferences for saved location
   - If found and valid: Return cached LatLng
   - If not found or invalid: Continue to step 3

3. **Manual Entry Dialog**
   - Show simple coordinate entry dialog
   - Accept lat/lon input or place name search
   - Validate input ranges and format
   - On success: Save to cache and return LatLng
   - On cancel: Continue to step 4

4. **Default Fallback**
   - Return Scotland centroid constant
   - Never fails - always returns valid LatLng

## Permission Handling Contract

### Permission States and Responses
```dart
enum LocationPermissionResponse {
  granted,        // Use GPS immediately
  denied,         // Skip to manual cache/entry
  deniedForever,  // Skip to manual cache/entry, no system dialog
  restricted,     // Skip to manual cache/entry (iOS parental controls)
}
```

### Permission Flow Requirements
- MUST NOT block app startup for permission requests
- MUST handle permission changes during app session
- MUST NOT show multiple permission dialogs in sequence
- MUST gracefully handle `deniedForever` state without system dialogs

## Dialog UI Contract

### ManualLocationDialog Interface
```dart
class ManualLocationDialog extends StatefulWidget {
  final LatLng? initialLocation;
  final bool enablePlaceSearch;
  
  const ManualLocationDialog({
    super.key,
    this.initialLocation,
    this.enablePlaceSearch = false,
  });
}

// Dialog result contract
sealed class ManualLocationResult {}
class ManualLocationSuccess extends ManualLocationResult {
  final LatLng location;
  final String? placeName;
}
class ManualLocationCancelled extends ManualLocationResult {}
class ManualLocationError extends ManualLocationResult {
  final String message;
}
```

### Dialog Requirements
- MUST validate coordinate input in real-time
- MUST clamp invalid values to valid ranges where possible
- MUST provide clear error messages for invalid input
- MUST meet ≥44dp touch target requirements (C3)
- MUST include semantic labels for accessibility (C3)
- MUST support both coordinate entry and optional place search

## Persistence Contract

### SharedPreferences Storage Schema
```dart
class LocationPersistence {
  static const String prefKeyLat = 'manual_location_lat';
  static const String prefKeyLon = 'manual_location_lon';
  static const String prefKeyPlace = 'manual_location_place';
  static const String prefKeyTimestamp = 'manual_location_timestamp';
  static const String prefKeySource = 'manual_location_source';
  
  // Storage operations
  Future<void> saveLocation(ManualLocation location);
  Future<Option<ManualLocation>> loadLocation();
  Future<void> clearLocation();
}
```

### Persistence Requirements
- MUST store coordinates as separate double values (not JSON blob)
- MUST handle SharedPreferences initialization failure gracefully
- MUST validate loaded data before returning (corruption resilience)
- MUST support partial data recovery (coordinates without place name)

## Integration Contracts

### FireRiskService Integration
```dart
// FireRiskService will call:
final locationResult = await locationResolver.getLatLon();
locationResult.fold(
  (error) => handleLocationError(error),
  (latLng) => proceedWithRiskAssessment(latLng),
);
```

### UI Integration Points
```dart
// Home screen integration
class HomeScreen extends StatefulWidget {
  final LocationResolver locationResolver;
  
  // Trigger location resolution on startup
  void initializeLocation() async {
    final result = await locationResolver.getLatLon();
    // Handle result...
  }
  
  // Manual location entry trigger
  void showLocationEntry() async {
    final result = await showDialog<ManualLocationResult>(
      context: context,
      builder: (context) => ManualLocationDialog(),
    );
    // Handle dialog result...
  }
}
```

## Error Handling Contract

### Error Categories and Required Responses
- **permissionDenied**: Continue to manual cache, no user-visible error
- **gpsUnavailable**: Continue to manual cache, no user-visible error  
- **timeout**: Continue to manual cache, no user-visible error
- **invalidInput**: Show validation error in dialog, allow retry
- **persistenceFailure**: Log error, continue to default fallback
- **geocodingFailure**: Show error message, fall back to coordinate entry

### Error Logging Requirements (C2 Compliance)
```dart
// CORRECT: Privacy-compliant coordinate logging
logger.info('Location resolved to ${latLng.latitude.toStringAsFixed(2)},${latLng.longitude.toStringAsFixed(2)}');

// WRONG: Precise coordinates violate privacy
logger.info('Location resolved to $latLng'); // Too precise, violates C2
```

## Testing Contracts

### Required Unit Tests
- All fallback chain scenarios (GPS success/failure → cache hit/miss → manual success/cancel → default)
- Permission state handling (granted/denied/deniedForever/restricted)
- Coordinate validation (in-range, out-of-range, invalid format)
- Persistence operations (save/load/clear/corruption handling)
- Error case handling (all LocationErrorType values)

### Required Widget Tests
- Dialog coordinate input validation
- Dialog accessibility compliance (≥44dp targets, semantic labels)
- Dialog error state display and recovery

### Required Integration Tests
- End-to-end permission flows
- Persistence across app restarts
- Location resolution performance (under timeout limits)