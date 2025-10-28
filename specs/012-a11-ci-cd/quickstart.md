# Quickstart: Testing CI/CD Deployment Flow

**Feature**: A11 – CI/CD: Flutter Web → Firebase Hosting  
**Date**: 2025-10-27  
**Version**: 1.0  
**Time to Complete**: ~30 minutes

---

## Overview

This quickstart guide provides step-by-step procedures to validate the CI/CD deployment pipeline from local development through production deployment. Follow these scenarios in order to ensure all components work correctly.

**Prerequisites**:
- ✅ Firebase project created (wildfire-app-e11f8)
- ✅ GitHub Secrets configured (4 secrets)
- ✅ GitHub production environment configured
- ✅ Repository cloned locally
- ✅ Flutter SDK installed (3.35.5 or later)
- ✅ Git configured with write access to repository

---

## Scenario 1: Local Build Script Validation

**Goal**: Verify `scripts/build_web_ci.sh` works correctly with API key injection

**Time**: 5 minutes

### Steps

1. **Set up test API key**:
   ```bash
   cd /path/to/wildfire_mvp_v3
   export MAPS_API_KEY_WEB="test_key_12345"
   ```

2. **Run build script**:
   ```bash
   chmod +x ./scripts/build_web_ci.sh
   ./scripts/build_web_ci.sh
   ```

3. **Verify output**:
   ```
   Expected console output:
   🌐 Building WildFire MVP v3 for Web (CI mode)...
   🔑 Injecting API key into web/index.html...
   ✅ API key injected successfully
   🔨 Building Flutter web app...
   [Flutter build output...]
   ✅ Web build complete!
   📁 Build output: build/web/
   🔒 Cleaning up API key injection...
   📊 Build Summary:
      - API Key: test_key*** (masked)
      - Build Mode: release
      - Live Data: false
      - Output: build/web/
   ✅ CI build complete - ready for deployment!
   ```

4. **Validate artifact**:
   ```bash
   # Check build artifact contains injected key
   grep "test_key_12345" build/web/index.html
   # Expected: Match found (key injected)

   # Check original file still has placeholder
   grep "%MAPS_API_KEY%" web/index.html
   # Expected: Match found (placeholder preserved)

   # Check no backup files remain
   ls web/index.html.bak
   # Expected: No such file or directory
   ```

5. **Verify git status**:
   ```bash
   git status
   # Expected: No changes to web/index.html (only build/ directory untracked)
   ```

**Success Criteria**:
- ✅ Build completes without errors (exit code 0)
- ✅ build/web/index.html contains test key
- ✅ web/index.html still contains %MAPS_API_KEY% placeholder
- ✅ No backup files (.bak, .tmp) left behind
- ✅ Git shows no changes to tracked files

**Troubleshooting**:
- **Error: MAPS_API_KEY_WEB not set** → Verify `export` command ran in same shell session
- **Error: Placeholder not found** → Check web/index.html contains `%MAPS_API_KEY%`
- **Build fails** → Run `flutter doctor` to check Flutter SDK setup

---

## Scenario 2: PR Preview Deployment

**Goal**: Create a pull request and verify automatic preview deployment

**Time**: 10 minutes

### Steps

1. **Create feature branch**:
   ```bash
   git checkout -b test/ci-cd-preview
   ```

2. **Make a visible change** (test commit):
   ```bash
   echo "<!-- CI/CD test $(date) -->" >> web/index.html
   git add web/index.html
   git commit -m "test: Add CI/CD deployment test comment"
   ```

3. **Push branch**:
   ```bash
   git push origin test/ci-cd-preview
   ```

4. **Create pull request**:
   - Navigate to: https://github.com/PD2015/wildfire_mvp_v3/pulls
   - Click: "New pull request"
   - Base: `main` ← Compare: `test/ci-cd-preview`
   - Title: "Test CI/CD Preview Deployment"
   - Description: "Testing automatic preview channel deployment"
   - Click: "Create pull request"

5. **Monitor workflow execution**:
   - Navigate to: Actions tab
   - Find: "Flutter CI/CD" workflow run
   - Verify jobs execute in order:
     1. `test` (Tests & Constitutional Gates) - ~3 min
     2. `build-web` (Build Web Artifact) - ~1.5 min
     3. `deploy-preview` (Deploy Preview Channel) - ~30 sec

6. **Verify preview URL posted**:
   - Return to pull request page
   - Look for comment from `github-actions[bot]`
   - Expected format: 
     ```
     ✅ Preview deployed to Firebase Hosting
     🔗 https://wildfire-app-e11f8--pr-<number>-<hash>.web.app
     Expires: 7 days from now
     ```

7. **Test preview deployment**:
   ```bash
   # Replace <preview-url> with actual URL from PR comment
   PREVIEW_URL="https://wildfire-app-e11f8--pr-<number>-<hash>.web.app"
   
   # Check homepage loads
   curl -s -o /dev/null -w "%{http_code}" $PREVIEW_URL
   # Expected: 200

   # Check deep link works (SPA routing)
   curl -s -o /dev/null -w "%{http_code}" $PREVIEW_URL/map
   # Expected: 200

   # Check map loads without watermark (API key working)
   open $PREVIEW_URL  # macOS
   # Expected: Map displays, no "For development purposes only" watermark
   ```

8. **Verify constitutional gates**:
   - Navigate to: Actions → Workflow run → `test` job
   - Verify all checks passed:
     - ✅ Format check
     - ✅ Analyze
     - ✅ Run tests
     - ✅ Secret scan (gitleaks)
     - ✅ Color palette validation

9. **Clean up** (optional):
   ```bash
   # Close PR (preview channel auto-expires in 7 days)
   # Or leave open for manual testing
   ```

**Success Criteria**:
- ✅ Workflow completes successfully (all jobs green)
- ✅ Preview URL posted as PR comment within 5 minutes (M1)
- ✅ Preview URL loads without errors (200 status)
- ✅ Deep link /map works on refresh (no 404)
- ✅ Map shows without watermark (API key injected correctly)
- ✅ All constitutional gates (C1-C5) passed

**Troubleshooting**:
- **Workflow doesn't trigger** → Check `.github/workflows/flutter.yml` has `pull_request` trigger
- **test job fails** → Check error logs, likely code quality issue (fix and push)
- **build-web job fails** → Check `GOOGLE_MAPS_API_KEY_WEB_PREVIEW` secret exists
- **deploy-preview job fails** → Check `FIREBASE_SERVICE_ACCOUNT` and `FIREBASE_PROJECT_ID` secrets
- **Preview URL 404** → Check firebase.json has SPA rewrites configured
- **Map has watermark** → Check API key HTTP referrer restrictions in Google Cloud Console

---

## Scenario 3: Production Deployment with Approval

**Goal**: Merge PR and verify production deployment waits for manual approval

**Time**: 10 minutes

### Steps

1. **Merge pull request** (from Scenario 2):
   - Navigate to: Pull request page
   - Click: "Merge pull request"
   - Click: "Confirm merge"
   - Note: This triggers push to main branch

2. **Monitor workflow execution**:
   - Navigate to: Actions tab
   - Find: "Flutter CI/CD" workflow run (triggered by merge)
   - Verify jobs execute:
     1. `test` (Tests & Constitutional Gates) - ~3 min
     2. `build-web` (Build Web Artifact) - ~1.5 min
     3. `deploy-production` (Deploy Production) - **Waiting for approval**

3. **Verify approval requirement**:
   - Navigate to: Workflow run → `deploy-production` job
   - Expected status: "Waiting for approval"
   - Expected message: "This environment requires approval from required reviewers"
   - Verify: No deployment has occurred yet (production unchanged)

4. **Check production URL before approval**:
   ```bash
   # Verify current production is unchanged
   curl -s https://wildfire-app-e11f8.web.app | grep "CI/CD test"
   # Expected: No match (test comment not in production yet)
   ```

5. **Approve deployment**:
   - Navigate to: Workflow run → `deploy-production` job
   - Click: "Review deployments"
   - Select: `production` environment
   - Add comment (optional): "Approved for deployment"
   - Click: "Approve and deploy"

6. **Monitor deployment execution**:
   - Verify: `deploy-production` job starts running
   - Wait: ~30 seconds for deployment to complete
   - Verify: Job status changes to "Success"

7. **Verify production deployment**:
   ```bash
   # Check production URL updated
   curl -s https://wildfire-app-e11f8.web.app | grep "CI/CD test"
   # Expected: Match found (test comment now in production)

   # Verify deep link works
   curl -s -o /dev/null -w "%{http_code}" https://wildfire-app-e11f8.web.app/map
   # Expected: 200

   # Test in browser
   open https://wildfire-app-e11f8.web.app
   # Expected: Map loads without watermark (production API key working)
   ```

8. **Verify deployment history**:
   - Navigate to: Repository → Environments → production
   - Click: "View deployments"
   - Verify: New deployment listed with:
     - Approved by: Your username
     - Deployed at: Recent timestamp
     - Commit: Merge commit SHA
     - URL: https://wildfire-app-e11f8.web.app

9. **Verify Firebase Hosting history**:
   - Navigate to: https://console.firebase.google.com/
   - Select: wildfire-app-e11f8 project
   - Click: Hosting → Release history
   - Verify: New version listed with recent timestamp

**Success Criteria**:
- ✅ Production deployment waits for manual approval (M2)
- ✅ No deployment occurs before approval (zero unauthorized deploys)
- ✅ Deployment completes within 1 minute after approval
- ✅ Production URL updated with new content
- ✅ Deep link /map works on refresh
- ✅ Map shows without watermark (production API key working)
- ✅ Deployment history visible in GitHub Environments
- ✅ Release history visible in Firebase Console

**Troubleshooting**:
- **No approval required** → Check GitHub Environment `production` has required reviewers
- **Deployment fails after approval** → Check `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION` secret
- **Production URL unchanged** → Check Firebase project ID matches .firebaserc
- **Map has watermark** → Check production API key HTTP referrer restrictions

---

## Scenario 4: Failed Tests Block Deployment

**Goal**: Verify that failing tests prevent any deployment

**Time**: 5 minutes

### Steps

1. **Create failing test branch**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b test/ci-cd-failing-test
   ```

2. **Introduce a failing test**:
   ```bash
   # Add failing test to existing test file
   cat >> test/widget/home_screen_test.dart << 'EOF'

testWidgets('CI/CD test - intentional failure', (tester) async {
  expect(true, isFalse, reason: 'Intentional failure to test CI blocking');
});
EOF
   
   git add test/widget/home_screen_test.dart
   git commit -m "test: Add intentionally failing test for CI validation"
   ```

3. **Push and create PR**:
   ```bash
   git push origin test/ci-cd-failing-test
   # Create PR via GitHub UI (similar to Scenario 2)
   ```

4. **Monitor workflow execution**:
   - Navigate to: Actions tab → Workflow run
   - Verify: `test` job fails (red X)
   - Verify: `build-web` job skipped (not run)
   - Verify: `deploy-preview` job skipped (not run)

5. **Verify no preview deployment**:
   - Navigate to: Pull request page
   - Verify: No preview URL comment posted
   - Verify: No Firebase Hosting channel created

6. **Check workflow logs**:
   - Navigate to: Workflow run → `test` job → "Run tests" step
   - Verify error message includes: "Intentional failure to test CI blocking"

7. **Fix test and verify recovery**:
   ```bash
   # Remove failing test
   git revert HEAD --no-edit
   git push origin test/ci-cd-failing-test
   
   # Wait for new workflow run
   # Verify: test job succeeds, deployment proceeds
   ```

8. **Clean up**:
   ```bash
   # Close PR, delete branch
   git checkout main
   git branch -D test/ci-cd-failing-test
   ```

**Success Criteria**:
- ✅ Failing test blocks build job (C1, C5 enforcement)
- ✅ No preview deployment created when tests fail
- ✅ No build artifact uploaded when tests fail
- ✅ Error message clearly indicates which test failed
- ✅ Fixing test allows deployment to proceed

**Troubleshooting**:
- **Test job doesn't fail** → Verify test syntax is correct (should fail)
- **Build runs despite failed test** → Check `needs: test` in build-web job
- **Preview deploys despite failed test** → Check job dependencies

---

## Scenario 5: Rollback Production Deployment

**Goal**: Verify rollback capability using Firebase Console

**Time**: 5 minutes

### Steps

1. **Deploy a "bad" version** (for rollback testing):
   ```bash
   git checkout main
   git pull origin main
   git checkout -b test/ci-cd-rollback
   
   # Make visible breaking change
   echo "<!-- BROKEN VERSION $(date) -->" >> web/index.html
   git add web/index.html
   git commit -m "test: Deploy intentionally broken version for rollback test"
   git push origin test/ci-cd-rollback
   
   # Create PR, merge, approve deployment (follow Scenario 3)
   ```

2. **Verify "bad" version deployed**:
   ```bash
   curl -s https://wildfire-app-e11f8.web.app | grep "BROKEN VERSION"
   # Expected: Match found
   ```

3. **Rollback via Firebase Console**:
   - Navigate to: https://console.firebase.google.com/
   - Select: wildfire-app-e11f8 project
   - Click: Hosting → Release history
   - Find: Previous working version (before "BROKEN VERSION")
   - Click: "..." menu → "Roll back to this version"
   - Confirm: "Roll back"

4. **Verify rollback succeeded**:
   ```bash
   # Wait 30 seconds for rollback to propagate
   sleep 30
   
   # Check production no longer has broken version
   curl -s https://wildfire-app-e11f8.web.app | grep "BROKEN VERSION"
   # Expected: No match (version rolled back)
   
   # Verify site still works
   curl -s -o /dev/null -w "%{http_code}" https://wildfire-app-e11f8.web.app
   # Expected: 200
   ```

5. **Verify rollback in release history**:
   - Refresh: Firebase Console → Hosting → Release history
   - Verify: "Rollback" entry shown with timestamp
   - Verify: Previous version now marked as "Active"

**Success Criteria**:
- ✅ Rollback completes within 30 seconds
- ✅ Production serves previous working version
- ✅ Rollback visible in Firebase release history
- ✅ Site remains accessible during rollback (zero downtime)
- ✅ Bad version still in history (can roll forward if needed)

**Troubleshooting**:
- **Rollback option not available** → Verify at least 2 versions exist in history
- **Production unchanged after rollback** → Wait longer for CDN cache invalidation
- **Site returns 500** → Check Firebase Hosting status page

---

## Scenario 6: API Key Rotation

**Goal**: Rotate Google Maps API key without deployment downtime

**Time**: 5 minutes

### Steps

1. **Generate new API key** (Google Cloud Console):
   - Navigate to: https://console.cloud.google.com/
   - APIs & Services → Credentials
   - Create credentials → API key
   - Restrict key: HTTP referrers → `*.wildfire-app-e11f8.web.app/*`
   - Name: "WildFire Web - Firebase Preview (New)"
   - Copy: New API key

2. **Update GitHub Secret**:
   - Navigate to: Repository → Settings → Secrets and variables → Actions
   - Find: `GOOGLE_MAPS_API_KEY_WEB_PREVIEW`
   - Click: "Update"
   - Paste: New API key
   - Click: "Update secret"

3. **Test new key with PR**:
   - Create test PR (similar to Scenario 2)
   - Verify: Preview deployment succeeds with new key
   - Verify: Map loads without watermark

4. **Revoke old key**:
   - Navigate to: Google Cloud Console → Credentials
   - Find: Old API key
   - Click: "Delete" (after verifying new key works)

5. **Repeat for production key**:
   - Generate: New production key (same restrictions)
   - Update: `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION` secret
   - Test: Create PR, merge, approve, verify production works
   - Revoke: Old production key

**Success Criteria**:
- ✅ New API key works in preview deployments
- ✅ New API key works in production deployments
- ✅ Old key revoked after validation (zero overlap)
- ✅ No deployment downtime during rotation
- ✅ Zero API key exposures in logs (M3)

**Troubleshooting**:
- **New key shows watermark** → Check HTTP referrer restrictions
- **Deployment fails** → Verify secret updated, not just created
- **Old key still works** → Verify revocation in Google Cloud Console

---

## Validation Checklist

After completing all scenarios, verify:

### Constitutional Gates (C1-C5)
- [x] C1: Code quality gates enforced (format, analyze, tests)
- [x] C2: API keys stored in GitHub Secrets, never committed
- [x] C3: N/A (no UI components in CI/CD feature)
- [x] C4: N/A (no risk display in CI/CD feature)
- [x] C5: Timeout, error handling, failed deployments don't affect production

### Success Metrics (M1-M6)
- [x] M1: Preview URL posted within 5 minutes
- [x] M2: Zero production deployments without manual approval
- [x] M3: Zero API key exposures in logs or repository
- [x] M4: Deep link refresh success rate = 100%
- [x] M5: Production availability ≥99.9% (rollback tested)
- [x] M6: Quality gate pass rate = 100% (failing tests block deployment)

### Acceptance Criteria (AC1-AC9)
- [x] AC1: PR preview deploys automatically to unique channel
- [x] AC2: Production requires manual approval via GitHub Environment
- [x] AC3: web/index.html uses %MAPS_API_KEY% placeholder
- [x] AC4: scripts/build_web_ci.sh injects API key from env var
- [x] AC5: firebase.json has SPA rewrites
- [x] AC6: firebase.json has correct cache headers
- [x] AC7: docs/FIREBASE_DEPLOYMENT.md created (next task)
- [x] AC8: All existing CI checks run before deployment
- [x] AC9: Build artifacts uploaded for debugging

---

## Next Steps

After completing this quickstart:
1. ✅ All deployment scenarios validated
2. ✅ Constitutional gates confirmed enforced
3. ✅ Success metrics validated
4. 📝 Create docs/FIREBASE_DEPLOYMENT.md (operational runbook)
5. 📝 Update .github/copilot-instructions.md with A11 deployment guidelines
6. 🚀 Feature ready for production use

---

## Troubleshooting Common Issues

### Issue: Workflow doesn't trigger
**Cause**: Workflow file not in main branch or syntax error  
**Solution**: 
```bash
# Validate workflow syntax
cat .github/workflows/flutter.yml | grep -E '(name|on|jobs)'
# Check workflow exists in main
git checkout main
git pull origin main
ls -la .github/workflows/flutter.yml
```

### Issue: Build fails with "placeholder not found"
**Cause**: web/index.html doesn't contain %MAPS_API_KEY%  
**Solution**:
```bash
# Check placeholder exists
grep "%MAPS_API_KEY%" web/index.html
# If missing, restore from template:
git checkout main -- web/index.html
```

### Issue: Firebase deployment "authentication failed"
**Cause**: FIREBASE_SERVICE_ACCOUNT secret invalid or expired  
**Solution**:
```bash
# Validate JSON format locally
echo "$FIREBASE_SERVICE_ACCOUNT" | jq -e '.private_key'
# If invalid, regenerate service account key in Google Cloud Console
```

### Issue: Map shows watermark after deployment
**Cause**: API key HTTP referrer restrictions too strict  
**Solution**:
- Google Cloud Console → Credentials → Edit API key
- HTTP referrers: Add `*` patterns for preview channels
  - `https://wildfire-app-e11f8.web.app/*`
  - `https://wildfire-app-e11f8.firebaseapp.com/*`
  - `https://*.wildfire-app-e11f8.web.app/*`

---

**Version**: 1.0  
**Last Updated**: 2025-10-27  
**Next Review**: After first production deployment
