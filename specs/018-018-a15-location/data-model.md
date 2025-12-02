# Data Model: 018-A15 Location Picker & what3words Integration

**Branch**: `018-018-a15-location` | **Date**: 2025-11-27

---

## Entity Definitions

### 1. PickedLocation (Return Value)

**Purpose**: Typed result returned from LocationPickerScreen via Navigator.pop

```dart
/// Result from location picker screen
/// 
/// Returned via Navigator.pop<PickedLocation> to calling screen.
/// Used by HomeScreen to update risk location, and ReportFireScreen
/// for clipboard copy of what3words address.
class PickedLocation extends Equatable {
  /// Selected coordinates (validated)
  final LatLng coordinates;
  
  /// what3words address (null if API unavailable)
  final String? what3words;
  
  /// Human-readable place name from search or reverse geocode
  final String? placeName;
  
  /// Timestamp when location was selected
  final DateTime selectedAt;

  const PickedLocation({
    required this.coordinates,
    this.what3words,
    this.placeName,
    required this.selectedAt,
  });

  @override
  List<Object?> get props => [coordinates, what3words, placeName, selectedAt];
}
```

**Validation Rules**:
- `coordinates.isValid` must be true (uses existing LatLng validation)
- `what3words` format: three lowercase words separated by dots (if present)
- `selectedAt` must not be in future

---

### 2. What3wordsAddress (Value Object)

**Purpose**: Validated what3words address with formatting utilities

```dart
/// Validated what3words address
///
/// Ensures format compliance and provides display formatting.
/// Three words separated by dots, lowercase, no special chars.
class What3wordsAddress extends Equatable {
  /// Raw words without prefix (e.g., "slurs.this.name")
  final String words;

  const What3wordsAddress._(this.words);

  /// Creates validated address, returns null if invalid
  static What3wordsAddress? tryParse(String input) {
    final cleaned = input.replaceAll(RegExp(r'^/{1,3}'), '').trim().toLowerCase();
    if (!_isValidFormat(cleaned)) return null;
    return What3wordsAddress._(cleaned);
  }

  /// Validates what3words format
  static bool _isValidFormat(String input) {
    final parts = input.split('.');
    if (parts.length != 3) return false;
    // Each word: 1-20 lowercase letters
    final wordPattern = RegExp(r'^[a-z]{1,20}$');
    return parts.every((p) => wordPattern.hasMatch(p));
  }

  /// Display format with triple-slash prefix (///word.word.word)
  String get displayFormat => '///$words';

  /// Short format for copying (word.word.word)
  String get copyFormat => words;

  @override
  List<Object> get props => [words];

  @override
  String toString() => displayFormat;
}
```

**Validation Rules**:
- Exactly 3 words separated by dots
- Each word: 1-20 lowercase letters only
- No numbers, hyphens, or special characters

---

### 3. What3wordsError (Sealed Error Type)

**Purpose**: Typed errors for what3words service operations

```dart
/// Error types for what3words service operations
sealed class What3wordsError {
  const What3wordsError();
  
  /// Human-readable error message for UI display
  String get userMessage;
}

/// API returned error response (invalid address, rate limit, etc.)
class What3wordsApiError extends What3wordsError {
  final String code;
  final String message;
  final int? statusCode;

  const What3wordsApiError({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String get userMessage => switch (code) {
    'InvalidKey' => 'what3words service unavailable',
    'InvalidInput' => 'Invalid what3words address',
    'QuotaExceeded' => 'what3words limit reached',
    _ => 'what3words error: $message',
  };
}

/// Network/connectivity error
class What3wordsNetworkError extends What3wordsError {
  final String? details;
  const What3wordsNetworkError([this.details]);
  
  @override
  String get userMessage => 'Unable to reach what3words service';
}

/// Invalid address format (client-side validation)
class What3wordsInvalidAddressError extends What3wordsError {
  final String input;
  const What3wordsInvalidAddressError(this.input);
  
  @override
  String get userMessage => 'Invalid what3words format';
}
```

---

### 4. LocationPickerState (Controller State)

**Purpose**: State machine for LocationPickerController

```dart
/// State for location picker screen
sealed class LocationPickerState extends Equatable {
  const LocationPickerState();
}

/// Initial state while map is loading
class LocationPickerInitial extends LocationPickerState {
  const LocationPickerInitial();
  
  @override
  List<Object?> get props => [];
}

/// Ready state with selected location
class LocationPickerReady extends LocationPickerState {
  /// Currently selected location (crosshair position)
  final LatLng selectedLocation;
  
  /// what3words address for selected location
  final What3wordsAddress? what3words;
  
  /// Loading state for what3words fetch
  final bool isLoadingWhat3words;
  
  /// Error message (if any)
  final String? errorMessage;
  
  /// Current search query
  final String? searchQuery;
  
  /// Search suggestions
  final List<PlaceSearchResult>? suggestions;
  
  /// Whether GPS is available
  final bool isGpsAvailable;

  const LocationPickerReady({
    required this.selectedLocation,
    this.what3words,
    this.isLoadingWhat3words = false,
    this.errorMessage,
    this.searchQuery,
    this.suggestions,
    this.isGpsAvailable = false,
  });

  /// Creates copy with updated fields
  LocationPickerReady copyWith({
    LatLng? selectedLocation,
    What3wordsAddress? Function()? what3words,
    bool? isLoadingWhat3words,
    String? Function()? errorMessage,
    String? Function()? searchQuery,
    List<PlaceSearchResult>? Function()? suggestions,
    bool? isGpsAvailable,
  }) {
    return LocationPickerReady(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      what3words: what3words != null ? what3words() : this.what3words,
      isLoadingWhat3words: isLoadingWhat3words ?? this.isLoadingWhat3words,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
      suggestions: suggestions != null ? suggestions() : this.suggestions,
      isGpsAvailable: isGpsAvailable ?? this.isGpsAvailable,
    );
  }

  @override
  List<Object?> get props => [
    selectedLocation,
    what3words,
    isLoadingWhat3words,
    errorMessage,
    searchQuery,
    suggestions,
    isGpsAvailable,
  ];
}
```

---

### 5. PlaceSearchResult (Search Autocomplete)

**Purpose**: Result from place autocomplete search

```dart
/// Search result from Google Places autocomplete
class PlaceSearchResult extends Equatable {
  /// Unique identifier for the place
  final String placeId;
  
  /// Primary text (place name)
  final String primaryText;
  
  /// Secondary text (address/context)
  final String? secondaryText;
  
  /// Cached coordinates (null until fetched via Place Details)
  final LatLng? coordinates;

  const PlaceSearchResult({
    required this.placeId,
    required this.primaryText,
    this.secondaryText,
    this.coordinates,
  });

  /// Full display text
  String get displayText => secondaryText != null 
    ? '$primaryText, $secondaryText' 
    : primaryText;

  @override
  List<Object?> get props => [placeId, primaryText, secondaryText, coordinates];
}
```

---

### 6. LocationPickerMode (Entry Context)

**Purpose**: Distinguish picker behavior based on entry point

```dart
/// Mode for location picker behavior
enum LocationPickerMode {
  /// Picking location for fire risk assessment (HomeScreen)
  /// - Saves to LocationResolver on confirm
  /// - No emergency banner
  riskLocation,
  
  /// Picking location for fire report (ReportFireScreen)
  /// - Returns result without saving
  /// - Shows emergency reminder banner
  /// - what3words copy emphasized
  fireReport,
}
```

---

## Entity Relationships

```
┌──────────────────────────────────────────────────────────────────┐
│                      Location Picker Flow                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  LocationPickerMode.riskLocation        LocationPickerMode.fireReport
│         │                                        │                │
│         ▼                                        ▼                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              LocationPickerController                        │ │
│  │  ┌─────────────────────────────────────────────────────┐    │ │
│  │  │         LocationPickerState (sealed)                 │    │ │
│  │  │  - LocationPickerInitial                            │    │ │
│  │  │  - LocationPickerReady                              │    │ │
│  │  │      ├── selectedLocation: LatLng                   │    │ │
│  │  │      ├── what3words: What3wordsAddress?             │    │ │
│  │  │      └── suggestions: List<PlaceSearchResult>?      │    │ │
│  │  └─────────────────────────────────────────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│                              ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 PickedLocation (result)                      │ │
│  │  - coordinates: LatLng                                       │ │
│  │  - what3words: String?                                       │ │
│  │  - placeName: String?                                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│              ┌───────────────┴───────────────┐                   │
│              ▼                               ▼                    │
│   riskLocation mode:              fireReport mode:                │
│   LocationResolver.saveManual()   Navigator.pop(PickedLocation)   │
│   then Navigator.pop()            (for clipboard copy)            │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Service Interfaces

### What3wordsService

```dart
/// what3words coordinate conversion service
///
/// C2 Compliance: Coordinates logged with 2-decimal redaction.
/// Never log what3words addresses (can identify precise locations).
abstract class What3wordsService {
  /// Convert what3words address to coordinates
  /// 
  /// Returns Left(What3wordsError) on:
  /// - Invalid address format
  /// - API error (invalid key, rate limit)
  /// - Network error
  Future<Either<What3wordsError, LatLng>> convertToCoordinates(String words);
  
  /// Convert coordinates to what3words address
  ///
  /// Returns Left(What3wordsError) on:
  /// - API error
  /// - Network error
  Future<Either<What3wordsError, What3wordsAddress>> convertToWords({
    required double lat,
    required double lon,
  });
}
```

### PlacesService (Optional - may use direct HTTP)

```dart
/// Google Places search service
///
/// Provides autocomplete and place details for location search.
abstract class PlacesService {
  /// Search for places matching query
  ///
  /// [query] - Search text (place name, address, postcode)
  /// [sessionToken] - Unique token for billing (one per search session)
  /// [location] - Optional bias toward this location
  Future<Either<ApiError, List<PlaceSearchResult>>> autocomplete({
    required String query,
    required String sessionToken,
    LatLng? location,
  });
  
  /// Get coordinates for a place
  ///
  /// [placeId] - Place ID from autocomplete result
  /// [sessionToken] - Same token used in autocomplete (reduces billing)
  Future<Either<ApiError, LatLng>> getPlaceCoordinates({
    required String placeId,
    required String sessionToken,
  });
}
```

---

## State Transitions

```
┌─────────────────┐
│ LocationPicker- │
│    Initial      │◄──── Screen opens
└────────┬────────┘
         │ Map loaded + initial location resolved
         ▼
┌─────────────────┐
│ LocationPicker- │◄──── User pans map (camera move)
│     Ready       │◄──── User searches (suggestions)
└────────┬────────┘◄──── User selects suggestion (pan)
         │              ◄──── User taps "Use GPS" (pan)
         │
         │ Camera movement stops (onCameraIdle)
         ▼
┌─────────────────┐
│ LocationPicker- │     isLoadingWhat3words = true
│ Ready (loading) │     Fetch what3words for new position
└────────┬────────┘
         │ what3words response
         ▼
┌─────────────────┐
│ LocationPicker- │     what3words populated (or error)
│ Ready (final)   │     isLoadingWhat3words = false
└────────┬────────┘
         │ User taps "Confirm"
         ▼
    Navigator.pop(PickedLocation)
```

---

*Data model complete. Ready for contracts definition.*
