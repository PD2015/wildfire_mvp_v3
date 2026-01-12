# Tasks: Compact Location UI

**Feature Branch**: `023-compact-location-ui`  
**Status**: In Progress  
**Last Updated**: 2026-01-12

---

## Progress Overview

| Phase | Status | Tasks Complete |
|-------|--------|----------------|
| Phase 1: Foundation | 🔲 Not Started | 0/3 |
| Phase 2: Risk Screen | 🔲 Not Started | 0/3 |
| Phase 3: Report Screen | 🔲 Not Started | 0/4 |
| Phase 4: Cleanup | 🔲 Not Started | 0/3 |

---

## Phase 1: Shared Components (Foundation)

### Task 1.1: LocationChip Widget
- [ ] Create `lib/widgets/location_chip.dart`
- [ ] Implement place name / coordinates display
- [ ] Implement source badge (GPS/MANUAL/CACHED)
- [ ] Implement expand/collapse chevron with rotation
- [ ] Implement loading state
- [ ] Add semantic labels
- [ ] Ensure ≥48dp touch target
- [ ] Create `test/widget/location_chip_test.dart`

### Task 1.2: ExpandableLocationPanel Widget
- [ ] Create `lib/widgets/expandable_location_panel.dart`
- [ ] Implement coordinates row (Lat/Lng)
- [ ] Implement what3words row with tester badge
- [ ] Integrate `LocationMiniMapPreview` for map
- [ ] Implement Update location button
- [ ] Implement Copy location button
- [ ] Implement Use GPS button (conditional)
- [ ] Wire up clipboard copy with feedback
- [ ] Add semantic labels
- [ ] Ensure ≥48dp touch targets
- [ ] Create `test/widget/expandable_location_panel_test.dart`

### Task 1.3: LocationChipWithPanel Composite
- [ ] Create `lib/widgets/location_chip_with_panel.dart`
- [ ] Implement expand/collapse state management
- [ ] Implement smooth height animation (≤300ms)
- [ ] Default to collapsed state
- [ ] Create `test/widget/location_chip_with_panel_test.dart`

---

## Phase 2: Risk Screen Integration

### Task 2.1: Add Location Chip to RiskBanner
- [ ] Add `locationChip` prop to `RiskBanner`
- [ ] Position chip below `RiskScale` in success state
- [ ] Verify chip fits within banner color scheme
- [ ] Update existing `RiskBanner` tests

### Task 2.2: Update HomeScreen Layout
- [ ] Remove standalone `_buildLocationCard()` from layout Column
- [ ] Create `LocationChipWithPanel` in `_buildRiskBanner()`
- [ ] Pass chip to `RiskBanner` as `locationChip` prop
- [ ] Wire `onUpdateLocation` to `_showManualLocationDialog()`
- [ ] Wire `onCopyLocation` to clipboard handler
- [ ] Wire `onUseGps` to `_controller.useGpsLocation()`
- [ ] Handle loading, success, and error states
- [ ] Test manually on web/mobile

### Task 2.3: Risk Screen Widget Tests
- [ ] Create `test/widget/risk_banner_location_chip_test.dart`
- [ ] Test chip renders inside banner
- [ ] Test correct place name / coordinates displayed
- [ ] Test tap expands panel
- [ ] Test panel shows all details
- [ ] Test action button callbacks
- [ ] Test accessibility semantics

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
