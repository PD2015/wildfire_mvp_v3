# WildFire Prototype — Data Sources

## EFFIS (European Forest Fire Information System)
- **Service**: WMS `GetFeatureInfo` for Fire Weather Index (FWI)
- **Input**: lat, lon
- **Output**: JSON with FWI value
- **Timeout**: 30s, max 3 retries with exponential backoff
- **Fallback**: handled by `FireRiskService`
- **Notes**: schema can change; use golden fixtures in tests

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

