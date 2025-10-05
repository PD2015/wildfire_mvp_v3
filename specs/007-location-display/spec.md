# Feature Specification: A7 — Location Display (Coordinates & Place Names)

**Feature ID**: A7  
**Status**: 📋 **PLANNED** (Not Started)  
**Priority**: Medium  
**Estimated Effort**: 2-3 hours  
**Dependencies**: A4 (LocationResolver), A6 (HomeScreen)  
**Created**: 2025-10-05  

## Overview

Add coordinate and place name display to the home screen to provide users with transparency about which location the fire risk assessment applies to. This enhances trust and enables users to verify location accuracy.

**User Story**: *"As a wildfire app user, I want to see the exact coordinates and place name being used for my fire risk assessment so I can verify the location is correct and understand the geographic context."*

## Current State Analysis

### ✅ **Existing Infrastructure**
- **Location Data**: `HomeStateSuccess` contains `LatLng location` 
- **Place Name Support**: `LocationCache.loadPlaceName()` and `LocationResolver.saveManual()` already support place names
- **Privacy Utilities**: `LocationUtils.logRedact()` for privacy-compliant coordinate display
- **Display Framework**: Home screen has existing timestamp and source info sections in `_buildStateInfo()`

### 🔄 **Integration Points**
- `HomeController` manages location and risk data loading
- `HomeScreen` displays risk information with transparency elements
- `LocationCache` persists manual location names
- `LocationResolver` handles location acquisition with optional place names

## Requirements

### Functional Requirements

- **FR-001**: System MUST display current coordinates used for fire risk assessment
- **FR-002**: System MUST show place name when available from cache or manual entry
- **FR-003**: System MUST use privacy-compliant coordinate display (2 decimal precision)
- **FR-004**: System MUST handle missing place names gracefully (coordinates only)
- **FR-005**: System MUST display location info for both success and error states with cached data
- **FR-006**: System MUST provide semantic labels for accessibility compliance

### Non-Functional Requirements

- **NFR-001**: Location display MUST load within 100ms (from cached data)
- **NFR-002**: Widget MUST comply with C3 accessibility guidelines (≥44dp touch targets, semantic labels)
- **NFR-003**: Coordinate display MUST comply with C2 privacy guidelines (redacted precision)
- **NFR-004**: Implementation MUST maintain C1 clean architecture principles

## Technical Design

### Architecture Overview

```
HomeController → LocationCache.loadPlaceName() → LocationInfo Widget → HomeScreen
       ↓                    ↓                         ↓              ↓
   LatLng data       Place name (optional)    Coordinate display   User visibility
```

### Data Flow

1. **HomeController.load()** gets location via LocationResolver
2. **HomeController.getCachedPlaceName()** loads place name from LocationCache
3. **HomeStateSuccess** includes both location and placeName fields
4. **HomeScreen._buildStateInfo()** renders LocationInfo widget
5. **LocationInfo** displays coordinates (privacy-redacted) and place name (if available)

### Key Components

#### **1. Enhanced HomeState Model**
```dart
class HomeStateSuccess extends HomeState {
  final FireRisk riskData;
  final LatLng location;
  final DateTime lastUpdated;
  final String? placeName; // NEW FIELD

  const HomeStateSuccess({
    required this.riskData,
    required this.location,
    required this.lastUpdated,
    this.placeName, // NEW OPTIONAL PARAMETER
  });
}

class HomeStateError extends HomeState {
  final String errorMessage;
  final FireRisk? cachedData;
  final LatLng? cachedLocation;
  final String? cachedPlaceName; // NEW FIELD
  final bool canRetry;
}
```

#### **2. LocationInfo Widget**
```dart
class LocationInfo extends StatelessWidget {
  final LatLng coordinates;
  final String? placeName;
  final bool isPrivacyMode; // For coordinate redaction

  @override
  Widget build(BuildContext context) {
    final displayCoords = isPrivacyMode 
        ? LocationUtils.logRedact(coordinates.latitude, coordinates.longitude)
        : '${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place name (if available)
            if (placeName != null) ...[
              Row(
                children: [
                  Icon(Icons.place, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      placeName!,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
            ],
            
            // Coordinates
            Row(
              children: [
                Icon(Icons.my_location, size: 16),
                SizedBox(width: 8),
                Semantics(
                  label: 'Location coordinates: $displayCoords',
                  child: Text(
                    displayCoords,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### **3. HomeController Enhancement**
```dart
class HomeController extends ChangeNotifier {
  // Add method to load cached place name
  Future<String?> getCachedPlaceName() async {
    final cache = LocationCache();
    return await cache.loadPlaceName();
  }

  // Modify _loadData() to include place name loading
  Future<void> _loadData({bool isRetry = false}) async {
    // ... existing location and risk loading ...
    
    // Load cached place name if available
    final placeName = await getCachedPlaceName();
    
    // Pass place name to success state
    _updateState(HomeStateSuccess(
      riskData: riskResult.right,
      location: locationResult.right,
      lastUpdated: DateTime.now().toUtc(),
      placeName: placeName, // NEW FIELD
    ));
  }
}
```

## Implementation Plan

### **Phase 1: Basic Coordinate Display** (30 minutes)
1. **Update HomeState Model** (`lib/models/home_state.dart`)
   - Add `placeName` field to `HomeStateSuccess`
   - Add `cachedPlaceName` field to `HomeStateError`
   - Update constructors and props

2. **Create LocationInfo Widget** (`lib/widgets/location_info.dart`)
   - Stateless widget for coordinate display
   - Privacy-compliant coordinate formatting
   - Semantic labels for accessibility

3. **Update HomeScreen Display** (`lib/screens/home_screen.dart`)
   - Integrate LocationInfo in `_buildStateInfo()`
   - Handle both success and error states

4. **Basic Testing** (`test/widget/widgets/location_info_test.dart`)
   - Test coordinate display
   - Test privacy redaction
   - Test accessibility labels

### **Phase 2: Place Name Integration** (20 minutes)
1. **Update HomeController** (`lib/controllers/home_controller.dart`)
   - Add `getCachedPlaceName()` method
   - Update `_loadData()` to load place names
   - Handle place name loading errors

2. **Enhance LocationInfo Widget**
   - Display place name when available
   - Handle missing place names gracefully
   - Add place name semantic labels

3. **Extended Testing**
   - Test place name display
   - Test missing place name handling
   - Test state transitions

### **Phase 3: Enhanced Features** (Optional - 45 minutes)
1. **Geocoder Service** (`lib/services/geocoder_service.dart`)
   - Reverse geocoding for coordinates without cached names
   - Handle geocoding API errors
   - Offline fallback strategies

2. **Privacy Utilities** (`lib/utils/location_utils.dart`)
   - Place name privacy redaction
   - Remove house numbers and precise addresses
   - City/region level display only

3. **Comprehensive Testing**
   - Geocoding service unit tests
   - Privacy utility tests
   - Integration test scenarios

## User Experience

### **Before Implementation**
```
┌─────────────────────────────┐
│ Wildfire Risk               │
├─────────────────────────────┤
│ ███ HIGH RISK ███           │
│ Updated 2 minutes ago EFFIS │
├─────────────────────────────┤
│ [Retry] [Set Location]      │
└─────────────────────────────┘
```

### **After Implementation**
```
┌─────────────────────────────┐
│ Wildfire Risk               │
├─────────────────────────────┤
│ ███ HIGH RISK ███           │
│ Updated 2 minutes ago EFFIS │
├─────────────────────────────┤
│ 📍 Edinburgh, Scotland      │
│ 📍 55.95, -3.19            │
├─────────────────────────────┤
│ [Retry] [Set Location]      │
└─────────────────────────────┘
```

## Benefits

### **User Benefits**
- **Transparency**: Clear visibility of assessment location
- **Trust**: Users can verify location accuracy
- **Context**: Geographic understanding of risk area
- **Debug Aid**: Easy identification of location issues

### **Technical Benefits**
- **Debugging**: Developers can verify location service functionality
- **Compliance**: Enhanced C4 transparency requirements
- **Accessibility**: Screen reader friendly location information
- **Maintainability**: Clean separation of location display concerns

## Constitutional Compliance

- **C1 (Code Quality)**: Clean architecture with separate LocationInfo widget and clear dependencies
- **C2 (Privacy)**: Uses `LocationUtils.logRedact()` for coordinate privacy (2 decimal precision)
- **C3 (Accessibility)**: Semantic labels for coordinates and place names, proper touch targets
- **C4 (Transparency)**: Clear display of location used for risk assessment
- **C5 (Resilience)**: Graceful handling of missing place names and geocoding failures

## Testing Strategy

### **Unit Tests**
- LocationInfo widget rendering
- Coordinate privacy redaction
- Place name display logic
- HomeController place name loading

### **Widget Tests**
- LocationInfo integration in HomeScreen
- State transitions with location data
- Accessibility compliance testing

### **Integration Tests**
- End-to-end location display flow
- Manual location with place name entry
- Cached location with place name retrieval

## Risk Assessment

### **Low Risk**
- ✅ Existing infrastructure supports implementation
- ✅ Privacy utilities already implemented
- ✅ Clear integration points identified

### **Medium Risk**
- ⚠️ Geocoding service dependency (if implemented)
- ⚠️ Potential performance impact from place name loading

### **Mitigation Strategies**
- Use cached data for immediate display
- Make geocoding service optional
- Implement timeout handling for place name loading
- Graceful degradation when place names unavailable

## Future Enhancements

### **Phase 4: Advanced Features** (Future)
1. **Interactive Location Display**
   - Tap coordinates to copy to clipboard
   - Tap place name to open maps application

2. **Location History**
   - Show recent locations used
   - Quick selection from history

3. **Enhanced Geocoding**
   - Multiple geocoding providers
   - Offline place name database
   - User preference for place name detail level

## References

- **A4 LocationResolver**: Location acquisition and caching
- **A6 HomeScreen**: Main user interface integration
- **C2 Privacy Gate**: Coordinate display compliance
- **C3 Accessibility Gate**: Screen reader support
- **C4 Transparency Gate**: Data source attribution

---

**Implementation Notes**: This feature enhances user trust and debugging capabilities while maintaining privacy compliance. The modular design allows for incremental implementation and future enhancements.

**Next Steps**: When ready to implement, start with Phase 1 (Basic Coordinate Display) for immediate user benefit, then proceed with Phase 2 (Place Name Integration) for enhanced user experience.