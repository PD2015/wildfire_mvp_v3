# Feature Specification: FireRiskService (Fallback Orchestrator)

**Feature Branch**: `002-spec-a2-fireriskservice`  
**Created**: 2 October 2025  
**Status**: Draft  
**Input**: User description: "Spec A2 — FireRiskService (fallback orchestrator) - Return a normalized FireRisk using a fallback chain: EFFIS → SEPA → cache → mock"

## Goal & Motivation

### Business Goal
Provide users with reliable fire risk information that is always available, ensuring the mobile application never displays "no data available" messages that could undermine user confidence in critical safety information.

### Success Metrics
- **Availability**: 99.9% successful FireRisk responses under all network conditions
- **Source Diversity**: Effective fallback chain utilization preventing single points of failure
- **User Trust**: Consistent risk data availability with clear source attribution
- **Performance**: Total response time including fallbacks under 10 seconds

### Non-Goals
- UI rendering and presentation of fire risk data (covered in Spec A3)
- Low-level cache storage mechanics and persistence strategies (covered in Spec A5)
- Real-time data streaming or push notifications
- Advanced geographic services beyond Scotland boundary detection

---
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
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

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
A mobile app user wants to check wildfire risk for their current location. The system must always provide a fire risk assessment, even when primary data sources are unavailable, by intelligently falling back through multiple data sources to ensure users never receive "no data available" responses.

### Acceptance Scenarios
1. **Given** EFFIS service is operational, **When** user requests fire risk for coordinates, **Then** system returns live EFFIS data with "effis" source and "live" freshness
2. **Given** EFFIS service is down and location is in Scotland, **When** user requests fire risk, **Then** system falls back to SEPA service and returns data with "sepa" source
3. **Given** both EFFIS and SEPA services are down, **When** user requests fire risk, **Then** system returns cached data (≤6h old) with "cache" freshness
4. **Given** all services are down and no valid cache exists, **When** user requests fire risk, **Then** system returns mock data with "moderate" risk level and "mock" source
5. **Given** location is outside Scotland, **When** EFFIS fails, **Then** system skips SEPA and proceeds to cache/mock without error

### Edge Cases
- What happens when cache data is older than 6 hours? (System skips cache and proceeds to mock)
- How does system handle invalid coordinates? (Return validation error before attempting any service calls)
- What if location is on Scottish border? (System uses precise boundary logic to determine if SEPA should be attempted)
- How does system behave with network timeouts? (Each service has timeout limits, system proceeds to next fallback)
- What happens during clock skew scenarios? (System uses UTC timestamps consistently)

## Requirements *(mandatory)*

### Functional Requirements

#### Core Orchestration
- **FR-001**: System MUST attempt fire risk data sources in strict fallback order: EFFIS → SEPA → Cache → Mock
- **FR-002**: System MUST return a FireRisk result under all conditions, never failing completely
- **FR-003**: System MUST validate coordinate parameters (lat: -90 to 90, lon: -180 to 180) before attempting any service calls
- **FR-004**: System MUST skip SEPA service when coordinates are outside Scotland boundary without treating as error
- **FR-005**: System MUST include accurate source attribution ("effis", "sepa", "cache", "mock") in all responses

#### Data Freshness & Caching
- **FR-006**: System MUST respect 6-hour cache TTL, automatically skipping expired cache entries
- **FR-007**: System MUST mark data freshness as "live" for real-time service calls or "cached" for stored data
- **FR-008**: System MUST include UTC timestamp (updatedAt) indicating when data was originally obtained
- **FR-009**: System MUST preserve original FWI values when available from EFFIS/SEPA sources

#### Geographic Logic
- **FR-010**: System MUST implement Scotland boundary detection using precise geographic coordinates
- **FR-011**: System MUST handle edge cases near Scottish borders consistently and predictably
- **FR-012**: System MUST process coordinates without persisting raw location data beyond caching needs

#### Error Resilience
- **FR-013**: System MUST continue fallback chain when individual services timeout or return errors
- **FR-014**: System MUST return mock data (moderate risk level) as ultimate fallback when all other sources fail
- **FR-015**: System MUST log telemetry data including: source chosen, attempt count, total latency, cache hit/miss status

#### Privacy & Security
- **FR-016**: System MUST round coordinates to 2-3 decimal places in logs to prevent precise location tracking
- **FR-017**: System MUST NOT persist personally identifiable location information beyond coarse caching keys
- **FR-018**: System MUST use only coarse geohash-based keys for caching without storing exact coordinates

### Key Entities *(include if feature involves data)*
- **FireRisk**: Normalized fire risk assessment containing risk level (veryLow to extreme), optional FWI value, data source, timestamp, and freshness indicator
- **GeographicBoundary**: Scotland region boundary logic for determining SEPA service eligibility
- **CacheEntry**: Temporary storage of fire risk data with TTL and geohash-based location keys
- **ServiceFallback**: Orchestration chain managing EFFIS → SEPA → Cache → Mock progression with reason codes

---

## Review & Acceptance Checklist
*GATE: Automated checks completed during specification creation*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs) - focuses on business logic and user needs
- [x] Focused on user value and business needs - emphasizes reliability and user trust
- [x] Written for non-technical stakeholders - uses business terminology and user scenarios
- [x] All mandatory sections completed - scenarios, requirements, entities documented

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain - all requirements clearly specified
- [x] Requirements are testable and unambiguous - each FR can be validated objectively
- [x] Success criteria are measurable - availability %, response times, source attribution
- [x] Scope is clearly bounded - excludes UI rendering, low-level caching, notifications
- [x] Dependencies and assumptions identified - service dependencies, constitutional gates, constraints

---

## Dependencies & Constraints

### Technical Dependencies
- **EFFIS Service**: Primary data source (implemented in Spec A1)
- **SEPA Service**: Secondary data source for Scotland region
- **Cache Service**: Local data persistence with TTL management
- **Geographic Utilities**: Scotland boundary detection logic

### Constitutional Gates
- **C1 (Code Quality)**: All code must pass testing and analysis requirements
- **C2 (Security & Privacy)**: No PII persistence, coordinate rounding in logs
- **C5 (Resilience)**: Comprehensive error handling and fallback mechanisms

### Performance Constraints
- **Response Time**: Total orchestration time ≤10 seconds including all fallbacks
- **Cache TTL**: 6-hour maximum for stored fire risk data
- **Geographic Precision**: Coordinate rounding to 2-3 decimal places for privacy

## Execution Status
*Updated during specification processing*

- [x] User description parsed and analyzed
- [x] Key concepts extracted (orchestration, fallback, normalization)
- [x] Business scenarios and edge cases defined
- [x] Functional requirements generated and categorized
- [x] Key entities identified with relationships
- [x] Dependencies and constraints documented
- [x] Review checklist completed - specification ready for planning

---
