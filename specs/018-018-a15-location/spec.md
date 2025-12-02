# 018-A15 Location Picker & what3words Integration

**Feature Branch**: `018-018-a15-location`  
**Created**: 2025-01-13  
**Status**: Draft  

## Purpose
Enable users to manually select and verify locations for fire risk assessment and wildfire reporting through an interactive map picker with what3words address support, enhancing location precision critical for emergency scenarios in Scotland.

## Problem Statement
Currently, users can only get fire risk for their GPS location or a cached location. There's no way to:
1. Check fire risk for a different area (e.g., "I'm hiking to Cairngorms tomorrow")
2. Set an accurate location when GPS is unavailable or inaccurate
3. Share precise location with emergency services using Scotland's preferred what3words format

The existing `LocationCard` shows coordinates but doesn't allow interactive selection. The `ReportFireScreen` mentions what3words in guidance text but doesn't provide actual integration.

## Solution Overview

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                      Entry Points                                │
├─────────────────────────────────────────────────────────────────┤
│  LocationCard          │  ReportFireScreen                       │
│  [Change/Set Button]   │  [Set Fire Location Button]             │
│         │              │              │                          │
│         └──────────────┴──────────────┘                          │
│                        │                                         │
│                        ▼                                         │
│              LocationPickerScreen                                │
│    ┌─────────────────────────────────────────────────────┐      │
│    │  ┌─────────────────────────────────────────────┐    │      │
│    │  │         Interactive GoogleMap               │    │      │
│    │  │  • Tap to place marker                      │    │      │
│    │  │  • Drag marker to adjust                    │    │      │
│    │  │  • Satellite/terrain toggle                 │    │      │
│    │  └─────────────────────────────────────────────┘    │      │
│    │                                                      │      │
│    │  ┌─────────────────────────────────────────────┐    │      │
│    │  │  Search Bar (Place Search)                  │    │      │
│    │  │  "Search for a place or what3words..."      │    │      │
│    │  └─────────────────────────────────────────────┘    │      │
│    │                                                      │      │
│    │  ┌─────────────────────────────────────────────┐    │      │
│    │  │  Location Info Panel                        │    │      │
│    │  │  📍 55.9533, -3.1883                        │    │      │
│    │  │  ///slurs.this.name                         │    │      │
│    │  │  [📋 Copy]  [Use Current GPS 📍]            │    │      │
│    │  └─────────────────────────────────────────────┘    │      │
│    │                                                      │      │
│    │  [Cancel]                    [Confirm Location ✓]   │      │
│    └─────────────────────────────────────────────────────┘      │
│                        │                                         │
│                        ▼                                         │
│         ┌──────────────────────────────────────────┐            │
│         │ What3wordsService                        │            │
│         │ • convertToCoordinates(w3w) → LatLng     │            │
│         │ • convertToWords(lat,lon) → w3w          │            │
│         └──────────────────────────────────────────┘            │
│                        │                                         │
│                        ▼                                         │
│         ┌──────────────────────────────────────────┐            │
│         │ LocationResolver.saveManual()            │            │
│         │ (existing service - A4)                  │            │
│         └──────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

---

## User Scenarios & Testing *(mandatory)*

### Scenario 1: User wants to check fire risk at planned hiking destination
**Given** user is on HomeScreen viewing their current location fire risk  
**When** they tap "Change" on LocationCard  
**Then** LocationPickerScreen opens with map centered on current location  
**And** a draggable marker is placed at current location

**When** user searches "Cairngorms"  
**Then** map pans to Cairngorms area  
**And** search suggestions show relevant results  
**And** marker moves to selected search result

**When** user taps "Confirm Location"  
**Then** picker closes  
**And** HomeScreen reloads with fire risk for new location  
**And** LocationCard shows new coordinates with "Your chosen location" subtitle

**Test Cases:**
- `location_picker_opens_from_home_screen_test.dart`
- `place_search_pans_map_test.dart`
- `confirm_updates_home_location_test.dart`

### Scenario 2: User needs to report fire with precise location
**Given** user is on ReportFireScreen  
**When** they tap "Set Fire Location" button  
**Then** LocationPickerScreen opens in fire report mode  
**And** emergency contact banner is visible ("Call 999 immediately")

**When** user taps on map to place marker  
**Then** marker appears at tap location  
**And** info panel shows coordinates AND what3words address  
**And** what3words displays with triple-slash format (///word.word.word)

**When** user taps copy button next to what3words  
**Then** what3words address is copied to clipboard  
**And** snackbar confirms "what3words copied to clipboard"

**Test Cases:**
- `fire_report_mode_shows_emergency_banner_test.dart`
- `tap_to_place_marker_test.dart`
- `what3words_copy_to_clipboard_test.dart`

### Scenario 3: User has no GPS and needs to set location manually
**Given** user's GPS permission is denied or unavailable  
**When** LocationCard shows "Set" button (no location)  
**And** user taps "Set" button  
**Then** LocationPickerScreen opens centered on Scotland default (55.8642, -4.2518)  
**And** "Use Current GPS" button is disabled or hidden

**When** user searches for their postcode "EH1 1RE"  
**Then** map centers on that postcode area  
**And** marker placed at search result

**Test Cases:**
- `gps_unavailable_shows_scotland_default_test.dart`
- `postcode_search_works_test.dart`
- `use_gps_button_hidden_when_unavailable_test.dart`

### Scenario 4: User enters what3words directly in search
**Given** user is on LocationPickerScreen  
**When** user types "///slurs.this.name" in search bar  
**Then** what3wordsService validates and converts to coordinates  
**And** map pans to location  
**And** marker placed at what3words location

**When** conversion fails (invalid words)  
**Then** error message shows "Invalid what3words address"  
**And** map doesn't move

**Test Cases:**
- `what3words_search_converts_to_coordinates_test.dart`
- `invalid_what3words_shows_error_test.dart`

### Edge Cases
- What happens when what3words API is unavailable? → Display "what3words unavailable", allow coordinate-only mode
- What happens when Google Places API is unavailable? → Disable search, tap-to-place still works
- How does system handle very slow networks? → Loading indicators, timeout after 10s with retry option
- What happens when user confirms location outside Scotland? → Allow it (fire risk APIs handle non-Scotland gracefully)

---

## Requirements *(mandatory)*

### Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | LocationPickerScreen with full-screen interactive GoogleMap | Must | Map renders, responds to gestures, supports tap-to-place |
| FR-002 | Search bar for place search (Google Places API) | Must | Autocomplete suggestions, select to pan map |
| FR-003 | what3words address display for selected location | Must | Show ///word.word.word format, update on marker move |
| FR-004 | what3words search input (detect ///pattern or /pattern) | Should | Convert w3w to coordinates, pan map |
| FR-005 | Copy what3words to clipboard | Must | One-tap copy, confirmation snackbar |
| FR-006 | "Use Current GPS" button to recenter on device location | Should | Only enabled when GPS available |
| FR-007 | Marker drag to adjust location | Must | Smooth drag, update coordinates/w3w on drop |
| FR-008 | Map type toggle (satellite/terrain for wilderness areas) | Should | Toggle button, persist preference |
| FR-009 | Integration with LocationResolver.saveManual() | Must | Persist selected location for fire risk screen |
| FR-010 | Fire report mode with emergency banner | Should | Visual distinction, different CTA text |
| FR-011 | Cancel without saving | Must | Close picker, no state change |

### Non-Functional Requirements

| ID | Requirement | Target | Measurement |
|----|-------------|--------|-------------|
| NFR-001 | Map load time | <2s on 4G | Performance test |
| NFR-002 | what3words API response | <500ms p95 | Telemetry |
| NFR-003 | Touch target size | ≥48dp | Visual inspection |
| NFR-004 | Accessibility | Full VoiceOver/TalkBack support | Accessibility audit |
| NFR-005 | Offline graceful degradation | Cache last map view, show error for w3w | Manual test |
| NFR-006 | Coordinate privacy logging | 2-decimal redaction (C2) | Code review |

---

## Key Entities

### LocationPickerScreen
Full-screen map picker with search and confirmation. Supports two modes: risk location (default) and fire report (shows emergency banner).

### What3wordsService
Service for converting between what3words addresses and coordinates. Uses dartz Either for error handling following project patterns.

### What3wordsAddress
Value object representing a validated what3words address. Format: three words separated by dots, displayed with /// prefix.

### LocationPickerController
ChangeNotifier managing picker state: selected location, what3words address, search state, map state.

### LocationPickerMode
Enum distinguishing entry points: `riskLocation` (from HomeScreen) vs `fireReport` (from ReportFireScreen).

---

## Integration Points

| Component | Integration | Notes |
|-----------|-------------|-------|
| `LocationResolver` | Call `saveManual()` on confirm | Existing service (A4) |
| `HomeController` | Reload on location change | Existing reload pattern |
| `GoogleMap` widget | Reuse existing map setup | From MapScreen (A10) |
| `GeographicUtils.logRedact()` | All coordinate logging | C2 compliance |

---

## API Keys & External Services

### what3words API
- **Purpose**: Convert coordinates ↔ what3words addresses
- **Rate Limits**: 1000 requests/day (free tier)
- **Fallback**: Display "what3words unavailable" if API fails

### Google Places API (for search)
- **Purpose**: Place autocomplete and geocoding
- **Scope**: Place Autocomplete, Place Details
- **Fallback**: Search disabled, tap-to-place still works

---

## Design Decisions

1. **ReportFireScreen integration**: Use Navigator.pop with typed `PickedLocation` result
   - Rationale: ReportFireScreen is static guidance screen, no dynamic state to manage
   - LocationPicker is transient (pick → return → done), doesn't need controller infrastructure
   - Future-proof: Add `ReportFireController` only if draft reports, backend submission, or photo uploads added later
   
2. **what3words integration**: Direct HTTP integration (not SDK)
   - Rationale: Matches existing service patterns (`EffisService`, `SepaService`)
   - Uses existing `http` package + `dartz` Either pattern
   - Zero bundle size increase vs ~2-3MB for SDK
   - Full control over error handling and retry logic

3. **Places API**: ✅ Confirmed available
   - Google Cloud project already configured for Maps API
   - Enable "Places API" in same project (APIs & Services → Enable APIs)
   - Existing API key restrictions apply

---

## Review & Acceptance Checklist

### Code Quality (C1)
- [ ] All files pass `flutter analyze`
- [ ] Follows existing patterns (ChangeNotifier, Either<L,R>)
- [ ] Consistent naming conventions

### Privacy Compliance (C2)
- [ ] All coordinate logging uses `GeographicUtils.logRedact()`
- [ ] No full-precision coordinates in logs or analytics
- [ ] what3words addresses NOT logged (can identify locations)

### Accessibility (C3)
- [ ] Touch targets ≥48dp
- [ ] Semantics labels on all interactive elements
- [ ] VoiceOver/TalkBack tested

### Transparency (C4)
- [ ] Error messages are clear and actionable
- [ ] Loading states visible
- [ ] what3words source attribution displayed

### Resilience (C5)
- [ ] Graceful fallback when what3words API unavailable
- [ ] Graceful fallback when Places API unavailable
- [ ] GPS unavailable handled elegantly

---

## Out of Scope (Future)

- Offline what3words (requires SDK license)
- Voice search for what3words
- AR view for location confirmation
- Saved locations list
- what3words in push notifications

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked → **All resolved**
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Design decisions documented
- [ ] Review checklist passed (pending implementation)
