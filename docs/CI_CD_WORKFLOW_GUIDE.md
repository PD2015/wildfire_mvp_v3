---
title: CI/CD Workflow Guide
status: active
last_updated: 2025-10-30
category: guides
subcategory: deployment
related:
  - FIREBASE_DEPLOYMENT.md
  - A11_CI_CD_REVIEW.md
  - guides/security/api-key-management.md
---

# CI/CD Pipeline & Workflow Guide

**Project**: WildFire MVP v3  
**Last Updated**: 30 October 2025  
**Pipeline**: GitHub Actions + Firebase Hosting  

---

## 📋 Table of Contents

1. [Pipeline Architecture](#pipeline-architecture)
2. [Workflow Phases](#workflow-phases)
3. [Best Practices](#best-practices)
4. [Feature Development Workflow](#feature-development-workflow)
5. [Troubleshooting](#troubleshooting)
6. [Monitoring & Commands](#monitoring--commands)
7. [Worktrees & CI/CD](#worktrees--cicd)
8. [Production Deployment](#production-deployment)
9. [Quick Reference](#quick-reference)

---

## 🔄 Pipeline Architecture

### **Overview**

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                      │
│                   (.github/workflows/flutter.yml)               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1: Constitutional Gates (C1-C5) - MUST PASS             │
├─────────────────────────────────────────────────────────────────┤
│  ✓ format      → dart format --set-exit-if-changed            │
│  ✓ analyze     → flutter analyze                               │
│  ✓ test        → flutter test (319 tests)                      │
│  ✓ gitleaks    → Secret scan (C2 compliance)                   │
│  ✓ color_guard → Scottish palette validation (C4)              │
└─────────────────────────────────────────────────────────────────┘
                              ↓ (All must pass)
┌─────────────────────────────────────────────────────────────────┐
│  Phase 2: Build Web Artifact                                   │
├─────────────────────────────────────────────────────────────────┤
│  build-web job:                                                 │
│  1. Inject API key from GitHub Secrets                         │
│  2. Build: flutter build web --release                         │
│  3. Upload artifact (build/web/)                               │
│  4. Retention: 7 days                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
            ┌─────────────────┴─────────────────┐
            ↓                                   ↓
┌───────────────────────────┐     ┌───────────────────────────┐
│ Phase 3a: PR Preview      │     │ Phase 3b: Production      │
│ (if pull_request)         │     │ (if push to main)         │
├───────────────────────────┤     ├───────────────────────────┤
│ deploy-preview job:       │     │ deploy-production job:    │
│ 1. Download artifact      │     │ 1. Download artifact      │
│ 2. Deploy to Firebase     │     │ 2. WAIT FOR APPROVAL ⏸️   │
│    Channel: pr-{number}   │     │ 3. Deploy to Firebase     │
│ 3. Post comment with URL  │     │    Channel: live          │
│ 4. Auto-cleanup: 7 days   │     │ 4. URL: production site   │
└───────────────────────────┘     └───────────────────────────┘
         ↓                                     ↓
   Preview URL:                          Production URL:
   pr-123--wildfire-app-e11f8.web.app   wildfire-app-e11f8.web.app
```

### **Key Components**

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **GitHub Actions** | CI/CD orchestration | `.github/workflows/flutter.yml` |
| **Firebase Hosting** | Web hosting (preview + production) | `firebase.json`, `.firebaserc` |
| **GitHub Secrets** | Secure API key storage | Repository Settings → Secrets |
| **GitHub Environments** | Production approval gate | Repository Settings → Environments |
| **Firebase Channels** | PR preview deployments | Auto-created per PR |

---

## 🎯 Workflow Phases

### **Phase 1: Constitutional Gates (C1-C5)**

**Purpose**: Enforce code quality and security standards before any deployment.

**Jobs**:

1. **format** (C1: Code Quality)
   ```yaml
   - run: dart format --set-exit-if-changed .
   ```
   - Ensures consistent code formatting
   - Fails if code not formatted
   - **Fix locally**: `dart format lib/ test/`

2. **analyze** (C1: Code Quality)
   ```yaml
   - run: flutter analyze
   ```
   - Static analysis for errors/warnings
   - Enforces Dart linting rules
   - **Fix locally**: `flutter analyze` then fix issues

3. **test** (C1: Code Quality & C5: Resilience)
   ```yaml
   - run: flutter test
   ```
   - Runs 319 unit/widget/integration tests
   - Must achieve 100% pass rate
   - **Fix locally**: `flutter test` and fix failures

4. **gitleaks** (C2: Secrets & Logging)
   ```yaml
   - uses: gitleaks/gitleaks-action@v2
   ```
   - Scans git history for API keys/secrets
   - Uses `.gitleaksignore` for false positives
   - **Fix**: Add to `.gitleaksignore` or remove secret

5. **color_guard** (C4: Trust & Transparency)
   ```yaml
   - run: dart run test/scripts/color_guard.dart
   ```
   - Validates Scottish wildfire risk colors
   - Ensures official palette used
   - **Fix**: Use color constants from `lib/theme/app_colors.dart`

**Trigger**: Every push to any branch, every PR

**Duration**: ~3-4 minutes total

---

### **Phase 2: Build Web Artifact**

**Purpose**: Create deployable web application with secure API key injection.

**Job**: `build-web`

**Steps**:
1. Checkout code
2. Setup Flutter 3.35.5
3. Get dependencies: `flutter pub get`
4. **Inject API key**: 
   ```bash
   env:
     MAPS_API_KEY_WEB: ${{ secrets.GOOGLE_MAPS_API_KEY_WEB_PREVIEW }}
   run: ./scripts/build_web_ci.sh
   ```
5. Build: `flutter build web --release --dart-define=MAP_LIVE_DATA=false`
6. **Upload artifact**: `build/web/` (7-day retention)

**Depends on**: All Phase 1 jobs must pass

**Duration**: ~1.5 minutes

**Output**: `web-build` artifact (ready for deployment)

---

### **Phase 3a: PR Preview Deployment**

**Purpose**: Deploy feature branches to temporary preview URLs for testing.

**Job**: `deploy-preview`

**Trigger**: `if: github.event_name == 'pull_request'`

**Steps**:
1. Download `web-build` artifact
2. Deploy to Firebase Hosting Channel:
   - Channel ID: `pr-{PR_NUMBER}`
   - URL: `https://wildfire-app-e11f8--pr-{number}-{hash}.web.app`
3. **Firebase bot comments** on PR with URL
4. **Auto-cleanup**: Preview deleted after 7 days

**Duration**: ~30 seconds

**Success Metrics** (from spec):
- M1: Preview URL available <5 minutes ✅
- M4: Deep links work (no 404s) ✅

**Example URLs**:
- PR #1: `https://wildfire-app-e11f8--pr-1-0f5od9k8.web.app`
- PR #2: `https://wildfire-app-e11f8--pr-2-abc123de.web.app`

---

### **Phase 3b: Production Deployment**

**Purpose**: Deploy main branch to production with manual approval gate.

**Job**: `deploy-production`

**Trigger**: `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`

**Steps**:
1. Download `web-build` artifact
2. **WAIT FOR APPROVAL** (GitHub Environment protection)
3. Deploy to Firebase Hosting live channel
4. URL: `https://wildfire-app-e11f8.web.app`

**Approval Process**:
1. Go to: Actions → Workflow run
2. Click: `deploy-production` job
3. Click: "Review pending deployments"
4. Select: `production` environment
5. Click: "Approve and deploy"

**Duration**: ~30 seconds after approval

**Success Metrics** (from spec):
- M2: Zero deployments without approval ✅
- M3: Zero API key exposures ✅
- M5: Production availability ≥99.9% ✅

---

## ✅ Best Practices

### **DO**

1. ✅ **Always work in feature branches**
   ```bash
   git checkout -b 013-a13-new-feature
   ```
   Never commit directly to `main`

2. ✅ **Create PRs early for preview deployments**
   ```bash
   gh pr create --draft --base main
   ```
   Even if work-in-progress, get preview URL

3. ✅ **Test locally before pushing**
   ```bash
   flutter test
   dart format lib/ test/
   flutter analyze
   ```
   Faster feedback than waiting for CI

4. ✅ **Use preview URLs for testing**
   - Test on real devices (mobile, tablet, desktop)
   - Share with stakeholders
   - Verify API keys working (no watermark)

5. ✅ **Keep PRs focused**
   - One feature per PR
   - Easier to review
   - Easier to rollback if issues

6. ✅ **Run constitutional gates locally**
   ```bash
   dart format lib/ test/
   flutter analyze
   flutter test
   ```

7. ✅ **Wait for CI approval before merging**
   - All 5 gates must pass
   - Preview must be tested
   - Code must be reviewed

8. ✅ **Test in preview before merging**
   - Check functionality works
   - Verify no regressions
   - Test on target devices

### **DON'T**

1. ❌ **Don't push to main directly**
   - Bypasses preview deployment
   - No review opportunity
   - Risky for production

2. ❌ **Don't merge PRs with failing tests**
   - Breaks main branch
   - Blocks other developers
   - Creates technical debt

3. ❌ **Don't skip local testing**
   - Wastes CI time
   - Slows development
   - Increases iteration cycle

4. ❌ **Don't commit secrets**
   - Pre-commit hook blocks
   - Gitleaks will catch
   - Security violation (C2)

5. ❌ **Don't approve production blindly**
   - Check preview first
   - Verify tests pass
   - Review changes

6. ❌ **Don't force-push to PR branches**
   - Breaks preview history
   - Confuses reviewers
   - Loses comments

---

## 🚀 Feature Development Workflow

### **Step 1: Create Feature Branch**

```bash
# From main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b 013-a13-new-feature

# Or use Specify workflow
.specify/scripts/bash/create-new-feature.sh --json "A13 - New Feature Description"
```

---

### **Step 2: Develop Locally**

```bash
# Make your changes
# Edit files in lib/, test/, etc.

# Run tests frequently
flutter test

# Format code
dart format lib/ test/

# Check for issues
flutter analyze

# Test web build if web-related
flutter build web --release --dart-define=MAP_LIVE_DATA=false
```

**💡 Tips**:
- Run tests after each significant change
- Fix issues immediately (cheaper than debugging later)
- Test on target platforms (web, iOS, Android)

---

### **Step 3: Commit & Push**

```bash
# Stage changes
git add .

# Pre-commit hook runs automatically (checks for secrets)
git commit -m "feat(a13): implement new feature"

# Push to GitHub
git push origin 013-a13-new-feature
```

**What happens**:
- ✅ Pre-commit hook checks for API keys
- ✅ CI runs on feature branch
- ✅ All 5 constitutional gates run
- ✅ Build web artifact
- ❌ NO deployment yet (not a PR)

---

### **Step 4: Create Pull Request**

```bash
# Option A: GitHub CLI
gh pr create \
  --title "feat(a13): Add new feature" \
  --body "Implements spec 013-a13-new-feature" \
  --base main

# Option B: GitHub Web UI
# https://github.com/PD2015/wildfire_mvp_v3/compare/013-a13-new-feature?expand=1

# Option C: Draft PR (for early feedback)
gh pr create --draft --base main
```

**What happens**:
- ✅ CI runs again (with PR context)
- ✅ All gates run
- ✅ Build artifact
- ✅ **Deploy to preview channel** 🎉
- ✅ **Firebase bot comments** with URL
- ✅ **Preview available in <5 minutes**

**Example PR comment**:
```
✅ Deploy Preview ready!

🔗 https://wildfire-app-e11f8--pr-123-abc123de.web.app

Built with commit abc123d
```

---

### **Step 5: Review Preview**

```bash
# Get PR number
gh pr view --json number,url

# Visit preview URL (from PR comment or via gh)
gh pr view 123 --web

# Or open directly
open https://wildfire-app-e11f8--pr-123-abc123de.web.app
```

**Testing checklist**:
- ✅ Feature works as expected
- ✅ No regressions (existing features still work)
- ✅ Mobile responsive (test on small viewport)
- ✅ Google Maps loads (no "development purposes" watermark)
- ✅ Deep links work (navigate to /map, /home, refresh page)
- ✅ No console errors (open DevTools)

---

### **Step 6: Iterate if Needed**

```bash
# Make changes based on preview feedback
# ... edit files ...

# Commit and push
git add .
git commit -m "fix(a13): address review feedback"
git push origin 013-a13-new-feature
```

**What happens**:
- ✅ CI runs again
- ✅ **Preview URL updates** automatically (same URL, new content)
- ✅ Old preview version replaced
- ✅ PR updated with new commit

**💡 Tip**: Preview URL stays the same throughout PR lifetime

---

### **Step 7: Get Approval**

```bash
# Request review
gh pr review 123 --request @reviewer

# Address review comments
# ... make changes ...
# ... commit and push ...

# Mark as ready (if draft)
gh pr ready 123
```

**Approval criteria**:
- ✅ All CI checks pass (green checkmarks)
- ✅ Code reviewed by maintainer
- ✅ Preview tested and working
- ✅ No merge conflicts

---

### **Step 8: Merge to Main**

```bash
# Option A: GitHub CLI (recommended)
gh pr merge 123 --squash --delete-branch

# Option B: GitHub Web UI
# Click "Squash and merge" button

# Option C: Merge commit (preserves history)
gh pr merge 123 --merge --delete-branch
```

**What happens**:
- ✅ PR merged to main
- ✅ Feature branch deleted
- ✅ **Production deployment triggered** 🚀
- ✅ All gates run on main
- ✅ Build artifact
- ⏸️ **WAIT FOR MANUAL APPROVAL**

---

### **Step 9: Approve Production Deployment**

**Steps**:
1. Go to: https://github.com/PD2015/wildfire_mvp_v3/actions
2. Find the latest workflow run (triggered by merge)
3. Click on the workflow run
4. See: `deploy-production` job showing "Waiting for approval"
5. Click: "Review pending deployments" button
6. Select: `production` environment checkbox
7. (Optional) Add approval comment
8. Click: "Approve and deploy" button

**What happens**:
- ✅ Deployment proceeds immediately
- ✅ Takes ~30 seconds
- ✅ **Production URL updated**: https://wildfire-app-e11f8.web.app
- ✅ Old version remains available in Firebase history (for rollback)

---

### **Step 10: Verify Production**

```bash
# Open production site
open https://wildfire-app-e11f8.web.app

# Or use Firebase CLI
firebase hosting:channel:open live

# Check deployment history
firebase hosting:releases:list --limit 5
```

**Verification checklist**:
- ✅ New feature visible
- ✅ Existing features working
- ✅ No console errors
- ✅ Performance acceptable
- ✅ Mobile responsive

---

## 🔧 Troubleshooting

### **Issue 1: CI Fails on Format**

**Symptom**: 
```
Error: Process completed with exit code 1.
dart format --set-exit-if-changed .
```

**Cause**: Code not formatted according to Dart style

**Fix**:
```bash
# Format all code
dart format lib/ test/

# Commit and push
git commit -am "style: format code per dart standards"
git push
```

---

### **Issue 2: CI Fails on Analyze**

**Symptom**:
```
flutter analyze
info • Unused import • lib/example.dart:5:8 • unused_import
```

**Cause**: Static analysis warnings/errors

**Fix**:
```bash
# Check what's wrong
flutter analyze

# Fix issues in code (remove unused imports, fix warnings)
# ... edit files ...

# Verify fixed
flutter analyze

# Commit and push
git commit -am "fix: resolve analyzer warnings"
git push
```

---

### **Issue 3: Tests Fail in CI But Pass Locally**

**Symptom**: Tests pass on your machine but fail in CI

**Common causes**:
1. **Platform differences** (web vs mobile)
2. **Binding initialization** missing
3. **Mock setup** incomplete
4. **File paths** (absolute vs relative)

**Fix**:
```bash
# Test on web platform locally (matches CI)
flutter test --platform=chrome

# Check for binding initialization
grep -r "ensureInitialized" test/
# If missing, add to test file:
# WidgetsFlutterBinding.ensureInitialized();

# Check for mock setup
grep -r "setMockInitialValues" test/
# If missing, add before SharedPreferences usage:
# SharedPreferences.setMockInitialValues({});

# Verify fixed locally
flutter test --platform=chrome

# Commit and push
git commit -am "test: fix CI test failures"
git push
```

---

### **Issue 4: Preview Deployment Fails**

**Symptom**:
```
Error: HTTP Error: 403, Permission denied
```

**Causes**:
1. **GitHub Secrets missing**
2. **Firebase Service Account invalid**
3. **Workflow permissions insufficient**

**Fix**:
```bash
# Check secrets are set
gh secret list
# Should show:
# FIREBASE_SERVICE_ACCOUNT
# FIREBASE_PROJECT_ID
# GOOGLE_MAPS_API_KEY_WEB_PREVIEW

# Test Firebase credentials locally
firebase deploy --only hosting --dry-run

# Verify workflow has write permissions
# In .github/workflows/flutter.yml, check:
# permissions:
#   contents: read
#   pull-requests: write
```

---

### **Issue 5: Gitleaks Fails (Secrets Detected)**

**Symptom**:
```
5:46PM WRN leaks found: 4
Finding: AIzaSy...
File: android/app/build.gradle.kts
```

**Cause**: API keys in git history

**Fix**:
```bash
# Check what was found
gh run view --log-failed | grep "Finding:"

# Option A: Add to .gitleaksignore (if false positive or rotated key)
echo "android/app/build.gradle.kts:gcp-api-key:37" >> .gitleaksignore
git add .gitleaksignore
git commit -m "fix(ci): ignore rotated API key in git history"
git push

# Option B: Remove secret and recommit (if still valid)
# Edit file to remove secret
# Use environment variable instead
git add .
git commit -m "fix(security): remove hardcoded API key"
git push
```

---

### **Issue 6: Build Fails on Missing Dependency**

**Symptom**:
```
Error: Could not find package flutter_test
```

**Cause**: `pubspec.yaml` out of sync

**Fix**:
```bash
# Update dependencies
flutter pub get

# Verify pubspec.lock is committed
git add pubspec.lock
git commit -m "chore: update dependency lock file"
git push
```

---

### **Issue 7: Preview URL Returns 404**

**Symptom**: Preview URL shows "Site Not Found"

**Causes**:
1. **Deployment failed silently**
2. **firebase.json** configuration error
3. **SPA routing** not configured

**Fix**:
```bash
# Check firebase.json has rewrites
cat firebase.json | grep -A 5 rewrites
# Should show:
# "rewrites": [{"source": "**", "destination": "/index.html"}]

# Test locally with Firebase emulator
firebase emulators:start --only hosting

# Check deployment logs
gh run view --log | grep -A 10 "Deploy to Firebase"
```

---

### **Issue 8: Production Approval Not Showing**

**Symptom**: No "Review pending deployments" button

**Causes**:
1. **Environment not configured**
2. **User not in reviewers list**
3. **Workflow didn't reach deploy job**

**Fix**:
```bash
# Check environment exists
# GitHub → Settings → Environments → production

# Verify you're a required reviewer
# GitHub → Settings → Environments → production → Required reviewers

# Check workflow logs
gh run view --log | grep -A 5 "deploy-production"
```

---

## 📊 Monitoring & Commands

### **Check CI Status**

```bash
# List recent workflow runs
gh run list --limit 5

# View specific run
gh run view 12345

# View all logs
gh run view 12345 --log

# View only failed logs
gh run view 12345 --log-failed

# Watch live (updates every 3 seconds)
gh run watch

# Filter by branch
gh run list --branch 013-a13-new-feature --limit 3

# Filter by status
gh run list --status failure --limit 5
```

---

### **Check Preview Deployments**

```bash
# View PR with preview URL
gh pr view 123

# List all active previews
firebase hosting:channel:list

# Open preview in browser
firebase hosting:channel:open pr-123

# Delete preview manually (if needed)
firebase hosting:channel:delete pr-123
```

---

### **Check Production Deployments**

```bash
# View latest production release
firebase hosting:releases:list --limit 1

# View last 10 releases
firebase hosting:releases:list --limit 10

# View release details
firebase hosting:releases:list --limit 1 --json

# Open production site
open https://wildfire-app-e11f8.web.app
```

---

### **Debug Build Issues**

```bash
# Check build logs locally
./scripts/build_web_ci.sh
# (Set MAPS_API_KEY_WEB first)

# Verify artifact created
ls -lh build/web/

# Check for API key in build output
grep "AIzaSy" build/web/index.html

# Verify original file restored
grep "%MAPS_API_KEY%" web/index.html
```

---

### **Monitor Firebase Resources**

```bash
# Check Firebase project info
firebase projects:list

# View hosting sites
firebase hosting:sites:list

# Check hosting quota usage
firebase hosting:channel:list --json | jq length
# (Max 100 channels per site)
```

---

## 🌳 Worktrees & CI/CD

### **Using Multiple Worktrees**

You can work on multiple features simultaneously using worktrees:

```bash
# Main workspace (A12 feature)
cd ~/wildfire_mvp_v3
git checkout 014-a12b-report-fire

# Create worktree for A11 work
git worktree add ~/wildfire_mvp_v3_a11 012-a11-ci-cd

# Now work in parallel:
cd ~/wildfire_mvp_v3        # Work on A12
cd ~/wildfire_mvp_v3_a11    # Work on A11
```

---

### **CI Behavior with Worktrees**

Each worktree can trigger CI independently:

**Worktree 1 (A12)**:
```bash
cd ~/wildfire_mvp_v3
git push origin 014-a12b-report-fire
# Triggers CI for A12 branch
```

**Worktree 2 (A11)**:
```bash
cd ~/wildfire_mvp_v3_a11
git push origin 012-a11-ci-cd
# Triggers CI for A11 branch
```

---

### **Creating PRs from Worktrees**

Each worktree can have its own PR:

```bash
# From A11 worktree
cd ~/wildfire_mvp_v3_a11
gh pr create --base main --title "feat(a11): CI/CD pipeline"
# Creates PR #1 with preview: pr-1-hash1.web.app

# From main workspace (A12)
cd ~/wildfire_mvp_v3
gh pr create --base main --title "feat(a12): Report Fire screen"
# Creates PR #2 with preview: pr-2-hash2.web.app
```

**Both previews coexist**:
- PR #1: `https://wildfire-app-e11f8--pr-1-hash1.web.app` (A11 work)
- PR #2: `https://wildfire-app-e11f8--pr-2-hash2.web.app` (A12 work)

---

### **Cleaning Up Worktrees**

```bash
# List worktrees
git worktree list

# Remove worktree (after PR merged)
git worktree remove ~/wildfire_mvp_v3_a11

# Prune deleted worktrees
git worktree prune
```

---

## 🚀 Production Deployment

### **Complete Production Deployment Flow**

#### **Step 1: Merge PR**
```bash
# Merge via CLI
gh pr merge 123 --squash --delete-branch

# Or merge via GitHub UI
# https://github.com/PD2015/wildfire_mvp_v3/pull/123
```

**Result**: Main branch updated, feature branch deleted

---

#### **Step 2: Wait for CI**
```bash
# Watch workflow progress
gh run watch

# Or check status periodically
gh run list --limit 1
```

**Timeline**:
- 0-3 minutes: Constitutional gates running
- 3-4.5 minutes: Build web artifact
- 4.5 minutes: **Waiting for approval**

---

#### **Step 3: Approve Deployment**

**Via GitHub UI**:
1. Go to: https://github.com/PD2015/wildfire_mvp_v3/actions
2. Click: Latest workflow run (will show orange dot for pending)
3. Click: `deploy-production` job
4. See: "This workflow is waiting for approval to deploy to production"
5. Click: "Review pending deployments" button
6. Check: `production` environment
7. (Optional) Add comment: "Approved - tested in PR #123 preview"
8. Click: "Approve and deploy"

**Via GitHub CLI** (if you have maintainer access):
```bash
# List pending deployments
gh run list --status waiting --limit 1

# Approve via API (requires additional setup)
# Note: No native gh command for this yet
```

---

#### **Step 4: Monitor Deployment**
```bash
# Watch deployment progress
gh run watch

# Check when complete
gh run view --log | tail -20
```

**Timeline**: ~30 seconds after approval

---

#### **Step 5: Verify Production**
```bash
# Open production site
open https://wildfire-app-e11f8.web.app

# Check via curl
curl -I https://wildfire-app-e11f8.web.app
# Expect: HTTP/2 200

# Verify specific route
curl -I https://wildfire-app-e11f8.web.app/map
# Expect: HTTP/2 200 (not 404)

# Check deployment info
firebase hosting:releases:list --limit 1
```

---

### **Rollback Procedure**

If production has issues, rollback to previous version:

#### **Option 1: Firebase Console** (Fastest)
1. Go to: https://console.firebase.google.com/
2. Select: `wildfire-app-e11f8` project
3. Click: Hosting → Release history
4. Find: Previous working version
5. Click: Three dots menu → "Rollback to this version"
6. Confirm: Click "Rollback"

**Result**: Previous version live in ~30 seconds

---

#### **Option 2: Firebase CLI**
```bash
# List recent releases
firebase hosting:releases:list --limit 10

# Find the release ID you want to rollback to
# Example: f1r3b4s3-r3l3as3-1d

# Rollback
firebase hosting:rollback f1r3b4s3-r3l3as3-1d --project wildfire-app-e11f8
```

---

#### **Option 3: Git Revert + Redeploy**
```bash
# Find the bad commit
git log --oneline -10

# Revert it
git revert <bad-commit-sha>

# Push to main
git push origin main

# Approve deployment when ready
# (Triggers full CI/CD flow)
```

**Result**: Full rebuild and test cycle (~5 minutes)

---

### **Emergency Rollback**

For critical production issues:

```bash
# Immediately rollback via Firebase Console (Option 1 above)
# Takes 30 seconds

# Then investigate root cause
git log --oneline -5
git diff main~1..main

# Create hotfix branch
git checkout -b hotfix/critical-issue main~1

# Fix issue
# ... edit files ...

# Test locally
flutter test
flutter build web --release

# Push and create PR
git push origin hotfix/critical-issue
gh pr create --base main --title "hotfix: Fix critical production issue"

# Test in preview
# Merge to main when verified
# Approve production deployment
```

---

## 📋 Quick Reference

### **Local Development**
```bash
# Run all tests
flutter test

# Run tests for web platform
flutter test --platform=chrome

# Format code
dart format lib/ test/

# Check for issues
flutter analyze

# Test web build
flutter build web --release --dart-define=MAP_LIVE_DATA=false

# Test build script
export MAPS_API_KEY_WEB="test-key"
./scripts/build_web_ci.sh
```

---

### **Git Workflow**
```bash
# Create feature branch
git checkout -b feature-branch

# Stage and commit
git add .
git commit -m "feat: add feature"

# Push branch
git push origin feature-branch

# Create PR
gh pr create --base main --title "feat: Add feature"

# Merge PR
gh pr merge 123 --squash --delete-branch
```

---

### **CI Monitoring**
```bash
# List recent runs
gh run list --limit 5

# View specific run
gh run view 12345

# View failed logs
gh run view 12345 --log-failed

# Watch live
gh run watch

# Check by branch
gh run list --branch feature-branch
```

---

### **Preview Deployments**
```bash
# View PR preview URL
gh pr view 123

# List all previews
firebase hosting:channel:list

# Open preview
firebase hosting:channel:open pr-123

# Delete preview
firebase hosting:channel:delete pr-123
```

---

### **Production**
```bash
# View releases
firebase hosting:releases:list --limit 5

# Open production
open https://wildfire-app-e11f8.web.app

# Rollback
firebase hosting:rollback <release-id>
```

---

### **Troubleshooting**
```bash
# Check secrets
gh secret list

# Test Firebase auth
firebase projects:list

# Verify config
cat firebase.json

# Check gitleaks ignore
cat .gitleaksignore

# View pre-commit hook
cat .git/hooks/pre-commit
```

---

## 🎯 Success Metrics (from A11 Spec)

| Metric | Target | Status |
|--------|--------|--------|
| **M1**: Preview URL available | <5 minutes | ✅ ~2 minutes |
| **M2**: Production without approval | Zero | ✅ 100% gated |
| **M3**: API key exposures | Zero | ✅ 0 detected |
| **M4**: Deep link success rate | 100% | ✅ SPA routing |
| **M5**: Production availability | ≥99.9% | ✅ Firebase SLA |
| **M6**: Quality gate pass rate | 100% | ✅ All enforced |

---

## 📞 Support

### **Documentation**
- **This file**: `docs/CI_CD_WORKFLOW_GUIDE.md`
- **Copilot instructions**: `.github/copilot-instructions.md`
- **A11 spec**: `specs/012-a11-ci-cd/spec.md`
- **A11 plan**: `specs/012-a11-ci-cd/plan.md`
- **A11 tasks**: `specs/012-a11-ci-cd/tasks.md`
- **Quickstart**: `specs/012-a11-ci-cd/quickstart.md`
- **Deployment runbook**: `docs/FIREBASE_DEPLOYMENT.md`

### **Resources**
- **GitHub Actions docs**: https://docs.github.com/en/actions
- **Firebase Hosting docs**: https://firebase.google.com/docs/hosting
- **Flutter web docs**: https://docs.flutter.dev/platform-integration/web
- **GitHub CLI docs**: https://cli.github.com/manual/

### **Project Info**
- **Repository**: https://github.com/PD2015/wildfire_mvp_v3
- **Production URL**: https://wildfire-app-e11f8.web.app
- **Firebase Console**: https://console.firebase.google.com/project/wildfire-app-e11f8
- **GitHub Actions**: https://github.com/PD2015/wildfire_mvp_v3/actions

---

**Last Updated**: 28 October 2025  
**Version**: 1.0  
**Maintainer**: WildFire MVP Team
