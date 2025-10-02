# WildFire Prototype — Data Sources

## EFFIS (European Forest Fire Information System)
- **Service**: WMS `GetFeatureInfo` for Fire Weather Index (FWI)
- **Base URL**: `https://ies-ows.jrc.ec.europa.eu/gwis`
- **Input**: lat, lon (WGS84 coordinates)
- **Output**: GeoJSON FeatureCollection with FWI value
- **Timeout**: 30s default, configurable
- **Retry Policy**: Max 3 retries with exponential backoff + jitter
- **Fallback**: handled by `FireRiskService`
- **Notes**: schema can change; use golden fixtures in tests

### WMS Parameters Used
- **SERVICE**: `WMS`
- **VERSION**: `1.3.0`
- **REQUEST**: `GetFeatureInfo`
- **LAYERS**: `ecmwf.fwi` (ECMWF Fire Weather Index layer)
- **QUERY_LAYERS**: `ecmwf.fwi`
- **CRS**: `EPSG:3857` (Web Mercator projection)
- **BBOX**: Dynamic bounding box (±1000m buffer around query point)
- **WIDTH/HEIGHT**: `256x256` pixels
- **I/J**: `128,128` (center query point)
- **INFO_FORMAT**: `application/json`
- **FEATURE_COUNT**: `1`

### HTTP Headers
- **User-Agent**: `WildFire/0.1 (prototype)`
- **Accept**: `application/json,*/*;q=0.8`

### Content-Type Behavior
- **Expected**: `application/json` (validated)
- **Parsing**: GeoJSON FeatureCollection format
- **FWI Extraction**: From feature properties (flexible property names)
- **Timestamp**: UTC parsing from `datetime`/`timestamp` properties (fallback to current time)

### Error Handling & Retry Policy
- **Retryable Errors**: HTTP 5xx, network timeouts, temporary failures
- **Non-Retryable**: HTTP 4xx (client errors), malformed responses
- **Backoff Formula**: `base_delay * (2^attempt) + jitter`
- **Jitter Range**: ±25% to prevent thundering herd
- **Max Retries**: 3 attempts (configurable, capped at 10)

### FWI → Risk Mapping
- `< 5` → Very Low
- `5–11` → Low
- `12–20` → Moderate
- `21–37` → High
- `38–49` → Very High
- `≥ 50` → Extreme

## SEPA (Scottish Environment Protection Agency)
- **Service**: Fallback source for Scotland
- **Scope**: Only queried if user location in Scotland
- **Output**: risk level approximated to match app’s 6-level scale
- **Notes**: coverage limited; provide clear source tag in UI

## Cache
- **Service**: Local `FireRiskCache`
- **Storage**: SharedPreferences, key = geohash(lat,lon,precision=5)
- **TTL**: 6 hours
- **Notes**: must mark results as `freshness=cached`

## Mock
- **Service**: Fixed dummy response (level = Moderate)
- **Purpose**: Guarantees UI never blank; clearly labeled in UI

## Freshness & Transparency
- Every data object must include:
  - `updatedAt` (UTC)
  - `source` (effis|sepa|cache|mock)
  - `freshness` (live|cached)

## Error Handling
- Always fail visible:
  - Loading state
  - Error message with retry
  - Cached fallback (with badge)

## References
- `specs/A1-effis-service.md`
- `specs/A2-fire-risk-service.md`
- Constitution v1.0

