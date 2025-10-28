# Tasks: A12b – Report Fire Screen (Descriptive)

**Input**: Design documents from `/specs/014-a12b-report-fire/`
**Prerequisites**: plan.md (complete), research.md, data-model.md, contracts/, quickstart.md

## Execution Summary
Enhancing existing A12 MVP Report Fire screen with Scotland-specific descriptive guidance while preserving all emergency calling functionality. Focus on accessibility, content structure, and visual hierarchy improvements building on proven url_launcher integration.

**Key Constraints**:
- Build on existing A12 MVP implementation (preserve emergency calling)
- Year 7-8 reading level with scannable content structure
- ≥48dp touch targets and semantic labels (C3: Accessibility)
- Constitutional gates: C1 (tests), C3 (accessibility), C4 (transparency), C5 (resilience)

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **Labels**: spec:A12b, gate:C1, gate:C3, gate:C4, gate:C5

## Path Conventions
**Flutter Project Structure** (from plan.md):
```
lib/features/report/
├── screens/report_fire_screen.dart          # Enhanced main screen
├── models/safety_guidance.dart              # New guidance model
└── widgets/
    ├── guidance_section.dart                # New step guidance widget
    └── safety_tips_card.dart                # New safety tips widget

test/features/report/
├── screens/report_fire_screen_test.dart     # Enhanced screen tests
├── models/safety_guidance_test.dart         # New model tests
└── widgets/
    ├── guidance_section_test.dart           # New widget tests
    └── safety_tips_card_test.dart           # New widget tests
```

## Phase 3.1: Setup & Dependencies ⚠️ VERIFY A12 BASE FIRST
- [ ] **T001** Verify existing A12 MVP functionality by running tests for `test/features/report/screens/report_fire_screen_test.dart` and `test/utils/url_launcher_utils_test.dart`
- [ ] **T002** [P] Confirm url_launcher ^6.3.0 and go_router ^14.2.7 dependencies in pubspec.yaml match technical context requirements

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [ ] **T003** [P] Widget test for SafetyGuidance model validation in `test/features/report/models/safety_guidance_test.dart` (gate:C1)
- [ ] **T004** [P] Widget test for GuidanceSection widget with step hierarchy and emergency buttons in `test/features/report/widgets/guidance_section_test.dart` (gate:C1, gate:C3)
- [ ] **T005** [P] Widget test for SafetyTipsCard widget with accessibility labels in `test/features/report/widgets/safety_tips_card_test.dart` (gate:C1, gate:C3)
- [ ] **T006** Enhanced widget test for ReportFireScreen with descriptive content validation in `test/features/report/screens/report_fire_screen_test.dart` (gate:C1, gate:C3)
- [ ] **T007** [P] Integration test for screen reader navigation order (banner → step1 → 999 → step2 → 101 → step3 → 0800 → tips → learn more) in `test/integration/report/report_fire_integration_test.dart` (gate:C3, gate:C5)

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Models & Data
- [ ] **T008** [P] Create SafetyGuidance model with stepTitle, description, examples, and contact association in `lib/features/report/models/safety_guidance.dart` (spec:A12b)
- [ ] **T009** [P] Create SafetyTip and SafetyTipsCard models with icon, title, description, and warning flag in `lib/features/report/models/safety_guidance.dart` (spec:A12b)

### Widget Components  
- [ ] **T010** [P] Create GuidanceSection widget with step number, guidance content, and emergency button integration in `lib/features/report/widgets/guidance_section.dart` (spec:A12b, gate:C3)
- [ ] **T011** [P] Create SafetyTipsCard widget with structured tips display and accessibility semantics in `lib/features/report/widgets/safety_tips_card.dart` (spec:A12b, gate:C3)

### Enhanced Screen Implementation
- [ ] **T012** **Update copy & headings**: Replace existing ReportFireScreen content with descriptive Scotland-specific guidance in `lib/features/report/screens/report_fire_screen.dart`:
  - Step 1: Include examples for location (road/landmark or What3Words), terrain (grass/peat/woodland), size/spread, wind direction, safe access
  - Step 2: Irresponsible lighting → 101 Police Scotland guidance
  - Step 3: Anonymous reporting → 0800 555 111 Crimestoppers guidance  
  - Ensure line breaks for scannability and Year 7-8 reading level (spec:A12b, gate:C4)

- [ ] **T013** **Spacing & visual hierarchy**: Implement proper Material 3 typography and spacing in enhanced ReportFireScreen:
  - Use titleMedium for section headings, bodyLarge for paragraphs
  - 16-24dp vertical rhythm between blocks, ≥12dp between heading and body
  - Keep CTAs 52dp height, full width, rounded 14-16dp  
  - Verify no clip/overflow on 320-430dp widths (spec:A12b, gate:C3)

- [ ] **T014** **Semantics & a11y polish**: Add comprehensive accessibility features to ReportFireScreen and all components:
  - Semantic labels for each CTA: "Call emergency services, 999, Fire Service", "Call Police Scotland, non-emergency 101", "Call Crimestoppers, anonymous line 0800 555 111"
  - Banner semantics: "Wildfire report instructions"  
  - Ensure focus order matches emergency priority (gate:C3)

### Optional Features
- [ ] **T015** **Optional offline banner**: Add connectivity detection and dismissible banner in ReportFireScreen:
  - Show banner if platform reports no connectivity OR launchUrl fails with no handler
  - Message: "No signal? If you see a fire, dial numbers manually or move to signal."
  - Do not block CTAs, maintain existing SnackBar functionality (gate:C5)

## Phase 3.4: Integration & Polish

- [ ] **T016** [P] **Tests**: Comprehensive test coverage validation:
  - Widget test: titles, paragraphs, and CTAs exist with expected texts
  - Semantics test: CTA labels present and correct
  - Optional: Golden tests for light/dark contrast verification
  - Verify `flutter test` passes locally and in CI (gate:C1)

- [ ] **T017** **Docs/Changelog**: Documentation updates:
  - Add README snippet for enhanced report screen and rationale
  - Update CHANGELOG.md with A12b entry explaining descriptive guidance enhancement

## Dependencies
- Setup & Verification (T001-T002) before everything
- Tests (T003-T007) before implementation (T008-T015) - **CRITICAL TDD ORDER**  
- Models (T008-T009) before widgets (T010-T011)
- Widget components (T010-T011) before screen enhancement (T012-T014)
- Core implementation before polish (T016-T017)

## Parallel Example
```bash
# Phase 3.2 - Launch T003-T005 together (different test files):
flutter test test/features/report/models/safety_guidance_test.dart &
flutter test test/features/report/widgets/guidance_section_test.dart &  
flutter test test/features/report/widgets/safety_tips_card_test.dart &
wait

# Phase 3.3 - Launch T008-T011 together (different implementation files):
# Implement SafetyGuidance model
# Implement GuidanceSection widget  
# Implement SafetyTipsCard widget
# (All in parallel since different files)
```

## Validation Checklist
*GATE: Verify before marking complete*

### Content & Accessibility (Gate C3, C4)
- [ ] All step guidance uses Year 7-8 reading level language
- [ ] Scotland emergency services (999, 101, 0800 555 111) prominently displayed
- [ ] All interactive elements ≥48dp touch targets  
- [ ] Semantic labels enable screen reader navigation
- [ ] Focus order follows emergency priority (urgent → important → standard)

### Technical Requirements (Gate C1, C5)
- [ ] All tests pass before implementation
- [ ] No breaking changes to existing A12 emergency calling functionality
- [ ] Enhanced screen loads instantly (<100ms) with static content
- [ ] SnackBar fallback still works for dialer failures
- [ ] Constitutional compliance verified (C1-C5)

### User Story Coverage (From quickstart.md)
- [ ] Story 1: Active fire emergency (999) with enhanced guidance
- [ ] Story 2: Illegal campfire (101) with Police Scotland context  
- [ ] Story 3: Suspected arson (Crimestoppers) with anonymous reporting guidance
- [ ] Story 4: Screen reader navigation follows logical emergency order
- [ ] Story 5: Device without dialer shows appropriate fallback messaging

## Notes
- Builds on existing A12 MVP - preserve all url_launcher integration
- Focus on content enhancement and accessibility over technical changes
- [P] tasks = different files, true independence verified
- TDD critical: Tests must fail before implementation begins
- Constitutional gates integrated throughout development phases