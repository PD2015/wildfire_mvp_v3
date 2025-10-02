# Feature Specification: EffisService (FWI Point Query)

**Feature Branch**: `001-spec-a1-effisservice`  
**Created**: 2025-10-02  
**Status**: Draft  
**Input**: User description: "Spec A1 — EffisService (FWI point query)"

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a WildFire MVP user, I need the app to retrieve current Fire Weather Index (FWI) data for my location so that I can see accurate wildfire risk information on the home screen.

### Acceptance Scenarios
1. **Given** a user at a valid UK coordinate, **When** the app requests FWI data, **Then** it returns current fire weather index with risk level and timestamp
2. **Given** a user at coordinates where EFFIS has no data, **When** the app requests FWI data, **Then** it returns a clear error that can be handled by fallback systems
3. **Given** EFFIS service is temporarily unavailable, **When** the app requests FWI data, **Then** it times out gracefully and returns an error for fallback handling
4. **Given** EFFIS returns malformed data, **When** the app processes the response, **Then** it detects the invalid format and returns an appropriate error

### Edge Cases
- What happens when coordinates are outside EFFIS coverage area?
- How does system handle network timeouts during peak usage?
- What occurs when EFFIS API changes response format unexpectedly?
- How are rate limits from EFFIS handled?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST retrieve Fire Weather Index values for given latitude/longitude coordinates
- **FR-002**: System MUST convert raw FWI values to standardized risk levels (veryLow, low, moderate, high, veryHigh, extreme)
- **FR-003**: System MUST provide timestamp indicating when FWI observation was recorded
- **FR-004**: System MUST handle network timeouts gracefully with configurable timeout duration
- **FR-005**: System MUST implement retry logic with exponential backoff for failed requests
- **FR-006**: System MUST validate coordinate inputs are within reasonable bounds
- **FR-007**: System MUST return structured error information for all failure cases
- **FR-008**: System MUST complete successful requests within 3 seconds under normal network conditions
- **FR-009**: System MUST log request metrics without exposing sensitive location data
- **FR-010**: System MUST work with 4 representative UK coordinate locations for testing

### Non-Functional Requirements
- **NFR-001**: Service MUST NOT cache or store FWI data (delegated to higher-level services)
- **NFR-002**: Service MUST NOT render UI components or handle user interface concerns
- **NFR-003**: Service MUST NOT handle polygon or raster data processing
- **NFR-004**: Privacy requirement: coordinate logging MUST be limited to 3 decimal places maximum
- **NFR-005**: Security requirement: no API keys required for EFFIS access, future authentication via environment variables only

### Key Entities *(include if feature involves data)*
- **FWI Result**: Contains fire weather index numeric value, mapped risk level, observation timestamp, and data source URI
- **API Error**: Contains error type, error message, retry information, and failure context for upstream handling
- **Risk Level**: Standardized wildfire risk categories mapped from FWI values using official thresholds

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
