# Phase 0: Research - CI/CD Best Practices for Firebase Hosting

**Feature**: A11 – CI/CD: Flutter Web → Firebase Hosting  
**Date**: 2025-10-27  
**Status**: Complete

---

## Research Areas

### 1. Firebase Hosting Channel Deployments (PR Previews)

**Decision**: Use Firebase Hosting Channels with GitHub Actions `FirebaseExtended/action-hosting-deploy`

**Rationale**:
- Official GitHub Action maintained by Firebase team
- Built-in support for PR preview channels (unique URL per PR)
- Automatic channel cleanup after 7 days (configurable TTL)
- Native integration with GitHub pull request comments (posts preview URL automatically)
- Handles authentication via FIREBASE_SERVICE_ACCOUNT secret
- Supports both live channels (production) and preview channels (PRs)

**Alternatives Considered**:
1. **Manual firebase-tools CLI deployment**: More control but requires custom PR commenting logic
2. **Custom Docker container with firebase-tools**: Overhead of container management, no additional benefit
3. **Netlify/Vercel**: Would require migration from Firebase, loss of existing Firebase project setup

**Implementation Pattern**:
```yaml
# PR Preview Deployment
- uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    repoToken: '${{ secrets.GITHUB_TOKEN }}'
    firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
    projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
    channelId: 'pr-${{ github.event.pull_request.number }}'
    expires: 7d
    target: hosting # Hosting target name (optional if only one site)

# Production Deployment
- uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    repoToken: '${{ secrets.GITHUB_TOKEN }}'
    firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
    projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
    channelId: live # Deploys to production
```

**Key Benefits**:
- Zero custom scripting for PR preview URLs
- Automatic comment on PR with preview link
- TTL-based cleanup (no manual maintenance)
- Consistent authentication pattern via service account

---

### 2. API Key Injection in CI/CD Builds

**Decision**: Use placeholder replacement pattern with `sed` during build phase

**Rationale**:
- Simple, testable, language-agnostic approach
- No Flutter SDK dependencies (pure shell script)
- Reuses existing pattern from `scripts/build_web.sh` (local dev)
- API keys never touch repository (injected at build time, discarded after)
- GitHub Actions environment variables provide secure key storage
- Works with any CI/CD system (GitHub Actions, GitLab CI, etc.)

**Alternatives Considered**:
1. **Flutter web build-time environment variables**: Requires custom index.html generation, more complex
2. **Dart code injection via --dart-define**: Only works for Dart code, not external scripts (Google Maps)
3. **Firebase Remote Config**: Runtime configuration, adds latency and complexity
4. **Secret scanning with encrypted files**: Requires decryption step, more points of failure

**Implementation Pattern**:
```bash
#!/bin/bash
# scripts/build_web_ci.sh
set -e

# Read API key from GitHub Secrets (set as environment variable by workflow)
WEB_API_KEY="${MAPS_API_KEY_WEB:-}"

if [ -z "$WEB_API_KEY" ]; then
  echo "❌ Error: MAPS_API_KEY_WEB environment variable not set"
  exit 1
fi

echo "🔑 Injecting API key into web/index.html..."
# Replace placeholder with actual key
sed -i.bak 's|%MAPS_API_KEY%|?key='"$WEB_API_KEY"'|g' web/index.html

echo "🔨 Building Flutter web app..."
flutter build web --release --dart-define=MAP_LIVE_DATA=false

echo "✅ Web build complete!"
echo "📁 Build output: build/web/"

# Cleanup: Restore original file (prevents key from being committed)
mv web/index.html.bak web/index.html

echo "🔒 API key injection cleaned up (original file restored)"
```

**Key Benefits**:
- Clear audit trail (API key injection logged but not exposed)
- Fail-fast on missing API key
- Automatic cleanup prevents accidental key commits
- Compatible with existing local build script pattern

---

### 3. GitHub Actions Job Dependencies and Artifact Sharing

**Decision**: Use job dependencies with `needs:` keyword and `actions/upload-artifact` / `actions/download-artifact`

**Rationale**:
- Native GitHub Actions feature (no third-party tools)
- Preserves build artifacts for debugging failed deployments
- Enforces sequential execution (tests → build → deploy)
- Artifacts automatically cleaned up after 90 days (default retention)
- Works across job runners (Ubuntu, macOS, Windows)

**Alternatives Considered**:
1. **Monolithic job (all steps in one job)**: Harder to debug, can't reuse artifacts, slower reruns
2. **Docker layer caching**: Overkill for Flutter web builds, adds complexity
3. **External artifact storage (S3, GCS)**: Requires additional authentication, cost, retention management

**Implementation Pattern**:
```yaml
jobs:
  test:
    name: Tests & Constitutional Gates
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test
      # ... other constitutional gates (gitleaks, color guard)

  build-web:
    name: Build Web Artifact
    needs: test  # Waits for test job to succeed
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      - run: flutter pub get
      - name: Build web with API key
        env:
          MAPS_API_KEY_WEB: ${{ secrets.GOOGLE_MAPS_API_KEY_WEB_PREVIEW }}
        run: ./scripts/build_web_ci.sh
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: build/web/
          retention-days: 7  # Short retention for preview builds

  deploy-preview:
    name: Deploy Preview Channel
    needs: build-web  # Waits for build-web to succeed
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: web-build
          path: build/web/
      - name: Deploy to Firebase preview channel
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
          channelId: 'pr-${{ github.event.pull_request.number }}'
          expires: 7d
```

**Key Benefits**:
- Clear separation of concerns (test, build, deploy)
- Failed tests block builds (build job never runs)
- Failed builds block deployments (deploy job never runs)
- Artifacts preserved for debugging (download from GitHub Actions UI)
- Can re-run individual jobs without full pipeline

---

### 4. GitHub Environments for Production Approval

**Decision**: Use GitHub Environments with required reviewers for production deployments

**Rationale**:
- Native GitHub feature (no third-party tools or webhooks)
- Integrates with GitHub's access control (reviewers, protection rules)
- Deployment history visible in repository Environments tab
- Reviewers notified via GitHub notifications
- Can add additional checks (wait timer, deployment branches)

**Alternatives Considered**:
1. **Manual workflow_dispatch trigger**: Requires maintainer to manually run workflow, less audit trail
2. **Branch protection rules**: Only protects merges, not deployments
3. **Third-party approval tools (Slack, PagerDuty)**: Additional dependencies, authentication complexity

**Implementation Pattern**:
```yaml
deploy-production:
  name: Deploy Production
  needs: build-web
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  environment:
    name: production  # GitHub Environment (requires setup in repo settings)
    url: https://wildfire-app-e11f8.web.app  # Deployment URL visible in UI
  steps:
    - uses: actions/checkout@v4
    - name: Download artifact
      uses: actions/download-artifact@v4
      with:
        name: web-build
        path: build/web/
    - name: Deploy to Firebase production
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
        channelId: live
```

**GitHub Environment Setup** (required once in repository settings):
1. Navigate to: Settings → Environments → New environment
2. Name: `production`
3. Protection rules:
   - ✅ Required reviewers: Add maintainers (e.g., yourself or team)
   - ✅ Wait timer: 0 minutes (optional: add delay before deployment)
   - ✅ Deployment branches: `main` only
4. Save environment

**Key Benefits**:
- Zero production deployments without approval (constitutional compliance)
- Audit trail (who approved, when, why)
- Can pause/cancel deployments before execution
- Rollback visible in deployment history

---

### 5. SPA Routing Configuration for go_router

**Decision**: Use Firebase Hosting rewrites to serve `index.html` for all routes

**Rationale**:
- Standard pattern for SPAs (React, Vue, Angular, Flutter web)
- Firebase Hosting natively supports rewrites (no custom server)
- Works with Flutter's go_router client-side routing
- No 404 errors on deep link refresh (e.g., `/map` → serves index.html → go_router handles `/map`)
- Cache headers can differ between index.html (no-cache) and assets (immutable)

**Alternatives Considered**:
1. **Hash routing (#/map)**: Works but uglier URLs, harder to share, SEO disadvantage
2. **Server-side rendering (SSR)**: Not supported by Flutter web, would require framework change
3. **Custom 404 page redirecting to index.html**: Causes flash of 404, poor UX

**Implementation Pattern** (already in firebase.json):
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
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
          {"key": "Cache-Control", "value": "no-cache, no-store, must-revalidate"}
        ]
      },
      {
        "source": "/flutter_service_worker.js",
        "headers": [
          {"key": "Cache-Control", "value": "no-cache, no-store, must-revalidate"}
        ]
      },
      {
        "source": "/assets/**",
        "headers": [
          {"key": "Cache-Control", "value": "public, max-age=31536000, immutable"}
        ]
      },
      {
        "source": "**/*.@(js|css|woff|woff2|ttf|png|jpg|jpeg|gif|svg|ico)",
        "headers": [
          {"key": "Cache-Control", "value": "public, max-age=31536000, immutable"}
        ]
      }
    ]
  }
}
```

**Key Configuration Elements**:
- `rewrites: [{"source": "**", "destination": "/index.html"}]`: All routes serve index.html
- `index.html` cache: `no-cache` (ensures users get latest app version)
- `flutter_service_worker.js` cache: `no-cache` (PWA update mechanism)
- `/assets/**` cache: `max-age=31536000, immutable` (1 year, content-hashed filenames)
- Other static files: `max-age=31536000, immutable` (fonts, images, CSS, JS)

**Validation Steps**:
1. Deploy to Firebase Hosting
2. Navigate to `/map` directly (not from home)
3. Refresh page (F5 or Cmd+R)
4. Verify: No 404 error, map screen loads correctly
5. Check Network tab: `index.html` returned with 200 status (not 404)

---

### 6. Rollback Strategies for Production Deployments

**Decision**: Multi-tiered rollback approach (Firebase Console, CLI, git revert)

**Rationale**:
- Firebase Hosting preserves deployment history (last 10 versions)
- Instant rollback via console (no build required)
- CLI rollback for scripted recovery
- Git revert for code-level rollback (rebuilds from previous commit)

**Alternatives Considered**:
1. **Blue-green deployment**: Requires multiple Firebase sites, cost and complexity
2. **Canary deployment**: Not supported by Firebase Hosting (all-or-nothing)
3. **Feature flags**: Runtime configuration, doesn't help with broken builds

**Rollback Options**:

#### Option 1: Firebase Console (Fastest, No CLI)
1. Navigate to: https://console.firebase.google.com/
2. Select project: `wildfire-app-e11f8`
3. Click: Hosting → Release history
4. Find: Previous working version
5. Click: "Rollback to this version"
6. Confirm: Rollback completes in ~30 seconds

**Pros**: Instant, no local tools required  
**Cons**: Manual process, no audit trail in git

#### Option 2: Firebase CLI (Scriptable)
```bash
# List recent deployments
firebase hosting:releases:list --project wildfire-app-e11f8

# Rollback to specific release
firebase hosting:rollback <release-id> --project wildfire-app-e11f8
```

**Pros**: Scriptable, audit trail in shell history  
**Cons**: Requires firebase-tools CLI installed

#### Option 3: Git Revert + Redeploy (Code-Level Rollback)
```bash
# Revert to previous commit
git revert <bad-commit-sha>
git push origin main

# Or checkout previous commit temporarily
git checkout <good-commit-sha>
firebase deploy --only hosting --project wildfire-app-e11f8
git checkout main
```

**Pros**: Full audit trail, rebuilds from source  
**Cons**: Requires CI/CD pipeline or manual build, slower (~5 min)

**Recommended Approach**:
- **Immediate rollback**: Use Firebase Console (Option 1)
- **Planned rollback**: Use git revert + CI/CD (Option 3) for audit trail
- **Scripted rollback**: Use Firebase CLI (Option 2) for automation

---

## Summary of Decisions

| Research Area | Decision | Key Tool/Pattern |
|---------------|----------|------------------|
| PR Preview Channels | Firebase Hosting Channels | `FirebaseExtended/action-hosting-deploy@v0` |
| API Key Injection | Placeholder replacement with sed | `sed -i 's/%MAPS_API_KEY%/...' web/index.html` |
| Job Dependencies | GitHub Actions artifacts + needs | `actions/upload-artifact@v4` + `needs: [test, build]` |
| Production Approval | GitHub Environments | `environment: production` with required reviewers |
| SPA Routing | Firebase rewrites | `{"source": "**", "destination": "/index.html"}` |
| Rollback Strategy | Multi-tiered (Console, CLI, git) | Firebase Console for speed, git for audit trail |

**Next Phase**: Phase 1 - Design contracts, data model, and quickstart procedures based on these research findings.
