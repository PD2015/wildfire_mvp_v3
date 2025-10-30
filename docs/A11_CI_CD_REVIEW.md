# A11 CI/CD Review: Flutter Web → Firebase Hosting

**Review Date**: 2025-10-26  
**Reviewer**: GitHub Copilot  
**Status**: ✅ RECOMMENDED WITH MODIFICATIONS

---

## Executive Summary

Your Specify command for A11 CI/CD is **well-structured and aligns well** with your project's existing architecture. However, I've identified several important adjustments needed to integrate with your current setup:

### ✅ Strengths
- Clear separation of environments (PR preview, staging, production)
- Secure secret management approach
- SPA routing considerations for go_router
- Appropriate cache header strategy

### ⚠️ Required Adjustments
1. **Branch model conflict**: You use `main` for active development, not `develop`
2. **Existing CI workflow**: Already have `.github/workflows/flutter.yml` - need to integrate, not replace
3. **API key injection mechanism**: Already have `scripts/build_web.sh` - leverage existing pattern
4. **Firebase project setup**: Need to clarify Firebase project ID (is it already created?)
5. **Constitutional gates**: Must integrate C1-C5 compliance checks from existing CI

---

## Recommended Changes to Specify Command

### 1. Updated Branch Model

**CURRENT REALITY** (from your repo):
- `main` = active development branch (merged from `011-a10-google-maps` recently)
- No `develop` branch exists
- PRs target `main` directly

**CHANGE THIS**:
```yaml
Branch Model
- main = production
- develop = staging
- PRs targeting main = preview channels
```

**TO THIS**:
```yaml
Branch Model
- main = production + active development (current state)
- tags (v*.*.*) = production releases with manual approval
- PRs targeting main = preview channels
- Option: Create staging branch later if needed, but not required for A11
```

---

### 2. Integration with Existing CI Workflow

You already have `.github/workflows/flutter.yml` with:
- ✅ Constitutional gates (C1: format, analyze, tests)
- ✅ LocationResolver tests (A4 validation)
- ✅ Secret scanning with gitleaks (C2)
- ✅ Color palette guard (C4)
- ✅ Chrome testing platform

**CHANGE**: Don't create standalone `firebase-hosting.yml`

**RECOMMENDED APPROACH**:
1. **Extend existing `flutter.yml`** with Firebase deployment job
2. Keep CI tests as prerequisite before deployment
3. Add Firebase deployment as final step only on success

**Updated Deliverables**:
```yaml
Scope / Deliverables (files)
- .github/workflows/flutter.yml (EXTEND existing, don't replace)
- firebase.json (NEW - hosting config with rewrites + headers)
- .firebaserc (NEW - links repo to Firebase project)
- web/index.html (MODIFY - already has Google Maps script, needs CI placeholder)
- scripts/build_web_ci.sh (NEW - CI-specific build script)
- docs/FIREBASE_DEPLOYMENT.md (RENAMED from ci-cd.md for clarity)
```

---

### 3. API Key Injection Mechanism

You **already have** `scripts/build_web.sh` that:
- ✅ Reads from `env/dev.env.json`
- ✅ Injects API key into `web/index.html`
- ✅ Restores original file after build
- ✅ Uses `git checkout web/index.html` for cleanup

**CHANGE**: Don't reinvent the wheel

**RECOMMENDED**:
1. Create `scripts/build_web_ci.sh` (CI-specific variant)
2. CI script reads from GitHub Secrets instead of env files
3. Reuse same injection logic as existing `build_web.sh`

**Example CI Build Script**:
```bash
#!/bin/bash
# scripts/build_web_ci.sh
# CI-specific build script that reads from environment variables

set -e

echo "🌐 Building WildFire MVP v3 for Web (CI mode)..."

# API key comes from GitHub Secrets (set via env vars)
WEB_API_KEY="${MAPS_API_KEY_WEB:-}"

if [ -z "$WEB_API_KEY" ]; then
  echo "❌ Error: MAPS_API_KEY_WEB environment variable not set"
  exit 1
fi

# Inject API key (same logic as build_web.sh)
echo "🔑 Injecting API key into web/index.html..."
sed -i 's|<script src="https://maps.googleapis.com/maps/api/js"></script>|<script src="https://maps.googleapis.com/maps/api/js?key='"$WEB_API_KEY"'"></script>|' web/index.html

# Build web app
echo "🔨 Building Flutter web app..."
flutter build web --release --dart-define=MAP_LIVE_DATA=false

echo "✅ Web build complete for CI!"
echo "📁 Output: build/web/"
```

---

### 4. Updated web/index.html Strategy

**CURRENT STATE**:
```html
<script src="https://maps.googleapis.com/maps/api/js"></script>
```

**PROBLEM**: CI needs to inject `?key=...` but current approach uses `sed` replacement.

**CHANGE**: Use explicit placeholder for better CI compatibility

**RECOMMENDED**:
```html
<!-- %MAPS_API_KEY% will be replaced by CI with actual key -->
<script src="https://maps.googleapis.com/maps/api/js%MAPS_API_KEY%"></script>
```

Then CI script does:
```bash
# Replace placeholder with ?key=XXX or empty string
sed -i 's|%MAPS_API_KEY%|?key='"$WEB_API_KEY"'|' web/index.html
```

**Benefits**:
- Clearer intent (placeholder is explicit)
- Works with or without key (dev mode = `%MAPS_API_KEY%` → empty string)
- No need to restore file after build (placeholder stays)

---

### 5. Firebase Project Clarification

**QUESTION**: Do you already have a Firebase project?

**IF YES** (project exists):
```yaml
Secrets (GitHub → Settings → Secrets and variables → Actions)
- FIREBASE_SERVICE_ACCOUNT = JSON for Firebase deployer SA
- FIREBASE_PROJECT_ID = wildfire-mvp-v3 (or your actual ID)
- MAPS_API_KEY_STAGING = Web key restricted to *.web.app + *.firebaseapp.com
- MAPS_API_KEY_PRODUCTION = Web key restricted to custom domain
```

**IF NO** (need to create):
Add to Specify command:
```yaml
Prerequisites
1. Create Firebase project: https://console.firebase.google.com/
   - Project name: WildFire MVP v3
   - Enable Hosting
2. Install Firebase CLI: npm i -g firebase-tools
3. Login: firebase login
4. Init hosting: firebase init hosting (select existing Flutter web build)
```

---

### 6. Updated Secrets Configuration

**CHANGE**: Align secret names with your existing conventions

**CURRENT NAMING** (from `env/dev.env.json.template`):
- `GOOGLE_MAPS_API_KEY_WEB`
- `GOOGLE_MAPS_API_KEY_ANDROID`
- `GOOGLE_MAPS_API_KEY_IOS`

**RECOMMENDED GITHUB SECRETS**:
```yaml
Secrets (GitHub → Settings → Secrets and variables → Actions)
Required:
- FIREBASE_SERVICE_ACCOUNT = {"type":"service_account",...} (JSON)
- FIREBASE_PROJECT_ID = wildfire-mvp-v3

Web API Keys (environment-specific):
- GOOGLE_MAPS_API_KEY_WEB_PREVIEW = For PR preview channels (*.web.app)
- GOOGLE_MAPS_API_KEY_WEB_PRODUCTION = For production (custom domain)

Optional (if you add staging):
- GOOGLE_MAPS_API_KEY_WEB_STAGING = For staging channel
```

**Rationale**: 
- Consistent naming with existing env files
- Clear environment distinction
- One preview key for all PRs (simpler)

---

### 7. Constitutional Gates Integration

Your existing CI has C1-C5 compliance checks. **MUST preserve these**.

**RECOMMENDED WORKFLOW STRUCTURE**:
```yaml
jobs:
  # Job 1: Run all tests + constitutional gates (EXISTING)
  test:
    name: Tests & Constitutional Gates (C1-C5)
    runs-on: ubuntu-latest
    steps:
      - checkout
      - setup flutter
      - format check (C1)
      - analyze (C1)
      - run tests (C1, C5)
      - secret scan (C2)
      - color guard (C4)
      # NEW: Build web artifact for deployment
      - name: Build web (if tests pass)
        if: success()
        run: |
          MAPS_API_KEY_WEB=${{ secrets.GOOGLE_MAPS_API_KEY_WEB_PREVIEW }}
          ./scripts/build_web_ci.sh
      - upload artifact: build/web

  # Job 2: Deploy to Firebase (NEW) - only if tests pass
  deploy-preview:
    name: Deploy Preview Channel
    needs: test  # Waits for test job
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - checkout
      - download artifact: build/web
      - setup firebase CLI
      - deploy preview channel
      - comment PR with URL

  deploy-production:
    name: Deploy Production
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval
    steps:
      - checkout
      - download artifact: build/web
      - setup firebase CLI
      - deploy production
```

---

### 8. firebase.json Configuration

**RECOMMENDED** (aligned with your go_router setup):
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/index.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      },
      {
        "source": "/flutter_service_worker.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      },
      {
        "source": "/assets/**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(js|css|woff|woff2|ttf|png|jpg|jpeg|gif|svg|ico)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
```

**Key Features**:
- ✅ SPA routing: All routes → `/index.html`
- ✅ No cache for `index.html` and service worker (ensures updates)
- ✅ Immutable cache for assets (1 year = 31536000s)
- ✅ Includes font files (woff, woff2, ttf)

---

### 9. Testing & Validation Strategy

**ADD TO SPECIFY COMMAND**:
```yaml
Testing Strategy (before running A11)
1. Test local Firebase build:
   - firebase init hosting (dry run)
   - firebase emulators:start --only hosting
   - Verify: http://localhost:5000
   - Check: SPA routing works (refresh /map doesn't 404)
   - Check: Assets load with correct cache headers

2. Test API key injection:
   - Set MAPS_API_KEY_WEB=test_key_12345
   - Run: ./scripts/build_web_ci.sh
   - Verify: build/web/index.html contains ?key=test_key_12345
   - Verify: No API key in web/index.html (source)

3. Test CI workflow (without deployment):
   - Push to feature branch
   - Check: Workflow runs tests
   - Check: Build artifact created
   - Check: No deployment triggered (only on PR)
```

---

## Updated Specify Command

Here's your **revised Specify command** with all recommendations:

```yaml
Title: A11 – CI/CD: Flutter Web → Firebase Hosting (PR Previews + Production)

Problem
We need a reliable CI/CD pipeline to build and deploy our Flutter web app to Firebase Hosting with: (1) automatic PR preview URLs, (2) production deploys on main with manual approval. Google Maps API keys must be injected securely at build time using GitHub Secrets. Must integrate with existing constitutional gates (C1-C5) from flutter.yml.

Goals
- Extend existing .github/workflows/flutter.yml with Firebase deployment
- PRs → Preview Channels (unique URL per PR, auto-cleanup after 7 days)
- main branch + manual approval → Production Channel
- SPA routing for go_router (no refresh 404s)
- Sensible cache headers (no-cache for index.html; immutable for /assets)
- Safe injection of Google Maps Web API key using GitHub Secrets
- Preserve existing CI checks: C1 (format, analyze, tests), C2 (secret scan), C4 (color guard), C5 (performance)

Non-Goals
- No backend/database work
- No server-side rendering or edge functions
- No staging environment (can add later if needed)
- No changes to mobile CI/CD (Android/iOS builds out of scope)

Scope / Deliverables (files)
- .github/workflows/flutter.yml (EXTEND existing workflow with deploy jobs)
- firebase.json (NEW - hosting config with rewrites + headers for SPA)
- .firebaserc (NEW - links repo to Firebase project)
- web/index.html (MODIFY - add %MAPS_API_KEY% placeholder for CI injection)
- scripts/build_web_ci.sh (NEW - CI-specific build script using env vars)
- docs/FIREBASE_DEPLOYMENT.md (NEW - runbook for Firebase operations)

Branch Model
- main = production + active development (current repository structure)
- PRs targeting main = preview channels (auto-deployed, auto-cleanup after 7d)
- tags (v*.*.*) = future versioned releases (optional)
- No develop branch (not currently used)

Secrets (GitHub → Settings → Secrets and variables → Actions)
Required:
- FIREBASE_SERVICE_ACCOUNT = JSON for Firebase deployer service account (role: Firebase Hosting Admin)
- FIREBASE_PROJECT_ID = Firebase project ID (e.g., wildfire-mvp-v3)

API Keys (align with existing naming convention):
- GOOGLE_MAPS_API_KEY_WEB_PREVIEW = Web API key for PR preview channels
  - Restrictions: HTTP referrers → *.web.app/*, *.firebaseapp.com/*
- GOOGLE_MAPS_API_KEY_WEB_PRODUCTION = Web API key for production
  - Restrictions: HTTP referrers → yourdomain.com/*, www.yourdomain.com/*

Success Metrics
- M1: Any PR to main receives a preview URL comment within 5 minutes
- M2: Preview channels auto-expire after 7 days (Firebase default)
- M3: Push to main deploys to production only after manual approval in GitHub Environments
- M4: Deep links refresh without 404s (e.g., https://app.com/map works on F5)
- M5: Lighthouse performance score ≥90 (C5 constitutional gate)
- M6: All constitutional gates (C1-C5) pass before deployment

Risks & Mitigations
- Misconfigured API key restrictions → Test preview URL before merging; document exact referrer patterns in FIREBASE_DEPLOYMENT.md
- Cache issues causing stale app → index.html no-cache; assets immutable with content hashing
- Service account key leakage → Stored only in GitHub Secrets; never in env files or logs
- Failing tests block all PRs → Expected behavior; ensures C1-C5 compliance before deployment
- Firebase quota limits → Monitor usage; free tier includes 10GB/month + 360MB/day

Acceptance Criteria
- AC1: PR preview deploys automatically to unique Firebase Hosting channel
- AC2: Production deploys require manual approval via GitHub Environment protection
- AC3: web/index.html uses %MAPS_API_KEY% placeholder (not hardcoded key)
- AC4: scripts/build_web_ci.sh injects API key from GOOGLE_MAPS_API_KEY_WEB_* env var
- AC5: firebase.json has rewrites to /index.html for SPA routing
- AC6: firebase.json has correct cache headers (no-cache for index.html, immutable for assets)
- AC7: docs/FIREBASE_DEPLOYMENT.md explains: setup, deployment, rollback, key rotation, troubleshooting
- AC8: All existing CI checks (format, analyze, tests, gitleaks, color guard) run before deployment
- AC9: Build artifacts uploaded to GitHub Actions for debugging failed deployments

Prerequisites (complete before running Specify)
1. Firebase project created: https://console.firebase.google.com/
   - Project name: WildFire MVP v3
   - Hosting enabled
2. Firebase CLI installed globally: npm i -g firebase-tools
3. Firebase authenticated: firebase login
4. Service account created with Firebase Hosting Admin role
5. Service account JSON downloaded and added to GitHub Secrets
6. Google Maps Web API keys created in Google Cloud Console
7. API key restrictions configured for preview (*.web.app) and production domains
8. GitHub Environments configured: Settings → Environments → Create "production"
   - Add required reviewers (yourself or team)
   - Add protection rules (require approval before deployment)
```

---

## Implementation Checklist

Before running the Specify command, complete these steps:

### Phase 1: Firebase Setup (15-20 minutes)
- [x] Create Firebase project at https://console.firebase.google.com/ (wildfire-app-e11f8)
- [x] Enable Firebase Hosting in project settings
- [x] Initialize hosting: `firebase init hosting` (completed 2025-10-27)
- [x] Test local emulator: `firebase emulators:start --only hosting` (verified port 5002)
- [x] Create service account with Firebase Hosting Admin role (completed 2025-10-27)
- [x] Download service account JSON file (stored securely)
- [x] Test actual deployment: `firebase deploy --only hosting` (✅ SUCCESS - https://wildfire-app-e11f8.web.app)

### Phase 2: API Key Configuration (10-15 minutes)
- [x] Create Google Maps API key for Firebase domains (WildFire Web - Firebase Preview)
  - Restricted to: `https://wildfire-app-e11f8.web.app/*`, `https://wildfire-app-e11f8.firebaseapp.com/*`, `https://*.wildfire-app-e11f8.web.app/*`
  - Covers: Production, alternative domain, and all PR preview channels
- [ ] Create separate production key (OPTIONAL - only needed when you get a custom domain)
- [x] Update local `env/dev.env.json` with new key
- [x] Test build with `./scripts/build_web.sh`
- [x] Test deployment: ✅ https://wildfire-app-e11f8.web.app (map loads without watermark)

### Phase 3: GitHub Configuration (10 minutes)
- [x] Add secrets to GitHub: Settings → Secrets and variables → Actions
  - [x] FIREBASE_SERVICE_ACCOUNT (paste JSON content)
  - [x] FIREBASE_PROJECT_ID (wildfire-app-e11f8)
  - [x] GOOGLE_MAPS_API_KEY_WEB_PREVIEW
  - [x] GOOGLE_MAPS_API_KEY_WEB_PRODUCTION
- [x] Create "production" environment: Settings → Environments → New environment
  - [x] Add required reviewers
  - [x] Set deployment protection rules

### Phase 4: Run Specify Command (2-3 minutes)
- [ ] Paste the updated Specify command above
- [ ] Review generated files
- [ ] Test locally before committing

### Phase 5: Testing (30-45 minutes)
- [ ] Test local Firebase emulator: `firebase emulators:start --only hosting`
- [ ] Verify SPA routing works (refresh /map doesn't 404)
- [ ] Create test PR and verify preview deployment
- [ ] Verify PR comment includes preview URL
- [ ] Test preview URL with different routes
- [ ] Merge PR and verify production deployment blocked (waiting for approval)
- [ ] Approve production deployment
- [ ] Verify production URL works

---

## Additional Recommendations

### 1. Add Firebase to .gitignore
```bash
# Add to .gitignore (if not already present)
echo ".firebase/" >> .gitignore
echo "firebase-debug.log" >> .gitignore
echo "firestore-debug.log" >> .gitignore
```

### 2. Update README.md
Add deployment section:
```markdown
## Deployment

### Preview (Pull Requests)
Every PR automatically deploys to a unique Firebase Hosting preview channel.
Check PR comments for the preview URL.

### Production (Main Branch)
Merging to `main` triggers production deployment after manual approval.
Requires: GitHub Environments → Production → Approve deployment

See [FIREBASE_DEPLOYMENT.md](FIREBASE_DEPLOYMENT.md) for details.
```

### 3. Add Rollback Documentation
In `docs/FIREBASE_DEPLOYMENT.md`, include:
```markdown
## Emergency Rollback

### Option 1: Firebase Console
1. Go to https://console.firebase.google.com/
2. Select project → Hosting
3. Click "Release History"
4. Find previous working version
5. Click "Rollback to this version"

### Option 2: Firebase CLI
```bash
# List recent deployments
firebase hosting:releases:list

# Rollback to specific version
firebase hosting:rollback <release-id>
```

### Option 3: Redeploy Previous Commit
```bash
git checkout <previous-commit-sha>
firebase deploy --only hosting
git checkout main
```
```

---

## Summary

Your Specify command is **85% ready**. The main changes needed are:

1. ✅ **Branch model**: Use `main` (no `develop`)
2. ✅ **Workflow integration**: Extend existing `flutter.yml`, don't create new file
3. ✅ **API key injection**: Create CI script that reuses existing pattern
4. ✅ **Placeholder strategy**: Use `%MAPS_API_KEY%` in `web/index.html`
5. ✅ **Secret naming**: Align with existing conventions (`GOOGLE_MAPS_API_KEY_WEB_*`)
6. ✅ **Constitutional gates**: Preserve existing C1-C5 checks
7. ✅ **Documentation**: Rename to `FIREBASE_DEPLOYMENT.md` for clarity

**Estimated Total Time**: 1.5-2 hours (including setup, testing, documentation)

**Risk Level**: LOW - You already have secure build scripts and comprehensive testing. Firebase Hosting is straightforward for SPAs.

---

## Ready to Proceed?

If you're happy with these changes, use the **Updated Specify Command** in the "Updated Specify Command" section above. It incorporates all recommendations and aligns with your project's existing architecture.

Would you like me to help with any of the prerequisite steps (Firebase setup, GitHub Environments, etc.) before you run the command?
