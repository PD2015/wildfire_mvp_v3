# Tasks: A10 – Google Maps MVP Map

**Input**: Design documents from `/specs/011-a10-google-maps/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅ (fire_location_service.md, map_controller.md)

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Tech stack: google_maps_flutter ^2.5.0, go_router 14.8.1, http, dartz, equatable, ChangeNotifier
   → Structure: Flutter single mobile app (iOS 15+, Android 21+)
2. Load design documents ✅
   → data-model.md: 5 entities (FireIncident, MapState sealed classes, LatLngBounds, queries/responses)
   → contracts/: 2 files → 2 contract test tasks
   → research.md: 8 decisions extracted → setup tasks
3. Generate tasks by category ✅
   → Setup: Google Maps SDK, env config, mock data
   → Tests: contract tests (fire_location_service, map_controller), widget tests, integration tests
   → Core: models, services, controller, UI
   → Integration: EFFIS WFS, LocationResolver, CacheService
   → Polish: performance, a11y, docs
4. Apply task rules ✅
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001-T035) ✅
6. Generate dependency graph ✅
7. Create parallel execution examples ✅
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Flutter project structure:
- **Core**: `lib/features/map/`, `lib/models/`, `lib/services/`
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`, `test/contract/`
- **Fixtures**: `test/fixtures/`, `assets/mock/`
- **Config**: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift`

---

## Phase 3.1: Setup

### T001 [P] Add google_maps_flutter dependency and platform configuration
**Description**: Add `google_maps_flutter: ^2.5.0` to pubspec.yaml, configure Android/iOS platform files for Google Maps SDK.

**Files**:
- `pubspec.yaml` (add dependency)
- `android/app/src/main/AndroidManifest.xml` (add meta-data for API key, location permissions)
- `ios/Runner/Info.plist` (add `<key>GMSApiKey</key><string>...</string>` **or** keep `AppDelegate.swift` with `GMSServices.provideAPIKey`)

**Acceptance Criteria**:
- ✅ google_maps_flutter ^2.5.0 in dependencies
- ✅ Android minSdkVersion ≥21 (already set)
- ✅ iOS platform version ≥15 (already set)
- ✅ API key placeholders configured (no hardcoded keys - C2)
- ✅ Android has `ACCESS_FINE_LOCATION` (and, if needed, `ACCESS_COARSE_LOCATION`) declared; iOS has `NSLocationWhenInUseUsageDescription`
- ✅ flutter pub get succeeds
- ✅ flutter analyze passes (C1)

**Constitutional Gates**: C1 (Code Quality), C2 (Secrets)

---

### T002 [P] Create environment file template and API key documentation
**Description**: Create `env/dev.env.json.template` with Google Maps API key structure, add API key restrictions documentation.

**Files**:
- `env/dev.env.json.template` (new - template only, no real keys)
- `env/.gitignore` (add `*.env.json` to ignore real keys)
- `docs/google-maps-setup.md` (new - key setup instructions)

**Acceptance Criteria**:
- ✅ Template shows `GOOGLE_MAPS_API_KEY_ANDROID` and `GOOGLE_MAPS_API_KEY_IOS` structure
- ✅ Documentation includes key restriction steps (SHA-1 for Android, bundle ID for iOS)
- ✅ Cost alarm setup documented (50% and 80% of free tier)
- ✅ No real API keys committed (C2)
- ✅ gitleaks scan passes (C2)

**Constitutional Gates**: C2 (Secrets & Logging)

---

### T003 [P] Create mock fire data fixtures
**Description**: Create `assets/mock/active_fires.json` with realistic fire incident data for offline testing.

**Files**:
- `assets/mock/active_fires.json` (new)
- `pubspec.yaml` (add assets declaration)

**Acceptance Criteria**:
- ✅ Mock data includes 5-10 fire incidents with valid Scottish coordinates
- ✅ Each incident has id, location, source=mock, freshness=mock, timestamp, intensity
- ✅ GeoJSON format matches EFFIS WFS response structure
- ✅ Timestamps realistic (within last 24 hours)
- ✅ Asset loads successfully in tests

**Constitutional Gates**: C5 (Resilience - mock-first dev principle)

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### T004 [P] Contract test for FireLocationService
**Description**: Create contract test for `FireLocationService.getActiveFires()` covering EFFIS WFS bbox queries, fallback chain, error handling.

**Files**:
- `test/contract/fire_location_service_contract_test.dart` (new)
- `test/fixtures/effis_wfs_burnt_areas_response.json` (new)

**Acceptance Criteria**:
- ✅ Test EFFIS WFS success returns List<FireIncident>
- ✅ Test SEPA fallback when EFFIS times out (Scotland coordinates only)
- ✅ Test Cache fallback returns FireIncident with freshness=cached
- ✅ Test Mock fallback never fails (returns mock data)
- ✅ Test bbox validation (southwest < northeast, lon/lat axis order matches EFFIS WFS expectations)
- ✅ Test 8s timeout per service tier
- ✅ Test coordinate logging uses GeographicUtils.logRedact() (C2)
- ✅ All tests FAIL (implementation doesn't exist yet)

**Constitutional Gates**: C2 (Secrets & Logging), C5 (Resilience)

---

### T005 [P] Contract test for MapController
**Description**: Create contract test for `MapController` covering initialize(), refreshMapData(), checkRiskAt(), state transitions.

**Files**:
- `test/contract/map_controller_contract_test.dart` (new)
- `test/mocks.dart` (add MockFireLocationService, update MockLocationResolver)

**Acceptance Criteria**:
- ✅ Test initialize() → MapLoading → MapSuccess with incidents
- ✅ Test refreshMapData() updates incidents for new bbox
- ✅ Test checkRiskAt() calls FireRiskService (A2)
- ✅ Test MapError state when all services fail (displays cached data if available)
- ✅ Test dispose() cleans up resources
- ✅ Test state transitions follow sealed class hierarchy
- ✅ All tests FAIL (implementation doesn't exist yet)

**Constitutional Gates**: C5 (Resilience - error state handling)

---

### T006 [P] Widget tests for MapScreen with accessibility validation
**Description**: Create widget tests for MapScreen UI, validate ≥44dp touch targets, semantic labels, screen reader support.

**Files**:
- `test/widget/map_screen_test.dart` (new)
- `test/support/a11y_helpers.dart` (extend with map-specific helpers)

**Acceptance Criteria**:
- ✅ Test MapScreen renders GoogleMap widget
- ✅ Test zoom controls are ≥44dp touch target (C3)
- ✅ Test "Check risk here" button is ≥44dp touch target (C3)
- ✅ Test marker info windows have semantic labels (C3)
- ✅ Test loading spinner has semanticLabel (C3)
- ✅ Test source chip displays "EFFIS", "Cached", or "Mock" (C4)
- ✅ Test "Last updated" timestamp visible (C4)
- ✅ All tests FAIL (implementation doesn't exist yet)

**Constitutional Gates**: C3 (Accessibility), C4 (Trust & Transparency)

---

### T007 [P] Integration test for fire marker display flow
**Description**: Create integration test covering full flow: location resolution → fire data fetch → marker display → info window tap.

**Files**:
- `test/integration/map/fire_marker_display_test.dart` (new)

**Acceptance Criteria**:
- ✅ Test complete flow: MockLocationResolver → MockFireLocationService → markers rendered
- ✅ Test marker tap opens info window with fire details
- ✅ Test source chip reflects data source (EFFIS/SEPA/Cache/Mock)
- ✅ Test empty incidents (no fires) displays "No active fires in this region. Pan or zoom to refresh"
- ✅ Test MAP_LIVE_DATA=false uses mock data (default)
- ✅ Test completes in <3s (performance requirement)
- ✅ All tests FAIL (implementation doesn't exist yet)

**Constitutional Gates**: C4 (Trust & Transparency), C5 (Resilience)

---

### T008 [P] Integration test for service fallback chain
**Description**: Create integration test verifying EFFIS → SEPA → Cache → Mock fallback sequence with controllable mock failures.

**Files**:
- `test/integration/map/service_fallback_test.dart` (new)

**Acceptance Criteria**:
- ✅ Test EFFIS timeout (>8s) falls back to SEPA (Scotland coords only)
- ✅ Test SEPA failure falls back to Cache (returns cached incidents with freshness=cached)
- ✅ Test Cache empty falls back to Mock (never fails)
- ✅ Test non-Scotland coordinates skip SEPA (EFFIS → Cache → Mock)
- ✅ Test each tier respects 8s timeout
- ✅ Test telemetry records all attempts (EffisAttempt, SepaAttempt, CacheHit, MockFallback)
- ✅ All tests FAIL (implementation doesn't exist yet)

**Constitutional Gates**: C5 (Resilience & Test Coverage)

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### T009 [P] Implement FireIncident model
**Description**: Create FireIncident data model with validation per data-model.md specification.

**Files**:
- `lib/models/fire_incident.dart` (new)
- `test/unit/models/fire_incident_test.dart` (new)

**Acceptance Criteria**:
- ✅ Implements Equatable for value equality
- ✅ Fields: id, location (LatLng), source (DataSource enum), freshness (Freshness enum), timestamp, intensity, description?, areaHectares?
- ✅ Validation: id non-empty, valid coordinates, timestamp not future, intensity in ["low","moderate","high"]
- ✅ fromJson() factory for EFFIS WFS GeoJSON parsing
- ✅ toJson() for caching
- ✅ Unit tests pass
- ✅ Contract tests T004 now have some passing assertions

**Constitutional Gates**: C1 (Code Quality)

---

### T010 [P] Implement MapState sealed class hierarchy
**Description**: Create MapState sealed class with MapLoading, MapSuccess, MapError concrete states per data-model.md.

**Files**:
- `lib/models/map_state.dart` (new)
- `test/unit/models/map_state_test.dart` (new)

**Acceptance Criteria**:
- ✅ Sealed base class MapState extends Equatable
- ✅ MapLoading: empty state
- ✅ MapSuccess: incidents (List<FireIncident>), centerLocation (LatLng), freshness (Freshness), lastUpdated (DateTime)
- ✅ MapError: message (String), cachedIncidents? (List<FireIncident>?), lastKnownLocation? (LatLng?)
- ✅ Validation: MapSuccess requires valid centerLocation, MapError requires non-empty message
- ✅ Unit tests pass
- ✅ Contract tests T005 now have some passing assertions

**Constitutional Gates**: C1 (Code Quality)

---

### T011 [P] Implement LatLngBounds model
**Description**: Create LatLngBounds model for bbox queries per data-model.md.

**Files**:
- `lib/models/lat_lng_bounds.dart` (new)
- `test/unit/models/lat_lng_bounds_test.dart` (new)

**Acceptance Criteria**:
- ✅ Fields: southwest (LatLng), northeast (LatLng)
- ✅ Validation: southwest < northeast in both dimensions
- ✅ toBboxString() returns EFFIS WFS format: "{minLon},{minLat},{maxLon},{maxLat}"
- ✅ contains(LatLng point) returns bool
- ✅ intersects(LatLngBounds other) returns bool
- ✅ Unit tests pass including edge cases (equator, prime meridian, poles)

**Constitutional Gates**: C1 (Code Quality)

---

### T012 Implement FireLocationService with 4-tier fallback
**Description**: Implement FireLocationService per contract, orchestrating EFFIS WFS → SEPA → Cache → Mock fallback chain.

**Files**:
- `lib/services/fire_location_service.dart` (interface - new)
- `lib/services/fire_location_service_impl.dart` (implementation - new)
- `lib/services/mock_fire_service.dart` (new - loads assets/mock/active_fires.json)

**Acceptance Criteria**:
- ✅ Tier 1: EFFIS WFS bbox query (reuse EffisService from A1, add WFS method)
- ✅ Tier 2: SEPA fallback (Scotland coordinates only via GeographicUtils.isInScotland)
- ✅ Tier 3: Cache lookup via CacheService (A5) with 6h TTL
- ✅ Tier 4: Mock service loads assets/mock/active_fires.json (never fails)
- ✅ Each tier respects 8s timeout
- ✅ Logging uses GeographicUtils.logRedact() for coordinates (C2)
- ✅ Returns Either<ServiceError, List<FireIncident>>
- ✅ Contract tests T004 now fully pass

**Constitutional Gates**: C2 (Secrets & Logging), C5 (Resilience)

---

### T013 Implement MapController with ChangeNotifier
**Description**: Implement MapController per contract, managing MapState transitions and orchestrating services.

**Files**:
- `lib/features/map/controllers/map_controller.dart` (new)
- `lib/features/map/` directory structure (create if needed)

**Acceptance Criteria**:
- ✅ Extends ChangeNotifier
- ✅ Dependency injection: LocationResolver (A4), FireLocationService (A10), FireRiskService (A2), CacheService? (A5), ConstitutionLogger?
- ✅ initialize() → resolves location → fetches fires → emits MapSuccess
- ✅ refreshMapData(LatLngBounds) → fetches fires for bbox → updates state
- ✅ checkRiskAt(LatLng) → calls FireRiskService.getCurrent() → returns RiskAssessmentResult
- ✅ State transitions: MapLoading → MapSuccess/MapError
- ✅ dispose() cleans up listeners
- ✅ Contract tests T005 now fully pass

**Constitutional Gates**: C5 (Resilience - error state management)

---

### T014 Implement MapScreen UI with GoogleMap widget
**Description**: Create MapScreen stateful widget rendering GoogleMap, markers, controls, info windows.

**Files**:
- `lib/features/map/screens/map_screen.dart` (new)
- `lib/features/map/widgets/fire_marker_info_window.dart` (new)
- `lib/features/map/widgets/map_source_chip.dart` (new)

**Acceptance Criteria**:
- ✅ Renders GoogleMap widget with user location marker
- ✅ Displays fire incident markers (use flame icon)
- ✅ Marker tap opens FireMarkerInfoWindow with details
- ✅ Shows MapSourceChip ("EFFIS", "Cached", "Mock") based on freshness (C4)
- ✅ Shows "Last updated: [UTC time]" in ISO-8601 format truncated to minutes (C4)
- ✅ Loading state shows centered CircularProgressIndicator with semanticLabel (C3)
- ✅ Error state shows SnackBar with message + cached data if available
- ✅ Widget tests T006 now fully pass

**Constitutional Gates**: C3 (Accessibility), C4 (Trust & Transparency)

---

### T015 [P] Implement "Check risk here" button and risk assessment UI
**Description**: Add floating action button for point risk assessment, integrate with FireRiskService (A2), display risk chip.

**Files**:
- `lib/features/map/widgets/risk_check_button.dart` (new)
- `lib/features/map/widgets/risk_result_chip.dart` (new)

**Acceptance Criteria**:
- ✅ FloatingActionButton with ≥44dp touch target (C3)
- ✅ Button has semanticLabel "Check fire risk at this location" (C3)
- ✅ On tap: calls MapController.checkRiskAt(map center or long-press location)
- ✅ Displays RiskResultChip with Scottish colour tokens (C4)
- ✅ Shows risk level, FWI value, "Last updated" timestamp in ISO-8601 format truncated to minutes (C4)
- ✅ Shows source ("EFFIS", "SEPA", "Cached", "Mock") (C4)
- ✅ Widget tests validate accessibility

**Constitutional Gates**: C3 (Accessibility), C4 (Trust & Transparency)

---

## Phase 3.4: Integration

### T016 Add EFFIS WFS method to EffisService
**Description**: Extend existing EffisService (A1) to support WFS burnt_areas_current_year layer with bbox queries.

**Files**:
- `lib/services/effis_service.dart` (extend interface)
- `lib/services/effis_service_impl.dart` (add getActiveFires method)
- `test/unit/services/effis_service_test.dart` (add WFS tests)

**Acceptance Criteria**:
- ✅ New method: `Future<Either<ApiError, List<FireIncident>>> getActiveFires(LatLngBounds bounds)`
- ✅ Base URL and layer name read from env (`EFFIS_BASE_URL`, `EFFIS_WFS_LAYER_ACTIVE`)
- ✅ Example shape: `/wfs?service=WFS&version=2.0.0&request=GetFeature&typeName=$EFFIS_WFS_LAYER_ACTIVE&outputFormat=application/json&bbox={bbox}`
- ✅ Parses GeoJSON FeatureCollection → List<FireIncident>
- ✅ 8s timeout
- ✅ Error handling (network errors, parse errors)
- ✅ Logging uses GeographicUtils.logRedact() (C2)
- ✅ Contract fixture parsing validated against `test/fixtures/effis_wfs_burnt_areas_response.json`
- ✅ Unit tests pass

**Constitutional Gates**: C2 (Secrets & Logging), C5 (Resilience)

---

### T017 Wire MapScreen into app navigation with go_router
**Description**: Add MapScreen route to app navigation, update bottom nav to include map tab.

**Files**:
- `lib/app.dart` (update GoRouter routes)
- `lib/widgets/bottom_nav.dart` (add map icon)
- `lib/screens/home_screen.dart` (update navigation flow if needed)

**Acceptance Criteria**:
- ✅ Route: `/map` → MapScreen
- ✅ Bottom navigation includes map icon (third tab)
- ✅ Deep link support: `wildfire://map`
- ✅ Navigation preserves MapController state (via Provider or dependency injection)
- ✅ Back button from MapScreen returns to HomeScreen
- ✅ Integration test verifies navigation

**Constitutional Gates**: C1 (Code Quality)

---

### T018 Integrate CacheService for fire incident caching
**Description**: Connect FireLocationService to CacheService (A5) for 6h TTL fire incident caching.

**Files**:
- `lib/services/fire_location_service_impl.dart` (add cache integration)
- `lib/services/cache/fire_incident_cache.dart` (new - adapter for CacheService<FireIncident>)

**Acceptance Criteria**:
- ✅ Cache key: geohash of bbox center (precision 5 = ~4.9km)  
  _Note:_ Acceptable for MVP; may over-reuse cache across large map pans. Consider viewport-corners hashing in A11+ if needed.
- ✅ TTL: 6 hours
- ✅ Cache hit returns List<FireIncident> with freshness=cached
- ✅ Cache miss proceeds to Mock fallback
- ✅ Cache stores EFFIS/SEPA data after successful fetch
- ✅ LRU eviction when cache reaches 100 entries
- ✅ Integration test verifies cache behavior

**Constitutional Gates**: C5 (Resilience)

---

### T019 Add MAP_LIVE_DATA feature flag support
**Description**: Implement feature flag to control live EFFIS data vs mock data usage.

**Files**:
- `lib/config/feature_flags.dart` (extend with MAP_LIVE_DATA)
- `lib/services/fire_location_service_impl.dart` (respect feature flag)
- `lib/main.dart` (read `--dart-define=MAP_LIVE_DATA`)

**Acceptance Criteria**:
- ✅ Feature flag: `const bool mapLiveData = bool.fromEnvironment('MAP_LIVE_DATA', defaultValue: false);`
- ✅ When false: FireLocationService skips EFFIS/SEPA, goes directly to Mock
- ✅ When true: FireLocationService uses full fallback chain (EFFIS → SEPA → Cache → Mock)
- ✅ Widget shows "Demo Data" chip when mock active (C4)
- ✅ CI and tests default to MAP_LIVE_DATA=false via `--dart-define-from-file=env/ci.env.json`
- ✅ Documentation updated with flag usage

**Constitutional Gates**: C4 (Trust & Transparency), C5 (Mock-first dev principle)

---

## Phase 3.5: Polish

### T020 [P] Implement lazy marker rendering for performance
**Description**: Optimize marker rendering to handle ≤50 markers without jank, implement clustering toggle for >50.

**Files**:
- `lib/features/map/widgets/map_markers.dart` (new - marker rendering logic)
- `lib/features/map/controllers/map_controller.dart` (add marker clustering logic)

**Acceptance Criteria**:
- ✅ Render only markers within visible bounds + padding
- ✅ Debounce camera idle events (1s) before refreshing markers
- ✅ When >50 markers: show "Enable clustering" toggle
- ✅ Clustering groups nearby markers into numbered cluster icons
- ✅ Performance test: 50 markers render in <3s, 60fps maintained
- ✅ Memory footprint ≤75MB on MapScreen

**Constitutional Gates**: C5 (Resilience - performance requirement)

---

### T021 [P] Accessibility audit and contrast validation
**Description**: Run full accessibility audit, validate Scottish colour token contrast ratios, ensure all interactive elements meet C3 requirements.

**Files**:
- `test/widget/a11y_audit_test.dart` (extend with MapScreen checks)
- `scripts/color_guard.sh` (run against map UI colors)

**Acceptance Criteria**:
- ✅ All touch targets ≥44dp (iOS) / ≥48dp (Android) (C3)
- ✅ Zoom controls, markers, buttons pass touch target test
- ✅ All interactive elements have semanticLabels (C3)
- ✅ Scottish colour tokens have ≥4.5:1 contrast ratio verified by script or unit snapshot (C4)
- ✅ Risk chips readable on map background
- ✅ Screen reader test: VoiceOver (iOS) and TalkBack (Android) announce all elements correctly
- ✅ color_guard.sh passes (no unauthorized colors)

**Constitutional Gates**: C3 (Accessibility), C4 (Trust & Transparency)

---

### T022 [P] Unit tests for FireIncident, MapState, LatLngBounds
**Description**: Comprehensive unit tests for all data models covering validation, equality, serialization.

**Files**:
- `test/unit/models/fire_incident_test.dart` (extend)
- `test/unit/models/map_state_test.dart` (extend)
- `test/unit/models/lat_lng_bounds_test.dart` (extend)

**Acceptance Criteria**:
- ✅ FireIncident: validation rules, fromJson/toJson edge cases, Equatable behavior
- ✅ MapState: sealed class exhaustiveness, state transitions, Equatable behavior
- ✅ LatLngBounds: validation, toBboxString formats, contains/intersects edge cases
- ✅ Test edge cases: equator, prime meridian, date line, poles, null optionals
- ✅ All unit tests pass
- ✅ Code coverage ≥80% for models

**Constitutional Gates**: C1 (Code Quality), C5 (Test Coverage)

---

### T023 [P] Integration test for complete map interaction flow
**Description**: End-to-end integration test covering location → fires → marker tap → risk check → refresh.

**Files**:
- `test/integration/map/complete_map_flow_test.dart` (new)

**Acceptance Criteria**:
- ✅ Test full flow: app launch → navigate to map → see markers → tap marker → check risk → pan map → refresh
- ✅ Test GPS denied fallback (Scotland centroid from LocationResolver A4)
- ✅ Test network timeout → cached data displayed
- ✅ Test empty region (no fires)
- ✅ Test completes in <8s (global deadline requirement)
- ✅ Test memory stable (no leaks after 3 cycles)

**Constitutional Gates**: C5 (Resilience)

---

### T024 [P] Performance smoke tests
**Description**: Automated performance tests validating map load time, frame rate, memory usage.

**Files**:
- `test/performance/map_performance_test.dart` (new)

**Acceptance Criteria**:
- ✅ Map interactive in ≤3s from tap (A10 requirement)
- ✅ 50 markers render within frame budget (measure raster/UI frame build times via timeline summary rather than raw FPS)
- ✅ Memory usage ≤75MB on MapScreen
- ✅ Camera movements smooth (no dropped frames)
- ✅ Service timeout ≤8s per tier (inherited from A2)
- ✅ Tests run in CI on Android emulator

**Constitutional Gates**: C5 (Resilience - performance requirements)

---

### T025 [P] Documentation: Google Maps setup guide
**Description**: Create comprehensive documentation for Google Maps API key setup, restrictions, cost monitoring.

**Files**:
- `docs/google-maps-setup.md` (extend T002 doc)
- `docs/effis-wfs-integration.md` (new)
- `README.md` (update with A10 section)

**Acceptance Criteria**:
- ✅ Step-by-step API key creation (Android + iOS)
- ✅ Key restriction setup (SHA-1 fingerprint, bundle ID)
- ✅ Cost monitoring alarm setup (50% and 80% thresholds)
- ✅ EFFIS WFS endpoint documentation
- ✅ MAP_LIVE_DATA feature flag usage
- ✅ Troubleshooting section (API key errors, quota exceeded, EFFIS timeouts)

**Constitutional Gates**: C2 (Secrets management documentation)

---

### T026 [P] EFFIS operational runbook
**Description**: Create runbook for EFFIS endpoint monitoring, failures, data quality issues.

**Files**:
- `docs/runbooks/effis-monitoring.md` (new)

**Acceptance Criteria**:
- ✅ Weekly EFFIS endpoint health check procedure
- ✅ Response time monitoring (baseline: <3s)
- ✅ Data freshness validation (burnt_areas_current_year updates daily)
- ✅ Fallback chain verification (SEPA → Cache → Mock)
- ✅ Incident response: EFFIS down → notify users, rely on Cache
- ✅ Operator action: "Flip to Cached/Mock" procedure with Slack/StatusPage template snippet
- ✅ Contact escalation path (EFFIS support)

**Constitutional Gates**: C5 (Resilience)

---

### T027 [P] Privacy and accessibility compliance statements
**Description**: Document privacy compliance (coordinate logging) and accessibility features (touch targets, screen readers).

**Files**:
- `docs/privacy-compliance.md` (extend with A10 map data)
- `docs/accessibility-statement.md` (extend with map features)

**Acceptance Criteria**:
- ✅ Privacy: Coordinate logging uses GeographicUtils.logRedact() (2dp precision) - C2
- ✅ Privacy: Logs include geohash + redacted coords only, never raw lat/lon or device IDs
- ✅ Privacy: No fire location data stored locally (cache only for performance)
- ✅ Accessibility: All touch targets ≥44dp documented - C3
- ✅ Accessibility: Screen reader support documented (semantic labels) - C3
- ✅ Accessibility: Scottish colour contrast ratios documented - C4
- ✅ Constitutional gates C1-C5 compliance summary

**Constitutional Gates**: C2 (Secrets & Logging), C3 (Accessibility), C4 (Trust & Transparency)

---

## Dependencies

### Setup Phase (T001-T003) - Must complete first
- T001 blocks T004-T027 (SDK required for all work)
- T002 blocks T019 (feature flag needs env setup)
- T003 blocks T012 (MockFireService needs mock data)

### Tests Phase (T004-T008) - Must complete before implementation
- T004-T008 are [P] (can run in parallel, different files)
- T004-T008 block T009-T015 (TDD: tests must fail before implementation)

### Core Implementation (T009-T015)
- T009-T011 are [P] (models in different files)
- T009 blocks T012 (FireLocationService needs FireIncident model)
- T010 blocks T013 (MapController needs MapState)
- T011 blocks T012 (FireLocationService needs LatLngBounds)
- T012 blocks T013 (MapController depends on FireLocationService)
- T013 blocks T014 (MapScreen uses MapController)
- T014 blocks T015 (risk check button is part of MapScreen)

### Integration Phase (T016-T019)
- T016 blocks T012 (FireLocationService uses EFFIS WFS)
- T017 after T014 (navigation after MapScreen exists)
- T018 after T012 (cache integration after FireLocationService)
- T019 after T012 (feature flag after FireLocationService)

### Polish Phase (T020-T027)
- T020-T027 are mostly [P] (different files)
- T020 after T014 (marker rendering optimization after basic UI)
- T021 after T014-T015 (a11y audit after all UI components)
- T022-T024 can start after T009-T011 (test models as they're created)
- T025-T027 can start anytime (documentation)

---

## Parallel Execution Examples

### Example 1: Setup phase (all parallel)
```bash
# Run all setup tasks in parallel (different files, no dependencies after SDK install)
# T001 must complete first, then:
Task T002 "Create environment file template and API key documentation"
Task T003 "Create mock fire data fixtures"
```

### Example 2: Test phase (all parallel after setup)
```bash
# Run all test creation tasks in parallel (TDD: write failing tests first)
Task T004 "Contract test for FireLocationService"
Task T005 "Contract test for MapController"
Task T006 "Widget tests for MapScreen with accessibility validation"
Task T007 "Integration test for fire marker display flow"
Task T008 "Integration test for service fallback chain"
```

### Example 3: Core models (parallel)
```bash
# Run model creation in parallel (different files)
Task T009 "Implement FireIncident model"
Task T010 "Implement MapState sealed class hierarchy"
Task T011 "Implement LatLngBounds model"
```

### Example 4: Polish phase (mostly parallel)
```bash
# Run polish tasks in parallel after core implementation
Task T020 "Implement lazy marker rendering for performance"
Task T021 "Accessibility audit and contrast validation"
Task T022 "Unit tests for FireIncident, MapState, LatLngBounds"
Task T025 "Documentation: Google Maps setup guide"
Task T026 "EFFIS operational runbook"
Task T027 "Privacy and accessibility compliance statements"
```

---

## Constitutional Compliance Checklist

### C1. Code Quality & Tests
- T001: flutter analyze configuration
- T004-T008: Contract and integration tests
- T022: Unit test coverage ≥80%
- All tasks: dart format before commit

### C2. Secrets & Logging
- T002: No API keys in repo, .gitignore enforcement
- T012, T016: GeographicUtils.logRedact() for coordinates
- T019: Feature flag for mock-first testing
- T025: Secret management documentation

### C3. Accessibility
- T006: Widget tests validate ≥44dp touch targets
- T014: Semantic labels for screen readers
- T015: Risk check button accessibility
- T021: Full accessibility audit
- T027: Accessibility compliance statement

### C4. Trust & Transparency
- T014: Source chips ("EFFIS", "Cached", "Mock")
- T014: "Last updated" timestamps visible
- T015: Risk level display with Scottish colors
- T019: "Demo Data" chip when mock active
- T021: Color contrast validation
- T027: Trust & transparency documentation

### C5. Resilience & Test Coverage
- T003: Mock data for offline testing
- T004, T008: Service fallback chain tests
- T012: 4-tier fallback (EFFIS → SEPA → Cache → Mock)
- T013: MapError state with cached data display
- T018: 6h cache TTL with LRU eviction
- T020: Performance optimization (≤50 markers, 60fps)
- T023: End-to-end integration test
- T024: Performance smoke tests
- T026: EFFIS monitoring runbook

---

## Task Execution Summary

**Total Tasks**: 27  
**Parallel Tasks**: 15 (marked [P])  
**Sequential Tasks**: 12  
**Estimated Duration**: 
- Setup (T001-T003): 1-2 days
- Tests (T004-T008): 2-3 days (parallel)
- Core (T009-T015): 4-5 days (some parallel)
- Integration (T016-T019): 2-3 days
- Polish (T020-T027): 2-3 days (mostly parallel)
- **Total**: 11-16 days with parallelization

**Risk Mitigation**:
- Mock data (T003) enables development before EFFIS integration
- TDD approach (T004-T008 before T009-T015) catches design issues early
- Feature flag (T019) allows staged rollout
- Comprehensive test coverage (T004-T008, T022-T024) ensures stability

**Next Steps**:
1. Create feature branch: `git checkout -b 011-a10-google-maps`
2. Run constitution gates: `.specify/scripts/bash/constitution-gates.sh`
3. Execute tasks in dependency order, marking [P] tasks for parallel execution
4. Commit after each task with conventional commit messages (feat:, test:, docs:, refactor:)
5. Final review: Run all tests, flutter analyze, constitution gates before merge
