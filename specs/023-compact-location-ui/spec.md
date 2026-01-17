# Feature Specification: Compact Location UI

**Feature Branch**: `023-compact-location-ui`  
**Created**: 2026-01-12  
**Status**: Draft  
**Input**: User flow review - reorganise Risk and Report screens for greater clarity by making location info less dominant

---

## Purpose

Improve the user experience on the Risk and Report screens by restructuring the visual hierarchy so that the **primary message** (fire risk level / emergency actions) is seen first, with location treated as **supporting context** rather than the hero content.

## Problem Statement

Currently, both the Risk and Report screens display the full LocationCard prominently at the top, causing users to see:

1. Location card (with coordinates, map preview, what3words, action buttons)
2. *Then* the actual risk level or emergency actions

This inverts the intended user flow:

- **Risk screen**: Users want to know "What's the fire risk?" before "Where am I?"
- **Report screen**: Users in a stressful situation want to know "What do I do?" before "What's my location?"

The current layout subtly reframes both screens as "location tools" rather than "risk assessment" or "emergency action" tools.

---

## User Scenarios & Testing

### Primary User Stories

**Risk Screen**: As a user checking fire risk, I want to see my current risk level immediately when I open the app, with location details available if I need them but not competing for attention.

**Report Screen**: As a user who may have spotted a fire, I want to immediately see what actions to take (call 999), with my location ready to copy/share for the emergency call but not blocking the urgent information.

### Acceptance Scenarios

#### Risk Screen

1. **Given** I open the Risk screen, **When** the data loads successfully, **Then** I see the risk level (e.g., "VERY LOW") and risk scale as the first major content element.

2. **Given** I'm viewing the Risk screen, **When** I look below the risk scale, **Then** I see a compact location chip showing place name and source (e.g., "Grantown-on-Spey · GPS ▼").

3. **Given** I tap the location chip, **When** it expands, **Then** I see the full location details: coordinates, what3words (if available), map preview, and action buttons (Update location, Copy location).

4. **Given** the location panel is expanded, **When** I tap the collapse chevron or the chip header, **Then** the panel collapses back to just the chip.

5. **Given** I tap "Update location" in the expanded panel, **When** the location picker opens, **Then** I can change my location using the same flow as before.

6. **Given** I view the Risk Guidance card, **When** scrolling past the location chip, **Then** the guidance card appears unchanged.

#### Report Screen

7. **Given** I open the Report screen, **When** the screen loads, **Then** I immediately see the emergency hero card with "See smoke, flames, or a campfire?" header and the 999 button as the most prominent element.

8. **Given** I'm viewing the Report screen, **When** I see the emergency hero card, **Then** it contains: header text, 999 Fire Service button (prominent), 101 Police and Crimestoppers buttons (secondary), and disclaimer text.

9. **Given** I'm viewing below the emergency hero, **When** I look at the location section, **Then** I see a collapsible card titled "Your location for the call" with place name, GPS badge, and always-visible Copy + Update buttons.

10. **Given** the location card is collapsed (default), **When** I tap the expand chevron, **Then** I see additional details: latitude/longitude, what3words (tester preview), and map preview.

11. **Given** I tap "Copy for your call", **When** the copy action completes, **Then** my location is copied to clipboard in a format suitable for emergency services.

12. **Given** I view the Safety Tips card, **When** scrolling past the location section, **Then** the safety tips appear unchanged.

### Edge Cases

- **Loading state**: Location chip shows loading indicator while location resolves
- **Location error**: Chip shows error state with "Set location" action
- **Manual location**: Chip displays "Manual" instead of "GPS" badge
- **No place name**: Falls back to coordinates display in chip
- **what3words unavailable**: Shows "/// Unavailable" with tester preview badge
- **Expand/collapse animation**: Smooth height transition (not jarring)

---

## Requirements

### Functional Requirements

#### Shared Components

| ID | Requirement |
|----|-------------|
| S1 | Create `LocationChip` widget that displays: place name (or coordinates fallback), location source badge (GPS/Manual), and expand/collapse chevron |
| S2 | Create `ExpandableLocationPanel` widget that shows: coordinates (lat/lng), what3words row (with tester badge), map preview, Update location button, Copy location button |
| S3 | `ExpandableLocationPanel` must animate expand/collapse with smooth height transition |
| S4 | Both components must use existing location services and state management (no new data layer) |
| S5 | Both components must inherit styling from existing theme (no hardcoded colors/sizes) |

#### Risk Screen (HomeScreen)

| ID | Requirement |
|----|-------------|
| R1 | RiskBanner remains unchanged in content (risk level, scale, timestamp, source) |
| R2 | Add `LocationChip` inside RiskBanner, positioned below the risk scale |
| R3 | When chip is tapped, `ExpandableLocationPanel` appears inline below the chip |
| R4 | Remove standalone `LocationCard` from HomeScreen layout |
| R5 | RiskGuidanceCard remains in current position (after risk banner) |

#### Report Screen

| ID | Requirement |
|----|-------------|
| E1 | Create `EmergencyHeroCard` that combines: header ("See smoke, flames, or a campfire?"), subtitle instruction, 999 button (prominent/filled), 101 + Crimestoppers buttons (secondary/outlined), disclaimer text |
| E2 | `EmergencyHeroCard` replaces current separate banner and emergency contacts card |
| E3 | Create `CollapsibleLocationCard` for Report screen with: header "Your location for the call", place name + GPS badge, always-visible Copy + Update buttons, expandable details section |
| E4 | `CollapsibleLocationCard` is collapsed by default |
| E5 | Safety Tips card remains unchanged |
| E6 | Remove current `ReportFireLocationCard` from top position |

### Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| N1 | All touch targets ≥48dp (C3 accessibility compliance) |
| N2 | Semantic labels on all interactive elements for screen readers |
| N3 | Expand/collapse animation completes in ≤300ms |
| N4 | No hardcoded colors - use `Theme.of(context).colorScheme` tokens |
| N5 | No hardcoded text styles - use `Theme.of(context).textTheme` tokens |
| N6 | Web-friendly: inline expansion (no modal or bottom sheet) |

---

## Visual Reference

Screenshots from React prototype are available in `/screenshots/`:
- `Risk, location chip collapsed.png` - Risk screen with chip in collapsed state
- `Risk location chip expanded.png` - Risk screen with location panel expanded
- `Report location card condensed.png` - Report screen with location collapsed
- `Report location chip expanded.png` - Report screen with location expanded

**Note**: The Flutter implementation should match the *layout* of these screenshots while using the *existing Flutter theme* styling (colors, typography, component styles).

---

## Out of Scope

- Changes to location services or data fetching logic
- Changes to risk calculation or display logic
- "Why location matters" explanatory card (deferred)
- Saved locations feature (future enhancement)
- what3words API integration (stays as tester preview)
- Changes to Map screen

---

## Implementation Notes

### Component Reuse Strategy

1. **LocationChip**: New widget, but delegates to existing `HomeController` / `ReportFireController` for location state
2. **ExpandableLocationPanel**: Extracts UI patterns from existing `LocationCard` widget, reuses same callbacks
3. **EmergencyHeroCard**: Composes existing `EmergencyButton` widgets with new layout
4. **CollapsibleLocationCard**: New widget purpose-built for emergency UX, reuses existing location display state

### Theme Integration

All new components should reference:
- `lib/theme/wildfire_a11y_theme.dart` - Main theme configuration
- `lib/theme/risk_palette.dart` - Risk-specific colors (unchanged)
- Existing button styles (`FilledButton`, `OutlinedButton`) from theme

### File Structure (Proposed)

```
lib/widgets/
├── location_chip.dart              # New: Compact location display
├── expandable_location_panel.dart  # New: Full location details
├── location_card.dart              # Existing: Keep for reference/migration
└── ...

lib/features/report/widgets/
├── emergency_hero_card.dart        # New: Combined emergency actions
├── collapsible_location_card.dart  # New: Report-specific location card
├── report_fire_location_card.dart  # Existing: Deprecate after migration
└── ...
```

---

## Success Criteria

1. ✅ Risk screen shows risk level as primary content above the fold
2. ✅ Report screen shows emergency actions as primary content above the fold
3. ✅ Location is accessible via one tap on both screens
4. ✅ All existing location functionality preserved (copy, update, GPS/manual)
5. ✅ Visual styling consistent with existing app theme
6. ✅ All existing tests pass (or updated for new structure)
7. ✅ New widget tests cover expand/collapse, accessibility, edge cases
