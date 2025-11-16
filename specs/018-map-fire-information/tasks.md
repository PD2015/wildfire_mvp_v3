# Task Breakdown: Map Fire Information Sheet

**Feature**: A1 Map Fire Information Sheet  
**Repository**: PD2015/wildfire_mvp_v3  
**Issue**: https://github.com/PD2015/wildfire_mvp_v3/issues/20  
**Branch**: `018-map-fire-information`

## Task Overview

**Total Tasks**: 32  
**Estimated Duration**: 5-7 days  
**Labels**: a1-feature, ui, services, testing, accessibility, android, ios

## Phase 1: Data Models and Core Infrastructure (1-2 days)

### Task 1: Update FireIncident Model [P]
**Priority**: High  
**Estimate**: 4 hours  
**Dependencies**: None

**Description**: Enhance existing FireIncident model with satellite sensor fields required for bottom sheet display.

**Requirements**:
- Add fields: `detectedAt`, `source`, `confidence`, `frp`, `lastUpdate`
- Maintain existing fields: `id`, `location`, `dataSource`, `freshness`
- Update `fromJson`/`toJson` methods for API compatibility
- Add validation rules per data model specification
- Ensure Equatable implementation for value comparison

**Files to Modify**:
- `lib/models/fire_incident.dart`

**Acceptance Criteria**:
- [ ] All new fields added with proper types
- [ ] JSON serialization handles both new and legacy formats
- [ ] Validation prevents invalid confidence values (0-100%)
- [ ] Model passes existing tests plus new field tests
- [ ] Constitutional compliance (C1: code quality)

### Task 2: Create ActiveFiresResponse Model [P]
**Priority**: High  
**Estimate**: 2 hours  
**Dependencies**: None

**Description**: Create wrapper model for API responses containing multiple fire incidents.

**Requirements**:
- Fields: `incidents`, `queriedBounds`, `responseTime`, `dataSource`, `totalCount`
- JSON serialization for caching
- Validation for bounds consistency

**Files to Create**:
- `lib/models/active_fires_response.dart`

**Acceptance Criteria**:
- [ ] Model handles empty incident lists
- [ ] Validates incidents fall within bounds
- [ ] Proper JSON serialization for caching
- [ ] Unit tests cover edge cases

### Task 3: Create Distance Calculation Utilities [P]
**Priority**: Medium  
**Estimate**: 3 hours  
**Dependencies**: None

**Description**: Implement utilities for calculating distance and bearing between user location and fire incidents.

**Requirements**:
- Great circle distance calculation using geolocator
- Cardinal direction bearing (N, NE, E, SE, etc.)
- Handle location permission denied gracefully
- Privacy-compliant coordinate logging

**Files to Create**:
- `lib/utils/distance_calculator.dart`

**Acceptance Criteria**:
- [ ] Accurate distance calculation using great circle formula
- [ ] Bearing returns user-friendly cardinal directions
- [ ] Handles edge cases (same location, poles, date line)
- [ ] Privacy-compliant logging via GeographicUtils.logRedact
- [ ] Unit tests with known distance calculations

### Task 4: Create Bottom Sheet State Management [P]
**Priority**: Medium  
**Estimate**: 2 hours  
**Dependencies**: Task 1

**Description**: Create state classes for managing bottom sheet display and loading states.

**Requirements**:
- BottomSheetState with loading, error, and data states
- FireMarkerState for marker selection
- State transitions for error recovery

**Files to Create**:
- `lib/models/bottom_sheet_state.dart`
- `lib/models/fire_marker_state.dart`

**Acceptance Criteria**:
- [ ] Clear state transitions defined
- [ ] Error state includes retry capability
- [ ] Immutable state objects with copyWith methods
- [ ] Unit tests for state transitions

## Phase 2: Service Layer Implementation (1-2 days)

### Task 5: Create ActiveFiresService Interface
**Priority**: High  
**Estimate**: 1 hour  
**Dependencies**: Task 1, Task 2

**Description**: Define service interface for fetching fire incidents within viewport bounds.

**Requirements**:
- `getIncidentsForViewport(LatLngBounds, {timeWindowHours, maxResults})`
- `getIncidentDetails(String incidentId)` for individual lookups
- Either<ApiError, T> return types for error handling

**Files to Create**:
- `lib/services/active_fires_service.dart`

**Acceptance Criteria**:
- [ ] Interface follows existing service patterns
- [ ] Clear documentation with parameter descriptions
- [ ] Error types align with existing ApiError structure

### Task 6: Implement ActiveFiresServiceImpl (Live Data)
**Priority**: High  
**Estimate**: 8 hours  
**Dependencies**: Task 5

**Description**: Implement live data service that fetches real fire incidents from EFFIS API.

**Requirements**:
- HTTP requests to EFFIS WFS service
- Geographic bounds filtering
- 8-second timeout with error handling
- Response parsing to FireIncident objects
- MAP_LIVE_DATA feature flag integration

**Files to Create**:
- `lib/services/active_fires_service_impl.dart`

**Acceptance Criteria**:
- [ ] Successful API integration with EFFIS WFS
- [ ] Proper error handling with retry capability
- [ ] Geographic filtering works correctly
- [ ] Respects MAP_LIVE_DATA feature flag
- [ ] Constitutional compliance (C5: resilience)

### Task 7: Implement ActiveFiresServiceMock
**Priority**: High  
**Estimate**: 4 hours  
**Dependencies**: Task 5

**Description**: Create mock service for demo data mode with realistic test incidents.

**Requirements**:
- Predefined fire incidents covering Scotland
- Variety of confidence levels, FRP values, and ages
- Realistic response delays (100-500ms)
- Clear DEMO DATA source labeling

**Files to Create**:
- `lib/services/active_fires_service_mock.dart`

**Acceptance Criteria**:
- [ ] Mock data includes all required fields
- [ ] Incidents distributed across Scottish geography
- [ ] Simulates realistic network delays
- [ ] Clear mock data source indicators
- [ ] Constitutional compliance (C4: transparency)

### Task 8: Enhance FireIncidentCache with Viewport Support
**Priority**: Medium  
**Estimate**: 6 hours  
**Dependencies**: Task 2

**Description**: Extend existing cache to support efficient viewport-based queries using geohash indexing.

**Requirements**:
- Geohash-based spatial indexing for viewport queries
- 6-hour TTL for fire incident data
- LRU eviction when cache size limit reached
- Cache hit/miss telemetry

**Files to Modify**:
- `lib/services/cache/fire_incident_cache_impl.dart`

**Acceptance Criteria**:
- [ ] Efficient viewport queries using spatial indexing
- [ ] Proper TTL handling with automatic cleanup
- [ ] LRU eviction prevents memory bloat
- [ ] Cache performance meets requirements (<200ms)
- [ ] Unit tests for cache behavior

### Task 9: Create Service Orchestrator with Fallback Chain
**Priority**: High  
**Estimate**: 6 hours  
**Dependencies**: Task 6, Task 7, Task 8

**Description**: Implement orchestrator that manages fallback chain: Live API → Cache → Mock data.

**Requirements**:
- Attempt live API first (if MAP_LIVE_DATA=true)
- Fall back to cache if live fails
- Fall back to mock data as last resort
- Telemetry for fallback chain performance

**Files to Create**:
- `lib/services/fire_location_service_orchestrator.dart`

**Acceptance Criteria**:
- [ ] Correct fallback order implemented
- [ ] Timeouts prevent hanging on failed services
- [ ] Clear data source indicators at each level
- [ ] Telemetry tracks service performance
- [ ] Constitutional compliance (C5: resilience)

## Phase 3: UI Components (2-3 days)

### Task 10: Create Data Source Chip Widget [P]
**Priority**: Medium  
**Estimate**: 2 hours  
**Dependencies**: None

**Description**: Create chip widget that displays data source (EFFIS, SEPA, Cache, Mock) with appropriate styling.

**Requirements**:
- Different colors/styles for each data source
- Accessibility labels for screen readers
- Constitutional color compliance

**Files to Create**:
- `lib/widgets/chips/data_source_chip.dart`

**Acceptance Criteria**:
- [ ] Clear visual distinction between data sources
- [ ] Accessibility labels for all chip types
- [ ] Constitutional color compliance (C4)
- [ ] Widget tests for all data source types

### Task 11: Create Demo Data Warning Chip [P]
**Priority**: Medium  
**Estimate**: 2 hours  
**Dependencies**: None

**Description**: Create prominent warning chip for demo data mode.

**Requirements**:
- Prominent "DEMO DATA" warning
- High contrast colors for visibility
- Clear semantic labeling

**Files to Create**:
- `lib/widgets/chips/demo_data_chip.dart`

**Acceptance Criteria**:
- [ ] Prominent visual styling for demo warning
- [ ] High contrast meets accessibility standards
- [ ] Clear screen reader announcements
- [ ] Widget tests for visibility and styling

### Task 12: Create Fire Details Bottom Sheet Widget
**Priority**: High  
**Estimate**: 12 hours  
**Dependencies**: Task 1, Task 3, Task 10, Task 11

**Description**: Implement main bottom sheet widget that displays comprehensive fire incident information.

**Requirements**:
- DraggableScrollableSheet for native feel
- All fire details: detection time, source, confidence, FRP, distance, bearing
- Risk level integration with EffisService
- Loading states, error states, retry functionality
- Complete accessibility support (≥44dp targets, semantic labels)

**Files to Create**:
- `lib/widgets/fire_details_bottom_sheet.dart`

**Acceptance Criteria**:
- [ ] Displays all fire incident fields correctly
- [ ] Risk level loads and displays with official colors
- [ ] Distance and bearing calculate and display correctly
- [ ] Loading and error states provide clear feedback
- [ ] All interactive elements ≥44dp touch targets
- [ ] Complete semantic labeling for screen readers
- [ ] Constitutional compliance (C3: accessibility, C4: transparency)

### Task 13: Create Custom Fire Marker Widget [P]
**Priority**: Medium  
**Estimate**: 4 hours  
**Dependencies**: Task 1

**Description**: Create custom marker widget for displaying fire incidents on map with appropriate visual styling.

**Requirements**:
- Size based on confidence/FRP values
- Color coding for incident age
- Accessibility semantic labels
- Selection state visualization

**Files to Create**:
- `lib/widgets/fire_marker.dart`

**Acceptance Criteria**:
- [ ] Visual styling reflects fire intensity
- [ ] Clear selection state indication
- [ ] Accessibility labels describe fire details
- [ ] Performance optimized for many markers
- [ ] Widget tests for different marker states

### Task 14: Create Time Filter Chip Widget [P]
**Priority**: Low  
**Estimate**: 3 hours  
**Dependencies**: None

**Description**: Create "Last 24h" filter chip for limiting fire incident time range.

**Requirements**:
- Toggle between different time ranges (24h, 48h, 7d)
- Clear visual indication of active filter
- Integration with service queries

**Files to Create**:
- `lib/widgets/chips/time_filter_chip.dart`

**Acceptance Criteria**:
- [ ] Clear filter state indication
- [ ] Multiple time range options
- [ ] Accessibility labels for filter states
- [ ] Widget tests for filter behavior

## Phase 4: Map Integration (1-2 days)

### Task 15: Update MapController for Fire Incidents
**Priority**: High  
**Estimate**: 8 hours  
**Dependencies**: Task 9, Task 12

**Description**: Enhance existing map controller to manage fire incident display and interaction.

**Requirements**:
- Viewport change detection with debouncing
- Fire incident loading and caching
- Marker tap handling for bottom sheet
- State management for selected incidents

**Files to Modify**:
- `lib/controllers/map_controller.dart` (or create if doesn't exist)

**Acceptance Criteria**:
- [ ] Viewport changes trigger debounced fire incident loading
- [ ] Marker taps open bottom sheet with correct incident
- [ ] State management prevents UI conflicts
- [ ] Performance optimized for smooth map interaction
- [ ] Constitutional compliance (C5: resilience)

### Task 16: Integrate Fire Markers with Map Screen
**Priority**: High  
**Estimate**: 6 hours  
**Dependencies**: Task 13, Task 15

**Description**: Add fire marker rendering to existing map screen infrastructure.

**Requirements**:
- Render FireIncident objects as custom markers
- Handle marker clustering for dense areas (basic)
- Integrate with existing map infrastructure
- Marker tap event handling

**Files to Modify**:
- `lib/screens/home_screen.dart` (or map screen file)

**Acceptance Criteria**:
- [ ] Fire markers display correctly on map
- [ ] Marker taps trigger bottom sheet opening
- [ ] Performance remains smooth with many markers
- [ ] Integration doesn't break existing map features

### Task 17: Integrate Bottom Sheet with Map Screen
**Priority**: High  
**Estimate**: 6 hours  
**Dependencies**: Task 12, Task 16

**Description**: Wire bottom sheet display to marker tap events and map state management.

**Requirements**:
- Bottom sheet opens on marker tap
- Risk level loads when sheet opens
- Distance calculation updates with user location
- Sheet dismissal methods (tap outside, swipe down, close button)

**Files to Modify**:
- `lib/screens/home_screen.dart` (or map screen file)

**Acceptance Criteria**:
- [ ] Smooth bottom sheet opening animation
- [ ] Risk level loads asynchronously without blocking UI
- [ ] Distance updates when user location changes
- [ ] Multiple dismissal methods work correctly
- [ ] No memory leaks on repeated open/close cycles

### Task 18: Add Debounced Viewport Query Logic
**Priority**: Medium  
**Estimate**: 4 hours  
**Dependencies**: Task 15

**Description**: Implement debouncing for viewport changes to prevent API spam during map navigation.

**Requirements**:
- 300ms debounce delay for camera position changes
- Cancel in-flight requests on new viewport queries
- Loading indicators during fetch operations
- Error handling for failed queries

**Files to Create**:
- `lib/utils/debounced_viewport_loader.dart`

**Acceptance Criteria**:
- [ ] Viewport changes debounced to prevent API spam
- [ ] In-flight requests cancelled properly
- [ ] Loading states provide user feedback
- [ ] Error handling shows retry options
- [ ] Performance optimized for smooth map interaction

## Phase 5: Testing Infrastructure (1 day)

### Task 19: Unit Tests - Enhanced FireIncident Model [P]
**Priority**: Medium  
**Estimate**: 3 hours  
**Dependencies**: Task 1

**Description**: Comprehensive unit tests for enhanced FireIncident model with new fields.

**Requirements**:
- Test all new field validation rules
- JSON serialization/deserialization edge cases
- Equality and hashing behavior
- Error handling for invalid data

**Files to Create**:
- `test/unit/models/fire_incident_test.dart` (enhance existing)

**Acceptance Criteria**:
- [ ] >95% code coverage for FireIncident model
- [ ] All validation rules tested with edge cases
- [ ] JSON parsing handles malformed data gracefully
- [ ] Constitutional compliance testing

### Task 20: Unit Tests - ActiveFiresService [P]
**Priority**: Medium  
**Estimate**: 4 hours  
**Dependencies**: Task 6, Task 7

**Description**: Unit tests for both live and mock ActiveFiresService implementations.

**Requirements**:
- Mock HTTP responses for live service testing
- Edge cases: empty responses, malformed data, timeouts
- Feature flag behavior (MAP_LIVE_DATA)
- Cache integration testing

**Files to Create**:
- `test/unit/services/active_fires_service_impl_test.dart`
- `test/unit/services/active_fires_service_mock_test.dart`

**Acceptance Criteria**:
- [ ] >90% code coverage for both service implementations
- [ ] Network error scenarios handled correctly
- [ ] Feature flag behavior verified
- [ ] Cache integration tested thoroughly

### Task 21: Unit Tests - Distance Calculator [P]
**Priority**: Low  
**Estimate**: 2 hours  
**Dependencies**: Task 3

**Description**: Unit tests for distance and bearing calculations.

**Requirements**:
- Test known distance calculations
- Edge cases: same location, poles, date line crossing
- Location permission denied scenarios
- Privacy-compliant logging verification

**Files to Create**:
- `test/unit/utils/distance_calculator_test.dart`

**Acceptance Criteria**:
- [ ] Accurate distance calculations verified against known values
- [ ] Edge cases handled correctly
- [ ] Privacy compliance verified
- [ ] Performance within acceptable limits

### Task 22: Widget Tests - Fire Details Bottom Sheet
**Priority**: High  
**Estimate**: 6 hours  
**Dependencies**: Task 12

**Description**: Comprehensive widget tests for bottom sheet including accessibility verification.

**Requirements**:
- Test all UI states: loading, data, error
- Accessibility compliance verification
- User interaction testing (tap, swipe, etc.)
- Risk level display with official colors

**Files to Create**:
- `test/widget/fire_details_bottom_sheet_test.dart`

**Acceptance Criteria**:
- [ ] All UI states render correctly
- [ ] Accessibility requirements verified (≥44dp, semantic labels)
- [ ] User interactions work as expected
- [ ] Constitutional color compliance verified
- [ ] Error handling UI tested

### Task 23: Widget Tests - Data Source Chips [P]
**Priority**: Low  
**Estimate**: 2 hours  
**Dependencies**: Task 10, Task 11

**Description**: Widget tests for data source and demo data warning chips.

**Requirements**:
- All chip types render correctly
- Accessibility labels verified
- Color compliance testing
- Demo warning prominence verification

**Files to Create**:
- `test/widget/chips/data_source_chip_test.dart`
- `test/widget/chips/demo_data_chip_test.dart`

**Acceptance Criteria**:
- [ ] All chip variants render correctly
- [ ] Accessibility compliance verified
- [ ] Constitutional color requirements met
- [ ] Demo warning visibility confirmed

### Task 24: Integration Tests - Fire Marker Interaction
**Priority**: High  
**Estimate**: 8 hours  
**Dependencies**: Task 16, Task 17

**Description**: End-to-end integration tests for marker tap → bottom sheet flow.

**Requirements**:
- Full user flow testing on Android/iOS
- Mock data mode verification
- Error handling path testing
- Performance benchmarking

**Files to Create**:
- `integration_test/map/fire_marker_interaction_test.dart`

**Acceptance Criteria**:
- [ ] Complete user flow works on Android/iOS
- [ ] Mock data mode properly isolated from network
- [ ] Error scenarios provide appropriate feedback
- [ ] Performance meets <200ms bottom sheet load target
- [ ] Constitutional compliance verified end-to-end

### Task 25: Performance Tests - Viewport Loading
**Priority**: Medium  
**Estimate**: 4 hours  
**Dependencies**: Task 18

**Description**: Performance tests for debounced viewport loading and caching behavior.

**Requirements**:
- Measure viewport query debounce timing
- Cache hit ratio verification
- Memory usage monitoring
- Load testing with many markers

**Files to Create**:
- `test/performance/viewport_loading_test.dart`

**Acceptance Criteria**:
- [ ] Debounce timing within specification (300ms)
- [ ] Cache hit ratio >70% for repeat queries
- [ ] Memory usage stable under load
- [ ] UI remains responsive with 100+ markers

## Phase 6: Documentation and Finalization (0.5 day)

### Task 26: Update Feature Documentation
**Priority**: Medium  
**Estimate**: 2 hours  
**Dependencies**: Task 24

**Description**: Update project documentation with fire information sheet feature details.

**Requirements**:
- Feature overview in main docs
- API documentation updates
- Testing instructions
- Troubleshooting guide

**Files to Create/Modify**:
- `docs/features/fire-information-sheet.md`
- `docs/README.md` (update)

**Acceptance Criteria**:
- [ ] Clear feature description with screenshots
- [ ] Complete API documentation for new services
- [ ] Testing instructions for QA team
- [ ] Troubleshooting guide for common issues

### Task 27: Capture Feature Screenshots
**Priority**: Low  
**Estimate**: 1 hour  
**Dependencies**: Task 24

**Description**: Capture high-quality screenshots of fire information sheet feature for documentation.

**Requirements**:
- Screenshots of bottom sheet in different states
- Demo data mode indicators visible
- Error state examples
- Accessibility features demonstration

**Files to Create**:
- `docs/screenshots/fire-information-sheet/`

**Acceptance Criteria**:
- [ ] High-quality screenshots for all UI states
- [ ] Demo data indicators clearly visible
- [ ] Error states documented visually
- [ ] Accessibility features demonstrated

### Task 28: Constitutional Compliance Audit
**Priority**: High  
**Estimate**: 3 hours  
**Dependencies**: Task 24, Task 25

**Description**: Final audit to verify all constitutional requirements (C1-C5) are met.

**Requirements**:
- Code quality gates verification (flutter analyze, format, tests)
- Secrets and logging compliance check
- Accessibility compliance verification
- Trust and transparency requirements check
- Resilience and error handling verification

**Files to Create**:
- `docs/compliance/fire-information-sheet-audit.md`

**Acceptance Criteria**:
- [ ] All constitutional gates (C1-C5) verified passing
- [ ] No secrets or PII in logs
- [ ] Accessibility requirements 100% compliant
- [ ] Official Scottish colors used exclusively
- [ ] Error handling comprehensive with retry options

## Parallel Execution Strategy

### Can Run in Parallel [P]:
- Task 1, 2, 3, 4 (Models and utilities)
- Task 10, 11, 13, 14 (UI components)
- Task 19, 20, 21, 23 (Unit tests)

### Sequential Dependencies:
- Service layer (Tasks 5→6,7→8→9)
- Map integration (Task 15→16→17)
- Integration testing (requires most components complete)

## Risk Mitigation

### High-Risk Areas:
1. **EFFIS API Integration** (Task 6): Mock-first development, thorough error handling
2. **Map Performance** (Task 16): Incremental testing, marker clustering fallback
3. **Accessibility Compliance** (Task 12, 22): Early testing, design reviews

### Mitigation Strategies:
- Start with mock data for rapid iteration
- Implement error states early
- Regular accessibility testing during development
- Performance monitoring throughout development

## Definition of Done

Each task is complete when:
- [ ] All acceptance criteria met
- [ ] Code passes flutter analyze and dart format
- [ ] Unit/widget tests written with >90% coverage
- [ ] Constitutional compliance verified
- [ ] PR includes screenshots for UI changes
- [ ] Documentation updated as required
- [ ] Integration tests pass on Android/iOS
- [ ] Performance requirements met
- [ ] Accessibility requirements verified