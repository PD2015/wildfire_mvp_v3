# Tasks: Compact Location UI

**Feature Branch**: `023-compact-location-ui`  
**Status**: In Progress  
**Last Updated**: 2026-01-12

---

## Progress Overview

| Phase | Status | Tasks Complete |
|-------|--------|----------------|
| Phase 1: Foundation | ✅ Complete | 3/3 |
| Phase 2: Risk Screen | ✅ Complete | 3/3 |
| Phase 3: Report Screen | 🔲 Not Started | 0/4 |
| Phase 4: Cleanup | 🔲 Not Started | 0/3 |

---

## Phase 1: Shared Components (Foundation)

### Task 1.1: LocationChip Widget
- [x] Create `lib/widgets/location_chip.dart`
- [x] Implement place name / coordinates display
- [x] Implement source badge (GPS/MANUAL/CACHED)
- [x] Implement expand/collapse chevron with rotation
- [x] Implement loading state
- [x] Add semantic labels
- [x] Ensure ≥48dp touch target
- [x] Create `test/widget/location_chip_test.dart` (21 tests)

### Task 1.2: ExpandableLocationPanel Widget
- [x] Create `lib/widgets/expandable_location_panel.dart`
- [x] Implement coordinates row (Lat/Lng)
- [x] Implement what3words row with tester badge
- [x] Integrate `LocationMiniMapPreview` for map
- [x] Implement Update location button
- [x] Implement Copy location button
- [x] Implement Use GPS button (conditional)
- [x] Wire up clipboard copy with feedback
- [x] Add semantic labels
- [x] Ensure ≥48dp touch targets
- [x] Create `test/widget/expandable_location_panel_test.dart` (24 tests)

### Task 1.3: LocationChipWithPanel Composite
- [x] Create `lib/widgets/location_chip_with_panel.dart`
- [x] Implement expand/collapse state management
- [x] Implement smooth height animation (≤300ms)
- [x] Default to collapsed state
- [x] Create `test/widget/location_chip_with_panel_test.dart` (24 tests)

---

## Phase 2: Risk Screen Integration

### Task 2.1: Add Location Chip to RiskBanner
- [x] Add `locationChip` prop to `RiskBanner`
- [x] Position chip below `RiskScale` in success state
- [x] Position chip below `RiskScale` in error-with-cache state
- [x] Verify chip fits within banner color scheme
- [x] Update existing `RiskBanner` tests (28 tests pass)

### Task 2.2: Update HomeScreen Layout
- [x] Remove standalone `_buildLocationCard()` from layout Column
- [x] Create `_buildLocationChip()` method returning `LocationChipWithPanel`
- [x] Pass chip to `RiskBanner` as `locationChip` prop
- [x] Wire `onChangeLocation` to `_showManualLocationDialog()`
- [x] Wire `onCopyWhat3words` to clipboard handler
- [x] Wire `onUseGps` to `_controller.useGpsLocation()`
- [x] Handle loading, success, and error states
- [x] Import `risk_level.dart` for color extension
- [ ] Test manually on web/mobile (pending)

### Task 2.3: Risk Screen Widget Tests
- [x] Create `test/widget/risk_banner_location_chip_integration_test.dart` (20 tests)
- [x] Test chip renders inside banner
- [x] Test correct location name displayed
- [x] Test tap expands panel
- [x] Test action button callbacks
- [x] Test accessibility semantics
- [x] Test visual hierarchy (chip below RiskScale)
- [x] Test all risk level color adaptations

---

## Phase 3: Report Screen Refactor

### Task 3.1: EmergencyHeroCard Widget
- [ ] Create `lib/features/report/widgets/emergency_hero_card.dart`
- [ ] Implement header with icon and title
- [ ] Implement subtitle instruction text
- [ ] Implement 999 button (prominent - reuse `EmergencyButton`)
- [ ] Implement 101 + Crimestoppers row (secondary)
- [ ] Add disclaimer text
- [ ] Add semantic labels
- [ ] Ensure ≥48dp touch targets
- [ ] Create `test/widget/emergency_hero_card_test.dart`

### Task 3.2: CollapsibleLocationCard Widget
- [ ] Create `lib/features/report/widgets/collapsible_location_card.dart`
- [ ] Implement "Your location for the call" header
- [ ] Implement place name + source badge summary
- [ ] Implement always-visible Copy button
- [ ] Implement always-visible Update button
- [ ] Implement expandable details section
- [ ] Implement lat/lng display in expanded
- [ ] Implement what3words in expanded (with tester badge)
- [ ] Implement map preview in expanded
- [ ] Default to collapsed state
- [ ] Implement smooth expand/collapse animation
- [ ] Format copied location for emergency services
- [ ] Create `test/widget/collapsible_location_card_test.dart`

### Task 3.3: Update ReportFireScreen Layout
- [ ] Replace `_Banner` with `EmergencyHeroCard`
- [ ] Remove separate emergency contacts Card
- [ ] Replace `ReportFireLocationCard` with `CollapsibleLocationCard`
- [ ] Wire up 999/101/Crimestoppers callbacks
- [ ] Wire up location card callbacks to controller
- [ ] Keep `_TipsCard` unchanged
- [ ] Test manually on web/mobile

### Task 3.4: Report Screen Widget Tests
- [ ] Update `test/features/report/screens/report_fire_screen_test.dart`
- [ ] Test emergency hero renders first
- [ ] Test all emergency buttons functional
- [ ] Test location card renders collapsed
- [ ] Test location card expands
- [ ] Test copy/update callbacks work

---

## Phase 4: Cleanup & Polish

### Task 4.1: Update Existing Tests
- [ ] Verify `test/widget/screens/home_screen_test.dart` passes
- [ ] Verify `test/widget/risk_banner_test.dart` passes
- [ ] Update any tests with changed selectors/structure
- [ ] Run full `flutter test` suite

### Task 4.2: Deprecation Comments
- [ ] Add `@Deprecated` comment to `LocationCard` (optional)
- [ ] Add `@Deprecated` comment to `ReportFireLocationCard` (optional)
- [ ] Document deprecation timeline in comments

### Task 4.3: Documentation Update
- [ ] Update `.github/copilot-instructions.md` with new component patterns
- [ ] Add usage examples for `LocationChipWithPanel`
- [ ] Add usage examples for `EmergencyHeroCard`
- [ ] Add usage examples for `CollapsibleLocationCard`

---

## Definition of Done

- [ ] All tasks above checked off
- [ ] `flutter test` passes (0 failures)
- [ ] `flutter analyze` clean (no new warnings)
- [ ] Manual testing on Chrome (web)
- [ ] Manual testing on Android/iOS (if available)
- [ ] Risk screen: Risk level visible first, location chip below
- [ ] Report screen: Emergency actions visible first, location below
- [ ] PR created with screenshots of before/after
- [ ] Code review approved

---

## Notes

_Add implementation notes, blockers, or decisions here during development._

```
2026-01-12: Spec and plan created. Ready to start Phase 1.
```
