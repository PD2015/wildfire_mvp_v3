# Data Model: LocationResolver

## Core Entities

### LatLng
**Purpose**: Geographic coordinate pair for location representation
**Fields**:
- `latitude`: double [-90.0, 90.0] - North/South position  
- `longitude`: double [-180.0, 180.0] - East/West position

**Validation Rules**:
- Latitude must be within [-90, 90] range
- Longitude must be within [-180, 180] range
- Both values must be finite (no NaN, Infinity)
- Precision limited to 6 decimal places for storage

**Factory Constructors**:
- `LatLng(double latitude, double longitude)` - Basic constructor with validation
- `LatLng.fromJson(Map<String, dynamic> json)` - Deserialization from SharedPreferences
- `LatLng.tryParse(String latStr, String lonStr)` - Safe parsing from user input

**Methods**:
- `toJson()`: Serialization for SharedPreferences storage
- `toString()`: Human-readable coordinate display
- `equals()` and `hashCode()`: Value object equality

### LocationError
**Purpose**: Represents different failure modes in location resolution
**Fields**:
- `type`: LocationErrorType enum - Specific error category
- `message`: String - Human-readable error description
- `originalException`: Exception? - Underlying platform exception if available

**Error Types** (LocationErrorType enum):
- `permissionDenied`: User denied GPS permissions
- `gpsUnavailable`: GPS hardware/service unavailable  
- `timeout`: GPS request exceeded timeout limit
- `invalidInput`: Manual coordinate input validation failed
- `persistenceFailure`: SharedPreferences read/write failed
- `geocodingFailure`: Optional place name lookup failed

**Factory Constructors**:
- `LocationError.permissionDenied()` - Standard permission denial
- `LocationError.timeout()` - GPS timeout after 2 seconds
- `LocationError.invalidInput(String reason)` - Validation failure with specific reason
- `LocationError.persistence(Exception cause)` - Storage operation failed

### ManualLocation
**Purpose**: User-entered location data with persistence metadata
**Fields**:
- `coordinates`: LatLng - The actual coordinate pair
- `placeName`: String? - Optional place name if entered via search
- `timestamp`: DateTime - When location was manually entered
- `source`: ManualLocationSource enum - How location was entered

**Source Types** (ManualLocationSource enum):
- `coordinateEntry`: Direct lat/lon input by user
- `placeSearch`: Derived from place name search (first result)

**Factory Constructors**:
- `ManualLocation.fromCoordinates(LatLng coords)` - Direct coordinate entry
- `ManualLocation.fromPlace(LatLng coords, String placeName)` - Place search result
- `ManualLocation.fromJson(Map<String, dynamic> json)` - SharedPreferences deserialization

**Methods**:
- `toJson()`: Serialization for persistence
- `isExpired(Duration maxAge)`: Check if manual location is stale
- `equals()` and `hashCode()`: Value object equality

### LocationStrategy
**Purpose**: Encapsulates the fallback chain logic and configuration
**Fields**:
- `gpsTimeout`: Duration - Maximum time to wait for GPS (default 2s)
- `enableManualEntry`: bool - Whether to show manual entry dialog
- `defaultLocation`: LatLng - Scotland centroid fallback
- `requirePermissionRequest`: bool - Whether to request permissions if denied

**Constants**:
- `scotlandCentroid`: LatLng(55.8642, -4.2518) - Default fallback location
- `defaultGpsTimeout`: Duration(seconds: 2) - Standard GPS timeout
- `coordinateValidationRegex`: RegExp for parsing decimal degrees

**Methods**:
- `shouldRequestPermissions()`: Determine if permission request is appropriate
- `getNextFallback(CurrentStage stage)`: Chain progression logic
- `validateCoordinateInput(String input)`: Input validation for manual entry

## State Transitions

### Location Resolution Flow
```
Start → Check Permissions
├─ Granted → GPS Request (2s timeout)
│  ├─ Success → Return LatLng
│  └─ Timeout/Failure → Check Manual Cache
├─ Denied → Check Manual Cache
└─ DeniedForever → Check Manual Cache

Check Manual Cache
├─ Found → Return Cached LatLng  
└─ Not Found → Manual Entry Dialog
   ├─ User Enters → Validate → Save → Return LatLng
   └─ User Cancels → Return Scotland Centroid
```

### Manual Entry Validation
```
User Input → Parse Coordinates
├─ Valid Format → Range Check
│  ├─ In Range → Create LatLng → Save → Success
│  └─ Out of Range → Show Error → Retry
└─ Invalid Format → Show Error → Retry
```

## Persistence Schema

### SharedPreferences Keys
- `manual_location_lat`: double - Stored latitude
- `manual_location_lon`: double - Stored longitude  
- `manual_location_place`: String? - Optional place name
- `manual_location_timestamp`: int - Epoch milliseconds
- `manual_location_source`: String - Source type enum value

### JSON Serialization Format
```json
{
  "coordinates": {
    "latitude": 55.9533,
    "longitude": -3.1883
  },
  "placeName": "Edinburgh",
  "timestamp": 1696291200000,
  "source": "placeSearch"
}
```

## Validation Constraints

### Coordinate Validation
- **Latitude Range**: -90.0 ≤ lat ≤ 90.0
- **Longitude Range**: -180.0 ≤ lon ≤ 180.0
- **Precision**: Maximum 6 decimal places (≈0.1 meter accuracy)
- **Format**: Decimal degrees only, no DMS (degrees/minutes/seconds)

### Input Sanitization
- Trim whitespace from user input
- Accept common separators: comma, space, tab
- Reject obviously invalid patterns: letters in coordinates
- Clamp values to valid ranges rather than rejection where reasonable

### Privacy Constraints
- Log coordinates at maximum 2-3 decimal places (≈100m precision)
- No automatic location sharing or transmission
- Manual locations stored locally only (SharedPreferences)
- No background location tracking or persistence

## Dependencies and Relationships

### Service Dependencies
- **LocationResolver** uses **LatLng** for coordinate representation
- **LocationResolver** returns **LocationError** for failure cases
- **LocationResolver** persists **ManualLocation** via SharedPreferences
- **LocationResolver** follows **LocationStrategy** for fallback logic

### UI Dependencies  
- **ManualLocationDialog** accepts current **LatLng** as default
- **ManualLocationDialog** validates input against **LocationStrategy** rules
- **ManualLocationDialog** returns **LatLng** on success or **LocationError** on failure

### Integration Points
- **FireRiskService** consumes **LatLng** from **LocationResolver.getLatLon()**
- **RiskBanner** may display location source information (GPS/Manual/Default)
- **HomeScreen** triggers location resolution on app startup and manual refresh