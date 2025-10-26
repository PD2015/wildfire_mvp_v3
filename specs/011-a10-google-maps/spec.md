# Feature Specification: A10 – Google Maps MVP Map

**Feature Branch**: `011-a10-google-maps`  
**Created**: October 19, 2025  
**Status**: Draft  
**Input**: User description: "Replace the placeholder MapScreen with a production-ready Google Maps implementation that renders user location, active fire markers from EFFIS, and a basic risk check action. Must follow the 4-tier fallback (EFFIS → SEPA → Cache → Mock) and pass constitution gates C1–C5."

## Execution Flow (main)
```
1. Parse user description from Input
   → Feature replaces placeholder map with production Google Maps
2. Extract key concepts from description
   → Actors: wildfire-aware users, emergency responders
   → Actions: view map, see fire locations, check risk at location
   → Data: user location, active fires, fire weather index
   → Constraints: 4-tier service fallback, constitutional compliance
3. For each unclear aspect:
   → All requirements clearly specified in user input
4. Fill User Scenarios & Testing section
   → Clear user flow: open map → see location & fires → check risk
5. Generate Functional Requirements
   → Each requirement mapped to success criteria
6. Identify Key Entities
   → Fire incidents, user location, risk assessments
7. Run Review Checklist
   → No ambiguities identified, implementation ready
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing

### Primary User Story
A user opens the wildfire app and navigates to the map screen to see active fire incidents in their area and assess fire risk at their current location or any point of interest. The map displays their location (GPS or manual), shows fire markers with source attribution, and allows them to tap anywhere to get a fire weather risk assessment.

### Acceptance Scenarios
1. **Given** user opens map with GPS enabled, **When** map loads, **Then** map centers on user location and displays active fire markers within viewable area
2. **Given** user denies GPS permission, **When** map loads, **Then** map centers on default location and displays fire markers with option to manually set location
3. **Given** active fires exist in viewable area, **When** user taps fire marker, **Then** details sheet shows fire source (EFFIS/SEPA/Cache/Mock) and timestamp
4. **Given** user wants risk assessment, **When** user taps "Check risk here" on any map location, **Then** system displays fire weather index chip with risk level and data source
5. **Given** network connectivity issues, **When** map loads, **Then** system falls back through service chain (EFFIS → SEPA → Cache → Mock) and displays appropriate data freshness indicators
6. **Given** user with accessibility needs, **When** interacting with map, **Then** all controls meet 44dp minimum size and provide semantic labels for screen readers

### Edge Cases
- What happens when GPS is unavailable but user needs location context? → System provides manual location input option
- How does system handle complete service failures? → Never-fail guarantee via mock data fallback with clear "Demo Data" labeling
- What if active fires exceed display capacity? → System displays up to 50 markers without performance degradation
- How are outdated fire reports handled? → Clear timestamp display and cache expiry indicators

## Requirements

### Functional Requirements
- **FR-001**: System MUST replace placeholder MapScreen with interactive Google Maps interface
- **FR-002**: System MUST display user location on map using GPS or manual input fallback
- **FR-003**: System MUST render active fire incident markers from external data sources
- **FR-004**: System MUST implement 4-tier service fallback (EFFIS → SEPA → Cache → Mock) for fire data
- **FR-005**: System MUST display fire marker details including data source and timestamp when tapped
- **FR-006**: System MUST provide "Check risk here" functionality for any map location
- **FR-007**: System MUST display fire weather index risk assessment with source attribution
- **FR-008**: System MUST show data freshness indicators (Live/Cached/Mock) for all displayed information
- **FR-009**: System MUST render initial map interface within 3 seconds of navigation
- **FR-010**: System MUST handle up to 50 fire markers without performance degradation
- **FR-011**: System MUST maintain memory usage under 75MB on map screen
- **FR-012**: System MUST provide accessibility compliance with 44dp minimum control sizes
- **FR-013**: System MUST implement semantic labeling for screen reader compatibility
- **FR-014**: System MUST prevent personally identifiable information exposure in logs
- **FR-015**: System MUST display proper data source attribution for all fire information
- **FR-016**: System MUST function when GPS permission is denied using fallback location methods

### Key Entities
- **Fire Incident**: Represents an active fire location with coordinates, intensity level, detection timestamp, and data source (EFFIS/SEPA/Cache/Mock)
- **User Location**: Current or selected geographic position used for map centering and risk assessments
- **Risk Assessment**: Fire weather index value at a specific location with risk level classification and data source attribution
- **Map State**: Current view boundaries, zoom level, and loaded fire incidents within visible area
- **Service Response**: Data retrieval result from fire information services including success/failure status and fallback chain position

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
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed
