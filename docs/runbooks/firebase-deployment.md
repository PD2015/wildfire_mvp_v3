# Firebase Deployment Runbook

## Overview
This document provides operational procedures for deploying the WildFire MVP Flutter web application to Firebase Hosting via CI/CD pipeline.

**Firebase Project**: wildfire-app-e11f8  
**Production URL**: https://wildfire-app-e11f8.web.app  
**Preview URL Pattern**: https://wildfire-app-e11f8--pr-{number}-{hash}.web.app

---

## Deployment Procedures

### PR Preview Deployment (Automatic)

Preview deployments are triggered automatically when you create or update a pull request.

**Steps**:
1. Create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```

2. Make changes and push:
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/my-feature
   ```

3. Create pull request via GitHub UI:
   - Base: `main`
   - Compare: `feature/my-feature`

4. Wait for workflow execution (~5 minutes):
   - ✅ `build` job: Runs format, analyze, tests (3 min)
   - ✅ `build-web` job: Builds Flutter web with API key injection (1.5 min)
   - ✅ `deploy-preview` job: Deploys to preview channel (30 sec)

5. Check PR comment for preview URL (posted by github-actions bot):
   ```
   ✅ Preview deployed to: https://wildfire-app-e11f8--pr-42-abc123.web.app
   Expires: 7 days from now
   ```

6. Test preview deployment:
   - Verify map loads without watermark
   - Test deep links (e.g., /map)
   - Check mobile responsiveness

**Preview Characteristics**:
- Auto-expires after 7 days
- Uses `GOOGLE_MAPS_API_KEY_WEB_PREVIEW` secret
- No manual approval required
- Updates automatically on new commits to PR

---

### Production Deployment (Manual Approval)

Production deployments require manual approval via GitHub Environments.

**Steps**:
1. Merge pull request to `main`:
   ```bash
   # Via GitHub UI: Click "Merge pull request" → "Confirm merge"
   # Or via CLI:
   gh pr merge 42 --merge
   ```

2. Workflow starts automatically on merge to `main`:
   - ✅ `build` job: Runs constitutional gates (3 min)
   - ✅ `build-web` job: Builds production artifact (1.5 min)
   - ⏳ `deploy-production` job: **Waiting for approval**

3. Navigate to GitHub Actions:
   - Repository → Actions tab
   - Click on the running workflow
   - Scroll to `deploy-production` job
   - Status: "This environment requires approval from required reviewers"

4. Approve deployment:
   - Click: "Review deployments"
   - Select: `production` environment
   - Click: "Approve and deploy"
   - Optional: Add comment explaining approval reason

5. Monitor deployment execution (~30 seconds):
   - Workflow downloads build artifact
   - FirebaseExtended action deploys to `live` channel

6. Verify production updated:
   ```bash
   curl -I https://wildfire-app-e11f8.web.app
   # Check Last-Modified header for recent timestamp
   
   # Test map loads
   open https://wildfire-app-e11f8.web.app
   ```

7. Check deployment history:
   - Repository → Environments → production → "View deployments"
   - Verify: New deployment with approval metadata

**Production Characteristics**:
- Requires manual approval (GitHub Environment protection rule)
- Uses `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION` secret
- Only triggers on push to `main` branch
- Permanent deployment (no expiry)

---

## Rollback Procedures

### Option 1: Firebase Console (Fastest - 30 seconds)

Use Firebase Console for immediate rollback during incidents.

**Steps**:
1. Navigate to Firebase Console:
   ```
   https://console.firebase.google.com/
   ```

2. Select project: `wildfire-app-e11f8`

3. Go to: Hosting → Release history

4. Find previous working version:
   - Look for green checkmark (successful deployment)
   - Check deployment timestamp
   - Review commit message

5. Click "..." menu → "Roll back to this version"

6. Confirm rollback

7. Wait ~30 seconds for rollback to complete

8. Verify production:
   ```bash
   curl -I https://wildfire-app-e11f8.web.app
   # Check Last-Modified header changed
   ```

**When to use**: Emergency situations, production incidents

---

### Option 2: Firebase CLI (Scriptable)

Use Firebase CLI for programmatic rollback or scripting.

**Steps**:
1. List recent releases:
   ```bash
   firebase hosting:releases:list --project wildfire-app-e11f8
   ```

2. Identify target release:
   - Find `releaseId` of working version
   - Note version number

3. Rollback to specific release:
   ```bash
   firebase hosting:rollback <release-id> --project wildfire-app-e11f8
   ```

4. Confirm rollback when prompted

5. Verify rollback:
   ```bash
   firebase hosting:releases:list --project wildfire-app-e11f8 | head -5
   ```

**When to use**: Scripted rollback, automation, batch operations

---

### Option 3: Git Revert + Redeploy (Audit Trail)

Use git revert for rollback with full audit trail in repository history.

**Steps**:
1. Identify bad commit:
   ```bash
   git log --oneline -10
   # Find commit SHA of problematic deployment
   ```

2. Revert the commit:
   ```bash
   git revert <bad-commit-sha>
   # This creates a new commit that undoes the changes
   ```

3. Push revert commit:
   ```bash
   git push origin main
   ```

4. Approve production deployment:
   - GitHub Actions workflow runs automatically
   - Navigate to Actions tab
   - Approve `deploy-production` job

5. Wait for deployment (~2 minutes total)

6. Verify production updated:
   ```bash
   git log --oneline -3
   # Should show: Revert "bad commit message"
   ```

**When to use**: Non-urgent rollback, need audit trail, code-based revert

---

## Troubleshooting

### Issue: Preview URL 404 Not Found

**Symptoms**:
- Preview URL deployed successfully
- Clicking URL returns 404
- Deep links (e.g., /map) fail with 404

**Cause**: SPA routing not configured in firebase.json

**Solution**:
1. Verify `firebase.json` has rewrites configuration:
   ```json
   {
     "hosting": {
       "public": "build/web",
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ]
     }
   }
   ```

2. If missing, add rewrites and redeploy

---

### Issue: Map Shows "For development purposes only" Watermark

**Symptoms**:
- Map loads but shows watermark overlay
- Console error: "This page can't load Google Maps correctly"

**Cause**: API key HTTP referrer restrictions too strict

**Solution**:
1. Go to Google Cloud Console:
   ```
   https://console.cloud.google.com/apis/credentials
   ```

2. Click on API key (GOOGLE_MAPS_API_KEY_WEB_PREVIEW or _PRODUCTION)

3. Under "Application restrictions":
   - Select: HTTP referrers
   - Add: `*.wildfire-app-e11f8.web.app/*`
   - Add: `wildfire-app-e11f8.web.app/*`

4. Click "Save"

5. Wait 5 minutes for propagation

6. Test preview/production URL

---

### Issue: Deployment "Authentication Failed"

**Symptoms**:
- `deploy-preview` or `deploy-production` job fails
- Error: "Authentication failed" or "Invalid service account"

**Cause**: `FIREBASE_SERVICE_ACCOUNT` secret invalid or expired

**Solution**:
1. Generate new service account key:
   - Google Cloud Console → IAM & Admin → Service Accounts
   - Select: firebase-adminsdk service account
   - Keys tab → Add Key → Create new key → JSON
   - Download JSON file

2. Update GitHub Secret:
   - Repository → Settings → Secrets → Actions
   - Find: `FIREBASE_SERVICE_ACCOUNT`
   - Click "Update"
   - Paste entire JSON content
   - Click "Update secret"

3. Re-run failed workflow

---

### Issue: Build Job Fails "Placeholder Not Found"

**Symptoms**:
- `build-web` job fails during API key injection
- Error: "Placeholder %MAPS_API_KEY% not found in web/index.html"

**Cause**: web/index.html doesn't contain placeholder pattern

**Solution**:
1. Verify placeholder exists:
   ```bash
   grep "%MAPS_API_KEY%" web/index.html
   ```

2. If missing, restore placeholder:
   ```bash
   # Find Google Maps script tag
   sed -i 's|<script src="https://maps.googleapis.com/maps/api/js[^"]*">|<script src="https://maps.googleapis.com/maps/api/js%MAPS_API_KEY%">|g' web/index.html
   ```

3. Commit and push fix:
   ```bash
   git add web/index.html
   git commit -m "fix: restore Google Maps API key placeholder"
   git push
   ```

---

### Issue: Tests Pass Locally But Fail in CI

**Symptoms**:
- `flutter test` passes locally
- `build` job fails in GitHub Actions
- Tests timeout or fail with different errors

**Cause**: Platform differences, missing dependencies, timing issues

**Solution**:
1. Check CI logs for specific error:
   ```bash
   # Look for actual failure message in Actions logs
   ```

2. Run tests with same configuration as CI:
   ```bash
   flutter test --platform=chrome --reporter expanded
   ```

3. Common fixes:
   - Add test timeouts: `testWidgets(..., timeout: Timeout(Duration(seconds: 60)))`
   - Mock external dependencies
   - Use `await tester.pumpAndSettle()` for animations

---

## API Key Rotation

### Rotating Preview API Key

Use when preview API key is compromised or needs refresh.

**Steps**:
1. Generate new API key:
   - Google Cloud Console → APIs & Services → Credentials
   - Click: "Create credentials" → "API key"
   - Name: "WildFire Web - Firebase Preview (New)"

2. Restrict new key:
   - Application restrictions: HTTP referrers
   - Website restrictions:
     - `*.wildfire-app-e11f8.web.app/*`
     - `wildfire-app-e11f8.web.app/*`
   - API restrictions: Maps JavaScript API
   - Click "Save"

3. Update GitHub Secret:
   - Repository → Settings → Secrets → Actions
   - Find: `GOOGLE_MAPS_API_KEY_WEB_PREVIEW`
   - Click "Update"
   - Paste new API key
   - Click "Update secret"

4. Test with PR:
   - Create test PR or trigger re-run on existing PR
   - Verify preview deployment succeeds
   - Verify map loads without watermark

5. Revoke old key:
   - Google Cloud Console → Credentials
   - Find old key → Delete
   - Confirm deletion

---

### Rotating Production API Key

Use when production API key is compromised or needs refresh.

**Steps**:
1. Generate new API key (same as preview steps above)

2. Name: "WildFire Web - Firebase Production (New)"

3. Same restrictions as preview

4. Update GitHub Secret:
   - Repository → Settings → Secrets → Actions
   - Find: `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION`
   - Click "Update"
   - Paste new API key

5. Test with production deployment:
   - Merge a test PR to main
   - Approve production deployment
   - Verify map loads

6. Revoke old key after successful deployment

**Rotation Schedule**: Every 90 days (recommended)

---

## Monitoring

### Deployment Status

**GitHub Actions**:
- Repository → Actions tab
- Filter by workflow: "Flutter CI"
- Check status: ✅ Success, ❌ Failed, ⏳ In Progress

**Firebase Console**:
- https://console.firebase.google.com/
- Project: wildfire-app-e11f8
- Hosting → Release history
- Shows: Deployment time, version, status

**GitHub Environments**:
- Repository → Environments → production
- Shows: Deployment history, approval records, timestamps

---

### Performance Metrics

Track success metrics from specs/012-a11-ci-cd/spec.md:

**M1: Preview URL <5 minutes**
- Measure: GitHub Actions workflow duration
- Target: <5 minutes from PR open to preview URL
- Monitor: Actions timing breakdown

**M2: Zero unauthorized production deploys**
- Measure: GitHub Environment deployment history
- Target: 100% of production deploys have approval record
- Monitor: Environments → production → "View deployments"

**M3: Zero API key exposures**
- Measure: GitHub Actions logs search
- Target: No full API keys in logs (only masked)
- Monitor: Search logs for "AIza" pattern

**M4: Deep link success 100%**
- Measure: Manual testing of preview/production URLs
- Target: All routes load correctly (/, /map, etc.)
- Test: `curl -I https://wildfire-app-e11f8.web.app/map` returns 200

**M5: Production availability ≥99.9%**
- Measure: Firebase Hosting uptime
- Target: ≥99.9% uptime (8.76 hours downtime/year max)
- Monitor: Firebase status page

**M6: Quality gate pass rate 100%**
- Measure: `build` job success rate
- Target: 100% pass rate (C1-C5 gates)
- Monitor: Actions workflow success rate

---

### Health Checks

**Daily**:
- Check production URL loads: `curl -I https://wildfire-app-e11f8.web.app`
- Verify map displays correctly
- Review failed workflow runs in Actions

**Weekly**:
- Review deployment history (Firebase Console)
- Check API key quota usage (Google Cloud Console)
- Verify no expired preview channels (auto-cleanup)

**Monthly**:
- Review success metrics (M1-M6)
- Audit GitHub Secrets (expiry, rotation)
- Test rollback procedures (in staging/preview)

---

## Emergency Contacts

**Firebase Support**:
- https://firebase.google.com/support
- Priority support: Firebase Console → Support tab

**GitHub Actions Status**:
- https://www.githubstatus.com/
- Subscribe: GitHub Status API

**Google Maps API Status**:
- https://status.cloud.google.com/
- Filter: Maps Platform

**Team Contacts**:
- Repository: https://github.com/PD2015/wildfire_mvp_v3
- Issues: https://github.com/PD2015/wildfire_mvp_v3/issues
- CI/CD Spec: specs/012-a11-ci-cd/

---

## Reference Documents

- **Feature Specification**: specs/012-a11-ci-cd/spec.md
- **Implementation Plan**: specs/012-a11-ci-cd/plan.md
- **Task Breakdown**: specs/012-a11-ci-cd/tasks.md
- **Build Script Contract**: specs/012-a11-ci-cd/contracts/build-script-contract.sh
- **Workflow Contract**: specs/012-a11-ci-cd/contracts/workflow-schema.yml
- **Quickstart Guide**: specs/012-a11-ci-cd/quickstart.md

---

*Last Updated: 2025-10-28*  
*Document Version: 1.0.0*  
*Feature: A11 CI/CD - Flutter Web → Firebase Hosting*
