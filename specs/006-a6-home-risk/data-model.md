# Data Model: A6 — Home (Risk Feed Container & Screen)

**Feature**: Home screen state and data management  
**Date**: 2025-10-04  
**Phase**: 1 (Design & Contracts)

## Core Entities

### HomeState
**Purpose**: Represents the current state of the home screen including loading, success, and error conditions.

**Type**: Sealed class hierarchy for exhaustive state handling

#### HomeStateLoading
```dart
class HomeStateLoading extends HomeState {
  final bool isRetry;  // true if this is a retry attempt
  final DateTime startTime;  // for progress indication
}
```

**Fields**:
- `isRetry`: Boolean indicating if this loading state is from a retry action
- `startTime`: Timestamp when loading started for progress calculation

**Usage**: Displayed when initially loading risk data or during retry operations

#### HomeStateSuccess  
```dart
class HomeStateSuccess extends HomeState {
  final FireRisk riskData;
  final LocationInfo location;
  final DateTime lastUpdated;
  final DataSource source;
}
```

**Fields**:
- `riskData`: Current fire risk information from FireRiskService
- `location`: Location data (GPS, cached, or manual) from LocationResolver  
- `lastUpdated`: Timestamp when risk data was fetched
- `source`: Indicator of data source (live/cached/mock) for transparency

**Usage**: Successfully loaded state with all required display information

#### HomeStateError
```dart
class HomeStateError extends HomeState {
  final String errorMessage;
  final FireRisk? cachedData;  // optional cached data to display
  final LocationInfo? location;
  final DateTime? lastUpdated;
  final bool canRetry;
}
```

**Fields**:
- `errorMessage`: User-friendly error description
- `cachedData`: Optional cached risk data to display alongside error
- `location`: Last known location information
- `lastUpdated`: Timestamp of cached data (if available)
- `canRetry`: Boolean indicating if retry is possible

**Usage**: Error state with optional cached data fallback and retry capability

**State Transitions**:
```
Initial → HomeStateLoading
HomeStateLoading → HomeStateSuccess (data loaded)
HomeStateLoading → HomeStateError (load failed)
HomeStateError → HomeStateLoading (retry triggered)
HomeStateSuccess → HomeStateLoading (manual refresh)
```

### HomeActionData
**Purpose**: Encapsulates data for user-initiated actions (retry, manual location)

```dart
class HomeActionData {
  final ActionType type;
  final LatLng? coordinates;  // for manual location
  final String? placeName;    // optional place name
}

enum ActionType { retry, manualLocation, refresh }
```

**Fields**:
- `type`: Type of action being performed  
- `coordinates`: Coordinates for manual location entry
- `placeName`: Optional descriptive name for manual location

**Usage**: Passed to HomeController for user-initiated actions

## Integration Models

### LocationDisplayInfo
**Purpose**: Formatted location information for UI display

```dart
class LocationDisplayInfo {
  final String displayText;      // "Edinburgh, Scotland" or "55.95, -3.19"
  final LatLng coordinates;
  final LocationSource source;   // gps, cached, manual, default
  final bool isDefault;         // true if using Scotland centroid
}

enum LocationSource { gps, cached, manual, default }
```

**Fields**:
- `displayText`: Human-readable location description
- `coordinates`: Actual coordinates used for risk calculation
- `source`: How this location was determined
- `isDefault`: Flag for default Scotland centroid usage

### RiskDisplayInfo  
**Purpose**: Formatted risk information for UI display with constitutional compliance

```dart
class RiskDisplayInfo {
  final RiskLevel level;        // low, moderate, high, extreme
  final Color primaryColor;     // official Scottish risk colors
  final Color backgroundColor;  // complementary background
  final String displayText;     // "Moderate Risk"
  final String description;     // risk level description
  final bool requiresBadge;     // true if cached/mock data
}
```

**Fields**:
- `level`: Risk enumeration value
- `primaryColor`: Official Scottish wildfire risk color (C4 compliance)
- `backgroundColor`: Accessible background color
- `displayText`: Localized risk level text
- `description`: Detailed risk description
- `requiresBadge`: Flag for cached/mock data badge display

### TimestampDisplayInfo
**Purpose**: Formatted timestamp information with relative time

```dart
class TimestampDisplayInfo {
  final DateTime timestamp;
  final String relativeText;    // "Updated 5 minutes ago"
  final String absoluteText;    // "10:30 AM, Oct 4"
  final bool isStale;          // true if >6 hours old
  final Color textColor;       // based on staleness
}
```

**Fields**:
- `timestamp`: Original timestamp from data source
- `relativeText`: Human-readable relative time
- `absoluteText`: Precise timestamp for accessibility
- `isStale`: Flag for aged data (cache TTL consideration)
- `textColor`: UI color based on data freshness

## Validation Rules

### HomeState Validation
- HomeStateSuccess MUST have non-null riskData, location, lastUpdated, and source
- HomeStateError MUST have non-empty errorMessage
- HomeStateError with cachedData MUST have lastUpdated timestamp
- HomeStateLoading MUST have valid startTime

### Location Validation  
- Manual coordinates MUST be valid lat/lon (-90≤lat≤90, -180≤lon≤180)
- LocationDisplayInfo MUST have non-empty displayText
- Default location fallback MUST use Scotland centroid (55.8642, -4.2518)

### Risk Display Validation
- RiskDisplayInfo colors MUST use official Scottish risk color constants
- All display text MUST be localized and accessibility-friendly
- Badge requirement MUST be set for cached/mock data sources

## State Management Patterns

### State Updates
```dart
// Loading state
_updateState(HomeStateLoading(isRetry: false, startTime: DateTime.now()));

// Success state  
_updateState(HomeStateSuccess(
  riskData: result.riskData,
  location: locationInfo,
  lastUpdated: DateTime.now(),
  source: result.source,
));

// Error with cached data
_updateState(HomeStateError(
  errorMessage: 'Failed to load current data',
  cachedData: cachedRisk,
  location: lastLocation,
  lastUpdated: cachedTimestamp,
  canRetry: true,
));
```

### Action Handling
```dart
// Retry action
void retry() {
  if (state is HomeStateError) {
    load(isRetry: true);
  }
}

// Manual location action
void setManualLocation(LatLng coordinates, [String? placeName]) {
  final actionData = HomeActionData(
    type: ActionType.manualLocation,
    coordinates: coordinates,
    placeName: placeName,
  );
  _handleLocationChange(actionData);
}
```

## Performance Considerations

### Memory Management
- HomeState objects are immutable and can be safely cached
- Previous state cleanup on updates to prevent memory leaks
- Dispose pattern for HomeController resources

### Update Optimization
- State equality checking to prevent unnecessary UI rebuilds
- Debounced retry attempts to prevent spam
- Efficient timestamp formatting with caching

---

**Constitutional Compliance**:
- **C3**: All interactive data includes semantic information
- **C4**: Official colors and timestamp/source transparency enforced
- **C5**: Error states explicit, no silent failures

**Status**: ✅ Data models defined with validation rules and state transitions  
**Next**: API contracts and component interfaces