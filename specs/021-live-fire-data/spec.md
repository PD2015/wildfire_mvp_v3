# Feature Specification: Live Fire Data Display

**Feature Branch**: `021-live-fire-data`  
**Created**: 2025-12-09  
**Status**: Draft  
**Input**: User description: "Live Fire Data Display - GWIS Hotspots and EFFIS Burnt Areas (Phases 2-3)"

---

## Purpose

Enable users to view real-time and historical fire activity on the map through two distinct data layers: active hotspots (where fires are burning now) and verified burnt areas (confirmed fire damage after containment).

## Problem Statement

Currently, the map displays mock fire data. Users cannot:
1. See real-time satellite-detected fire hotspots from the last 24 hours
2. View verified burnt area perimeters with authoritative size data
3. Distinguish between "active now" fires and "historically burned" areas
4. Filter between different time periods of fire data

The existing map infrastructure (Google Maps, markers, polygons, bottom sheet) is in place but needs integration with live GWIS and EFFIS data sources.

---

## User Scenarios & Testing

### Primary User Story

As a Scottish resident concerned about wildfires, I want to see where fires are currently burning and where fires have previously burned, so I can understand fire activity in areas I care about.

### Acceptance Scenarios

#### Hotspot Display (Active Fires)

1. **Given** the user opens the Fire Map with "Active Hotspots" mode selected, **When** there are satellite-detected fires in Scotland from the last 24 hours, **Then** each detection appears as a semi-transparent orange/red square on the map representing the 375m detection area.

2. **Given** the user is viewing the map at a zoomed-out level (regional view), **When** multiple hotspots are close together, **Then** they are grouped into a single cluster showing a count badge (e.g., "5 detections").

3. **Given** the user taps a cluster badge, **When** the cluster contains multiple hotspots, **Then** the map zooms in to show individual hotspot squares.

4. **Given** the user taps an individual hotspot square, **When** viewing at detailed zoom, **Then** a bottom sheet appears showing: detection time (relative format), satellite sensor, confidence level, and fire intensity.

5. **Given** the user wants to see fires from the past week, **When** they select "This Week" filter, **Then** the map shows hotspots from the last 7 days instead of just 24 hours.

#### Burnt Area Display (Verified Perimeters)

6. **Given** the user opens the Fire Map with "Burnt Areas" mode selected, **When** there are verified burnt areas for the current fire season, **Then** semi-transparent polygons show the fire perimeters.

7. **Given** the user taps a burnt area polygon, **When** viewing the details, **Then** a bottom sheet shows: official area in hectares, fire date, last update date, and land cover breakdown (if available).

8. **Given** a burnt area has been simplified for display, **When** viewing the details, **Then** a notice indicates the boundary is simplified and shows the official verified size.

#### Mode Toggle (Mutual Exclusivity)

9. **Given** the user is viewing Active Hotspots, **When** they switch to Burnt Areas mode, **Then** hotspots are hidden and only burnt area polygons are shown.

10. **Given** the user is viewing Burnt Areas, **When** they switch to Active Hotspots mode, **Then** burnt areas are hidden and only hotspot squares are shown.

#### Empty States

11. **Given** no active hotspots exist in the visible map region, **When** viewing Active Hotspots mode, **Then** a message states "No active fires detected" with a hint to toggle to past fires.

12. **Given** the burnt area service is unavailable, **When** the user tries to view Burnt Areas, **Then** mock/cached data is shown with an indicator that data may be outdated.

### Edge Cases

- **Cluster at zoom boundary**: When user zooms from level 9 to 10, clusters smoothly transition to individual squares
- **Very large burnt area**: Polygons with many points are simplified without losing general shape accuracy
- **Missing land cover data**: If land cover breakdown is unavailable, show "Land cover: Unknown"
- **Service unavailable**: Fall back to mock data with appropriate indicator
- **Pull to refresh**: User can manually refresh fire data at any time

---

## Requirements

### Functional Requirements

#### Data Display - Hotspots

- **FR-001**: System MUST display active fire hotspots as semi-transparent squares representing the satellite detection area (approximately 375 metres)
- **FR-002**: System MUST show hotspot detection time in relative format (e.g., "2 hours ago", "yesterday")
- **FR-003**: System MUST display satellite sensor information (e.g., "VIIRS on NOAA-21")
- **FR-004**: System MUST show confidence level as percentage (e.g., "High 95%")
- **FR-005**: System MUST display fire radiative power intensity in descriptive terms (e.g., "Strong - 45 MW")
- **FR-006**: System MUST cluster nearby hotspots when viewing at regional zoom levels, showing count badge
- **FR-007**: System MUST zoom to show individual hotspots when user taps a cluster

#### Data Display - Burnt Areas

- **FR-008**: System MUST display verified burnt area perimeters as semi-transparent filled polygons
- **FR-009**: System MUST show official burnt area size in hectares (authoritative EFFIS figure)
- **FR-010**: System MUST display fire detection date and last update date
- **FR-011**: System MUST show land cover breakdown when available, or "Unknown" when missing
- **FR-012**: System MUST indicate when polygon boundary has been simplified for display
- **FR-013**: System MUST only show burnt areas from the current fire season (previous seasons hidden entirely)

#### Mode Toggle

- **FR-014**: System MUST provide a toggle to switch between "Active Hotspots" and "Burnt Areas" display modes
- **FR-015**: System MUST show only one data type at a time (mutually exclusive modes)
- **FR-016**: System MUST default to "Active Hotspots" mode when map is opened
- **FR-017**: System MUST reset filter selection to default ("Today") when starting a new session

#### Time Filters

- **FR-018**: System MUST provide "Today" filter (last 24 hours) for hotspot data
- **FR-019**: System MUST provide "This Week" filter (last 7 days) for hotspot data
- **FR-020**: System MUST provide "This Season" filter for burnt area data (current fire season: March-September)

#### User Interface

- **FR-021**: System MUST maintain existing map controls, buttons, and styling
- **FR-022**: System MUST maintain existing timestamp chip showing data freshness
- **FR-023**: System MUST maintain existing bottom sheet design for fire details
- **FR-024**: All interactive elements MUST meet minimum touch target size (44dp)
- **FR-025**: System MUST provide pull-to-refresh gesture for manual data refresh

#### Empty States

- **FR-026**: When no active fires exist, system MUST show message "No active fires detected" with instruction to toggle for past fires
- **FR-027**: System MUST maintain existing empty state card styling

#### Error Handling

- **FR-028**: System MUST fall back to mock data when live data services are unavailable
- **FR-029**: System MUST indicate when showing fallback/cached data vs live data

#### Educational Content

- **FR-030**: Hotspot details MUST include educational label explaining satellite detection accuracy (~375m)
- **FR-031**: Burnt area details MUST include educational label explaining verified perimeter mapping

### Non-Functional Requirements

- **NFR-001**: Polygon simplification MUST reduce complex boundaries to maximum 500 points for rendering performance
- **NFR-002**: Coordinate logging MUST use 2 decimal place precision only (privacy compliance)
- **NFR-003**: Map rendering with 50+ fire elements MUST remain smooth without visible lag

---

## Key Entities

### Fire Hotspot
- **What it represents**: A satellite-detected thermal anomaly indicating possible active fire
- **Key attributes**: Location (point), detection time, satellite sensor, confidence percentage, fire intensity (MW), data source
- **Relationship**: Displayed as square on map, tappable for details

### Burnt Area
- **What it represents**: A verified fire perimeter mapped after containment
- **Key attributes**: Boundary polygon, official area (hectares), fire date, last update, land cover breakdown, simplification status
- **Relationship**: Displayed as polygon on map, tappable for details

### Fire Data Mode
- **What it represents**: The currently selected view type
- **Options**: Active Hotspots, Burnt Areas
- **Behaviour**: Mutually exclusive - only one mode active at a time

### Time Filter
- **What it represents**: The time period for displayed data
- **Options for Hotspots**: Today (24h), This Week (7 days)
- **Options for Burnt Areas**: This Season (current fire season)
- **Behaviour**: Resets to default each session

---

## Constraints & Assumptions

### Constraints
- Hotspot location accuracy is limited to ~375m (satellite pixel size)
- Burnt area boundaries must be simplified for mobile rendering performance
- Only current season burnt areas are shown (no historical seasons in this phase)
- Hotspots and burnt areas cannot be displayed simultaneously

### Assumptions
- GWIS and EFFIS data services are accessible from the app
- Fire season is defined as March 1 to September 30
- Users understand the difference between "active" and "historical" fire data after seeing the mode toggle
- Land cover data may be missing for some burnt areas

### Dependencies
- Existing map screen infrastructure (Google Maps, markers, polygons)
- Existing bottom sheet component for fire details
- Existing timestamp chip for data freshness
- Existing empty state card component

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked and resolved via clarification
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

**Result**: SUCCESS - Spec ready for planning phase
