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

## T000: Privacy/Logging Helper
**Files**: `lib/utils/location_utils.dart`
**Labels**: spec:A4, gate:C2

Create privacy-compliant logging helper to prove Gate C2 compliance:

1. **Create logging utility** in `lib/utils/location_utils.dart`:
   ```dart
   class LocationUtils {
     /// Privacy-compliant coordinate logging with 2 decimal precision
     /// Prevents PII exposure in logs per Gate C2 requirements
     static String logRedact(double lat, double lon) {
       return '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
     }
     
     /// Validate coordinate ranges
     static bool isValidCoordinate(double lat, double lon) {
       return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
     }
   }
   ```

2. **Integration in LocationResolver**:
   - Replace all raw coordinate logging with `LocationUtils.logRedact(lat, lon)`
   - Ensure no debug prints or error messages expose full precision coordinates
   - Add to export statements for service consumption

3. **Test coverage requirements**:
   - Unit tests verify logRedact() output format (exactly 2 decimal places)
   - Integration tests scan all log output to ensure no raw coordinates leak
   - Test edge cases: negative coordinates, extreme values, precision boundaries

**Acceptance Criteria**:
- [x] logRedact() always outputs exactly 2 decimal places
- [x] No raw coordinates (>2 decimal precision) appear in any logs
- [x] Edge cases tested: (-90.123456, 180.987654) → "-90.12,180.99"
- [x] All LocationResolver logging uses logRedact() helper
- [x] Tests verify log output contains no PII coordinate exposure

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
     Future<Either<LocationError, LatLng>> getLatLon({bool allowDefault = true});
     Future<void> saveManual(LatLng location, {String? placeName});
   }
   ```

3. **Implement service** in `lib/services/location_resolver_impl.dart`:
   - Scotland centroid constant: `LatLng(56.5, -4.2)` (rural central location)
   - Web/emulator guard: skip GPS attempts on unsupported platforms
   - 5-tier fallback chain with 2.5s total resolution budget:
     1. Last known device position (instant, via `getLastKnownPosition()`)
     2. GPS fix with 2-second timeout using geolocator
     3. SharedPreferences cached manual location
     4. Manual entry (caller responsibility - return Left if allowDefault=false)
     5. Scotland centroid (only if allowDefault=true)
   - Permission handling: granted → proceed, denied → fallback
   - Handle deniedForever without crashes
   - Mid-session permission changes handled gracefully
   - Privacy-compliant logging via `logRedact(lat, lon)` helper (C2)
   - Headless service: no UI coupling, caller handles manual entry dialogs

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
- [ ] Last known position available → returns immediately (<100ms)
- [ ] GPS permission granted → returns GPS coordinates within 2s timeout
- [ ] GPS permission denied + allowDefault=true → returns Scotland centroid
- [ ] GPS permission denied + allowDefault=false → returns Left(permissionDenied)
- [ ] Web/emulator platform → skips GPS, uses cache/manual/default path
- [ ] Mid-session permission revocation → no crash, immediate fallback
- [ ] GPS timeout (>2s) → fallback within 2.5s total budget
- [ ] All coordinate logging via logRedact() helper (C2)
- [ ] Headless service: no UI coupling, caller triggers manual entry (C5)

---

## T002: Manual Entry Dialog & SharedPreferences Persistence
**Files**: `lib/widgets/manual_location_dialog.dart`, `lib/services/location_cache.dart`
**Labels**: spec:A4, gate:C1, gate:C3, gate:C5

Implement manual coordinate entry dialog with validation and SharedPreferences persistence:

1. **Create dialog widget** in `lib/widgets/manual_location_dialog.dart`:
   - Two text fields: latitude and longitude with proper input formatters:
     ```dart
     keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true)
     inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))]
     ```
   - Real-time validation for coordinate ranges
   - Touch targets ≥44dp with proper semantic labels (C3):
     ```dart
     Semantics(
       label: 'Latitude coordinate input',
       child: TextField(...)
     )
     ```
   - Clear error messages for invalid input
   - Save/Cancel buttons ≥44dp with semantic labels and key identifiers

2. **Input validation logic**:
   - Latitude: [-90.0, 90.0] range
   - Longitude: [-180.0, 180.0] range
   - Handle non-numeric input gracefully
   - Visual feedback for invalid ranges
   - Prevent save with invalid coordinates

3. **Create persistence service** in `lib/services/location_cache.dart`:
   - Save coordinates to SharedPreferences with version field
   - Restore coordinates on app restart with version compatibility check
   - Handle SharedPreferences corruption gracefully (C5)
   - Cache keys with version: 
     - 'manual_location_version': '1.0' (for format compatibility)
     - 'manual_location_lat': double value
     - 'manual_location_lon': double value  
     - 'manual_location_place': string (optional display name)
     - 'manual_location_timestamp': int (milliseconds since epoch)

4. **Integration with LocationResolver**:
   - Manual entry is invoked by the caller (e.g., Home), not by the service
   - A6/Home receives Left(permissionDenied|timeout) → opens ManualLocationDialog
   - Successful manual entry persisted immediately via saveManual()
   - Cache checked by service before returning Left to trigger manual entry

**Acceptance Criteria**:
- [ ] Dialog accepts valid coordinates (55.9533, -3.1883) with proper input formatters
- [ ] Dialog rejects invalid ranges (999, 999) with clear error messages
- [ ] All touch targets (fields, buttons) meet 44dp minimum (C3)
- [ ] Proper Semantics labels for screen readers, not semanticCounterText (C3)
- [ ] Manual location persists across app restart with version compatibility
- [ ] SharedPreferences corruption handled without crash (C5)
- [ ] Dialog is triggered by A6/Home on Left(LocationError), not by service itself

---

## T003: Comprehensive Test Coverage
**Files**: `test/unit/services/location_resolver_test.dart`, `test/widget/manual_location_dialog_test.dart`, `test/integration/location_flow_test.dart`
**Labels**: spec:A4, gate:C1, gate:C3, gate:C5

Create comprehensive test suite covering all fallback scenarios and edge cases:

1. **Unit tests** in `test/unit/services/location_resolver_test.dart`:
   - Last known position available → returns immediately (<100ms with fakes)
   - GPS permission granted → returns GPS coordinates
   - GPS permission denied + allowDefault=true → returns Scotland centroid
   - GPS permission denied + allowDefault=false → returns Left(permissionDenied)
   - GPS permission deniedForever + allowDefault=false → returns Left(permissionDenied)
   - GPS timeout (>2s) within 2.5s total budget → fallback behavior
   - Web/emulator platform → skips GPS calls, uses cache/manual/default path
   - SharedPreferences corruption → graceful degradation (C5)
   - Mid-session permission revocation → no crash
   - Coordinate validation edge cases
   - Mock geolocator and SharedPreferences for controlled testing
   - logRedact() helper never exposes raw coordinates in logs

2. **Widget tests** in `test/widget/manual_location_dialog_test.dart`:
   - Valid coordinate input accepted with input formatters
   - Invalid coordinate input rejected with clear error messages
   - Input formatters prevent invalid characters (letters, multiple decimals)
   - Touch target size validation ≥44dp for all interactive elements (C3)
   - Proper Semantics labels (not semanticCounterText) for screen readers (C3)
   - Save/Cancel button behavior with semantic labels
   - Keyboard type validation (numberWithOptions)
   - Accessibility testing with semantic finders and talkback simulation

3. **Integration tests** in `test/integration/location_flow_test.dart`:
   - Complete 5-tier fallback chain: last known → GPS → cache → manual → default
   - allowDefault=true flow: returns Scotland centroid when no manual entry available
   - allowDefault=false flow: returns Left to trigger manual entry dialog
   - Manual entry persistence across app restart with version compatibility
   - Permission flow testing (granted/denied/deniedForever)
   - Performance validation with fakes: <500ms total resolution, <100ms last known
   - 2.5s total budget enforcement using controlled fake timers
   - SharedPreferences performance: <200ms read/write operations
   - Web platform integration: skips GPS, uses alternative paths

4. **Test scenarios from quickstart.md**:
   - Story 1: First app launch with GPS available
   - Story 2: GPS permission denied fallback
   - Story 3: Manual location entry and validation
   - Story 4: Manual location persistence
   - Story 5: Invalid input handling
   - Story 6: Mid-session permission changes

**Acceptance Criteria**:
- [ ] Unit test coverage >90% for all service methods including allowDefault scenarios
- [ ] Widget tests verify accessibility compliance with proper Semantics (C3)
- [ ] Integration tests cover complete 5-tier fallback chain (C5)
- [ ] Performance tests use fakes to validate budgets without CI flakiness
- [ ] logRedact() helper tested to ensure no raw coordinates in logs (C2)
- [ ] Web/emulator platform tests verify GPS calls are skipped
- [ ] All quickstart user stories have corresponding test validation
- [ ] Tests run without external dependencies (mocked GPS/permissions/platform)

---

## T004: Documentation & CI Validation
**Files**: `docs/CONTEXT.md`, `.github/workflows/ci.yml` updates
**Labels**: spec:A4, gate:C1, gate:C2, gate:C5

Update documentation and ensure CI pipeline validates implementation:

1. **Update documentation** in `docs/CONTEXT.md`:
   - Add LocationResolver service description with headless architecture
   - Document 5-tier fallback chain with allowDefault parameter:
     ```
     Location Request → Last Known Available? → Yes → Return Last Known
                                              → No → GPS Available? → Yes → Return GPS
                                                                  → No → Cache Available? → Yes → Return Cache
                                                                                          → No → allowDefault? → Yes → Scotland Centroid
                                                                                                               → No → Left(LocationError)
     ```
   - Document Scotland centroid choice: LatLng(56.5, -4.2) for rural/central bias avoidance
   - Document privacy compliance via logRedact(lat, lon) helper
   - Integration guide: A6/Home handles Left(LocationError) → ManualLocationDialog
   - Persistence semantics with version compatibility and graceful corruption handling

2. **Verify CI pipeline** in `.github/workflows/ci.yml`:
   - Ensure `flutter analyze` passes with no warnings (C1)
   - Ensure `dart format --set-exit-if-changed .` passes (C1)
   - Ensure `flutter test` runs all new tests successfully (C1)
   - Add location permissions to test environment if needed

3. **Create usage examples**:
   - Basic integration pattern with FireRiskService using allowDefault parameter
   - Error handling examples for Left(LocationError) responses
   - Manual entry dialog triggered by A6/Home, not service
   - logRedact() helper usage for privacy-compliant logging:
     ```dart
     // CORRECT: Privacy-preserving logging
     _logger.info('Location resolved: ${logRedact(lat, lon)}');
     // Outputs: "Location resolved: 56.50,-4.20"
     
     // WRONG: Raw coordinates expose PII
     _logger.info('Location: $lat,$lon'); // Violates C2 gate
     ```

4. **Constitutional compliance documentation**:
   - C1: Code quality standards and test coverage requirements
   - C2: Privacy-compliant logging examples with coordinate redaction
   - C3: Accessibility features in manual entry dialog
   - C5: Resilience patterns and fallback chain documentation

**Acceptance Criteria**:
- [ ] CI pipeline passes all checks: analyze, format, test
- [ ] Documentation includes 5-tier fallback chain with allowDefault explanation
- [ ] Scotland centroid choice (56.5, -4.2) documented as rural/central
- [ ] logRedact() helper usage examples demonstrate C2 compliance
- [ ] Persistence semantics with version compatibility documented
- [ ] A6/Home integration patterns for headless service documented
- [ ] Constitutional compliance (C1, C2, C3, C5) with concrete examples
- [ ] No flutter analyze warnings or errors
- [ ] All tests pass in CI environment

---

## Dependencies
- **Sequential execution required**: T000 → T001 → T002 → T003 → T004
- T000 creates privacy/logging utilities used by all other tasks
- T001 creates foundation models and service interface, uses T000 utilities
- T002 depends on T001 models and service contract
- T003 requires T000-T002 implementations to test, validates logRedact() compliance
- T004 validates complete implementation from T000-T003

## Parallel Opportunities
- T000 can be developed independently and in parallel with early T001 work
- Within T001: Models and interface can be created in parallel with T000
- Within T003: Unit tests, widget tests, and integration tests can be developed in parallel after T000-T002
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

**Total**: 5 atomic tasks implementing A4 LocationResolver with constitutional compliance (C1, C2, C3, C5) and comprehensive test coverage including privacy-compliant logging utilities.