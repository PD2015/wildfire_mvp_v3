---
title: Preview Deployment Testing Guide
status: active
last_updated: 2025-10-20
category: guides
subcategory: testing
related:
  - guides/testing/integration-tests.md
  - reference/test-coverage.md
  - ../setup/google-maps.md
---

# Preview Deployment Testing Guide

## Overview

Web integration tests cannot run in CI without exposing API keys. Instead, we test against **deployed preview environments** where API keys are securely injected during the build process.

## Why Not Test in CI?

**Problem**: Google Maps JavaScript API script loads in `web/index.html` **before Flutter starts**. Without an API key, the Maps API throws `RefererNotAllowedMapError`, which prevents the entire Flutter widget tree from rendering properly.

**Solution**: Test against deployed Firebase preview channels where:
- API keys are injected via `build_web_ci.sh` from GitHub Secrets
- HTTP referrer restrictions are properly configured
- Real production-like environment

## Testing Strategy

### 1. Automated Preview Tests (CI/CD)

**When**: After every preview deployment (on PRs)

The `test-preview` job in `.github/workflows/flutter.yml` automatically:
1. Waits for `deploy-preview` to complete
2. Runs integration tests against the deployed preview URL
3. Reports results in PR checks

**Status**: Currently `continue-on-error: true` because API key restrictions may need preview URL patterns added.

**To enable strict testing**:
1. Add Firebase preview URL pattern to Google Maps API HTTP referrer restrictions:
   ```
   https://wildfire-app-e11f8--pr-*-*.web.app/*
   ```
2. Remove `continue-on-error: true` from workflow
3. Tests will block PR merge if they fail

### 2. Manual QA Checklist (Before PR Merge)

**When**: Before approving/merging any PR that touches UI or navigation

**Steps**:
1. Find preview URL in PR comment (posted by Firebase action)
2. Open in Chrome/Firefox
3. Run through checklist:

```markdown
## Preview Deployment QA Checklist

**Preview URL**: [Insert URL from PR comment]

### Core Navigation
- [ ] Home screen loads with risk banner
- [ ] Navigation bar shows 3 destinations: Home, Map, Report Fire
- [ ] Click "Map" → Map screen loads with tiles visible (no watermark)
- [ ] Click "Report Fire" → Report fire screen loads

### Map Functionality
- [ ] Map tiles load correctly (Google Maps)
- [ ] Map is interactive (pan, zoom work)
- [ ] No console errors in browser DevTools
- [ ] No "This page can't load Google Maps correctly" warning

### Report Fire Screen
- [ ] Emergency buttons render (Call 999, Call 112, Call 101)
- [ ] All buttons have correct labels and semantics
- [ ] Tap each button → Confirms intent before action

### Cross-Browser (if time permits)
- [ ] Safari (macOS/iOS)
- [ ] Firefox
- [ ] Mobile Chrome (responsive view)
```

### 3. Staging Environment Smoke Tests

**When**: After deployment to staging (before promoting to production)

**URL**: https://wildfire-app-e11f8-staging.web.app

**Automated Tests** (future enhancement):
```bash
# Run against staging environment
flutter test integration_test/ \
  --dart-define=TEST_TARGET_URL=https://wildfire-app-e11f8-staging.web.app \
  --platform=chrome
```

**Manual Validation**:
- Run full QA checklist above
- Test on real mobile devices (iOS/Android browsers)
- Verify analytics/monitoring (Firebase Console)
- Check Lighthouse scores (performance, accessibility)

## HTTP Referrer Configuration

### Required API Key Restrictions

Your Google Maps API key must allow these referrers:

**Development**:
```
localhost:*
127.0.0.1:*
```

**Preview Deployments**:
```
https://wildfire-app-e11f8--pr-*-*.web.app/*
```

**Staging**:
```
https://wildfire-app-e11f8-staging.web.app/*
```

**Production**:
```
https://wildfire-app-e11f8.web.app/*
https://your-custom-domain.com/*
```

### How to Update Restrictions

1. **Google Cloud Console** → APIs & Services → Credentials
2. Click your web API key
3. Under "API restrictions" → "HTTP referrers"
4. Add patterns above
5. Save changes (takes effect immediately)

## Troubleshooting

### "This page can't load Google Maps correctly" Warning

**Cause**: HTTP referrer restrictions don't include the preview URL pattern

**Fix**:
1. Copy preview URL from browser address bar
2. Extract pattern: `https://wildfire-app-e11f8--pr-123-abc123.web.app/`
3. Add wildcard pattern to API key restrictions: `https://wildfire-app-e11f8--pr-*-*.web.app/*`

### Tests Pass Locally but Fail on Preview

**Cause**: Different API keys (local vs. preview)

**Check**:
- Local: Uses `env/dev.env.json` → `GOOGLE_MAPS_API_KEY_WEB`
- Preview: Uses GitHub Secret → `GOOGLE_MAPS_API_KEY_WEB_PREVIEW`
- Ensure both keys have correct referrer restrictions

### Console Error: "RefererNotAllowedMapError"

**Cause**: API key restrictions don't include the URL you're testing from

**Fix**: Add the URL pattern to HTTP referrer restrictions (see above)

## CI/CD Integration

### Current Workflow

```
PR Created → build-web → deploy-preview → test-preview (continue-on-error)
                                         ↓
                                    Preview URL in PR comment
                                         ↓
                                    Manual QA using checklist
                                         ↓
                                    Approve & Merge
                                         ↓
                            Push to staging → deploy-staging
                                         ↓
                                    Smoke tests (manual)
                                         ↓
                            Push to main → deploy-production (requires approval)
```

### Future Enhancements

1. **Strict Preview Tests**: Remove `continue-on-error` once API restrictions configured
2. **Playwright E2E**: More comprehensive browser automation (see `docs/guides/testing/e2e-testing.md`)
3. **Visual Regression**: Screenshot comparison between deployments
4. **Performance Budgets**: Fail if Lighthouse scores drop below thresholds

## Best Practices

1. **Always test preview deployments** before merging PRs that touch:
   - Navigation (routing, bottom nav)
   - Map screen (Google Maps integration)
   - Platform-specific features (web vs. mobile)

2. **Use browser DevTools**:
   - Console: Check for JavaScript errors
   - Network: Verify Maps API requests succeed (200 status)
   - Elements: Inspect rendered widget tree

3. **Test on multiple browsers**:
   - Chrome (primary)
   - Firefox (secondary)
   - Safari (if available)

4. **Document issues in PR**:
   - If QA reveals bugs, add comments to PR
   - Link to console errors/screenshots
   - Block merge until fixed

## Related Documentation

- **Setup**: [Google Maps API Setup Guide](../setup/google-maps.md)
- **Integration Tests**: [Integration Testing Guide](integration-tests.md)
- **CI/CD**: [CI/CD Workflow Guide](../../CI_CD_WORKFLOW_GUIDE.md)
- **Deployment**: [Firebase Deployment](../../FIREBASE_DEPLOYMENT.md)
