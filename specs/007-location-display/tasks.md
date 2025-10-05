# Tasks: A7 — Location Display (Coordinates & Place Names)

**Feature ID**: A7  
**Status**: 📋 **PLANNED**  
**Total Effort**: ~2-3 hours  

## Execution Summary
Add coordinate and place name display to home screen for location transparency and user trust. Leverages existing location infrastructure with privacy-compliant coordinate display and optional place name integration.

**Key Constraints**:
- Use LocationUtils.logRedact() for privacy compliance (C2)
- Maintain accessibility with semantic labels (C3) 
- Graceful handling of missing place names
- Constitutional gates: C1 (clean architecture), C2 (privacy), C3 (accessibility), C4 (transparency)

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **Labels**: spec:A7, gate:C1, gate:C2, gate:C3, gate:C4

---

## Phase 1: Basic Coordinate Display (30 minutes)

**[T001] [P] Update HomeState Model** ⏸️  
- **File**: `lib/models/home_state.dart`
- **Purpose**: Add placeName fields to HomeStateSuccess and HomeStateError
- **Labels**: spec:A7, gate:C1
- **Requirements**:
  - Add `String? placeName` field to HomeStateSuccess
  - Add `String? cachedPlaceName` field to HomeStateError  
  - Update constructors with optional placeName parameters
  - Update props lists and toString methods
  - Maintain backward compatibility with existing code

**[T002] [P] Create LocationInfo Widget** ⏸️
- **File**: `lib/widgets/location_info.dart`
- **Purpose**: Reusable widget for displaying coordinates and place names
- **Labels**: spec:A7, gate:C2, gate:C3
- **Requirements**:
  - StatelessWidget accepting LatLng coordinates and optional placeName
  - Use LocationUtils.logRedact() for privacy-compliant coordinate display
  - Card-based UI with place and location icons
  - Semantic labels for accessibility: "Location coordinates: {coords}"
  - Handle missing place names gracefully (coordinates only)
  - Responsive layout supporting both portrait and landscape

**[T003] Update HomeScreen Display** ⏸️
- **File**: `lib/screens/home_screen.dart`  
- **Purpose**: Integrate LocationInfo widget in state display section
- **Labels**: spec:A7, gate:C3, gate:C4
- **Requirements**:
  - Add LocationInfo to _buildStateInfo() for HomeStateSuccess
  - Add LocationInfo to _buildStateInfo() for HomeStateError (when cachedLocation available)
  - Import LocationInfo widget
  - Maintain existing layout with proper spacing
  - Ensure 16dp spacing between elements
- **Dependencies**: T001 (HomeState changes), T002 (LocationInfo widget)

**[T004] [P] Basic Widget Testing** ⏸️
- **File**: `test/widget/widgets/location_info_test.dart`
- **Purpose**: Unit tests for LocationInfo widget rendering and behavior
- **Labels**: spec:A7, gate:C1, gate:C3
- **Requirements**:
  - Test coordinate display with privacy redaction (55.9533 → "55.95")
  - Test place name display when provided
  - Test coordinates-only display when no place name
  - Test semantic labels for accessibility
  - Test icon rendering (Icons.place, Icons.my_location)
  - Test responsive layout behavior

---

## Phase 2: Place Name Integration (20 minutes)

**[T005] Enhance HomeController** ⏸️
- **File**: `lib/controllers/home_controller.dart`
- **Purpose**: Add place name loading capability to data loading flow
- **Labels**: spec:A7, gate:C1, gate:C5
- **Requirements**:
  - Add getCachedPlaceName() method using LocationCache
  - Update _loadData() to load place names after location resolution
  - Pass placeName to HomeStateSuccess constructor
  - Handle place name loading errors gracefully (continue without place name)
  - Ensure no blocking on place name loading (parallel with risk data)
- **Dependencies**: T001 (HomeState model changes)

**[T006] Update LocationInfo Widget** ⏸️  
- **File**: `lib/widgets/location_info.dart`
- **Purpose**: Enhance display logic for place names and improve UX
- **Labels**: spec:A7, gate:C3, gate:C4
- **Requirements**:
  - Conditional place name display: show place icon + name when available
  - Improve visual hierarchy: place name with larger text, coordinates smaller
  - Add semantic labels for place names: "Place: {placeName}"
  - Handle long place names with proper text wrapping
  - Maintain consistent visual spacing between elements
- **Dependencies**: T002 (initial LocationInfo implementation)

**[T007] [P] Extended Testing** ⏸️
- **File**: `test/unit/controllers/home_controller_test.dart`, `test/widget/widgets/location_info_test.dart`
- **Purpose**: Test place name integration and state transitions
- **Labels**: spec:A7, gate:C1, gate:C5
- **Requirements**:
  - Test HomeController.getCachedPlaceName() method
  - Test _loadData() with and without cached place names
  - Test LocationInfo widget with place name variations
  - Test place name loading error scenarios
  - Test state transitions maintaining place name data
  - Mock LocationCache for deterministic testing

---

## Phase 3: Enhanced Features (Optional - 45 minutes)

**[T008] [P] Privacy Utilities Enhancement** ⏸️
- **File**: `lib/utils/location_utils.dart`
- **Purpose**: Add place name privacy redaction utilities
- **Labels**: spec:A7, gate:C2
- **Requirements**:
  - Add redactPlaceName() method to remove house numbers
  - Keep city/region level information only
  - Handle various place name formats (addresses, cities, regions)
  - Example: "123 Main Street, Edinburgh" → "Edinburgh"
  - Example: "Edinburgh, Scotland" → "Edinburgh, Scotland" (no change)

**[T009] [P] Geocoder Service (Optional)** ⏸️
- **File**: `lib/services/geocoder_service.dart`
- **Purpose**: Reverse geocoding for coordinates without cached place names
- **Labels**: spec:A7, gate:C1, gate:C5
- **Requirements**:
  - Abstract GeocoderService interface
  - GeocoderServiceImpl using HTTP geocoding API (Nominatim/OSM)
  - Timeout handling and error recovery
  - Fallback to coordinate display on geocoding failure
  - Rate limiting to prevent API abuse
  - Optional integration in HomeController (feature flag)

**[T010] [P] Comprehensive Testing** ⏸️
- **Files**: `test/unit/services/geocoder_service_test.dart`, `test/unit/utils/location_utils_test.dart`
- **Purpose**: Complete test coverage for enhanced features
- **Labels**: spec:A7, gate:C1, gate:C2
- **Requirements**:
  - Test GeocoderService HTTP requests and responses
  - Test privacy utilities with various place name formats
  - Test error handling and timeout scenarios
  - Test integration with HomeController (if implemented)
  - Mock HTTP client for deterministic geocoding tests

---

## Quick Validation

### Manual Testing Checklist
```bash
# 1. Run the app and verify location display
flutter run

# 2. Test coordinate display with real location
# Expected: See privacy-redacted coordinates (2 decimal places)

# 3. Test place name display with manual location
# Use "Set Location" button, enter coordinates with place name
# Expected: See both place name and coordinates

# 4. Test error state with cached location
# Simulate network error while cached location exists
# Expected: See cached location info in error state

# 5. Run unit tests
flutter test test/widget/widgets/location_info_test.dart
flutter test test/unit/controllers/home_controller_test.dart
```

### Integration Points to Verify
1. **LocationCache Integration**: Place names persist and load correctly
2. **HomeController Integration**: Place name loading doesn't block UI
3. **Privacy Compliance**: Coordinates show only 2 decimal places
4. **Accessibility**: Screen reader announces location information
5. **Responsive Layout**: Location info displays properly on different screen sizes

### Constitutional Gate Checklist
- **C1**: Clean architecture with separate LocationInfo widget ✓
- **C2**: Privacy-compliant coordinate redaction ✓  
- **C3**: Semantic labels and accessibility compliance ✓
- **C4**: Transparent location display for user trust ✓
- **C5**: Graceful error handling for missing place names ✓

---

## Implementation Priority

**High Priority (Immediate Value)**:
- T001: HomeState Model (foundation)
- T002: LocationInfo Widget (core feature)
- T003: HomeScreen Integration (user visibility)

**Medium Priority (Enhanced UX)**:
- T005: HomeController Enhancement (place name loading)
- T006: LocationInfo Enhancement (better place name display)

**Low Priority (Optional Features)**:
- T008: Privacy Utilities (regulatory compliance)
- T009: Geocoder Service (automatic place names)

**Always Required**:
- T004, T007, T010: Testing (constitutional gate C1)

---

**Next Steps**: When ready to implement, start with T001, T002, T004 in parallel for basic coordinate display, then proceed with T003 for user integration. This provides immediate user value while maintaining clean architecture principles.