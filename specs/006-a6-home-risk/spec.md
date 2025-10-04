# Feature Specification: A6 — Home (Risk Feed Container & Screen)

**Feature Branch**: `006-a6-home-risk`  
**Created**: 2025-10-04  
**Status**: Draft  
**Input**: User description: "A6 — Home (Risk Feed Container & Screen) Goal: Render RiskBanner on the Home screen and wire it to LocationResolver + FireRiskService so users always see a risk value (live/cached/mock) with timestamp and source. Scope: Home controller (ChangeNotifier or Riverpod), HomeState model, HomeScreen UI with Retry + manual location button, navigation entry. Out of scope: Implementing Effis/Cache/Location internals (A1/A5/A4), maps. Acceptance: On launch, RiskBanner shows Loading → Success or Error(+Cached). Retry works. Manual location updates state. A11y + colors + timestamp/source comply with Constitution. Tests: Integration tests with fakes for success/fallback/error/cached, a11y labels, and 44dp targets. Gates: C1/C3/C4/C5."

## Execution Flow (main)
```
1. Parse user description from Input ✓
   → Feature: Home screen displaying fire risk information
2. Extract key concepts from description ✓
   → Actors: App users seeking fire risk information
   → Actions: View risk, retry on failure, update location manually
   → Data: Fire risk level, timestamp, data source, location
   → Constraints: A11y compliance, constitutional gates C1/C3/C4/C5
3. For each unclear aspect: ✓
   → All aspects clearly defined in user input
4. Fill User Scenarios & Testing section ✓
   → Clear user flow: Launch → Loading → Risk display with fallback handling
5. Generate Functional Requirements ✓
   → All requirements testable and measurable
6. Identify Key Entities ✓
   → HomeState, FireRisk, Location data
7. Run Review Checklist ✓
   → No implementation details, focused on user value
8. Return: SUCCESS (spec ready for planning) ✓
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a wildfire-aware resident, I want to immediately see the current fire risk level for my location when I open the app, so I can make informed decisions about outdoor activities and safety precautions. The app should gracefully handle connectivity issues and always provide some risk indication, even if from cached data or fallback sources.

### Acceptance Scenarios
1. **Given** I open the app for the first time, **When** the app launches, **Then** I see a loading indicator followed by my current fire risk level with timestamp and data source
2. **Given** I'm viewing the home screen, **When** the risk data fails to load, **Then** I see an error message with a retry button and any available cached data
3. **Given** I'm on the home screen with an error state, **When** I tap the retry button, **Then** the app attempts to reload risk data and updates the display accordingly
4. **Given** I want to check risk for a different location, **When** I tap the manual location button, **Then** I can enter coordinates and see updated risk information for that location
5. **Given** I'm using assistive technology, **When** I navigate the home screen, **Then** all elements have appropriate accessibility labels and the interface meets WCAG guidelines
6. **Given** the app has cached risk data, **When** fresh data is unavailable, **Then** I see the cached risk level clearly marked with its timestamp and "cached" source indicator

### Edge Cases
- What happens when location services are denied? → App shows manual location entry option and falls back to default Scotland location
- How does system handle complete network failure? → App displays cached data if available, or shows mock/default risk level with clear source labeling
- What if cached data is expired? → App attempts refresh but still shows expired cache with clear timestamp, allowing user to decide on relevance
- How does retry work during poor connectivity? → App provides visual feedback during retry attempts with timeout handling

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST display fire risk information prominently on the home screen as the primary content
- **FR-002**: System MUST show loading states during data fetching to provide user feedback
- **FR-003**: System MUST display timestamp and data source (live/cached/mock) for transparency  
- **FR-004**: System MUST provide retry functionality when risk data loading fails
- **FR-005**: System MUST display cached risk data when fresh data is unavailable, clearly marked as cached
- **FR-006**: System MUST provide manual location entry capability accessible from the home screen
- **FR-007**: System MUST update risk display immediately when location is manually changed
- **FR-008**: System MUST implement proper error handling showing meaningful messages to users
- **FR-009**: System MUST comply with accessibility guidelines including proper labels and 44dp minimum touch targets
- **FR-010**: System MUST use approved color scheme and maintain constitutional compliance (C1/C3/C4/C5)
- **FR-011**: System MUST gracefully degrade through available data sources (live → cached → mock) without crashes
- **FR-012**: System MUST persist user's manual location choices for subsequent app launches

### Key Entities *(include if feature involves data)*
- **HomeState**: Represents current screen state including loading/success/error states, risk data, location information, and user interaction capabilities
- **FireRisk**: Fire risk level information including risk value, confidence level, timestamp, and data source identifier  
- **LocationInfo**: User's current or manually selected location with coordinates and optional place name for context
- **DataSource**: Source indicator (live/cached/mock) to maintain transparency about data freshness and reliability

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
