# Data Model: FireRiskService

## Overview
FireRiskService orchestrates multiple data sources to provide normalized fire risk assessments. This document defines the core entities and their relationships in the fallback orchestration system.

## Core Entities

### FireRisk
**Purpose**: Normalized fire risk assessment that can be created from any data source
**Lifecycle**: Created per request, not persisted long-term
**Key Attributes**:
- `level`: Risk category (veryLow, low, moderate, high, veryHigh, extreme)
- `fwi`: Fire Weather Index value (optional, depends on data source)
- `source`: Data source identifier (effis, sepa, cache, mock)
- `updatedAt`: UTC timestamp of original data collection
- `freshness`: Data age indicator (live, cached)

**Business Rules**:
- Must always have a valid risk level
- FWI value only present for EFFIS/SEPA sources
- Source attribution is mandatory for audit trail
- Timestamp represents original data time, not request time

### ServiceAttempt
**Purpose**: Tracks individual data source attempts during fallback chain
**Lifecycle**: Created and discarded per request for telemetry
**Key Attributes**:
- `service`: Service identifier (effis, sepa, cache, mock)
- `attempted`: Whether service was tried
- `succeeded`: Whether service returned valid data
- `latency`: Response time in milliseconds
- `skipReason`: Why service was skipped (out-of-region, timeout, error)

**Business Rules**:
- Services attempted in strict order: EFFIS → SEPA → Cache → Mock
- SEPA skipped when coordinates outside Scotland
- Mock service never fails (always returns moderate risk)

### GeographicContext
**Purpose**: Location-based information for service routing decisions
**Lifecycle**: Created per request, used for routing logic
**Key Attributes**:
- `latitude`: Decimal degrees (-90 to 90)
- `longitude`: Decimal degrees (-180 to 180) 
- `isInScotland`: Boolean indicating SEPA service eligibility
- `cacheKey`: Geohash-based identifier for cache lookups

**Business Rules**:
- Coordinates validated before any service attempts
- Scotland boundary detection determines SEPA eligibility
- Cache keys use coarse geohash to protect privacy
- Raw coordinates not persisted beyond request scope

### CacheEntry
**Purpose**: Temporary storage of successful fire risk data
**Lifecycle**: Stored for up to 6 hours, then expired
**Key Attributes**:
- `cacheKey`: Geohash-based location identifier
- `fireRisk`: Stored FireRisk data
- `cachedAt`: UTC timestamp when data was cached
- `expiresAt`: UTC timestamp when cache entry becomes invalid

**Business Rules**:
- TTL fixed at 6 hours from original data timestamp
- Only successful EFFIS/SEPA responses are cached
- Mock data never cached
- Expired entries automatically skipped

## Entity Relationships

```
Request → GeographicContext
       → ServiceAttempt[] (fallback chain)
       → CacheEntry (lookup/store)
       → FireRisk (final result)

GeographicContext.isInScotland → determines SEPA attempt
GeographicContext.cacheKey → CacheEntry lookup
ServiceAttempt.succeeded → determines fallback progression
CacheEntry.expiresAt → determines cache validity
```

## Privacy & Security Considerations

### Data Minimization
- Geographic coordinates rounded to 2-3 decimal places in logs
- Cache keys use coarse geohash (not precise coordinates)  
- No persistent storage of exact user locations

### Data Retention
- ServiceAttempt data discarded after telemetry logging
- CacheEntry data auto-expires after 6 hours
- FireRisk data not persisted (created per request)

### Audit Trail
- All service attempts logged with anonymized location data
- Source attribution preserved in FireRisk responses
- Fallback reasons captured for service improvement