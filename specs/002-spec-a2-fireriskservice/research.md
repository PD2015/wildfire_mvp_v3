# Research: FireRiskService Technical Implementation

## Problem Statement
Users need reliable fire risk information that's always available, even when individual data sources fail. The implementation challenge is creating a resilient orchestration system that balances data quality, availability, and user trust while respecting privacy constraints and constitutional requirements.

## Key Research Areas

### 1. Fallback Strategy Design

#### Decision: Sequential vs Parallel Service Calls
**Chosen**: Sequential fallback chain
**Rationale**: 
- Preserves data source priority (EFFIS is most authoritative)
- Reduces unnecessary API calls and bandwidth usage
- Simpler error handling and timeout management
- Clear audit trail of which source provided data

**Alternative Considered**: Parallel calls with priority ranking
**Rejected Because**: 
- Increases API usage costs unnecessarily
- Complex result ranking logic
- Potential race conditions in result handling

#### Decision: Hard vs Soft Fallback Boundaries
**Chosen**: Hard boundaries with clear failure criteria
**Rationale**:
- Predictable behavior for testing and debugging
- Clear service SLA expectations
- Prevents cascade failures from affecting other services

### 2. Geographic Boundary Logic

#### Decision: Scotland Boundary Detection Method
**Chosen**: Coordinate-based polygon boundary checking
**Rationale**:
- Precise boundary detection for SEPA service eligibility
- Supports edge cases near borders accurately
- Can be tested with known coordinate sets

**Implementation Notes**:
- Use established Scottish geographic boundaries
- Handle edge cases (islands, border areas) explicitly
- Consider territorial waters if relevant to fire risk

#### Decision: Coordinate Precision for Privacy
**Chosen**: 2-3 decimal places for logging (≈100m-1km precision)
**Rationale**:
- Balances privacy protection with useful telemetry
- Sufficient precision for geographic boundary detection
- Prevents exact location tracking while enabling service improvement

### 3. Caching Strategy

#### Decision: Cache TTL Duration
**Chosen**: 6 hours maximum TTL
**Rationale**:
- Balances data freshness with availability during outages
- Fire weather conditions can change significantly in 12+ hours
- Aligns with typical meteorological data update cycles

**Monitoring Required**: Track cache hit rates and user satisfaction with data freshness

#### Decision: Cache Key Strategy
**Chosen**: Geohash-based keys with appropriate precision
**Rationale**:
- Protects user privacy by avoiding exact coordinate storage
- Enables reasonable cache sharing for nearby locations
- Standardized geohash algorithm ensures consistency

**Precision Level**: Use geohash precision that covers ~1km² areas for reasonable sharing without over-aggregation

### 4. Error Handling Philosophy

#### Decision: Never-Fail vs Can-Fail Design
**Chosen**: Never-fail with guaranteed mock fallback
**Rationale**:
- Fire safety information is critical - "no data" is worse than approximate data
- Builds user trust and app reliability
- Mock data clearly labeled to manage expectations

#### Decision: Error Propagation Strategy
**Chosen**: Structured error reasons with context
**Rationale**:
- Enables intelligent retry logic in calling code
- Supports debugging and service improvement
- Allows UI to show appropriate messaging

### 5. Performance Considerations

#### Decision: Total Request Timeout
**Chosen**: 10-second maximum for complete fallback chain
**Rationale**:
- Reasonable user expectation for safety-critical information
- Allows time for 2-3 service attempts with proper timeouts
- Prevents indefinite hanging in poor network conditions

#### Decision: Individual Service Timeouts
**Research Needed**: Determine optimal timeout per service type
- EFFIS: Network service, likely 30s as established in A1
- SEPA: External service, needs investigation
- Cache: Local/fast service, should be <1s
- Mock: Immediate response

### 6. Privacy & Security Research

#### Decision: Data Retention Policy
**Chosen**: Minimal retention with automatic cleanup
**Rationale**:
- Supports privacy-by-design principles
- Reduces data breach impact
- Complies with data minimization requirements

**Implementation**:
- Cache entries auto-expire
- Telemetry data aggregated and anonymized
- No long-term location data storage

#### Decision: Logging Strategy
**Chosen**: Structured logging with privacy protection
**Rationale**:
- Enables service monitoring and improvement
- Protects user privacy through coordinate rounding
- Supports debugging without exposing sensitive data

## Dependencies & Integration Points

### External Service Dependencies
- **EFFIS Service**: Primary data source (implemented in A1)
- **SEPA Service**: Secondary source for Scotland (needs implementation)
- **Cache Service**: Local persistence layer (architecture TBD in A5)

### Internal Dependencies
- Geographic utilities for Scotland boundary detection
- Telemetry service for monitoring and improvement
- Error handling framework consistent with existing services

## Risk Mitigation Strategies

### Service Reliability Risks
- **Risk**: All external services fail simultaneously
- **Mitigation**: Mock service as guaranteed fallback + clear labeling

### Performance Risks  
- **Risk**: Cascading timeouts cause poor user experience
- **Mitigation**: Aggressive timeout limits + circuit breaker patterns

### Privacy Risks
- **Risk**: Location data exposure through logs/cache
- **Mitigation**: Coordinate rounding + geohash keys + automatic cleanup

### Data Quality Risks
- **Risk**: Users don't understand data source limitations
- **Mitigation**: Clear source attribution + freshness indicators

## Future Research Areas

### Service Expansion
- Additional geographic regions beyond Scotland
- Integration with other national fire services
- Weather station data as additional fallback source

### Performance Optimization
- Intelligent cache warming based on usage patterns
- Predictive service health checking
- Load balancing across multiple EFFIS endpoints

### User Experience Enhancement
- Context-aware timeout adjustments
- Progressive data loading (show cached while fetching live)
- User preference for data source priority