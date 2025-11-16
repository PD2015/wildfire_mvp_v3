````markdown
# Feature Specification: Map Fire Information Sheet

**Feature Branch**: `018-map-fire-information`  
**Created**: 2025-11-12  
**Status**: Draft  
**Input**: User description: "Map Fire Information Sheet - Users can see fire markers on the map but lack contextual details to make safe, informed decisions. We need a tap-for-details bottom sheet that shows key attributes about a selected fire and ties into our existing EFFIS risk service for trust and transparency."

## Execution Flow (main)
```
1. Parse user description from Input
   → ✅ Feature parsed: Interactive fire details for map markers
2. Extract key concepts from description
   → ✅ Actors: Wildfire app users; Actions: tap marker, view details; Data: fire attributes, risk levels; Constraints: safety decisions, trust/transparency
3. For each unclear aspect:
   → ✅ All aspects clearly defined in problem statement
4. Fill User Scenarios & Testing section
   → ✅ Clear user flow: view map → tap marker → see details → make safety decision
5. Generate Functional Requirements
   → ✅ Requirements defined and testable
6. Identify Key Entities (if data involved)
   → ✅ Fire incidents and risk assessments identified
7. Run Review Checklist
   → ✅ Business-focused, no implementation details
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
A wildfire application user is viewing the map with fire markers visible in their region. They want to understand the severity and details of a specific fire to make informed safety decisions for their location or travel plans. They tap on a fire marker and expect to see comprehensive information including when the fire was detected, its intensity, confidence level, and the associated wildfire risk level for that location.

### Acceptance Scenarios
1. **Given** user is viewing map with visible fire markers, **When** user taps on any fire marker, **Then** a bottom sheet appears showing fire details including detection time, data source, confidence level, fire radiative power, last update time, distance from user location, and current risk level
2. **Given** user has tapped a fire marker, **When** the fire information sheet is displayed, **Then** the sheet shows appropriate data source indicators (live data vs demo data) and risk level using color-coded visual elements
3. **Given** user is viewing fire information sheet, **When** data cannot be loaded or is outdated, **Then** user sees clear error messaging with option to retry loading the information
4. **Given** user is viewing fire information sheet, **When** user wants to dismiss the details, **Then** user can close the sheet by tapping outside it, swiping down, or using a close button
5. **Given** application is in demo mode, **When** user views any fire information, **Then** clear "DEMO DATA" indicators are prominently displayed

### Edge Cases
- What happens when fire data is stale or unavailable from the data source?
- How does system handle location services being disabled (for distance calculation)?
- What information is shown when risk level calculation fails?
- How are very old fire incidents (>72 hours) visually distinguished?
- What happens when user taps multiple markers in quick succession?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST display a detailed information sheet when user taps on any fire marker
- **FR-002**: System MUST show fire detection timestamp in user's local timezone with clear date/time formatting
- **FR-003**: System MUST display data source information (satellite sensor type: VIIRS, MODIS, etc.)
- **FR-004**: System MUST show confidence level as both percentage and descriptive text (e.g., "High confidence: 85%")
- **FR-005**: System MUST display Fire Radiative Power (FRP) value with appropriate units and intensity description
- **FR-006**: System MUST show last data update timestamp to indicate information freshness
- **FR-007**: System MUST calculate and display distance from user's current location to fire location
- **FR-008**: System MUST calculate and display bearing/direction from user location to fire (e.g., "15km Northeast")
- **FR-009**: System MUST retrieve and display current wildfire risk level for the fire's coordinates using existing risk assessment service
- **FR-010**: System MUST display appropriate data source badges indicating live vs demo data mode
- **FR-011**: System MUST show "DEMO DATA" warning when application is in demonstration mode
- **FR-012**: System MUST provide clear error messages when fire details cannot be retrieved
- **FR-013**: System MUST offer retry functionality when data loading fails
- **FR-014**: System MUST use accessible color schemes and typography for all risk level indicators
- **FR-015**: System MUST ensure all interactive elements meet minimum touch target size requirements
- **FR-016**: System MUST provide appropriate screen reader support for all displayed information
- **FR-017**: System MUST allow users to dismiss the information sheet through multiple interaction methods
- **FR-018**: System MUST handle rapid successive marker taps gracefully without UI conflicts
- **FR-019**: System MUST cache recently viewed fire information to improve performance on repeat access
- **FR-020**: System MUST refresh stale fire information automatically when sheet is opened

### Key Entities *(include if feature involves data)*
- **Fire Incident**: Represents an active wildfire detection with attributes including unique identifier, geographic coordinates, detection timestamp, data source sensor, confidence percentage, fire radiative power measurement, and last update time
- **Risk Assessment**: Represents wildfire risk evaluation for a specific geographic location with risk level classification, assessment timestamp, and data source attribution
- **User Location**: Represents current user position used for calculating distance and bearing to fire incidents, with privacy-appropriate coordinate resolution
- **Data Source Indicator**: Represents the origin and reliability of fire and risk data, including live vs demonstration mode flags and sensor/service attribution

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

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
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---

````
