# Tasks: LocationResolver (Low-Friction Location)

**Input**: Design documents from `/specs/004-a4-locationresolver-low/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md: Dart 3.0+ Flutter SDK, geolocator, permission_handler, shared_preferences
2. Load design documents:
   → data-model.md: LatLng, LocationError, ManualLocation entities
   → contracts/: LocationResolver interface with Either<LocationError, LatLng> pattern
   → quickstart.md: 6 user story validation scenarios
3. Generate 4 atomic tasks per user constraints:
   → T001: Core service with GPS fallback chain
   → T002: Manual entry dialog with persistence
   → T003: Comprehensive test coverage
   → T004: Documentation and CI validation
4. Constitutional compliance integrated (C1, C2, C3, C5)
5. TDD approach: Contract tests before implementation
```

## Labels Applied
- **spec:A4**: LocationResolver low-friction location service
- **gate:C1**: Code quality with comprehensive tests
- **gate:C2**: Privacy-compliant coordinate logging (2 decimal precision)
- **gate:C3**: Accessibility compliance (≥44dp targets, semantic labels)
- **gate:C5**: Resilience with graceful fallback chain

---

## T001: LocationResolver Service & Permission Handling
**Files**: `lib/services/location_resolver.dart`, `lib/services/location_resolver_impl.dart`, `lib/models/location_models.dart`
**Labels**: spec:A4, gate:C1, gate:C2, gate:C5

Implement core LocationResolver service with 4-tier fallback strategy and permission handling:

1. **Create data models** in `lib/models/location_models.dart`:
   - `LatLng` class with validation (lat: [-90,90], lon: [-180,180])
   - `LocationError` enum with types: permissionDenied, gpsUnavailable, timeout, invalidInput
   - Export models for service consumption

2. **Create interface** in `lib/services/location_resolver.dart`:
   ```dart
   abstract class LocationResolver {
     Future<Either<LocationError, LatLng>> getLatLon();
     Future<void> saveManual(LatLng location, {String? placeName});
   }
   ```

3. **Implement service** in `lib/services/location_resolver_impl.dart`:
   - Scotland centroid constant: `LatLng(55.8642, -4.2518)`
   - GPS attempt with 2-second timeout using geolocator
   - Permission handling: granted → proceed, denied → fallback
   - Handle deniedForever without crashes
   - Mid-session permission changes handled gracefully
   - Privacy-compliant logging: coordinates limited to 2 decimal places (C2)
   - Fallback chain: GPS → cached → manual → Scotland centroid (C5)

4. **Dependencies setup** in `pubspec.yaml`:
   ```yaml
   dependencies:
     geolocator: ^9.0.2
     permission_handler: ^11.0.1
     shared_preferences: ^2.2.2
     dartz: ^0.10.1
     equatable: ^2.0.5
   ```

5. **Platform configuration**:
   - Add location permissions to Android manifest
   - Add NSLocationWhenInUseUsageDescription to iOS Info.plist

**Acceptance Criteria**:
- [ ] GPS permission granted → returns actual coordinates
- [ ] GPS permission denied → graceful fallback to Scotland centroid
- [ ] Mid-session permission revocation → no crash, immediate fallback
- [ ] GPS timeout (>2s) → fallback to cached or default
- [ ] All coordinate logging limited to 2 decimal precision (C2)
- [ ] Service never fails - always returns Right(LatLng) (C5)

---

## T002: Manual Entry Dialog & SharedPreferences Persistence
**Files**: `lib/widgets/manual_location_dialog.dart`, `lib/services/location_cache.dart`
**Labels**: spec:A4, gate:C1, gate:C3, gate:C5

Implement manual coordinate entry dialog with validation and SharedPreferences persistence:

1. **Create dialog widget** in `lib/widgets/manual_location_dialog.dart`:
   - Two text fields: latitude and longitude
   - Real-time validation for coordinate ranges
   - Touch targets ≥44dp (C3)
   - Semantic labels for screen readers (C3):
     ```dart
     semanticCounterText: 'Latitude coordinate'
     semanticCounterText: 'Longitude coordinate' 
     ```
   - Clear error messages for invalid input
   - Save/Cancel buttons with proper key identifiers

2. **Input validation logic**:
   - Latitude: [-90.0, 90.0] range
   - Longitude: [-180.0, 180.0] range
   - Handle non-numeric input gracefully
   - Visual feedback for invalid ranges
   - Prevent save with invalid coordinates

3. **Create persistence service** in `lib/services/location_cache.dart`:
   - Save coordinates to SharedPreferences
   - Restore coordinates on app restart
   - Handle SharedPreferences corruption gracefully (C5)
   - Cache keys: 'manual_location_lat', 'manual_location_lon', 'manual_location_place'

4. **Integration with LocationResolver**:
   - Manual entry triggered when GPS fails and no cache
   - Successful manual entry persisted immediately
   - Cache checked before manual entry dialog

**Acceptance Criteria**:
- [ ] Dialog accepts valid coordinates (55.9533, -3.1883)
- [ ] Dialog rejects invalid ranges (999, 999) with clear error
- [ ] Touch targets meet 44dp minimum (C3)
- [ ] Semantic labels present for accessibility (C3)
- [ ] Manual location persists across app restart
- [ ] SharedPreferences corruption handled without crash (C5)
- [ ] Dialog integrates with LocationResolver fallback chain

---

## T003: Comprehensive Test Coverage
**Files**: `test/unit/services/location_resolver_test.dart`, `test/widget/manual_location_dialog_test.dart`, `test/integration/location_flow_test.dart`
**Labels**: spec:A4, gate:C1, gate:C3, gate:C5

Create comprehensive test suite covering all fallback scenarios and edge cases:

1. **Unit tests** in `test/unit/services/location_resolver_test.dart`:
   - GPS permission granted → returns GPS coordinates
   - GPS permission denied → returns Scotland centroid
   - GPS permission deniedForever → returns Scotland centroid
   - GPS timeout (>2s) → fallback behavior
   - SharedPreferences corruption → graceful degradation (C5)
   - Mid-session permission revocation → no crash
   - Coordinate validation edge cases
   - Mock geolocator and SharedPreferences for controlled testing

2. **Widget tests** in `test/widget/manual_location_dialog_test.dart`:
   - Valid coordinate input accepted
   - Invalid coordinate input rejected with error
   - Touch target size validation ≥44dp (C3)
   - Semantic label presence (C3)
   - Save/Cancel button behavior
   - Accessibility testing with semantic finders

3. **Integration tests** in `test/integration/location_flow_test.dart`:
   - Complete fallback chain: GPS → cache → manual → default
   - Manual entry persistence across app restart
   - Permission flow testing (granted/denied/deniedForever)
   - Performance validation: <500ms location resolution
   - SharedPreferences performance: <200ms read/write

4. **Test scenarios from quickstart.md**:
   - Story 1: First app launch with GPS available
   - Story 2: GPS permission denied fallback
   - Story 3: Manual location entry and validation
   - Story 4: Manual location persistence
   - Story 5: Invalid input handling
   - Story 6: Mid-session permission changes

**Acceptance Criteria**:
- [ ] Unit test coverage >90% for all service methods
- [ ] Widget tests verify accessibility compliance (C3)
- [ ] Integration tests cover complete fallback chain (C5)
- [ ] Performance tests validate GPS timeout and cache speed
- [ ] All quickstart user stories have corresponding test validation
- [ ] Tests run without external dependencies (mocked GPS/permissions)

---

## T004: Documentation & CI Validation
**Files**: `docs/CONTEXT.md`, `.github/workflows/ci.yml` updates
**Labels**: spec:A4, gate:C1, gate:C2, gate:C5

Update documentation and ensure CI pipeline validates implementation:

1. **Update documentation** in `docs/CONTEXT.md`:
   - Add LocationResolver service description
   - Document fallback chain: GPS → cached → manual → Scotland centroid
   - Include basic flow diagram (optional):
     ```
     Location Request → GPS Available? → Yes → Return GPS
                                      → No → Cache Available? → Yes → Return Cache
                                                              → No → Manual Entry → Return Manual
                                                                                  → Default → Scotland Centroid
     ```
   - Document privacy compliance: coordinate precision limited to 2 decimals
   - Integration guide for other services

2. **Verify CI pipeline** in `.github/workflows/ci.yml`:
   - Ensure `flutter analyze` passes with no warnings (C1)
   - Ensure `dart format --set-exit-if-changed .` passes (C1)
   - Ensure `flutter test` runs all new tests successfully (C1)
   - Add location permissions to test environment if needed

3. **Create usage examples**:
   - Basic integration pattern with FireRiskService
   - Error handling examples
   - Manual entry dialog usage

4. **Constitutional compliance documentation**:
   - C1: Code quality standards and test coverage requirements
   - C2: Privacy-compliant logging examples with coordinate redaction
   - C3: Accessibility features in manual entry dialog
   - C5: Resilience patterns and fallback chain documentation

**Acceptance Criteria**:
- [ ] CI pipeline passes all checks: analyze, format, test
- [ ] Documentation includes fallback chain explanation
- [ ] Usage examples provided for integration
- [ ] Constitutional compliance (C1, C2, C3, C5) documented
- [ ] No flutter analyze warnings or errors
- [ ] All tests pass in CI environment

---

## Dependencies
- **Sequential execution required**: T001 → T002 → T003 → T004
- T001 creates foundation models and service interface
- T002 depends on T001 models and service contract
- T003 requires T001 and T002 implementations to test
- T004 validates complete implementation from T001-T003

## Parallel Opportunities
- Within T001: Models and interface can be created in parallel
- Within T003: Unit tests, widget tests, and integration tests can be developed in parallel after T001-T002
- Within T004: Documentation and CI updates can be done in parallel

## Validation Commands
```bash
# Run all LocationResolver tests
flutter test test/unit/services/location_resolver_test.dart
flutter test test/widget/manual_location_dialog_test.dart  
flutter test test/integration/location_flow_test.dart

# Verify code quality
flutter analyze --no-pub
dart format --set-exit-if-changed .

# Manual testing scenarios
# 1. Fresh install → request location → grant GPS → verify coordinates
# 2. Fresh install → request location → deny GPS → verify Scotland centroid
# 3. Manual entry → enter coordinates → restart app → verify persistence
```

---

**Total**: 4 atomic tasks implementing A4 LocationResolver with constitutional compliance (C1, C2, C3, C5) and comprehensive test coverage.