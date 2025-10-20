# EFFIS Monitoring Runbook

## Overview

This runbook provides operational procedures for monitoring EFFIS (European Forest Fire Information System) WFS service integration, handling failures, and ensuring service resilience.

**Service**: EFFIS WFS (Web Feature Service)  
**Endpoint**: `https://ies-ows.jrc.ec.europa.eu/wfs`  
**Layer**: `effis:burntareas.latest` (current year burnt areas)  
**Update Frequency**: Daily during fire season (March-November)  
**Timeout**: 8 seconds per service tier  
**Fallback Chain**: EFFIS → Cache (6h TTL) → Mock

## Architecture Overview

### Service Tiers
```
Tier 1: EFFIS WFS (Primary)
  ├─ Timeout: 8s
  ├─ Data: Live fire incidents
  └─ Freshness: "live"

Tier 2: Cache (Secondary)
  ├─ Timeout: 200ms
  ├─ TTL: 6 hours
  └─ Freshness: "cached"

Tier 3: Mock (Never Fails)
  ├─ Timeout: None
  ├─ Data: Static mock incidents
  └─ Freshness: "mock"
```

### Resilience Principle (C5)
**The service NEVER fails completely**. Users always see data, even if it's cached or mock data. This is a constitutional requirement.

---

## Health Check Procedures

### Weekly Health Check (Recommended)

**Schedule**: Every Monday 09:00 UTC  
**Duration**: 15 minutes  
**Owner**: DevOps/SRE team

#### Checklist

1. **Endpoint Availability**
   ```bash
   # Test WFS GetCapabilities
   curl -I https://ies-ows.jrc.ec.europa.eu/wfs?service=WFS&request=GetCapabilities
   
   # Expected: HTTP 200 OK
   # Response time: <3s baseline
   ```

2. **Data Freshness**
   ```bash
   # Query for recent fires in UK region
   curl "https://ies-ows.jrc.ec.europa.eu/wfs?service=WFS&version=2.0.0&request=GetFeature&typeName=effis:burntareas.latest&outputFormat=application/json&bbox=-8,50,2,60&count=10"
   
   # Check: lastUpdated timestamps within last 24 hours during fire season
   ```

3. **Response Time Monitoring**
   ```bash
   # Measure response time
   time curl -s "https://ies-ows.jrc.ec.europa.eu/wfs?service=WFS&request=GetCapabilities" > /dev/null
   
   # Baseline: <3s
   # Warning: >5s
   # Critical: >8s (triggers timeout)
   ```

4. **Data Quality Check**
   - At least 1 fire incident during fire season (March-November)
   - Valid GeoJSON FeatureCollection structure
   - All incidents have required fields: id, geometry, properties

5. **Fallback Chain Verification**
   ```bash
   # Test with app in staging environment
   flutter run --dart-define=MAP_LIVE_DATA=true --dart-define-from-file=env/staging.env.json
   
   # Verify:
   # - Source chip shows "LIVE" when EFFIS succeeds
   # - Source chip shows "CACHED" when EFFIS times out but cache available
   # - Source chip shows "MOCK" when both EFFIS and cache fail
   ```

6. **Log Analysis**
   ```bash
   # Check app logs for EFFIS failures (last 7 days)
   grep -i "effis.*failed\|effis.*timeout" logs/app-*.log | wc -l
   
   # Acceptable: <5% failure rate
   # Warning: 5-10% failure rate
   # Critical: >10% failure rate
   ```

---

## Response Time Monitoring

### Performance Baselines

| Metric | Good | Warning | Critical | Action |
|--------|------|---------|----------|--------|
| EFFIS Response Time | <3s | 3-5s | >5s | Investigate |
| EFFIS Timeout Rate | <1% | 1-5% | >5% | Alert team |
| Cache Hit Rate | >80% | 60-80% | <60% | Review TTL |
| Overall Service Availability | 99.9% | 99-99.9% | <99% | Incident response |

### Monitoring Tools

**Application Logs**:
```dart
// In FireLocationServiceImpl
_logger.info('EFFIS request: bbox=$bbox, elapsed=${stopwatch.elapsed}');
// Typical output: "EFFIS request: bbox=-8,50,2,60, elapsed=2.345s"
```

**Google Cloud Monitoring** (if deployed on GCP):
- Custom metric: `wildfire_mvp_v3/effis/response_time`
- Alert policy: Response time >5s for 5 consecutive minutes

**Uptime Checks** (external monitoring):
- Pingdom/UptimeRobot monitoring EFFIS endpoint
- Check frequency: Every 5 minutes
- Alert on 3 consecutive failures

---

## Data Freshness Validation

### Expected Update Frequency

**Fire Season (March-November)**:
- Daily updates expected
- Data lag: <24 hours acceptable
- Missing updates: Investigate after 48 hours

**Off-Season (December-February)**:
- Updates may be infrequent
- Data lag: <72 hours acceptable
- Focus on endpoint availability rather than freshness

### Freshness Check Script

```bash
#!/bin/bash
# effis-freshness-check.sh

EFFIS_URL="https://ies-ows.jrc.ec.europa.eu/wfs"
BBOX="-8,50,2,60"  # UK region

# Fetch recent fires
RESPONSE=$(curl -s "${EFFIS_URL}?service=WFS&version=2.0.0&request=GetFeature&typeName=effis:burntareas.latest&outputFormat=application/json&bbox=${BBOX}&count=1")

# Extract most recent timestamp
LATEST_DATE=$(echo "$RESPONSE" | jq -r '.features[0].properties.lastUpdate' 2>/dev/null)

if [ -z "$LATEST_DATE" ]; then
  echo "❌ No fire data available"
  exit 1
fi

# Calculate age in hours
NOW=$(date +%s)
LATEST_TS=$(date -d "$LATEST_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$LATEST_DATE" +%s)
AGE_HOURS=$(( (NOW - LATEST_TS) / 3600 ))

echo "Latest fire data: $LATEST_DATE (${AGE_HOURS}h ago)"

# Fire season check (March-November)
MONTH=$(date +%m)
if [ "$MONTH" -ge 3 ] && [ "$MONTH" -le 11 ]; then
  if [ "$AGE_HOURS" -gt 24 ]; then
    echo "⚠️  Data is stale (>${AGE_HOURS}h during fire season)"
    exit 1
  fi
fi

echo "✅ Data freshness OK"
```

---

## Incident Response

### Incident: EFFIS Endpoint Down

**Symptoms**:
- HTTP 5xx errors from EFFIS WFS
- Connection timeouts (>8s)
- Logs show "EFFIS unavailable" errors
- Users see "CACHED" or "MOCK" source chips

**Impact**:
- ✅ **Service continues normally** (fallback to cache/mock)
- Users may see older data (cache up to 6h old)
- Users in new regions may see mock data (no cache available)

**Response Procedure**:

1. **Verify Incident** (5 minutes)
   ```bash
   # Check EFFIS endpoint
   curl -I https://ies-ows.jrc.ec.europa.eu/wfs
   
   # Check from multiple locations
   # Use: https://www.uptrends.com/tools/uptime
   ```

2. **Assess Impact** (5 minutes)
   - Check cache hit rate: Should be >80% during outage
   - Verify mock fallback working: Source chip shows "MOCK" when cache misses
   - Monitor user reports: Any complaints about data quality?

3. **User Communication** (10 minutes)
   - **If cache covering >80% of requests**: No user notification needed
   - **If cache <80%**: Post in-app notice or StatusPage update
   
   **Template (StatusPage)**:
   ```
   🟡 Investigating: Live fire data temporarily unavailable
   
   We're currently using cached data from the European Forest Fire 
   Information System (EFFIS). Data may be up to 6 hours old in some 
   regions. Service functionality is not affected.
   
   Status: Monitoring
   ETA: [When EFFIS typically recovers, or "Under investigation"]
   ```

4. **Contact EFFIS Support** (if outage >2 hours)
   - Email: `effis-support@ec.europa.eu`
   - Include: Timestamp, affected endpoints, error messages
   - Request: ETA for service restoration

5. **Post-Incident** (after restoration)
   - Update StatusPage: "✅ Resolved: Live fire data restored"
   - Verify cache re-populating with fresh data
   - Document incident in ops log

---

### Incident: High Timeout Rate (5-10%)

**Symptoms**:
- EFFIS responding slowly (3-8s)
- Increased fallback to cache
- Logs show frequent "EFFIS timeout" warnings

**Impact**:
- Service degraded but functional
- Higher cache usage
- Slower first-load experience for users

**Response Procedure**:

1. **Verify Network Path** (10 minutes)
   ```bash
   # Traceroute to EFFIS
   traceroute ies-ows.jrc.ec.europa.eu
   
   # DNS lookup time
   dig ies-ows.jrc.ec.europa.eu
   
   # TCP connection time
   time curl -s -o /dev/null -w "%{time_connect}" https://ies-ows.jrc.ec.europa.eu/
   ```

2. **Check EFFIS Status Page**
   - Visit: https://effis.jrc.ec.europa.eu/
   - Look for service announcements

3. **Temporary Mitigation**
   - Increase cache TTL from 6h to 12h (if timeout rate >10%)
   - Update `CacheService` configuration:
     ```dart
     // In FireIncidentCacheImpl
     static const Duration _defaultTtl = Duration(hours: 12); // Temporary
     ```

4. **Monitor and Escalate**
   - Monitor for 24 hours
   - If no improvement, contact EFFIS support
   - Consider implementing request retry logic (currently not implemented)

---

### Incident: Cache Corruption

**Symptoms**:
- Users report inconsistent fire locations
- Logs show JSON parse errors from cache
- Cache hit rate drops unexpectedly

**Impact**:
- Falls back to mock data more frequently
- Users may see outdated information

**Response Procedure**:

1. **Verify Corruption** (5 minutes)
   ```bash
   # Check SharedPreferences on test device
   flutter run --dart-define=MAP_LIVE_DATA=false
   
   # Look for cache errors in logs
   grep -i "cache.*error\|cache.*corrupt" logs/app.log
   ```

2. **Clear Cache** (immediate)
   ```dart
   // In-app cache clear (add to debug menu if not present)
   await CacheService.clear();
   ```
   
   Or via user action:
   - Settings → Advanced → Clear Cache

3. **Root Cause Analysis** (after mitigation)
   - Review cache serialization logic in `FireIncidentCacheImpl`
   - Check for data model changes without migration
   - Verify cache versioning (`version` field in JSON)

4. **Preventive Measures**
   - Add cache version migration in next release
   - Implement cache integrity checks on read
   - Add telemetry for cache parse errors

---

## Fallback Chain Verification

### Testing Fallback Scenarios

**Scenario 1: EFFIS Timeout → Cache Hit**
```bash
# Simulate EFFIS timeout (block network to EFFIS endpoint)
sudo iptables -A OUTPUT -d ies-ows.jrc.ec.europa.eu -j DROP

# Run app with live data
flutter run --dart-define=MAP_LIVE_DATA=true

# Expected:
# - Source chip shows "CACHED"
# - Timestamp shows cache age (e.g., "Last updated: 3h ago")
# - No error messages displayed

# Cleanup
sudo iptables -D OUTPUT -d ies-ows.jrc.ec.europa.eu -j DROP
```

**Scenario 2: EFFIS Timeout + Cache Miss → Mock**
```bash
# Clear cache
flutter run --dart-define=MAP_LIVE_DATA=false  # Warm up app
# Then clear cache via Settings → Clear Cache

# Block EFFIS
sudo iptables -A OUTPUT -d ies-ows.jrc.ec.europa.eu -j DROP

# Run with live data
flutter run --dart-define=MAP_LIVE_DATA=true

# Expected:
# - Source chip shows "MOCK"
# - Mock fire incidents displayed (Edinburgh, Glasgow, Aviemore)
# - No crashes or error dialogs

# Cleanup
sudo iptables -D OUTPUT -d ies-ows.jrc.ec.europa.eu -j DROP
```

**Scenario 3: EFFIS Success**
```bash
# Normal operation
flutter run --dart-define=MAP_LIVE_DATA=true

# Expected:
# - Source chip shows "LIVE"
# - Real fire incidents from EFFIS displayed
# - Timestamp shows recent time (<1 hour during fire season)
```

---

## Operator Actions

### "Flip to Cached/Mock" Procedure

When EFFIS is down and you need to explicitly communicate service status to users:

1. **Update Feature Flag** (temporary override)
   ```bash
   # Deploy app update with MAP_LIVE_DATA=false
   # OR configure feature flag in backend (if using remote config)
   ```

2. **User Notification**
   - In-app banner: "Using cached data due to service maintenance"
   - StatusPage update (see template above)

3. **Slack Notification Template**
   ```
   🟡 EFFIS Service Alert

   Status: Down (HTTP 503)
   Impact: Low (fallback to cached data)
   Action Taken: Cache extended to 12h TTL
   User Notification: StatusPage updated
   Next Check: [Timestamp]
   
   Ops team: Monitor cache hit rate in dashboard
   ```

4. **StatusPage Template**
   ```
   🟡 Service Degradation: Live Fire Data

   What: European fire data service (EFFIS) temporarily unavailable
   Impact: App using cached data (up to 6 hours old)
   Workaround: None needed - service functioning normally
   ETA: Monitoring for restoration
   Updates: Will post when resolved
   
   Last updated: [ISO-8601 timestamp]
   ```

### Cache TTL Adjustment

**When to Adjust**:
- EFFIS outage >6 hours
- High timeout rate (>10%) expected to continue
- Fire season low-activity period (minimal data changes)

**Procedure**:
```dart
// In lib/services/cache/fire_incident_cache_impl.dart
static const Duration _defaultTtl = Duration(hours: 12); // Changed from 6

// Deploy change
flutter build apk --dart-define-from-file=env/prod.env.json
// OR push to app stores if change requires release
```

**Rollback**:
- Revert to 6h TTL when EFFIS stable
- Monitor cache hit rate after rollback

---

## Contact Escalation

### Internal Team

| Role | Contact | Responsibility | SLA |
|------|---------|----------------|-----|
| On-Call Engineer | [Phone/Slack] | First responder | <15 min |
| DevOps Lead | [Phone/Email] | Incident commander | <30 min |
| Product Owner | [Slack/Email] | User communication | <1 hour |
| Engineering Manager | [Phone/Email] | Executive escalation | <2 hours |

### External Contacts

**EFFIS Support**:
- Email: `effis-support@ec.europa.eu`
- Response time: 24-48 hours (best effort)
- Escalation: Via European Commission Copernicus Programme

**Google Maps Support** (if map tiles affected):
- Google Cloud Console: Support tab
- Response time: Depends on support plan
- Priority: Affects map display, not fire data

---

## Monitoring Dashboards

### Key Metrics (Recommended)

**Service Health**:
- EFFIS availability (%)
- EFFIS response time (p50, p95, p99)
- Timeout rate (%)
- Error rate by tier (EFFIS, Cache, Mock)

**Cache Performance**:
- Cache hit rate (%)
- Cache size (entries)
- Cache eviction rate (evictions/hour)
- Average cache age (hours)

**User Experience**:
- Time to first fire marker (seconds)
- Data source distribution (LIVE/CACHED/MOCK %)
- User-reported data issues (count)

**Alerts**:
- EFFIS response time >5s for 5 min → Warning
- EFFIS availability <95% over 1 hour → Critical
- Cache hit rate <60% for 1 hour → Warning
- Error rate >5% over 15 min → Critical

---

## Operational Best Practices

### Do's ✅

1. **Monitor Weekly**: Run health checks every Monday
2. **Document Incidents**: Keep ops log for pattern analysis
3. **Test Fallbacks**: Verify cache and mock tiers monthly
4. **Communicate Proactively**: Update StatusPage for extended outages (>2h)
5. **Maintain Baselines**: Track normal performance for comparison
6. **Automate Checks**: Use cron jobs for daily freshness validation
7. **Cache Generously**: 6-hour TTL balances freshness and resilience

### Don'ts ❌

1. **Don't Panic**: Fallback chain ensures service continuity
2. **Don't Over-Communicate**: Small blips (<30min) don't need user alerts
3. **Don't Clear Cache Globally**: Affects all users, rarely necessary
4. **Don't Increase Timeout**: 8s is constitutional limit (C5)
5. **Don't Skip Post-Mortems**: Learn from incidents
6. **Don't Ignore Trends**: Small degradations compound over time

---

## Appendix

### Useful Commands

```bash
# Quick EFFIS health check
curl -I https://ies-ows.jrc.ec.europa.eu/wfs?service=WFS

# Query UK fires
curl "https://ies-ows.jrc.ec.europa.eu/wfs?service=WFS&version=2.0.0&request=GetFeature&typeName=effis:burntareas.latest&outputFormat=application/json&bbox=-8,50,2,60&count=10" | jq .

# App logs - EFFIS attempts
flutter logs | grep -i effis

# App logs - Cache behavior
flutter logs | grep -i cache

# Test cache freshness
flutter run --dart-define=MAP_LIVE_DATA=true --dart-define-from-file=env/dev.env.json
# Watch for source chip: LIVE/CACHED/MOCK
```

### Related Documentation
- `docs/google-maps-setup.md` - API key configuration
- `docs/WEB_PLATFORM_RESEARCH.md` - CORS proxy setup for web
- `docs/CROSS_PLATFORM_TESTING.md` - Platform-specific testing
- `docs/privacy-compliance.md` - Data handling policies
- `.github/copilot-instructions.md` - Development guidelines

### Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-20 | 1.0 | Initial runbook | GitHub Copilot |

---

**Next Review Date**: 2025-11-20 (monthly review recommended during fire season)
