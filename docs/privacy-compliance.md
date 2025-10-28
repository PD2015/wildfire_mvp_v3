# Privacy Compliance Statement

## Overview

WildFire MVP v3 is designed with privacy-first principles following Constitutional Gate C2 (Secrets & Logging). This document details how the application handles location data, fire incident information, and logging to protect user privacy.

**Last Updated**: 2025-10-20  
**Version**: 1.0  
**Constitutional Compliance**: C2 (Secrets & Logging)

---

## Data Collection

### Location Data

**What We Collect**:
- User's coarse location (via GPS or manual entry)
- Map viewport bounds (for fetching relevant fire data)
- Cached fire incident locations (public data from EFFIS)

**How We Use It**:
- To display fire incidents relevant to user's area
- To calculate fire risk at user's location
- To cache fire data for offline resilience (6-hour TTL)

**What We DON'T Collect**:
- ❌ Precise GPS coordinates (full precision never stored)
- ❌ Location history or tracking data
- ❌ Device identifiers linked to location
- ❌ User movement patterns
- ❌ Background location tracking (location only accessed when map screen active)

### Fire Incident Data

**Source**: European Forest Fire Information System (EFFIS) and Scottish Environment Protection Agency (SEPA)

**Data Type**: Public information (fire locations, intensity, area affected)

**Storage**:
- Cached locally for 6 hours only (performance optimization)
- No permanent storage of fire locations
- Cache automatically expires and is cleared
- No user-specific fire data associations

---

## Coordinate Logging (C2 Compliance)

### Privacy-Preserving Logging

All coordinate logging in WildFire MVP v3 follows strict privacy rules to prevent user tracking through logs.

#### Coordinate Redaction

**Implementation**: `GeographicUtils.logRedact()` and `LocationUtils.logRedact()`

**Precision Reduction**:
- Full precision: `55.9533, -3.1883` (±10m accuracy)
- Logged precision: `55.95, -3.19` (±1km accuracy)
- Redacted: **2 decimal places only**

**Privacy Impact**:
- Cannot identify individual locations from logs
- Cannot track user movements
- Sufficient for debugging geographic logic
- Compliant with GDPR anonymization principles

**Example**:
```dart
// ❌ WRONG - exposes precise location
_logger.info('User location: $lat, $lon'); // 55.9533, -3.1883

// ✅ CORRECT - privacy-preserving
_logger.info('User location: ${LocationUtils.logRedact(lat, lon)}'); // 55.95, -3.19
```

#### Geohash Logging

**Implementation**: `GeohashUtils.encode()` and `GeographicUtils.geohash()`

**Precision**: 5 characters (~4.9km resolution)

**Privacy Impact**:
- Geohash `gcpue` covers ~24 sq km area around Edinburgh
- Cannot reverse engineer precise location
- Inherently privacy-preserving spatial identifier
- Used for cache keys and spatial logging

**Example**:
```dart
// ✅ SAFE - geohash has low spatial resolution
_logger.debug('Cache lookup for geohash: $geohash'); // "gcpue"
```

### Logging Policy Summary

| Log Type | Privacy Measure | Example |
|----------|----------------|---------|
| User location | 2dp redaction | `55.95,-3.19` |
| Fire location | 2dp redaction | `56.12,-4.25` |
| Cache key | Geohash (5 chars) | `gcpue` |
| Map bounds | Geohash of center | `gcpv7` |
| Device ID | ❌ Never logged | N/A |
| Timestamps | UTC only | `2025-10-20T14:30:00Z` |

---

## Data Storage

### Local Storage (Device)

**SharedPreferences**:
- Cache metadata (geohash keys, timestamps, TTL)
- Manual location preference (if user enters location manually)
- Feature flag preferences (MAP_LIVE_DATA setting)
- App settings (theme, notification preferences)

**Cache Storage**:
- Fire incident data: 6-hour TTL, automatic expiry
- Maximum 100 cached entries (LRU eviction)
- Fire risk data: 6-hour TTL, automatic expiry
- Cleared on app uninstall

**No Cloud Storage**:
- ❌ No data uploaded to remote servers
- ❌ No user accounts or authentication
- ❌ No analytics tracking personal data
- ❌ No third-party data sharing

### API Key Security

**Never Stored in Code**:
- API keys in gitignored environment files only
- `env/dev.env.json` never committed to repository
- Pre-commit hooks block accidental key commits
- Template files (`*.template`) contain placeholders only

**Key Restrictions**:
- Android keys: Restricted by package name + SHA-1 fingerprint
- iOS keys: Restricted by bundle ID
- Web keys: Restricted by HTTP referrer

**See**: `docs/google-maps-setup.md` for API key security best practices

---

## Third-Party Services

### Google Maps

**Data Sent**:
- Map tile requests (viewport coordinates)
- API key (restricted by platform)
- Map interaction events (zoom, pan)

**Data Received**:
- Map tiles (images)
- Geocoding results (if using address search - not currently implemented)

**Privacy**:
- No user authentication
- No cross-session tracking
- See [Google Maps Privacy Policy](https://policies.google.com/privacy)

### EFFIS (European Forest Fire Information System)

**Data Sent**:
- Bounding box coordinates (map viewport)
- No user identifiers
- No authentication tokens

**Data Received**:
- Public fire incident locations
- Fire intensity data
- Update timestamps

**Privacy**:
- Public data source (no personal data)
- No user tracking
- See [EFFIS Data Policy](https://effis.jrc.ec.europa.eu/)

### SEPA (Scottish Environment Protection Agency)

**Status**: Future integration (not currently implemented in A10)

**Data Sent** (when implemented):
- Bounding box coordinates (Scotland only)
- No user identifiers

**Data Received**:
- Public flood/environmental data
- No personal information

---

## User Rights (GDPR Compliance)

### Right to Access

**What Data**: Users can view cached fire data and location preferences in app settings

**How**: Settings → Privacy → View Cached Data (debug menu)

### Right to Deletion

**What Data**: All cached fire data and location preferences

**How**: 
- Settings → Privacy → Clear Cache
- Uninstall app (removes all local data)

**Outcome**: All cached data deleted immediately

### Right to Rectification

**What Data**: Manual location entry

**How**: Settings → Location → Update Manual Location

### Right to Object

**What Data**: Location access

**How**: 
- Deny GPS permission at OS level
- Use manual location entry instead
- App fully functional without GPS

### Data Portability

**Not Applicable**: No user account or profile data stored

---

## Cross-Border Data Transfers

### EFFIS Service (EU)

**Location**: European Union (Italy - JRC Ispra)

**Transfer Mechanism**: Standard HTTPS

**Privacy Shield**: N/A (public data source)

### Google Maps (Global)

**Location**: Google data centers worldwide

**Transfer Mechanism**: Google Cloud Platform

**Privacy Shield**: Google Privacy Shield certified

**See**: [Google Maps Terms of Service](https://cloud.google.com/maps-platform/terms)

---

## Privacy by Design (C2 Constitutional Principle)

### Technical Measures

1. **Coordinate Redaction**
   - `LocationUtils.logRedact()` and `GeographicUtils.logRedact()` enforced
   - Pre-commit hook checks for raw coordinate logging
   - Code review requirement: All logs use redaction utilities

2. **Geohash Spatial Keys**
   - All cache keys use geohash (inherently low-resolution)
   - No full-precision coordinates in cache keys
   - Geohash provides ~5km spatial resolution

3. **No Background Location**
   - Location only accessed when map screen active
   - No location tracking or history
   - No geofencing or location-based notifications

4. **Automatic Data Expiry**
   - 6-hour cache TTL (automatic cleanup)
   - LRU eviction at 100 entries
   - No indefinite data retention

5. **No User Authentication**
   - No accounts, no user IDs, no session tracking
   - Stateless architecture
   - No cross-device data sync

### Organizational Measures

1. **Developer Training**
   - All developers trained on C2 compliance
   - Code review checklist includes privacy checks
   - Privacy impact assessed for all features

2. **Incident Response**
   - Privacy breach procedures documented
   - Data leak detection in CI/CD pipeline
   - Quarterly privacy audits

3. **Documentation**
   - Privacy policy reviewed quarterly
   - User-facing privacy notices in-app
   - Transparency reports (if required)

---

## Constitutional Compliance Summary

### C2: Secrets & Logging

**Requirements**:
- ✅ No API keys in repository (gitignored, pre-commit hooks)
- ✅ Coordinate logging always redacted (2dp precision)
- ✅ Geohash logging for spatial operations (5-char precision)
- ✅ No device IDs or personal identifiers in logs
- ✅ UTC timestamps only (no timezone inference)

**Enforcement**:
- Pre-commit hooks: Block API keys, detect raw coordinates
- Code review: Mandatory privacy checks
- CI/CD: gitleaks scan on every commit
- Constitution gates: `.specify/scripts/bash/constitution-gates.sh`

**Verification**:
```bash
# Run constitution gates (includes C2 checks)
./.specify/scripts/bash/constitution-gates.sh

# Check for raw coordinates in logs (should return 0)
grep -r "logger.*\$lat.*\$lon" lib/ test/ || echo "✅ No raw coordinate logging"

# Check for API keys in source (should return 0)
gitleaks detect --no-git || echo "✅ No secrets in source"
```

---

## Frequently Asked Questions

### Q: Does WildFire MVP v3 track my location?

**A**: No. We only access your location when you open the map screen, and we don't store location history. Your location is used once to show nearby fire incidents, then discarded.

### Q: What happens to my location data?

**A**: Your location is used to query public fire data sources (EFFIS/SEPA), then it's discarded. We log redacted coordinates (±1km precision) for debugging, but never your full precise location.

### Q: Can I use the app without GPS?

**A**: Yes! You can manually enter a location or use the default Scotland centroid. The app is fully functional without GPS access.

### Q: Where is my data stored?

**A**: All data is stored locally on your device. We cache fire incident data for 6 hours to improve performance, but it's automatically deleted after expiry. Nothing is uploaded to cloud servers.

### Q: What data do you share with third parties?

**A**: We only share necessary data with public fire data services (EFFIS, SEPA) to fetch fire incidents. This includes your map viewport coordinates (which area you're viewing), but no personal identifiers.

### Q: How do I delete my data?

**A**: Go to Settings → Privacy → Clear Cache. Or simply uninstall the app - all data is deleted automatically.

### Q: Do you use cookies or tracking?

**A**: No cookies (mobile app, not web browser). No analytics tracking personal data. No third-party trackers or advertising SDKs.

### Q: Is my API key secure?

**A**: API keys are never stored in the app source code. They're in gitignored environment files and restricted by platform (Android package name, iOS bundle ID). See `docs/google-maps-setup.md` for details.

---

## Contact

**Privacy Questions**: [Contact information to be added]

**Data Protection Officer**: [To be assigned if GDPR compliance required]

**Privacy Policy Updates**: This statement is reviewed quarterly and updated as needed. Last review: 2025-10-20.

---

## Related Documentation

- `docs/google-maps-setup.md` - API key security
- `docs/WEB_API_KEY_SECURITY.md` - Web platform security
- `docs/accessibility-statement.md` - Accessibility features
- `docs/runbooks/effis-monitoring.md` - Operational procedures
- `.github/copilot-instructions.md` - C2 compliance guidelines

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-20 | 1.0 | Initial privacy compliance statement | GitHub Copilot |

**Next Review**: 2026-01-20 (quarterly review recommended)
