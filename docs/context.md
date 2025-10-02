# WildFire Prototype — Context Pack

## What We’re Building
WildFire MVP prototype for Scotland. **Phase-0 goal**: display current wildfire risk on the Home screen.
- Primary data: EFFIS Fire Weather Index (FWI)
- Fallbacks: SEPA (Scotland only) → Cache → Mock
- Focus: proving data feeds + hooks, not emergency-grade reliability yet.

## Scope for Phase-0
- Risk data service + simple Home screen banner
- No notifications, authentication, or advanced map features
- Map overlays and reporting deferred to later phases

## Guardrails (from Constitution)
- No secrets in repo; env/runtime config only
- All data must show **Last updated** timestamp + source label
- Use official wildfire risk color scale only
- A11y: semantic labels + ≥44dp targets
- Clear offline/error/cached states (no silent fails)

## Data Chain (for Phase-0)
**FireRiskService Fallback Decision Tree**:
```
getCurrent(lat, lon) → FireRisk
    ↓
[Validate coordinates] → Left(ApiError) if invalid
    ↓
[1. EFFIS] (3s timeout) → Success? → FireRisk{source: effis, freshness: live}
    ↓ Fail
[2. SEPA] (2s timeout, Scotland only) → Success? → FireRisk{source: sepa, freshness: live}  
    ↓ Fail
[3. Cache] (1s timeout) → Hit? → FireRisk{source: original, freshness: cached}
    ↓ Miss
[4. Mock] (<100ms, never fails) → FireRisk{source: mock, freshness: mock}
```

**Service Details**:
1. **EFFIS** — Fire Weather Index via WMS GetFeatureInfo (A1 implementation)
   - Global coverage, primary data source
   - Returns EffisFwiResult → converted to FireRisk
   - 3-second timeout within 8-second total budget
2. **SEPA** — Scotland Environment Protection Agency fallback
   - **Geographic bounds**: 54.6-60.9°N, -9.0-1.0°E (includes St Kilda, Orkney, Shetland)
   - Only attempted when `isInScotland(lat, lon) == true` AND EFFIS fails
   - 2-second timeout for Scottish-specific fire risk data
3. **Cache** — TTL 6h for resilience
   - Preserves original source attribution in cached FireRisk
   - 1-second timeout for cache lookups
4. **Mock** — clearly tagged as fallback when no data available
   - **Never-fail guarantee**: Always succeeds within 100ms
   - Uses deterministic geohash-based risk levels for consistency

**Privacy Compliance (C2)**:
- All logging uses `GeographicUtils.logRedact(lat, lon)` → rounds to 2dp
- No raw coordinates or place names in logs or telemetry
- Geographic resolution ~1.1km prevents exact location identification

## Non-Goals
- Emergency compliance or alert certification
- Push notifications
- Fire polygon rendering
- Multi-user accounts

## References
- Constitution v1.0 (root)
- `docs/DATA-SOURCES.md`
- `scripts/allowed_colors.txt` (palette)
- `lib/theme/risk_palette.dart` (when added)

