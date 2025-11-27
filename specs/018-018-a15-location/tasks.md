# Tasks: 018-A15 Location Picker & what3words Integration

**Input**: Design documents from `/specs/018-018-a15-location/`
**Branch**: `018-018-a15-location`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- All file paths are relative to repository root

---

## Phase 3.1: Setup & Configuration

- [ ] **T001** Add WHAT3WORDS_API_KEY to feature flags
  - **Goal**: Enable what3words API key configuration via env file
  - **Files**: `lib/config/feature_flags.dart`
  - **Dependencies**: None
  - **Details**: Add `static const String what3wordsApiKey = String.fromEnvironment('WHAT3WORDS_API_KEY', defaultValue: '');`

- [ ] **T002** [P] Update env template with what3words placeholder
  - **Goal**: Document required API key for developers
  - **Files**: `env/dev.env.json.template`
  - **Dependencies**: None
  - **Details**: Add `"WHAT3WORDS_API_KEY": "YOUR_W3W_KEY_HERE"` to template
  - **Note**: Static Maps API and Geocoding API use existing `GOOGLE_MAPS_API_KEY_*` keys (no new key needed)

- [ ] **T003** [P] Create location_picker feature directory structure
  - **Goal**: Set up feature folder following existing patterns
  - **Files**: 
    - `lib/features/location_picker/screens/` (directory)
    - `lib/features/location_picker/controllers/` (directory)
    - `lib/features/location_picker/widgets/` (directory)
    - `lib/features/location_picker/models/` (directory)
  - **Dependencies**: None

---

## Phase 3.2: Models (Parallel - different files)

- [ ] **T004** [P] Create What3wordsAddress value object with validation
  - **Goal**: Validated what3words address with format checking
  - **Files**: `lib/models/what3words_models.dart`
  - **Test**: `test/unit/models/what3words_models_test.dart`
  - **Dependencies**: None
  - **Details**: 
    - `tryParse()` validates 3 words separated by dots
    - `displayFormat` returns `///word.word.word`
    - `copyFormat` returns `word.word.word`
    - Extends Equatable

- [ ] **T005** [P] Create What3wordsError sealed class hierarchy
  - **Goal**: Typed errors for what3words service operations
  - **Files**: `lib/models/what3words_models.dart` (same file as T004)
  - **Test**: `test/unit/models/what3words_models_test.dart`
  - **Dependencies**: T004 (same file)
  - **Details**:
    - `What3wordsApiError` - API errors with code, message, statusCode
    - `What3wordsNetworkError` - connectivity issues
    - `What3wordsInvalidAddressError` - format validation failures
    - All have `userMessage` getter

- [ ] **T006** [P] Create PickedLocation return model
  - **Goal**: Typed result returned from picker via Navigator.pop
  - **Files**: `lib/features/location_picker/models/picked_location.dart`
  - **Test**: `test/unit/models/picked_location_test.dart`
  - **Dependencies**: None
  - **Details**:
    - `coordinates: LatLng` (required)
    - `what3words: String?` (nullable)
    - `placeName: String?` (nullable)
    - `selectedAt: DateTime` (required)
    - Extends Equatable

- [ ] **T007** [P] Create LocationPickerState sealed class
  - **Goal**: State machine for controller
  - **Files**: `lib/features/location_picker/models/location_picker_state.dart`
  - **Test**: `test/unit/models/location_picker_state_test.dart`
  - **Dependencies**: T004, T009
  - **Details**:
    - `LocationPickerInitial` - initial loading state
    - `LocationPickerReady` - with location, what3words, search state
    - `copyWith()` method for state updates

- [ ] **T008** [P] Create LocationPickerMode enum
  - **Goal**: Distinguish picker entry points
  - **Files**: `lib/features/location_picker/models/location_picker_mode.dart`
  - **Dependencies**: None
  - **Details**:
    - `riskLocation` - from HomeScreen (saves on confirm)
    - `fireReport` - from ReportFireScreen (returns only)

- [ ] **T009** [P] Create PlaceSearchResult model (optional - for search feature)
  - **Goal**: Autocomplete result from Places API
  - **Files**: `lib/features/location_picker/models/place_search_result.dart`
  - **Test**: `test/unit/models/place_search_result_test.dart`
  - **Dependencies**: None
  - **Details**:
    - `placeId`, `primaryText`, `secondaryText`, `coordinates?`
    - `displayText` getter

---

## Phase 3.3: Services

- [ ] **T010** Create What3wordsService interface
  - **Goal**: Define contract for what3words operations
  - **Files**: `lib/services/what3words_service.dart`
  - **Dependencies**: T004, T005
  - **Details**:
    - `convertToCoordinates(String words)` → `Either<What3wordsError, LatLng>`
    - `convertToWords({double lat, double lon})` → `Either<What3wordsError, What3wordsAddress>`
    - 5s default timeout
    - C2: Document coordinate redaction in logging

- [ ] **T011** Create What3wordsServiceImpl with HTTP client
  - **Goal**: HTTP implementation calling what3words API
  - **Files**: `lib/services/what3words_service_impl.dart`
  - **Test**: `test/unit/services/what3words_service_test.dart`
  - **Dependencies**: T001, T010
  - **Details**:
    - Uses `http.Client` (existing dependency)
    - API key from `FeatureFlags.what3wordsApiKey`
    - `X-Api-Key` header authentication
    - Timeout handling → `What3wordsNetworkError`
    - API error parsing → `What3wordsApiError`
    - C2: Log coordinates with `LocationUtils.logRedact()`
    - C2: NEVER log what3words addresses

- [ ] **T012** [P] Create MockWhat3wordsService for testing
  - **Goal**: Mock implementation for widget/integration tests
  - **Files**: `lib/services/mock_what3words_service.dart`
  - **Dependencies**: T010
  - **Details**:
    - Returns configurable mock responses
    - Supports delay simulation
    - Supports error injection

- [ ] **T034** [P] Create GeocodingService interface
  - **Goal**: Define contract for reverse geocoding (coordinates → place name)
  - **Files**: `lib/services/geocoding_service.dart`
  - **Dependencies**: None
  - **Details**:
    - `reverseGeocode({double lat, double lon})` → `Either<GeocodingError, String>`
    - Returns simplified location string (e.g., "Near Aviemore, Highland")
    - 3s default timeout
    - C2: Log coordinates with `LocationUtils.logRedact()`

- [ ] **T035** Create GeocodingServiceImpl with HTTP client
  - **Goal**: HTTP implementation calling Google Geocoding API
  - **Files**: `lib/services/geocoding_service_impl.dart`
  - **Test**: `test/unit/services/geocoding_service_test.dart`
  - **Dependencies**: T034
  - **Details**:
    - Uses `http.Client` (existing dependency)
    - API key from existing `FeatureFlags.googleMapsApiKey*` (platform-aware)
    - Parse response to extract locality/area name
    - Prefer: neighborhood > locality > admin_area_level_2 > admin_area_level_1
    - Format: "Near {locality}, {region}" or just "{locality}"
    - Graceful fallback if no results
    - C2: Log coordinates with `LocationUtils.logRedact()`

- [ ] **T036** [P] Create MockGeocodingService for testing
  - **Goal**: Mock implementation for widget/integration tests
  - **Files**: `lib/services/mock_geocoding_service.dart`
  - **Dependencies**: T034
  - **Details**:
    - Returns configurable mock responses
    - Supports delay simulation
    - Supports error injection

---

## Phase 3.4: Controller

- [ ] **T013** Create LocationPickerController (ChangeNotifier)
  - **Goal**: State management for picker screen
  - **Files**: `lib/features/location_picker/controllers/location_picker_controller.dart`
  - **Test**: `test/unit/controllers/location_picker_controller_test.dart`
  - **Dependencies**: T007, T010, T011
  - **Details**:
    - `initialize({LatLng? initialLocation})` - set up initial state
    - `setLocation(LatLng)` - update on camera idle, fetch w3w
    - `searchWhat3words(String)` - validate and convert w3w input
    - `useCurrentGps()` - get GPS location via LocationResolver
    - `buildResult()` → `PickedLocation?`
    - Debounce w3w fetch (300ms after camera idle)
    - C2: Log with `LocationUtils.logRedact()`

---

## Phase 3.5: Widgets (some parallel)

- [ ] **T014** [P] Create CrosshairOverlay widget
  - **Goal**: Fixed center marker on map
  - **Files**: `lib/features/location_picker/widgets/crosshair_overlay.dart`
  - **Test**: `test/widget/crosshair_overlay_test.dart`
  - **Dependencies**: None
  - **Details**:
    - Centered `Icon` with shadow for visibility
    - Configurable size (default 48dp)
    - Uses `BrandPalette` colors
    - Decorative only (no semantics)

- [ ] **T015** [P] Create LocationInfoPanel widget
  - **Goal**: Bottom panel showing coords and what3words
  - **Files**: `lib/features/location_picker/widgets/location_info_panel.dart`
  - **Test**: `test/widget/location_info_panel_test.dart`
  - **Dependencies**: T004
  - **Details**:
    - Displays coordinates (2dp precision)
    - what3words with loading spinner or error state
    - Copy button (≥48dp, C3 compliance)
    - "Use GPS" button (≥48dp, conditional visibility)
    - Uses `Theme.of(context).colorScheme` for colors
    - Semantic labels for all interactive elements (C3)

- [ ] **T016** Create LocationSearchBar widget
  - **Goal**: Search input with autocomplete dropdown
  - **Files**: `lib/features/location_picker/widgets/location_search_bar.dart`
  - **Test**: `test/widget/location_search_bar_test.dart`
  - **Dependencies**: T009
  - **Details**:
    - Detects what3words input (starts with `/` or `///`)
    - Shows suggestions dropdown
    - Loading indicator
    - Clear button
    - ≥48dp height (C3)
    - Semantic label "Search for location" (C3)

- [ ] **T017** Create LocationPickerScreen
  - **Goal**: Full-screen picker with map, search, info panel
  - **Files**: `lib/features/location_picker/screens/location_picker_screen.dart`
  - **Test**: `test/widget/location_picker_screen_test.dart`
  - **Dependencies**: T013, T014, T015, T016, T008
  - **Details**:
    - AppBar with back and confirm buttons
    - `GoogleMap` with stable `ValueKey`
    - `CrosshairOverlay` in `Stack`
    - `LocationSearchBar` below AppBar
    - `LocationInfoPanel` at bottom
    - Mode variations (title, emergency banner)
    - `Navigator.pop<PickedLocation>` on confirm
    - C3: All buttons ≥48dp

---

## Phase 3.6: Integration with Existing Screens

- [ ] **T037** Add what3words and formattedLocation to HomeState
  - **Goal**: Extend HomeStateSuccess to include location metadata for display
  - **Files**: `lib/models/home_state.dart`
  - **Test**: `test/unit/models/home_state_test.dart` (update existing)
  - **Dependencies**: T004
  - **Details**:
    - Add `what3words: String?` to HomeStateSuccess
    - Add `formattedLocation: String?` to HomeStateSuccess (from geocoding)
    - Add `isWhat3wordsLoading: bool` to HomeStateLoading
    - Add `isGeocodingLoading: bool` to HomeStateLoading
    - Keep existing fields, extend Equatable props

- [ ] **T038** Add LocationSource display label extension
  - **Goal**: User-friendly badge labels for location source
  - **Files**: `lib/models/location_models.dart`
  - **Dependencies**: None
  - **Details**:
    - Add `displayLabel` extension on LocationSource enum
    - `gps` → "GPS", `manual` → "Manual", `cached` → "Cached", `defaultFallback` → "Default"
    - Do NOT modify existing enum values

- [ ] **T039** Update HomeController to fetch what3words on location resolution
  - **Goal**: Automatically fetch what3words when GPS location obtained
  - **Files**: `lib/controllers/home_controller.dart`
  - **Test**: `test/unit/controllers/home_controller_test.dart` (update existing)
  - **Dependencies**: T011, T037
  - **Details**:
    - Inject `What3wordsService` dependency
    - After location resolved, call `convertToWords()` in parallel
    - Update HomeStateSuccess with `what3words` result
    - Graceful degradation: null if service fails (don't block main flow)
    - C2: Do NOT log what3words addresses

- [ ] **T040** Update HomeController to fetch geocoding on location resolution
  - **Goal**: Automatically fetch formatted location name
  - **Files**: `lib/controllers/home_controller.dart`
  - **Dependencies**: T035, T037
  - **Details**:
    - Inject `GeocodingService` dependency
    - After location resolved, call `reverseGeocode()` in parallel with w3w
    - Update HomeStateSuccess with `formattedLocation` result
    - Graceful degradation: null if service fails
    - C2: Log with `LocationUtils.logRedact()`

- [ ] **T041** Create buildStaticMapUrl utility function
  - **Goal**: Generate Google Static Maps API URL for location preview
  - **Files**: `lib/utils/static_map_url_builder.dart`
  - **Test**: `test/unit/utils/static_map_url_builder_test.dart`
  - **Dependencies**: None
  - **Details**:
    - Parameters: lat, lon, apiKey, width, height, zoom
    - Default: 600x300, zoom 11, terrain maptype
    - Round coordinates to 2dp for privacy (C2)
    - Add red marker at location
    - Return full URL string

- [ ] **T042** Create LocationMiniMapPreview widget
  - **Goal**: Tappable static map preview with loading/error states
  - **Files**: `lib/widgets/location_mini_map_preview.dart`
  - **Test**: `test/widget/location_mini_map_preview_test.dart`
  - **Dependencies**: T041
  - **Details**:
    - 140px height, rounded corners (16dp)
    - Image.network with loading spinner
    - Error state: "Map preview unavailable"
    - Tappable overlay to open picker
    - "Tap to change" label in corner
    - ≥48dp tap target (full surface)

- [ ] **T043** Enhance LocationCard with what3words and static map
  - **Goal**: Replace simple LocationCard with rich preview card
  - **Files**: `lib/widgets/location_card.dart`
  - **Test**: `test/widget/location_card_test.dart` (update existing)
  - **Dependencies**: T038, T042
  - **Details**:
    - Add header row with title + LocationSource badge
    - Add `formattedLocation` display (e.g., "Near Aviemore, Highland")
    - Add what3words row with loading spinner, copy button
    - Add `LocationMiniMapPreview` 
    - Add "Change location" button
    - Props: formattedLocation, location (LatLng), staticMapUrl, source, what3words, isWhat3WordsLoading, callbacks
    - Keep existing LocationSource icon logic
    - ≥48dp for copy and change buttons (C3)

- [ ] **T044** Update HomeScreen to use enhanced LocationCard
  - **Goal**: Wire up new LocationCard with HomeController state
  - **Files**: `lib/screens/home_screen.dart`
  - **Test**: `test/widget/home_screen_test.dart` (update existing)
  - **Dependencies**: T041, T043, T039, T040
  - **Details**:
    - Compute staticMapUrl using buildStaticMapUrl()
    - Pass what3words, formattedLocation, source from HomeStateSuccess
    - onChangeLocation → navigate to LocationPickerScreen
    - onCopyWhat3Words → copy to clipboard + snackbar
    - onTapMapPreview → same as onChangeLocation

- [ ] **T045** Integrate picker navigation into HomeScreen
  - **Goal**: Navigate to picker, handle result, update location
  - **Files**: `lib/screens/home_screen.dart`
  - **Dependencies**: T017, T044
  - **Details**:
    - Replace `_showManualLocationDialog()` → `Navigator.push<PickedLocation>()`
    - Pass `LocationPickerMode.riskLocation` and current location
    - On result: call `_controller.setManualLocation(result.coordinates, placeName: result.placeName)`
    - Preserve existing behavior if cancelled (pop with null)

- [ ] **T046** Update RiskBanner to show formattedLocation
  - **Goal**: Display human-readable location in risk banner
  - **Files**: `lib/widgets/risk_banner.dart`
  - **Test**: `test/widget/risk_banner_test.dart` (update if exists)
  - **Dependencies**: T040
  - **Details**:
    - Add optional `formattedLocation: String?` prop
    - Display below or alongside risk level if available
    - Graceful fallback: don't show if null
    - Keep existing risk display unchanged

- [ ] **T019** Integrate picker into ReportFireScreen
  - **Goal**: Add "Set Fire Location" button for w3w copy
  - **Files**: `lib/features/report/screens/report_fire_screen.dart`
  - **Test**: `test/widget/report_fire_screen_test.dart` (update existing)
  - **Dependencies**: T017
  - **Details**:
    - Add "Set Fire Location" button in appropriate position
    - Pass `LocationPickerMode.fireReport`
    - On result: copy what3words to clipboard + snackbar
    - Keep existing emergency contacts functionality

---

## Phase 3.7: Tests (TDD - write alongside implementation)

- [ ] **T020** [P] Unit tests for What3wordsAddress validation
  - **Goal**: Test format validation edge cases
  - **Files**: `test/unit/models/what3words_models_test.dart`
  - **Dependencies**: T004, T005
  - **Details**:
    - Valid formats: `slurs.this.name`, `///slurs.this.name`, `/slurs.this.name`
    - Invalid: `invalid`, `two.words`, `CAPS.are.ok` → lowercase normalized
    - Error type verification

- [ ] **T021** [P] Unit tests for What3wordsService
  - **Goal**: Test HTTP client integration
  - **Files**: `test/unit/services/what3words_service_test.dart`
  - **Dependencies**: T011
  - **Details**:
    - Mock HTTP client responses
    - Test success cases (coords ↔ words)
    - Test API error handling
    - Test network timeout handling
    - Test invalid address rejection

- [ ] **T047** [P] Unit tests for GeocodingService
  - **Goal**: Test HTTP client integration for reverse geocoding
  - **Files**: `test/unit/services/geocoding_service_test.dart`
  - **Dependencies**: T035
  - **Details**:
    - Mock HTTP client responses
    - Test success case with various address components
    - Test fallback priority (neighborhood > locality > admin_area)
    - Test zero results handling
    - Test API error handling
    - Test network timeout handling

- [ ] **T022** [P] Unit tests for LocationPickerController
  - **Goal**: Test state transitions
  - **Files**: `test/unit/controllers/location_picker_controller_test.dart`
  - **Dependencies**: T013
  - **Details**:
    - Initialize with location
    - setLocation triggers w3w fetch
    - w3w error doesn't crash (graceful degradation)
    - buildResult returns correct PickedLocation

- [ ] **T048** [P] Unit tests for HomeController what3words/geocoding
  - **Goal**: Test parallel fetching of w3w and geocoding
  - **Files**: `test/unit/controllers/home_controller_test.dart` (extend existing)
  - **Dependencies**: T039, T040
  - **Details**:
    - Test what3words fetched on successful location
    - Test geocoding fetched on successful location
    - Test graceful degradation (w3w failure doesn't block)
    - Test geocoding failure doesn't block
    - Test parallel execution (both services called)

- [ ] **T049** [P] Unit tests for buildStaticMapUrl
  - **Goal**: Test URL generation with various inputs
  - **Files**: `test/unit/utils/static_map_url_builder_test.dart`
  - **Dependencies**: T041
  - **Details**:
    - Test default parameters
    - Test custom width/height/zoom
    - Test coordinate rounding to 2dp (privacy)
    - Test marker inclusion
    - Test URL encoding

- [ ] **T023** [P] Widget tests for CrosshairOverlay
  - **Goal**: Verify rendering
  - **Files**: `test/widget/crosshair_overlay_test.dart`
  - **Dependencies**: T014

- [ ] **T024** [P] Widget tests for LocationInfoPanel
  - **Goal**: Verify states and interactions
  - **Files**: `test/widget/location_info_panel_test.dart`
  - **Dependencies**: T015
  - **Details**:
    - Loading state shows spinner
    - Ready state shows w3w with copy button
    - Copy button triggers callback
    - GPS button conditional visibility

- [ ] **T025** [P] Widget tests for LocationSearchBar
  - **Goal**: Verify input handling
  - **Files**: `test/widget/location_search_bar_test.dart`
  - **Dependencies**: T016
  - **Details**:
    - What3words detection (/// prefix)
    - Suggestions dropdown
    - Clear button

- [ ] **T026** Widget tests for LocationPickerScreen
  - **Goal**: Full screen integration test
  - **Files**: `test/widget/location_picker_screen_test.dart`
  - **Dependencies**: T017
  - **Details**:
    - Opens with initial location
    - fireReport mode shows emergency banner
    - Confirm button returns PickedLocation

- [ ] **T050** [P] Widget tests for LocationMiniMapPreview
  - **Goal**: Verify loading, error, and tap states
  - **Files**: `test/widget/location_mini_map_preview_test.dart`
  - **Dependencies**: T042
  - **Details**:
    - Loading state shows spinner
    - Error state shows fallback text
    - Tap triggers callback
    - Label visible in corner

- [ ] **T051** [P] Widget tests for enhanced LocationCard
  - **Goal**: Verify what3words display, static map, and interactions
  - **Files**: `test/widget/location_card_test.dart` (extend existing)
  - **Dependencies**: T043
  - **Details**:
    - What3words loading state shows spinner
    - What3words ready state shows address + copy button
    - Copy button triggers callback
    - Static map preview rendered
    - Source badge shows correct label
    - formattedLocation displayed when provided

---

## Phase 3.8: Integration Tests

- [ ] **T027** Integration test: HomeScreen → Picker → Location updated
  - **Goal**: End-to-end flow for risk location selection
  - **Files**: `test/integration/location_picker_flow_test.dart`
  - **Dependencies**: T045
  - **Details**:
    - Open app, tap Change button
    - Picker opens, pan map
    - Confirm, verify location updated
    - Fire risk data reloads

- [ ] **T028** Integration test: ReportFireScreen → Picker → Clipboard
  - **Goal**: End-to-end flow for fire report location
  - **Files**: `test/integration/location_picker_flow_test.dart`
  - **Dependencies**: T019
  - **Details**:
    - Navigate to Report tab
    - Tap Set Location button
    - Select location, confirm
    - Verify w3w copied to clipboard

- [ ] **T029** Integration test: Error handling and fallbacks
  - **Goal**: Verify graceful degradation (C5)
  - **Files**: `test/integration/location_picker_flow_test.dart`
  - **Dependencies**: T027
  - **Details**:
    - what3words unavailable → coordinates still work
    - GPS unavailable → button hidden
    - Network timeout → error shown, retry available

- [ ] **T052** Integration test: what3words auto-fetch on GPS location
  - **Goal**: Verify what3words fetched automatically on app load
  - **Files**: `test/integration/home_screen_w3w_test.dart`
  - **Dependencies**: T039
  - **Details**:
    - App launches with GPS location
    - what3words auto-fetched (loading → result)
    - LocationCard shows what3words address
    - Copy button works

- [ ] **T053** Integration test: geocoding auto-fetch on GPS location
  - **Goal**: Verify formatted location fetched automatically
  - **Files**: `test/integration/home_screen_geocoding_test.dart`
  - **Dependencies**: T040
  - **Details**:
    - App launches with GPS location
    - Geocoding auto-fetched
    - LocationCard shows formatted location (e.g., "Near Aviemore, Highland")
    - RiskBanner shows formatted location

---

## Phase 3.9: Polish & Documentation

- [ ] **T030** [P] Add accessibility tests (C3)
  - **Goal**: Verify ≥48dp touch targets and semantic labels
  - **Files**: `test/accessibility/location_picker_a11y_test.dart`
  - **Dependencies**: T17
  - **Details**:
    - All buttons meet minimum size
    - Semantic labels present
    - VoiceOver/TalkBack compatible

- [ ] **T031** [P] Update quickstart.md with actual test commands
  - **Goal**: Verify all validation steps work
  - **Files**: `specs/018-018-a15-location/quickstart.md`
  - **Dependencies**: T029

- [ ] **T032** [P] Run flutter analyze and fix any issues
  - **Goal**: C1 compliance - zero analyzer warnings
  - **Files**: All new files
  - **Dependencies**: T029

- [ ] **T033** Run manual validation per quickstart.md
  - **Goal**: Human verification of all scenarios
  - **Files**: N/A (manual testing)
  - **Dependencies**: T032

---

## Dependencies Graph

```
T001 (feature flags) ─── T011 (what3words impl uses API key)

T002 (env template) ─ parallel, no deps
T003 (directory structure) ─ parallel, no deps

T004 (What3wordsAddress) ─┬── T005 (same file)
                         ├── T010 (interface uses)
                         ├── T015 (panel uses)
                         └── T037 (HomeState uses)

T006 (PickedLocation) ─── T017 (screen returns)

T007 (State) ─── T013 (controller uses)

T008 (Mode) ─── T017 (screen uses)

T009 (PlaceSearchResult) ─┬── T007 (state uses)
                         └── T016 (search bar uses)

T010 (What3words interface) ─┬── T011 (impl)
                            └── T012 (mock)

T011 (What3words impl) ─┬── T013 (controller uses)
                       └── T039 (HomeController uses)

T034 (Geocoding interface) ─── T035 (impl)
                            └── T036 (mock)

T035 (Geocoding impl) ─── T040 (HomeController uses)

T037 (HomeState updates) ─┬── T039 (w3w fetch)
                         └── T040 (geocoding fetch)

T038 (LocationSource labels) ─── T043 (LocationCard uses)

T039 (HomeController w3w) ─── T044 (HomeScreen uses)
T040 (HomeController geo) ─┬── T044 (HomeScreen uses)
                          └── T046 (RiskBanner uses)

T041 (staticMapUrl) ─── T042 (MiniMapPreview uses)
                     └── T044 (HomeScreen uses)

T042 (MiniMapPreview) ─── T043 (LocationCard uses)

T043 (LocationCard) ─── T044 (HomeScreen uses)

T013 (Controller) ─── T017 (screen uses)

T014 (Crosshair) ─── T017 (screen uses)
T015 (InfoPanel) ─── T017 (screen uses)
T016 (SearchBar) ─── T017 (screen uses)

T017 (Screen) ─┬── T045 (HomeScreen picker nav)
               └── T019 (ReportFireScreen integration)

T044, T045 ─── T027 (integration test)
T019 ─── T028 (integration test)
T039 ─── T052 (w3w auto-fetch test)
T040 ─── T053 (geocoding auto-fetch test)
```

---

## Parallel Execution Examples

### Batch 1: Setup (all parallel)
```bash
# Can run T001, T002, T003 simultaneously
Task T001: "Add WHAT3WORDS_API_KEY to lib/config/feature_flags.dart"
Task T002: "Update env/dev.env.json.template with what3words placeholder"
Task T003: "Create lib/features/location_picker/ directory structure"
```

### Batch 2: Models (mostly parallel)
```bash
# T004, T006, T008, T009 can run in parallel (different files)
# T005 must follow T004 (same file)
# T007 must follow T004 (depends on What3wordsAddress)
Task T004: "Create What3wordsAddress in lib/models/what3words_models.dart"
Task T006: "Create PickedLocation in lib/features/location_picker/models/"
Task T008: "Create LocationPickerMode enum"
Task T009: "Create PlaceSearchResult model"
```

### Batch 3: Service Interfaces (parallel)
```bash
# Both interfaces can be created in parallel
Task T010: "Create What3wordsService interface"
Task T034: "Create GeocodingService interface"
```

### Batch 4: Service Implementations + Mocks (parallel after interfaces)
```bash
Task T011: "Create What3wordsServiceImpl"
Task T012: "Create MockWhat3wordsService"
Task T035: "Create GeocodingServiceImpl"
Task T036: "Create MockGeocodingService"
```

### Batch 5: HomeState + Utilities (parallel)
```bash
Task T037: "Add what3words/formattedLocation to HomeState"
Task T038: "Add LocationSource display label extension"
Task T041: "Create buildStaticMapUrl utility"
```

### Batch 6: HomeController updates (sequential)
```bash
Task T039: "Update HomeController to fetch what3words on location resolution"
Task T040: "Update HomeController to fetch geocoding on location resolution"
```

### Batch 7: Widgets (parallel after controller)
```bash
# After T013 (controller) is complete
Task T014: "Create CrosshairOverlay widget"
Task T015: "Create LocationInfoPanel widget"
Task T042: "Create LocationMiniMapPreview widget"
```

### Batch 8: LocationCard + RiskBanner (after widgets)
```bash
Task T043: "Enhance LocationCard with what3words and static map"
Task T046: "Update RiskBanner to show formattedLocation"
```

### Batch 9: Tests (parallel with implementation)
```bash
# Unit tests can run in parallel
Task T020: "Unit tests for What3wordsAddress"
Task T021: "Unit tests for What3wordsService"
Task T047: "Unit tests for GeocodingService"
Task T022: "Unit tests for LocationPickerController"
Task T048: "Unit tests for HomeController what3words/geocoding"
Task T049: "Unit tests for buildStaticMapUrl"
Task T050: "Widget tests for LocationMiniMapPreview"
Task T051: "Widget tests for enhanced LocationCard"
```

---

## Blocked Tasks / Decision Points

| Task | Blocker | Resolution Needed |
|------|---------|-------------------|
| **T009, T016** (Places search) | Places API package decision | **Recommendation**: Defer to v2, or use direct HTTP. Search is "Should" priority, not MVP. |
| **T001** | what3words API key | Developer must obtain key from what3words.com (free tier) |
| **T035** | Geocoding API | Uses existing Google Maps API key - no new key needed |

---

## Constitution Compliance Tracking

| Gate | Tasks | Status |
|------|-------|--------|
| **C1**: Code Quality | T032 (flutter analyze) | Pending |
| **C2**: Secrets & Logging | T001 (env config), T011 (logRedact), T013 (no w3w logging), T035 (logRedact), T041 (2dp coords) | Tracked |
| **C3**: Accessibility | T14-T17 (≥48dp), T042 (≥48dp tap), T043 (≥48dp buttons), T030 (a11y tests) | Tracked |
| **C4**: Trust & Transparency | Uses existing BrandPalette, T038 (source badges) | No new colors |
| **C5**: Resilience | T011 (timeouts), T035 (timeouts), T029 (error tests), T039/T040 (graceful degradation) | Tracked |

---

## Estimated Effort

| Phase | Tasks | Parallel Potential | Est. Time |
|-------|-------|-------------------|-----------|
| 3.1 Setup | T001-T003 | High | 30 min |
| 3.2 Models | T004-T009 | High | 1-2 hr |
| 3.3 Services | T010-T012, T034-T036 | High | 3-4 hr |
| 3.4 Controller | T013 | Low | 2 hr |
| 3.5 Widgets | T014-T017, T042 | Medium | 3-4 hr |
| 3.6 Integration | T037-T046, T019 | Medium | 4-5 hr |
| 3.7 Tests | T020-T026, T047-T051 | High | 3-4 hr |
| 3.8 Int. Tests | T027-T029, T052-T053 | Low | 2 hr |
| 3.9 Polish | T030-T033 | Medium | 1 hr |

**Total**: ~20-25 hours implementation time

---

## Summary of Changes from Original Plan

### Added Tasks (T034-T053)
- **T034-T036**: GeocodingService (interface, impl, mock) for reverse geocoding
- **T037**: HomeState extensions for what3words and formattedLocation
- **T038**: LocationSource display label extension
- **T039-T040**: HomeController updates to auto-fetch w3w and geocoding
- **T041**: Static map URL builder utility
- **T042**: LocationMiniMapPreview widget
- **T043**: Enhanced LocationCard (replaces simple card with rich preview)
- **T044-T045**: HomeScreen integration (split from original T018)
- **T046**: RiskBanner update for formattedLocation
- **T047-T053**: Additional unit/widget/integration tests

### Key Design Decisions
1. **Reuse existing Google Maps API key** for Static Maps and Geocoding (no new key)
2. **Keep existing LocationSource enum** - add displayLabel extension only
3. **Auto-fetch what3words on GPS location** - no user interaction needed
4. **Include reverse geocoding** - small scope, natural fit with location features
5. **Enhance LocationCard** (not replace) - backwards compatible approach

---

*Tasks ready for execution. Start with Phase 3.1 Setup tasks.*
