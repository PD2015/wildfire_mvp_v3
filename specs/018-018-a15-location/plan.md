# Implementation Plan: 018-A15 Location Picker & what3words Integration

**Branch**: `018-018-a15-location` | **Date**: 2025-11-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/018-018-a15-location/spec.md`

---

## Summary

Add an interactive **LocationPickerScreen** with Google Maps, **what3words integration**, and enhanced Location Card to enable users to:
1. Select custom locations for fire risk assessment (beyond GPS)
2. Get precise what3words addresses for emergency service reporting
3. Search for places or enter what3words directly

**Technical approach**: 
- Full-screen map picker with fixed crosshair (camera movement, not draggable marker)
- Direct HTTP what3words integration (matches existing service patterns)
- Navigator.pop return pattern (no new controllers for calling screens)
- ChangeNotifier state management (matches HomeController, MapController)

---

## Technical Context

| Aspect | Value |
|--------|-------|
| **Language/Version** | Dart 3.9.2, Flutter 3.35.5 stable |
| **Primary Dependencies** | google_maps_flutter ^2.5.0, http ^1.1.0, dartz ^0.10.1, equatable ^2.0.5 |
| **Storage** | SharedPreferences (via existing LocationResolver) |
| **Testing** | flutter_test, mockito |
| **Target Platform** | Android, iOS, Web (Chrome/Safari) |
| **Project Type** | Mobile (Flutter multi-platform) |
| **Performance Goals** | Map load <2s, what3words response <500ms, 60fps pan |
| **Constraints** | what3words free tier (1000 req/day), offline degradation |
| **Scale/Scope** | Single screen + 1 service + 5 widgets |

---

## Constitution Check ✅

*All gates pass - no violations requiring justification*

### C1. Code Quality & Tests ✅
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy: unit tests for service, widget tests for UI, integration test for flow
- [x] CI enforcement: existing pre-commit hooks and GitHub Actions

### C2. Secrets & Logging ✅
- [x] No hardcoded secrets: WHAT3WORDS_API_KEY via env/dev.env.json
- [x] Logging: coordinates via LocationUtils.logRedact() (2dp precision)
- [x] what3words addresses NEVER logged (can identify precise locations)
- [x] Secret scanning: existing gitleaks integration

### C3. Accessibility (UI features) ✅
- [x] All interactive elements ≥48dp touch targets (search bar, buttons)
- [x] Semantic labels planned for all components (see widget-contracts.md)
- [x] A11y verification: widget tests + VoiceOver/TalkBack manual testing

### C4. Trust & Transparency ✅
- [x] Uses existing BrandPalette/RiskPalette (no new colors)
- [x] Source labeling: N/A for picker (no risk data displayed)
- [x] Timestamp: N/A for picker (single selection, not historical data)

### C5. Resilience & Test Coverage ✅
- [x] Network calls: 5s timeout for what3words API
- [x] Services: Either<What3wordsError, T> pattern (no silent failures)
- [x] Graceful degradation: picker works without what3words or Places API
- [x] Integration tests: error/fallback flows covered in quickstart.md

### Development Principles ✅
- [x] "Fail visible": Loading spinners, error messages visible
- [x] "Fallbacks not blanks": Coordinates work when what3words unavailable
- [x] "Keep logs clean": Structured logging, coordinates redacted
- [x] "Single source of truth": What3wordsAddress validation in one place
- [x] "Mock-first dev": MockWhat3wordsService for testing

---

## Project Structure

### Documentation (this feature)
```
specs/018-018-a15-location/
├── plan.md              # This file ✅
├── research.md          # Phase 0 output ✅
├── data-model.md        # Phase 1 output ✅
├── quickstart.md        # Phase 1 output ✅
├── contracts/           # Phase 1 output ✅
│   ├── widget-contracts.md
│   └── service-contracts.md
└── tasks.md             # Phase 2 output (via /tasks)
```

### Source Code (new files)
```
lib/
├── features/
│   └── location_picker/
│       ├── screens/
│       │   └── location_picker_screen.dart      # Full-screen picker
│       ├── controllers/
│       │   └── location_picker_controller.dart  # ChangeNotifier
│       ├── widgets/
│       │   ├── location_search_bar.dart         # Search + autocomplete
│       │   ├── location_info_panel.dart         # Coords + w3w display
│       │   └── crosshair_overlay.dart           # Fixed center marker
│       └── models/
│           └── picked_location.dart             # Return type
├── services/
│   ├── what3words_service.dart                  # Interface
│   └── what3words_service_impl.dart             # HTTP implementation
└── models/
    └── what3words_models.dart                   # What3wordsAddress, errors
```

### Source Code (modified files)
```
lib/
├── app.dart                                     # Add route (optional - may use Navigator.push directly)
├── config/feature_flags.dart                    # Add WHAT3WORDS_API_KEY
├── screens/home_screen.dart                     # Replace dialog → picker
└── features/report/screens/report_fire_screen.dart  # Add "Set Location" button

env/
└── dev.env.json.template                        # Add WHAT3WORDS_API_KEY placeholder
```

### Test Files
```
test/
├── unit/
│   ├── services/what3words_service_test.dart
│   ├── controllers/location_picker_controller_test.dart
│   └── models/what3words_models_test.dart
├── widget/
│   ├── location_picker_screen_test.dart
│   ├── location_search_bar_test.dart
│   ├── location_info_panel_test.dart
│   └── crosshair_overlay_test.dart
└── integration/
    └── location_picker_flow_test.dart
```

**Structure Decision**: Uses existing Flutter feature-based architecture (`lib/features/*/`). New `location_picker` feature follows pattern established by `map` and `report` features.

---

## Phase 0: Research ✅ COMPLETE

See [research.md](research.md) for detailed findings:

| Decision | Outcome | Rationale |
|----------|---------|-----------|
| what3words integration | Direct HTTP (not SDK) | Matches project patterns, zero bundle increase |
| Map picker UI | Fixed crosshair + camera | Better UX than draggable marker |
| State management | ChangeNotifier | Matches existing controllers |
| Navigation | Navigator.pop with typed result | ReportFireScreen is stateless |
| Places API | Use existing Google Cloud project | Already configured for Maps |

All NEEDS CLARIFICATION items resolved.

---

## Phase 1: Design ✅ COMPLETE

Artifacts generated:
- [data-model.md](data-model.md) - 6 entities with validation rules
- [contracts/widget-contracts.md](contracts/widget-contracts.md) - 4 widgets with test assertions
- [contracts/service-contracts.md](contracts/service-contracts.md) - 2 services with API specs
- [quickstart.md](quickstart.md) - 10 validation scenarios

Key design decisions:
1. **What3wordsAddress** as value object with format validation
2. **LocationPickerState** sealed class hierarchy (Initial → Ready)
3. **LocationPickerMode** enum for entry point differentiation
4. **PickedLocation** typed result for Navigator.pop

---

## Phase 2: Task Planning Approach

*This section describes what /tasks will generate - NOT executed during /plan*

### Task Generation Strategy

**From data-model.md** (6 entities):
1. What3wordsAddress value object + tests [P]
2. What3wordsError sealed class + tests [P]
3. PickedLocation model + tests [P]
4. LocationPickerState sealed class + tests [P]
5. PlaceSearchResult model + tests [P]
6. LocationPickerMode enum [P]

**From service-contracts.md** (2 services):
7. What3wordsService interface [P]
8. What3wordsServiceImpl + tests
9. LocationPickerController + tests

**From widget-contracts.md** (4 widgets):
10. CrosshairOverlay widget + test [P]
11. LocationInfoPanel widget + test [P]
12. LocationSearchBar widget + test
13. LocationPickerScreen widget + test

**Integration tasks**:
14. Add WHAT3WORDS_API_KEY to FeatureFlags
15. Update env/dev.env.json.template
16. Modify HomeScreen → open picker
17. Modify ReportFireScreen → add location button
18. Integration test: full flow

### Ordering Strategy
- **TDD**: Tests written with implementations
- **Dependency order**: Models → Services → Controller → Widgets → Integration
- **[P] markers**: Items 1-6, 7, 10-11 can run in parallel

### Estimated Output
~18-20 tasks in tasks.md

---

## Complexity Tracking

*No violations - all designs fit within constitutional constraints*

| Aspect | Status | Notes |
|--------|--------|-------|
| New dependencies | None | Uses existing http, dartz, google_maps_flutter |
| New services | 1 (What3wordsService) | Follows existing patterns |
| New screens | 1 (LocationPickerScreen) | Single-purpose, no state persistence |
| State complexity | Low | Single controller, sealed states |

---

## Progress Tracking

**Phase Status**:
- [x] Phase 0: Research complete
- [x] Phase 1: Design complete
- [x] Phase 2: Task planning described (not executed)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] No complexity deviations required

---

## Open Questions & Trade-offs

| Item | Decision Needed | Recommendation |
|------|-----------------|----------------|
| **Places API package** | Use `google_maps_webservice` package vs direct HTTP? | Direct HTTP for consistency with what3words, or defer search feature to v2 |
| **Search debounce duration** | 200ms vs 300ms vs 500ms | 300ms (balance responsiveness vs API calls) |
| **Initial zoom level** | 8 (region) vs 12 (city) vs 15 (street) | 12 for city-level context |
| **Map type toggle** | Include satellite/terrain toggle? | Defer to v2 (not in FR-008 "Should") |
| **Mini-map preview** | Add to LocationCard? | Defer to v2 (complexity vs value) |

**Recommended prioritization**: Core picker + what3words is MVP. Search autocomplete and map type toggle are enhancements for v2.

---

*Plan complete. Ready for `/tasks` command to generate tasks.md*
