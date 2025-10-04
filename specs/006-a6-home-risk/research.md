# Research: A6 — Home (Risk Feed Container & Screen)

**Feature**: Home screen integration with existing services  
**Date**: 2025-10-04  
**Phase**: 0 (Research & Unknowns Resolution)

## Research Tasks Completed

### 1. State Management Approach
**Decision**: ChangeNotifier for HomeController  
**Rationale**: 
- User explicitly requested "prefer ChangeNotifier for MVP"
- No new third-party state management libraries allowed
- ChangeNotifier is lightweight and suitable for single-screen state
- Integrates well with existing service layer (A1-A5)

**Alternatives Considered**:
- Riverpod: Rejected due to "no new third-party libs unless already present" constraint
- StatefulWidget only: Rejected due to complexity of managing multiple async operations
- BLoC: Rejected as it would require flutter_bloc dependency

### 2. Service Integration Patterns
**Decision**: Dependency injection via constructor for testability  
**Rationale**:
- Allows mock injection for testing (6 test scenarios required)
- Follows established patterns from A2-A5 implementations
- Enables isolation testing of HomeController logic

**Integration Points Identified**:
- LocationResolver (A4): For getting user location with fallback chain
- FireRiskService (A2): For retrieving risk data with EFFIS/SEPA/Cache/Mock fallback
- CacheService (A5): Implicit via FireRiskService integration

### 3. HomeState Design
**Decision**: Sealed class hierarchy with loading/success/error states  
**Rationale**:
- Explicit state modeling prevents invalid states
- Supports error states with optional cached data
- Aligns with "fail visible, not silent" constitutional principle
- Enables comprehensive test coverage

**States Identified**:
- `HomeStateLoading`: Initial load or retry in progress
- `HomeStateSuccess`: Risk data loaded successfully with timestamp and source
- `HomeStateError`: Failed to load with optional cached data and retry capability

### 4. Testing Strategy
**Decision**: 6 integration test scenarios with service mocks  
**Rationale**:
- User specified exact test matrix: EFFIS, SEPA, cache, mock, location denied→manual, retry
- Integration tests verify complete user flows
- Service mocks enable controlled testing of each data source
- Widget tests for UI components ensure accessibility compliance

**Test Scenarios Mapped**:
1. EFFIS success flow
2. SEPA success flow (Scotland location)
3. Cache fallback flow
4. Mock fallback flow
5. Location denied → manual entry flow
6. Retry after error flow

### 5. UI/UX Requirements Research
**Decision**: RiskBanner integration with timestamp and source visibility  
**Rationale**:
- Existing RiskBanner from A3 provides risk display functionality
- Constitutional requirement C4: timestamp and source labeling mandatory
- Accessibility requirements C3: 44dp targets, semantic labels

**UI Components Needed**:
- Home screen layout with RiskBanner integration
- Manual location dialog with coordinate validation
- Retry button with loading state indication
- Source chips/badges for data provenance
- Relative timestamp display ("Updated 5 minutes ago")

### 6. Performance and Lifecycle
**Decision**: Load on screen init, cache-first for subsequent views  
**Rationale**:
- User expects immediate risk information on app launch
- Existing services handle network timeouts and error states
- HomeController lifecycle tied to screen lifecycle for resource management

**Load Sequence**:
1. HomeController.load() called on screen init
2. LocationResolver gets current/cached/manual location
3. FireRiskService fetches risk data (with fallback chain)
4. UI updates based on resulting HomeState

## Technical Decisions Summary

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| State Management | ChangeNotifier | User preference, no new dependencies |
| Service Integration | Constructor injection | Testability and existing patterns |
| State Modeling | Sealed class hierarchy | Explicit state, error handling |
| Testing Approach | 6 integration scenarios | User-specified test matrix |
| UI Strategy | RiskBanner integration | Reuse existing A3 component |
| Performance | Cache-first after initial load | Responsive user experience |

## Dependencies Confirmed
- Flutter SDK (existing)
- ChangeNotifier (Flutter built-in)
- LocationResolver from A4 (existing)
- FireRiskService from A2 (existing)
- CacheService integration via A2 (existing)
- RiskBanner from A3 (existing)

## Risk Mitigation
- **Service Integration**: All A1-A5 services already implemented and tested
- **State Complexity**: ChangeNotifier keeps state management simple
- **Testing Coverage**: 6 scenarios cover all major user flows
- **Performance**: Existing services handle network timeouts and caching

---

**Status**: ✅ All technical unknowns resolved  
**Next Phase**: Design & Contracts (data models, API contracts, quickstart)