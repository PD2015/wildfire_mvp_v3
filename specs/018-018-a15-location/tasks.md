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
  - **Dependencies**: T010
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

- [ ] **T018** Integrate picker into HomeScreen
  - **Goal**: Replace manual location dialog with picker
  - **Files**: `lib/screens/home_screen.dart`
  - **Test**: `test/widget/home_screen_test.dart` (update existing)
  - **Dependencies**: T017
  - **Details**:
    - Modify `_showManualLocationDialog()` → navigate to picker
    - Pass `LocationPickerMode.riskLocation`
    - On result: call `_controller.setManualLocation()`
    - Preserve existing behavior if cancelled

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

- [ ] **T022** [P] Unit tests for LocationPickerController
  - **Goal**: Test state transitions
  - **Files**: `test/unit/controllers/location_picker_controller_test.dart`
  - **Dependencies**: T013
  - **Details**:
    - Initialize with location
    - setLocation triggers w3w fetch
    - w3w error doesn't crash (graceful degradation)
    - buildResult returns correct PickedLocation

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

---

## Phase 3.8: Integration Tests

- [ ] **T027** Integration test: HomeScreen → Picker → Location updated
  - **Goal**: End-to-end flow for risk location selection
  - **Files**: `test/integration/location_picker_flow_test.dart`
  - **Dependencies**: T018
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
T001 (feature flags)
  └── T011 (service impl uses flag)

T002 (env template) ─ parallel, no deps
T003 (directory structure) ─ parallel, no deps

T004 (What3wordsAddress) ─┬── T005 (same file)
                         ├── T010 (interface uses)
                         └── T015 (panel uses)

T006 (PickedLocation) ─── T017 (screen returns)

T007 (State) ─── T013 (controller uses)

T008 (Mode) ─── T017 (screen uses)

T009 (PlaceSearchResult) ─── T016 (search bar uses)

T010 (Service interface) ─── T011 (impl)
                          └── T012 (mock)

T011 (Service impl) ─── T013 (controller uses)

T013 (Controller) ─── T017 (screen uses)

T014 (Crosshair) ─── T017 (screen uses)
T015 (InfoPanel) ─── T017 (screen uses)
T016 (SearchBar) ─── T017 (screen uses)

T017 (Screen) ─┬── T018 (HomeScreen integration)
               └── T019 (ReportFireScreen integration)

T018, T019 ─── T027, T028, T029 (integration tests)
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

### Batch 3: Service Interface + Mocks (parallel)
```bash
Task T010: "Create What3wordsService interface"
Task T012: "Create MockWhat3wordsService" (after T010)
```

### Batch 4: Widgets (parallel after controller)
```bash
# After T013 (controller) is complete
Task T014: "Create CrosshairOverlay widget"
Task T015: "Create LocationInfoPanel widget"
```

### Batch 5: Tests (parallel with implementation)
```bash
# Unit tests can run in parallel
Task T020: "Unit tests for What3wordsAddress"
Task T021: "Unit tests for What3wordsService"
Task T022: "Unit tests for LocationPickerController"
Task T023: "Widget tests for CrosshairOverlay"
Task T024: "Widget tests for LocationInfoPanel"
```

---

## Blocked Tasks / Decision Points

| Task | Blocker | Resolution Needed |
|------|---------|-------------------|
| **T009, T016** (Places search) | Places API package decision | **Recommendation**: Defer to v2, or use direct HTTP. Search is "Should" priority, not MVP. |
| **T001** | what3words API key | Developer must obtain key from what3words.com (free tier) |

---

## Constitution Compliance Tracking

| Gate | Tasks | Status |
|------|-------|--------|
| **C1**: Code Quality | T032 (flutter analyze) | Pending |
| **C2**: Secrets & Logging | T001 (env config), T011 (logRedact), T013 (no w3w logging) | Tracked |
| **C3**: Accessibility | T14-T17 (≥48dp), T030 (a11y tests) | Tracked |
| **C4**: Trust & Transparency | Uses existing BrandPalette | No new colors |
| **C5**: Resilience | T011 (timeouts), T029 (error tests) | Tracked |

---

## Estimated Effort

| Phase | Tasks | Parallel Potential | Est. Time |
|-------|-------|-------------------|-----------|
| 3.1 Setup | T001-T003 | High | 30 min |
| 3.2 Models | T004-T009 | High | 1-2 hr |
| 3.3 Services | T010-T012 | Medium | 2 hr |
| 3.4 Controller | T013 | Low | 2 hr |
| 3.5 Widgets | T014-T017 | Medium | 3-4 hr |
| 3.6 Integration | T018-T019 | Low | 1-2 hr |
| 3.7 Tests | T020-T026 | High | 2-3 hr |
| 3.8 Int. Tests | T027-T029 | Low | 1-2 hr |
| 3.9 Polish | T030-T033 | Medium | 1 hr |

**Total**: ~15-20 hours implementation time

---

*Tasks ready for execution. Start with Phase 3.1 Setup tasks.*
