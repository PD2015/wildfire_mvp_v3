# Research: Map Fire Information Sheet

## Technical Decisions

### Fire Incident Data Model Enhancement
**Decision**: Extend existing FireIncident model with required fields: detectedAt, source, confidence, frp, lastUpdate
**Rationale**: 
- Existing model already has basic structure with validation
- Need to add satellite sensor data fields for user trust and transparency
- Constitutional requirement for data source transparency (C4)
**Alternatives considered**: 
- Create separate SatelliteFireData model (rejected - unnecessary complexity)
- Use Map<String, dynamic> for dynamic fields (rejected - poor type safety)

### ActiveFiresService API Design
**Decision**: Implement service with getIncidentsForViewport(LatLngBounds, {timeWindowHours: 24}) signature
**Rationale**:
- Viewport-based queries reduce data transfer and improve performance
- Time window filtering essential for relevance (24-hour active fires)
- Follows existing service patterns with Either<ApiError, T> error handling
- Supports MAP_LIVE_DATA flag for demo vs live data transparency
**Alternatives considered**:
- Point-based queries with radius (rejected - less efficient for map views)
- All fires without filtering (rejected - performance concerns)
- Separate live/mock service implementations (rejected - violates DRY)

### Bottom Sheet Implementation Approach  
**Decision**: Custom Flutter bottom sheet using DraggableScrollableSheet
**Rationale**:
- Native feel with proper gesture handling
- Built-in accessibility support meets C3 requirements
- Integrates well with existing map infrastructure
- Supports responsive design for different screen sizes
**Alternatives considered**:
- Modal dialog (rejected - poor mobile UX)
- Custom info window overlay (rejected - limited space, poor accessibility)
- Full-screen detail page (rejected - breaks map context)

### Distance and Bearing Calculation
**Decision**: Use geolocator package's distanceBetween and custom bearing calculation
**Rationale**:
- Geolocator already dependency for location services
- Accurate great circle distance calculation
- Need custom bearing for cardinal direction display (e.g., "15km Northeast")
**Alternatives considered**:
- Manual haversine formula implementation (rejected - reinventing wheel)
- Third-party geo library (rejected - additional dependency)
- Approximate distance calculation (rejected - inaccurate for safety decisions)

### Risk Level Integration Strategy
**Decision**: Fetch risk level via existing EffisService within bottom sheet on sheet open
**Rationale**:
- Leverages existing EffisService infrastructure and patterns
- On-demand loading prevents unnecessary API calls
- Constitutional requirement for risk transparency (C4)
- Clear error handling with retry mechanism
**Alternatives considered**:
- Pre-fetch risk for all visible markers (rejected - API rate limit concerns)
- Cache risk with fire incidents (rejected - risk data may be more dynamic)
- Skip risk integration (rejected - requirement FR-009)

### Caching Strategy  
**Decision**: Extend existing FireIncidentCache with viewport-based keying using geohash
**Rationale**:
- Existing cache infrastructure with LRU eviction and TTL
- Geohash provides efficient spatial indexing for viewport queries
- 6-hour TTL balances freshness with performance
- Follows constitutional principle of "fallbacks, not blanks"
**Alternatives considered**:
- No caching (rejected - poor offline/slow network experience)
- Simple coordinate-based caching (rejected - inefficient for viewport queries)
- Database storage (rejected - overkill for MVP prototype)

### Error Handling and Resilience Patterns
**Decision**: Implement comprehensive error states with retry functionality
**Rationale**:
- Constitutional requirement (C5) for visible failures and error handling
- Essential for user trust when making safety decisions
- Network dependency requires robust failure modes
**Error States Planned**:
- Loading state with spinner
- Network error with retry button  
- Stale data warning with refresh option
- Service unavailable with fallback message
- Location permission denied graceful handling

### Accessibility Implementation
**Decision**: Full semantic labeling with screen reader support and 44dp touch targets
**Rationale**:
- Constitutional requirement (C3) for accessibility compliance
- Critical for emergency/safety application usage
- Standard Flutter accessibility patterns available
**Specific Implementations**:
- Semantic labels for all fire data fields
- Role-based navigation (heading, button, text)
- High contrast colors for risk levels
- Minimum 44dp touch targets for all interactive elements
- Focus management for sheet opening/closing

## Integration Points

### Existing Services Integration
- **EffisService**: Will call getFwi(lat, lon) for risk level in bottom sheet
- **LocationResolver**: Will use for user location to calculate distance/bearing
- **CacheService**: Will extend FireIncidentCache for viewport-based incident caching
- **MAP_LIVE_DATA**: Will respect feature flag for live vs demo data display

### UI Component Integration
- **HomeScreen/MapScreen**: Will enhance with marker tap handling and bottom sheet display
- **RiskPalette**: Will use existing risk level colors for constitutional compliance
- **Existing badge patterns**: Will follow CachedBadge pattern for data source indicators

### Testing Integration
- **Existing test patterns**: Will follow established unit/widget/integration test structure
- **Mock services**: Will integrate with existing MockFireRiskService patterns
- **CI/CD**: Will integrate with existing flutter analyze/format/test pipeline

## Performance Considerations

### Debounced Viewport Queries
- Implement 300ms debounce on camera position changes
- Cancel in-flight requests when new viewport query triggered
- Use StreamTransformer.switchMap pattern for query cancellation

### Memory Management
- LRU cache eviction for fire incident storage
- Dispose bottom sheet controllers properly
- Efficient marker clustering for dense fire regions (future enhancement)

### Network Optimization
- Gzip compression for API requests
- Conditional requests with ETags when supported
- Timeout configuration (8s for ActiveFiresService, 3s for risk lookup)

## Constitutional Compliance Summary

All constitutional gates (C1-C5) addressed in design:
- **C1**: Flutter analyze/format/test integration planned
- **C2**: No secrets, coordinate logging via existing GeographicUtils.logRedact
- **C3**: 44dp touch targets, semantic labels, screen reader support
- **C4**: Scottish risk colors, timestamps, source labels, demo data indicators  
- **C5**: Comprehensive error handling, timeouts, retry mechanisms, fallback flows

Development principles alignment:
- Fail visible: Loading/error states clearly displayed
- Fallbacks not blanks: Cached data with clear indicators
- Clean logs: Structured logging, no PII via existing patterns
- Single source of truth: Risk colors from RiskPalette constants
- Mock-first dev: ActiveFiresService supports mock injection via MAP_LIVE_DATA