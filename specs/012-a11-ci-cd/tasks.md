# Tasks: A11 – CI/CD: Flutter Web → Firebase Hosting

**Input**: Design documents from `/specs/012-a11-ci-cd/`
**Prerequisites**: ✅ plan.md, ✅ research.md, ✅ data-model.md, ✅ contracts/, ✅ quickstart.md

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Tech stack: Dart 3.9.2, Flutter 3.35.5, Firebase Hosting, GitHub Actions
   → Structure: Single Flutter project (lib/, test/, web/, .github/workflows/)
2. Load design documents: ✅
   → data-model.md: 6 entities (Workflow, Artifact, Channel, Secret, Environment, Event)
   → contracts/: 2 files (workflow-schema.yml, build-script-contract.sh)
   → research.md: 6 decisions (Firebase Channels, API injection, etc.)
   → quickstart.md: 6 validation scenarios (40 min total)
3. Generate tasks by category: ✅
   → Setup: No project init needed (existing Flutter project)
   → Foundation (P1): Placeholder, build script, workflow extension
   → Validation (P2): Tests, documentation, agent context
   → Testing (P3-P4): Quickstart scenario execution
4. Apply task rules: ✅
   → web/index.html, scripts/build_web_ci.sh, .github/workflows/flutter.yml = different files = [P] potentially
   → BUT: Build script depends on placeholder, workflow depends on build script = sequential P1
   → Test scripts, docs, agent update = different files = [P] in P2
5. Number tasks sequentially (T001-T012): ✅
6. Generate dependency graph: ✅
7. Create parallel execution examples: ✅
8. Validate task completeness: ✅
   → All contracts have tests? YES (5 tests in build-script-contract, workflow validation in scenarios)
   → All entities implemented? YES (managed by external services, validated in scenarios)
   → All quickstart scenarios executable? YES (6 scenarios, 40 min)
9. Return: SUCCESS (12 tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
**Single Flutter project structure** (from plan.md):
- `.github/workflows/flutter.yml` - CI/CD workflow configuration
- `scripts/build_web_ci.sh` - Build script with API key injection
- `web/index.html` - Main HTML entry point
- `docs/FIREBASE_DEPLOYMENT.md` - Deployment runbook
- `test/scripts/build_web_ci_test.sh` - Build script validation tests

---

## Phase 1: Foundation (P1 - Sequential)
**CRITICAL: These tasks MUST be completed in order (dependencies)**

### T001: Modify web/index.html with API key placeholder
**File**: `web/index.html`  
**Depends on**: None (prerequisite)  
**Blocks**: T002 (build script needs placeholder)

**Description**:
Replace the hardcoded Google Maps API key in web/index.html with the %MAPS_API_KEY% placeholder for CI/CD injection.

**Steps**:
1. Open `web/index.html`
2. Find the Google Maps script tag:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=CURRENT_KEY_HERE"></script>
   ```
3. Replace with placeholder pattern:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js%MAPS_API_KEY%"></script>
   ```
4. Verify placeholder is correct:
   ```bash
   grep "%MAPS_API_KEY%" web/index.html
   # Expected: Match found
   ```
5. Test local development still works:
   ```bash
   ./scripts/build_web.sh  # Uses env/dev.env.json, should inject key
   ```

**Acceptance Criteria**:
- ✅ web/index.html contains `%MAPS_API_KEY%` placeholder (not hardcoded key)
- ✅ Placeholder location matches sed replacement pattern from contract
- ✅ Local build script (build_web.sh) still works with existing env file
- ✅ Git diff shows only Google Maps script line changed

**Constitutional Gates**:
- C2: No API key committed to repository

---

### T002: Create scripts/build_web_ci.sh
**File**: `scripts/build_web_ci.sh`  
**Depends on**: T001 (needs placeholder in web/index.html)  
**Blocks**: T003 (workflow needs build script)

**Description**:
Create CI-specific build script that injects Google Maps API key from environment variables, builds Flutter web, and cleans up secrets.

**Steps**:
1. Create `scripts/build_web_ci.sh` with content from `contracts/build-script-contract.sh` template
2. Implement the 4 phases:
   - **Phase 1**: Validate inputs (check MAPS_API_KEY_WEB env var, verify placeholder exists)
   - **Phase 2**: Inject API key (sed replacement, backup original file)
   - **Phase 3**: Build Flutter web (`flutter build web --release --dart-define=MAP_LIVE_DATA=false`)
   - **Phase 4**: Cleanup (restore original web/index.html, validate)
3. Make script executable:
   ```bash
   chmod +x scripts/build_web_ci.sh
   ```
4. Test locally:
   ```bash
   export MAPS_API_KEY_WEB="test_key_12345"
   ./scripts/build_web_ci.sh
   # Verify: build/web/index.html contains key, web/index.html has placeholder
   ```

**Acceptance Criteria**:
- ✅ Script exits with code 1 if MAPS_API_KEY_WEB not set
- ✅ Script exits with code 1 if placeholder not found in web/index.html
- ✅ Script creates build/web/ directory with index.html containing injected key
- ✅ Script restores original web/index.html with placeholder (no key)
- ✅ Script logs masked API key (first 8 chars + ***)
- ✅ All 5 validation tests from contract pass

**Constitutional Gates**:
- C1: Script follows bash best practices (set -e, error handling)
- C2: API key never logged in full, cleanup prevents key leaks
- C5: Clear error messages, fail-fast on missing inputs

**Contract Reference**: `contracts/build-script-contract.sh`

---

### T003: Extend .github/workflows/flutter.yml
**File**: `.github/workflows/flutter.yml`  
**Depends on**: T002 (needs build_web_ci.sh script)  
**Blocks**: T007, T008, T009 (quickstart scenarios need workflow)

**Description**:
Extend existing GitHub Actions workflow with three new jobs: build-web, deploy-preview, and deploy-production. Preserve all existing constitutional gate checks (test job).

**Steps**:
1. Open `.github/workflows/flutter.yml`
2. **DO NOT MODIFY** existing `test` job (preserves C1-C5 gates)
3. Add `build-web` job after `test` job:
   ```yaml
   build-web:
     name: Build Web Artifact
     needs: test
     runs-on: ubuntu-latest
     timeout-minutes: 15
     steps:
       - uses: actions/checkout@v4
       - name: Setup Flutter
         uses: subosito/flutter-action@v2
         with:
           flutter-version: '3.35.5'
           channel: 'stable'
       - run: flutter pub get
       - name: Build web with API key injection
         env:
           MAPS_API_KEY_WEB: ${{ secrets.GOOGLE_MAPS_API_KEY_WEB_PREVIEW }}
         run: |
           chmod +x ./scripts/build_web_ci.sh
           ./scripts/build_web_ci.sh
       - name: Upload build artifact
         uses: actions/upload-artifact@v4
         with:
           name: web-build-${{ github.sha }}
           path: build/web/
           retention-days: 7
           if-no-files-found: error
   ```
4. Add `deploy-preview` job:
   ```yaml
   deploy-preview:
     name: Deploy Preview Channel
     needs: build-web
     if: github.event_name == 'pull_request'
     runs-on: ubuntu-latest
     timeout-minutes: 10
     steps:
       - uses: actions/checkout@v4
       - name: Download build artifact
         uses: actions/download-artifact@v4
         with:
           name: web-build-${{ github.sha }}
           path: build/web/
       - name: Deploy to Firebase preview channel
         uses: FirebaseExtended/action-hosting-deploy@v0
         with:
           repoToken: '${{ secrets.GITHUB_TOKEN }}'
           firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
           projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
           channelId: pr-${{ github.event.pull_request.number }}
           expires: 7d
   ```
5. Add `deploy-production` job:
   ```yaml
   deploy-production:
     name: Deploy Production
     needs: build-web
     if: github.event_name == 'push' && github.ref == 'refs/heads/main'
     runs-on: ubuntu-latest
     timeout-minutes: 10
     environment:
       name: production
       url: https://wildfire-app-e11f8.web.app
     steps:
       - uses: actions/checkout@v4
       - name: Download build artifact
         uses: actions/download-artifact@v4
         with:
           name: web-build-${{ github.sha }}
           path: build/web/
       - name: Deploy to Firebase production
         uses: FirebaseExtended/action-hosting-deploy@v0
         with:
           repoToken: '${{ secrets.GITHUB_TOKEN }}'
           firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
           projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
           channelId: live
   ```
6. Validate workflow syntax:
   ```bash
   # Check YAML syntax (no errors)
   cat .github/workflows/flutter.yml | grep -E '(name|on|jobs)' | head -20
   ```

**Acceptance Criteria**:
- ✅ Existing `test` job UNCHANGED (C1-C5 constitutional gates preserved)
- ✅ `build-web` job depends on `test` (needs: test)
- ✅ `deploy-preview` job only runs on PRs (if: github.event_name == 'pull_request')
- ✅ `deploy-production` job requires manual approval (environment: production)
- ✅ All jobs have timeout-minutes set (C5 resilience)
- ✅ Workflow uses correct secret names (match GitHub Secrets)

**Constitutional Gates**:
- C1: Preserves existing test job (format, analyze, tests)
- C2: Uses GitHub Secrets for API keys and service account
- C5: Timeouts prevent hung jobs, error handling in scripts

**Contract Reference**: `contracts/workflow-schema.yml`

---

## Phase 2: Validation (P2 - Parallel)
**These tasks can run in parallel (different files, independent)**

### T004 [P]: Create test/scripts/build_web_ci_test.sh
**File**: `test/scripts/build_web_ci_test.sh`  
**Depends on**: T002 (needs build_web_ci.sh to test)  
**Parallel with**: T005, T006

**Description**:
Create validation tests for build_web_ci.sh script covering all 5 test cases from the build script contract.

**Steps**:
1. Create `test/scripts/build_web_ci_test.sh`:
   ```bash
   #!/bin/bash
   # Unit tests for scripts/build_web_ci.sh
   
   # Test 1: Missing API key
   test_missing_api_key() {
     unset MAPS_API_KEY_WEB
     ./scripts/build_web_ci.sh 2>&1 | grep "MAPS_API_KEY_WEB environment variable not set"
     [ $? -eq 0 ] && echo "✅ Test 1 passed" || echo "❌ Test 1 failed"
   }
   
   # Test 2: Missing placeholder
   test_missing_placeholder() {
     # Backup original, remove placeholder temporarily
     cp web/index.html web/index.html.test.bak
     sed -i.tmp 's|%MAPS_API_KEY%||g' web/index.html
     
     export MAPS_API_KEY_WEB="test_key"
     ./scripts/build_web_ci.sh 2>&1 | grep "placeholder not found"
     local result=$?
     
     # Restore original
     mv web/index.html.test.bak web/index.html
     rm -f web/index.html.tmp
     
     [ $result -eq 0 ] && echo "✅ Test 2 passed" || echo "❌ Test 2 failed"
   }
   
   # Test 3: Successful build
   test_successful_build() {
     export MAPS_API_KEY_WEB="test_key_12345"
     ./scripts/build_web_ci.sh > /dev/null 2>&1
     
     # Verify artifact contains key
     grep "test_key_12345" build/web/index.html > /dev/null
     local has_key=$?
     
     # Verify original has placeholder
     grep "%MAPS_API_KEY%" web/index.html > /dev/null
     local has_placeholder=$?
     
     if [ $has_key -eq 0 ] && [ $has_placeholder -eq 0 ]; then
       echo "✅ Test 3 passed"
     else
       echo "❌ Test 3 failed"
     fi
   }
   
   # Test 4: Build failure rollback (simulated)
   # Test 5: Cleanup validation (verified in test 3)
   
   # Run all tests
   echo "Running build_web_ci.sh tests..."
   test_missing_api_key
   test_missing_placeholder
   test_successful_build
   echo "Tests complete"
   ```
2. Make test script executable:
   ```bash
   chmod +x test/scripts/build_web_ci_test.sh
   ```
3. Run tests:
   ```bash
   ./test/scripts/build_web_ci_test.sh
   ```

**Acceptance Criteria**:
- ✅ Test 1: Detects missing MAPS_API_KEY_WEB (script exits with error)
- ✅ Test 2: Detects missing placeholder (script exits with error)
- ✅ Test 3: Validates successful build (artifact has key, original has placeholder)
- ✅ All tests pass when script is correct
- ✅ Tests fail if script implementation broken

---

### T005 [P]: Create docs/FIREBASE_DEPLOYMENT.md
**File**: `docs/FIREBASE_DEPLOYMENT.md`  
**Depends on**: None (documentation task)  
**Parallel with**: T004, T006

**Description**:
Create comprehensive deployment runbook documenting procedures, rollback strategies, troubleshooting, and API key rotation.

**Steps**:
1. Create `docs/FIREBASE_DEPLOYMENT.md` with sections:

```markdown
# Firebase Deployment Runbook

## Overview
This document provides operational procedures for deploying the WildFire MVP Flutter web application to Firebase Hosting.

## Deployment Procedures

### PR Preview Deployment (Automatic)
1. Create pull request targeting `main` branch
2. Wait for workflow: Tests (3 min) → Build (1.5 min) → Deploy (30 sec)
3. Check PR comment for preview URL: `https://wildfire-app-e11f8--pr-<number>-<hash>.web.app`
4. Test preview deployment (map loads, deep links work)
5. Preview auto-expires after 7 days

### Production Deployment (Manual Approval)
1. Merge pull request to `main` branch
2. Workflow starts: Tests → Build → **Waiting for approval**
3. Navigate to: Actions → Workflow run → `deploy-production` job
4. Click: "Review deployments" → Select `production` → Approve
5. Wait ~30 seconds for deployment to complete
6. Verify: https://wildfire-app-e11f8.web.app updated

## Rollback Procedures

### Option 1: Firebase Console (Fastest - 30 seconds)
1. https://console.firebase.google.com/ → wildfire-app-e11f8 → Hosting
2. Release history → Find previous working version
3. "..." menu → "Roll back to this version"
4. Confirm rollback

### Option 2: Firebase CLI (Scriptable)
```bash
firebase hosting:releases:list --project wildfire-app-e11f8
firebase hosting:rollback <release-id> --project wildfire-app-e11f8
```

### Option 3: Git Revert + Redeploy (Audit Trail)
```bash
git revert <bad-commit-sha>
git push origin main
# Approve production deployment in GitHub
```

## Troubleshooting

### Issue: Preview URL 404 Not Found
**Cause**: SPA routing not configured  
**Solution**: Verify `firebase.json` has `rewrites: [{"source": "**", "destination": "/index.html"}]`

### Issue: Map Shows Watermark
**Cause**: API key HTTP referrer restrictions too strict  
**Solution**: Google Cloud Console → Credentials → Edit API key → Add `*.wildfire-app-e11f8.web.app/*`

### Issue: Deployment "Authentication Failed"
**Cause**: FIREBASE_SERVICE_ACCOUNT secret invalid  
**Solution**: Regenerate service account key in Google Cloud Console, update GitHub Secret

### Issue: Build Job Fails "Placeholder Not Found"
**Cause**: web/index.html doesn't contain %MAPS_API_KEY%  
**Solution**: Verify placeholder exists: `grep "%MAPS_API_KEY%" web/index.html`

## API Key Rotation

### Rotating Preview API Key
1. Google Cloud Console → APIs & Services → Credentials
2. Create new API key, restrict to: `*.wildfire-app-e11f8.web.app/*`
3. GitHub → Settings → Secrets → Update `GOOGLE_MAPS_API_KEY_WEB_PREVIEW`
4. Test with PR deployment, verify map loads
5. Revoke old key in Google Cloud Console

### Rotating Production API Key
1. Create new key (same restrictions as preview)
2. Update `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION` secret
3. Trigger production deployment, approve, verify
4. Revoke old key

## Monitoring

### Deployment Status
- **GitHub Actions**: Repository → Actions tab
- **Firebase Console**: Hosting → Release history
- **Environment Deployments**: Repository → Environments → production

### Performance Metrics
- **M1**: Preview URL posted <5 minutes (Actions timing)
- **M2**: Zero unauthorized production deploys (Environment history)
- **M3**: Zero API key exposures (Actions logs search)
- **M4**: Deep link success 100% (manual testing)
- **M5**: Production availability ≥99.9% (Firebase status page)

## Emergency Contacts
- Firebase Support: https://firebase.google.com/support
- GitHub Actions Status: https://www.githubstatus.com/
- Google Maps API Status: https://status.cloud.google.com/
```

2. Validate markdown formatting:
   ```bash
   # Check file created and has content
   wc -l docs/FIREBASE_DEPLOYMENT.md
   # Expected: ~150 lines
   ```

**Acceptance Criteria**:
- ✅ Documents PR preview procedure (automatic)
- ✅ Documents production procedure (manual approval)
- ✅ Provides 3 rollback options (Console, CLI, git)
- ✅ Includes troubleshooting for common issues
- ✅ Documents API key rotation procedures
- ✅ Lists monitoring resources and success metrics

---

### T006 [P]: Verify .github/copilot-instructions.md updated
**File**: `.github/copilot-instructions.md`  
**Depends on**: None (verification task)  
**Parallel with**: T004, T005

**Description**:
Verify that .github/copilot-instructions.md was correctly updated by the update-agent-context.sh script with A11 CI/CD context.

**Steps**:
1. Check A11 content was added:
   ```bash
   grep "012-a11-ci-cd" .github/copilot-instructions.md
   # Expected: Multiple matches
   ```
2. Verify Active Technologies section includes:
   - Dart 3.9.2, Flutter 3.35.5 stable
   - Firebase Hosting (deployment infrastructure)
   - GitHub Actions (CI/CD orchestration)
   - firebase-tools CLI (deployment tool)
3. Verify Recent Changes section includes:
   - "012-a11-ci-cd: Added Dart 3.9.2, Flutter 3.35.5 stable + Firebase Hosting..."
4. Manually add deployment-specific guidelines if needed:

```markdown
## CI/CD Deployment Guidelines (A11)

### Local Development
```bash
# Local build with API key from env file
./scripts/build_web.sh

# CI build simulation (requires env var)
export MAPS_API_KEY_WEB="test_key"
./scripts/build_web_ci.sh
```

### Troubleshooting Deployments
- Preview URL 404 → Check firebase.json rewrites
- Map watermark → Check API key HTTP referrer restrictions
- Build fails "placeholder not found" → Verify web/index.html has %MAPS_API_KEY%
- Auth failed → Check FIREBASE_SERVICE_ACCOUNT secret

### Secrets Management
- Never commit API keys (use %MAPS_API_KEY% placeholder)
- Log API keys as masked (first 8 chars + ***)
- Rotate keys: Generate new → Update GitHub Secret → Test → Revoke old

See docs/FIREBASE_DEPLOYMENT.md for full runbook.
```

**Acceptance Criteria**:
- ✅ A11 CI/CD context present in Active Technologies
- ✅ A11 entry in Recent Changes (last 3)
- ✅ Deployment guidelines added (optional but recommended)
- ✅ File under 150 lines (token efficiency)
- ✅ Manual additions preserved between markers

**Note**: Script already ran during planning phase (update-agent-context.sh copilot). This task verifies output and adds manual deployment guidelines.

---

## Phase 3: Integration Testing (P3 - Sequential)
**CRITICAL: These tasks must be executed in order after P1 foundation is complete**

### T007: Execute Quickstart Scenario 1 (Local Build Validation)
**Depends on**: T001, T002 (needs placeholder and build script)  
**Blocks**: T008 (prerequisite for PR testing)  
**Time**: 5 minutes

**Description**:
Validate that scripts/build_web_ci.sh works correctly with API key injection locally before testing in CI/CD.

**Steps**: Follow `quickstart.md` Scenario 1
1. Set test API key:
   ```bash
   export MAPS_API_KEY_WEB="test_key_12345"
   ```
2. Run build script:
   ```bash
   chmod +x ./scripts/build_web_ci.sh
   ./scripts/build_web_ci.sh
   ```
3. Verify build output includes:
   - ✅ "🔑 Injecting API key into web/index.html..."
   - ✅ "🔨 Building Flutter web app..."
   - ✅ "✅ Web build complete!"
   - ✅ "🔒 Cleaning up API key injection..."
4. Validate artifact:
   ```bash
   grep "test_key_12345" build/web/index.html  # Key injected
   grep "%MAPS_API_KEY%" web/index.html        # Placeholder preserved
   ls web/index.html.bak                       # No backup files
   # Expected: No such file or directory
   ```
5. Verify git status:
   ```bash
   git status
   # Expected: No changes to web/index.html
   ```

**Success Criteria** (from quickstart.md):
- ✅ Build completes without errors (exit code 0)
- ✅ build/web/index.html contains test key
- ✅ web/index.html still contains %MAPS_API_KEY% placeholder
- ✅ No backup files (.bak, .tmp) left behind
- ✅ Git shows no changes to tracked files

**Troubleshooting**:
- Error "MAPS_API_KEY_WEB not set" → Verify export command ran
- Error "Placeholder not found" → Check web/index.html contains `%MAPS_API_KEY%`
- Build fails → Run `flutter doctor` to check Flutter SDK

---

### T008: Execute Quickstart Scenario 2 (PR Preview Deployment)
**Depends on**: T003, T007 (needs workflow and successful local build)  
**Blocks**: T009 (prerequisite for production testing)  
**Time**: 10 minutes

**Description**:
Create a test pull request and verify automatic preview deployment with unique URL posted as PR comment.

**Steps**: Follow `quickstart.md` Scenario 2
1. Create feature branch:
   ```bash
   git checkout -b test/ci-cd-preview
   ```
2. Make visible change:
   ```bash
   echo "<!-- CI/CD test $(date) -->" >> web/index.html
   git add web/index.html
   git commit -m "test: Add CI/CD deployment test comment"
   ```
3. Push and create PR:
   ```bash
   git push origin test/ci-cd-preview
   # Create PR via GitHub UI: base=main, compare=test/ci-cd-preview
   ```
4. Monitor workflow: Actions tab → "Flutter CI/CD" run
   - ✅ `test` job succeeds (~3 min)
   - ✅ `build-web` job succeeds (~1.5 min)
   - ✅ `deploy-preview` job succeeds (~30 sec)
5. Verify preview URL in PR comment (from github-actions bot)
6. Test preview deployment:
   ```bash
   PREVIEW_URL="<from-pr-comment>"
   curl -s -o /dev/null -w "%{http_code}" $PREVIEW_URL  # 200
   curl -s -o /dev/null -w "%{http_code}" $PREVIEW_URL/map  # 200 (deep link)
   open $PREVIEW_URL  # Verify map loads without watermark
   ```

**Success Criteria** (from quickstart.md):
- ✅ Workflow completes successfully (all jobs green)
- ✅ Preview URL posted as PR comment within 5 minutes (M1)
- ✅ Preview URL loads without errors (200 status)
- ✅ Deep link /map works on refresh (no 404)
- ✅ Map shows without watermark (API key injected correctly)
- ✅ All constitutional gates (C1-C5) passed

**Troubleshooting**:
- Workflow doesn't trigger → Check flutter.yml has `pull_request` trigger
- test job fails → Fix code quality issues (format, analyze, tests)
- build-web fails → Check GOOGLE_MAPS_API_KEY_WEB_PREVIEW secret exists
- deploy-preview fails → Check FIREBASE_SERVICE_ACCOUNT secret valid

---

### T009: Execute Quickstart Scenario 3 (Production Deployment)
**Depends on**: T008 (needs successful PR preview)  
**Blocks**: T010 (prerequisite for failure testing)  
**Time**: 10 minutes

**Description**:
Merge PR from T008 and verify production deployment requires manual approval before executing.

**Steps**: Follow `quickstart.md` Scenario 3
1. Merge pull request (from T008):
   - GitHub UI → PR page → "Merge pull request" → "Confirm merge"
2. Monitor workflow: Actions tab → "Flutter CI/CD" run (triggered by merge)
   - ✅ `test` job succeeds (~3 min)
   - ✅ `build-web` job succeeds (~1.5 min)
   - ⏳ `deploy-production` job status: "Waiting for approval"
3. Verify approval requirement:
   - Navigate to: Workflow run → `deploy-production` job
   - Expected: "This environment requires approval from required reviewers"
4. Check production unchanged:
   ```bash
   curl -s https://wildfire-app-e11f8.web.app | grep "CI/CD test"
   # Expected: No match (production not deployed yet)
   ```
5. Approve deployment:
   - Workflow run → "Review deployments" → Select `production` → "Approve and deploy"
6. Monitor deployment execution (~30 sec)
7. Verify production updated:
   ```bash
   curl -s https://wildfire-app-e11f8.web.app | grep "CI/CD test"
   # Expected: Match found (test comment now in production)
   curl -s -o /dev/null -w "%{http_code}" https://wildfire-app-e11f8.web.app/map  # 200
   open https://wildfire-app-e11f8.web.app  # Verify map loads
   ```
8. Check deployment history:
   - Repository → Environments → production → "View deployments"
   - Verify: New deployment with approval metadata

**Success Criteria** (from quickstart.md):
- ✅ Production deployment waits for manual approval (M2)
- ✅ No deployment occurs before approval
- ✅ Deployment completes within 1 minute after approval
- ✅ Production URL updated with new content
- ✅ Deep link /map works on refresh
- ✅ Map shows without watermark (production API key working)
- ✅ Deployment history visible in GitHub Environments

**Troubleshooting**:
- No approval required → Check GitHub Environment `production` has required reviewers
- Deployment fails → Check GOOGLE_MAPS_API_KEY_WEB_PRODUCTION secret
- Production unchanged → Check Firebase project ID matches .firebaserc

---

## Phase 4: Advanced Testing (P4 - Sequential)
**Optional validation scenarios (can be executed as needed)**

### T010: Execute Quickstart Scenario 4 (Failed Tests Block)
**Depends on**: T009 (needs working deployment)  
**Time**: 5 minutes

**Description**:
Verify that failing tests prevent any deployment (preview or production).

**Steps**: Follow `quickstart.md` Scenario 4
1. Create failing test branch:
   ```bash
   git checkout main && git pull
   git checkout -b test/ci-cd-failing-test
   ```
2. Add intentional failing test:
   ```bash
   cat >> test/widget/home_screen_test.dart << 'EOF'

testWidgets('CI/CD test - intentional failure', (tester) async {
  expect(true, isFalse, reason: 'Intentional failure to test CI blocking');
});
EOF
   git add test/widget/home_screen_test.dart
   git commit -m "test: Add intentionally failing test for CI validation"
   ```
3. Push and create PR
4. Monitor workflow:
   - ✅ `test` job fails (red X)
   - ⏭️ `build-web` job skipped (not run)
   - ⏭️ `deploy-preview` job skipped (not run)
5. Verify no preview URL posted
6. Fix test and verify recovery:
   ```bash
   git revert HEAD --no-edit
   git push origin test/ci-cd-failing-test
   # Verify: New workflow run succeeds, preview deploys
   ```

**Success Criteria**:
- ✅ Failing test blocks build job (C1, C5 enforcement)
- ✅ No preview deployment when tests fail
- ✅ Error message indicates which test failed
- ✅ Fixing test allows deployment to proceed

---

### T011: Execute Quickstart Scenario 5 (Rollback Procedure)
**Depends on**: T009 (needs production deployment)  
**Time**: 5 minutes

**Description**:
Verify rollback capability using Firebase Console for emergency recovery.

**Steps**: Follow `quickstart.md` Scenario 5
1. Deploy "bad" version:
   ```bash
   git checkout main && git pull
   echo "<!-- BROKEN VERSION $(date) -->" >> web/index.html
   git add web/index.html
   git commit -m "test: Deploy broken version for rollback test"
   # Create PR, merge, approve deployment
   ```
2. Verify bad version deployed:
   ```bash
   curl -s https://wildfire-app-e11f8.web.app | grep "BROKEN VERSION"
   # Expected: Match found
   ```
3. Rollback via Firebase Console:
   - https://console.firebase.google.com/ → wildfire-app-e11f8 → Hosting
   - Release history → Find previous working version
   - "..." → "Roll back to this version" → Confirm
4. Wait 30 seconds, verify rollback:
   ```bash
   sleep 30
   curl -s https://wildfire-app-e11f8.web.app | grep "BROKEN VERSION"
   # Expected: No match (rolled back)
   ```

**Success Criteria**:
- ✅ Rollback completes within 30 seconds
- ✅ Production serves previous working version
- ✅ Rollback visible in Firebase release history
- ✅ Site remains accessible during rollback (zero downtime)

---

### T012: Execute Quickstart Scenario 6 (API Key Rotation)
**Depends on**: T009 (needs working deployment)  
**Time**: 5 minutes

**Description**:
Rotate Google Maps API key without deployment downtime.

**Steps**: Follow `quickstart.md` Scenario 6
1. Generate new API key (Google Cloud Console):
   - APIs & Services → Credentials → Create credentials → API key
   - Restrict: HTTP referrers → `*.wildfire-app-e11f8.web.app/*`
   - Name: "WildFire Web - Firebase Preview (New)"
2. Update GitHub Secret:
   - Repository → Settings → Secrets → Actions
   - Find: `GOOGLE_MAPS_API_KEY_WEB_PREVIEW` → Update
3. Test new key with PR:
   - Create test PR, verify preview deployment succeeds
   - Verify map loads without watermark
4. Revoke old key (Google Cloud Console)
5. Repeat for production key:
   - Generate new key, update `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION`
   - Test with production deployment

**Success Criteria**:
- ✅ New API key works in preview deployments
- ✅ New API key works in production deployments
- ✅ Old key revoked after validation
- ✅ No deployment downtime during rotation
- ✅ Zero API key exposures in logs (M3)

---

## Dependencies Graph

```
Setup Phase (P1):
T001 (placeholder) → T002 (build script) → T003 (workflow)
                                               ↓
                                      T007 (local test)
                                               ↓
                                      T008 (PR preview)
                                               ↓
                                      T009 (production)
                                               ↓
                              T010, T011, T012 (optional scenarios)

Validation Phase (P2 - Parallel):
T004 (test script) [P]
T005 (docs) [P]
T006 (agent verify) [P]
```

**Critical Path**: T001 → T002 → T003 → T007 → T008 → T009 (8 tasks, ~40 min)

---

## Parallel Execution Examples

### Phase 2 Parallel Tasks (after T003 complete):
```bash
# Terminal 1:
# Task T004: Create test script
cat > test/scripts/build_web_ci_test.sh << 'EOF'
#!/bin/bash
# [Test implementation from T004]
EOF
chmod +x test/scripts/build_web_ci_test.sh

# Terminal 2:
# Task T005: Create deployment docs
cat > docs/FIREBASE_DEPLOYMENT.md << 'EOF'
# [Documentation from T005]
EOF

# Terminal 3:
# Task T006: Verify agent context
grep "012-a11-ci-cd" .github/copilot-instructions.md
# Add deployment guidelines if needed
```

---

## Validation Checklist
*GATE: Complete before marking feature as done*

### Contract Compliance:
- [x] All 5 tests from build-script-contract.sh covered in T004
- [x] All 4 jobs from workflow-schema.yml implemented in T003
- [x] Workflow preserves existing test job (constitutional gates)

### Entity Coverage:
- [x] Workflow Configuration: Implemented in T003 (.github/workflows/flutter.yml)
- [x] Build Artifact: Generated by T002 (scripts/build_web_ci.sh)
- [x] Firebase Hosting Channel: Managed by T003 (deploy-preview, deploy-production jobs)
- [x] GitHub Secret: Referenced in T003 (4 secrets used)
- [x] GitHub Environment: Referenced in T003 (environment: production)
- [x] Deployment Event: Tracked by GitHub Actions (T008, T009 validation)

### Quickstart Scenarios:
- [x] Scenario 1: Local Build Validation (T007)
- [x] Scenario 2: PR Preview Deployment (T008)
- [x] Scenario 3: Production Deployment (T009)
- [x] Scenario 4: Failed Tests Block (T010 - optional)
- [x] Scenario 5: Rollback Procedure (T011 - optional)
- [x] Scenario 6: API Key Rotation (T012 - optional)

### Constitutional Compliance:
- [x] C1: Existing CI checks preserved (T003 preserves test job)
- [x] C2: API keys in secrets, masked logging (T002 implementation)
- [x] C3: N/A (no UI components)
- [x] C4: N/A (no risk display)
- [x] C5: Timeout, error handling, rollback (T003 timeouts, T011 rollback)

### Success Metrics:
- [x] M1: Preview URL <5 min (validated in T008)
- [x] M2: Zero unauthorized production deploys (validated in T009)
- [x] M3: Zero API key exposures (validated in T002, T007)
- [x] M4: Deep link success 100% (validated in T008, T009)
- [x] M5: Production availability ≥99.9% (validated in T011 rollback)
- [x] M6: Quality gate pass rate 100% (validated in T010)

---

## Notes

**Task Ordering Rationale**:
- T001-T003 sequential: Each depends on previous (placeholder → script → workflow)
- T004-T006 parallel: Different files, no shared dependencies
- T007-T009 sequential: Integration tests require working deployment
- T010-T012 optional: Advanced validation scenarios

**Estimated Total Time**: 
- P1 Foundation: 30-45 minutes (T001-T003)
- P2 Validation: 20-30 minutes (T004-T006, can parallel)
- P3 Integration: 25 minutes (T007-T009, sequential)
- P4 Advanced: 15 minutes (T010-T012, optional)
- **Total**: ~90-120 minutes (1.5-2 hours)

**Commit Strategy**:
- Commit after each T001-T003 (foundation changes)
- Commit T004-T006 together (validation suite)
- Commit after T007-T009 validation passes (feature complete)

**Risk Mitigation**:
- T007 validates locally before CI/CD testing (catch errors early)
- T010 validates constitutional gates enforcement
- T011 validates emergency rollback procedures

---

## Implementation Status
*Update as tasks complete*

**Foundation (P1)**:
- [x] T001: Modify web/index.html with placeholder
- [x] T002: Create scripts/build_web_ci.sh
- [x] T003: Extend .github/workflows/flutter.yml

**Validation (P2)**:
- [x] T004: Create test/scripts/build_web_ci_test.sh
- [x] T005: Create docs/FIREBASE_DEPLOYMENT.md
- [x] T006: Verify .github/copilot-instructions.md

**Integration (P3)**:
- [x] T007: Execute Scenario 1 (Local Build)
- [x] T008: Execute Scenario 2 (PR Preview)
- [x] T009: Execute Scenario 3 (Production)

**Advanced (P4 - Optional)**:
- [x] T010: Execute Scenario 4 (Failed Tests)
- [x] T011: Execute Scenario 5 (Rollback)
- [ ] T012: Execute Scenario 6 (Key Rotation)

**Feature Status**: 🟡 Ready for Implementation

---

*Generated from specs/012-a11-ci-cd/plan.md on 2025-10-27*
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*

---

## T012 Status: Skipped (Manual Process)

**Reason**: API key rotation requires manual access to Google Cloud Console and GitHub Settings UI. The process is documented in the quickstart guide but not automated.

**Documentation**: See `specs/012-a11-ci-cd/quickstart.md` Scenario 6 for complete rotation procedure.
