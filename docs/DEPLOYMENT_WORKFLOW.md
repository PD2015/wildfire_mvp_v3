# Deployment Workflow - GitFlow with Local Merge Strategy

**Version**: 2.1 (2025-11-01)  
**Philosophy**: Test locally, validate in staging, deploy to production with confidence

## 🎯 Core Principles

1. **Merge conflicts resolved locally** - Never resolve conflicts in GitHub UI
2. **All tests pass locally before push** - Don't rely on CI to catch issues
3. **Staging environment validates** - Test in production-like environment
4. **Manual production approval** - Deliberate deployment with rollback plan

---

## 📊 Branch Strategy

```
main (production)
  ↑ merge locally after staging validation
staging (staging environment)
  ↑ PR merge after code review
feature/xxx (development)
  ↑ branch from staging
```

### Branch Purposes

| Branch | Environment | Auto-Deploy | Purpose |
|--------|------------|-------------|---------|
| `main` | **Production** | ❌ Manual approval | Live site (wildfire-app-e11f8.web.app) |
| `staging` | **Staging** | ✅ Auto | Integration testing, QA, stakeholder review |
| `feature/*` | **Preview** | ✅ Auto (PR only) | Development, code review |

---

## 🔄 Complete Development Cycle

### Phase 1: Feature Development (Local)

```bash
# 1. Start from latest staging
git checkout staging
git pull origin staging

# 2. Create feature branch
git checkout -b feature/new-feature

# 3. Develop and test locally
flutter test
flutter analyze
flutter build web --release

# 4. Push feature branch
git push origin feature/new-feature
```

**Deliverable**: Feature branch with passing local tests

---

### Phase 2: Integration (PR to staging)

```bash
# 1. Update feature branch with latest staging
git checkout staging
git pull origin staging
git checkout feature/new-feature
git merge staging  # ← Resolve conflicts locally

# 2. Test merged state
flutter test
flutter analyze

# 3. Push updated feature
git push origin feature/new-feature

# 4. Create PR to staging (on GitHub)
gh pr create --base staging --title "feat: new feature" --body "Description"
```

**GitHub Actions**:
- ✅ Constitutional gates (format, analyze, test, gitleaks)
- ✅ Web build artifact created
- ✅ Preview deployment to `pr-N` channel
- 👁️ Code review required

**Deliverable**: PR merged to `staging` after review

---

### Phase 3: Staging Validation (staging branch)

When PR merges to `staging`:

```bash
# Automatic triggers:
# - CI runs full test suite
# - Deploy to staging channel: wildfire-app-e11f8-staging.web.app
```

**Manual Testing**:
1. **Smoke tests** - Basic functionality works
2. **Integration tests** - Features work together
3. **QA review** - Test all acceptance criteria
4. **Stakeholder demo** - Get approval

**Duration**: 1-3 days depending on feature size

**Deliverable**: Validated feature ready for production

---

### Phase 4: Production Release Preparation (Local)

```bash
# 1. Ensure staging is fully tested
# Check staging: https://wildfire-app-e11f8-staging.web.app

# 2. Update local main
git checkout main
git pull origin main

# 3. Merge staging into main LOCALLY
git merge staging
# If conflicts: resolve, test, then continue

# 4. Final verification
flutter test --coverage
flutter analyze
flutter build web --release --dart-define-from-file=env/prod.env.json

# 5. Create release tag
git tag -a v1.2.3 -m "Release 1.2.3: New feature"

# 6. Push to main with tag
git push origin main --tags
```

**Why merge locally?**
- ✅ Resolve conflicts in your IDE (better tools)
- ✅ Run full test suite on merged code
- ✅ Verify build succeeds before pushing
- ✅ Rollback easily if issues found (`git reset --hard HEAD~1`)

**Deliverable**: `main` branch ready for production deployment

---

### Phase 5: Production Deployment (Manual Approval)

When `main` is pushed:

```yaml
# GitHub Actions workflow triggered
jobs:
  build:
    # Runs constitutional gates
  
  build-web:
    # Creates production build artifact
  
  deploy-production:
    # WAITS for manual approval ← YOU control this
    environment: production
```

**Approval Process**:
1. GitHub sends email: "Deployment to production waiting"
2. Review GitHub Actions logs: All checks passed?
3. Check staging one more time: Everything working?
4. Click "Review deployments" → "Approve and deploy"
5. Monitor deployment: Watch Firebase console
6. Verify production: Test live site

**Safety Net**: If issues found, rollback immediately:
```bash
# Option 1: Firebase Console (30 seconds)
# Hosting → Release history → Previous version → Rollback

# Option 2: Git revert (full audit trail)
git revert HEAD
git push origin main
# Wait for CI to redeploy previous version
```

**Deliverable**: Feature live in production with monitoring

---

## 🚀 Quick Reference Commands

### Starting New Feature
```bash
git checkout staging && git pull origin staging
git checkout -b feature/my-feature
# Develop...
git push origin feature/my-feature
gh pr create --base staging --title "feat: my feature"
```

### Merging to Staging
```bash
# After PR approved and merged, check staging deployment
gh run list --branch=staging --limit 1
# Wait for success, then test: https://wildfire-app-e11f8-staging.web.app
```

### Releasing to Production (main)
```bash
git checkout main && git pull origin main
git merge staging  # Resolve conflicts if any
flutter test && flutter analyze
git tag v1.2.3 -m "Release 1.2.3"
git push origin main --tags
# Wait for approval request in email
# Go to GitHub → Actions → Review deployments → Approve
```

### Emergency Rollback
```bash
# Firebase Console (fastest):
# https://console.firebase.google.com/project/wildfire-app-e11f8/hosting

# Or via CLI:
firebase hosting:rollback
```

---

## 📋 Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Developer Workflow                      │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐
│ feature/xxx  │ ← Branch from staging
└──────┬───────┘
       │ Local development & testing
       │ git merge staging (resolve conflicts)
       │ flutter test (all pass)
       ↓
┌──────────────┐
│  Pull Request │ → base: staging
└──────┬───────┘
       │ CI: Gates, Build, Preview deploy
       │ Code review
       │ Merge to staging
       ↓
┌──────────────┐
│   staging    │ ← Staging environment
└──────┬───────┘   Auto-deploy to staging channel
       │ Manual QA testing (1-3 days)
       │ Stakeholder approval
       │ 
       │ Ready for production?
       ↓
┌──────────────┐
│  Local merge │ ← YOU control this
│  to main     │   git checkout main
└──────┬───────┘   git merge staging (local)
       │ flutter test (verify)
       │ git push origin main
       ↓
┌──────────────┐
│ Production   │ ← Manual approval required
│ Approval Gate│   Email notification sent
└──────┬───────┘   Review → Approve → Deploy
       │
       ↓
┌──────────────┐
│  🎉 LIVE 🎉  │ ← Production site
└──────────────┘   Monitoring active
                   Rollback ready
```

---

## 🛡️ Safety Mechanisms

### 1. Local Merge Testing
**Problem**: Merge conflicts resolved in GitHub UI can't be tested locally  
**Solution**: Always merge locally, test, then push

### 2. Staging Environment
**Problem**: Testing in production is risky  
**Solution**: `staging` branch auto-deploys to staging for validation

### 3. Manual Production Approval
**Problem**: Auto-deploy on merge can deploy broken code  
**Solution**: GitHub Environment protection requires manual "Approve" button

### 4. Version Tagging
**Problem**: Hard to identify which code is in production  
**Solution**: Git tags (`v1.2.3`) mark production releases

### 5. Fast Rollback
**Problem**: Issues found in production need quick fix  
**Solution**: Firebase console rollback (<30 seconds) or git revert

---

## 📝 Current vs Improved Workflow

### Current (Risky)
```bash
feature → PR → merge on GitHub → main → AUTO-DEPLOY 🔴
          Conflicts resolved in GitHub UI
          Tests run AFTER merge to main
          Production breaks if tests fail
```

### Improved (Safe)
```bash
feature → PR → staging → staging env (test 1-3 days) → 
local merge to main → manual approval → DEPLOY ✅
All conflicts resolved locally
All tests pass before main updated
Production deployment is deliberate
```

---

## 🔧 Required Configuration Changes

To implement this workflow, update `.github/workflows/flutter.yml`:

### Change 1: Add staging deployment
```yaml
deploy-staging:
  name: Deploy Staging
  needs: build-web
  if: github.ref == 'refs/heads/staging' && github.event_name == 'push'
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to staging channel
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        channelId: staging
        expires: 30d
```

### Change 2: Keep production manual approval
```yaml
deploy-production:
  name: Deploy Production
  needs: build-web
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  environment:
    name: production  # ← This requires manual approval
```

### Change 3: Branch protection rules
```bash
# Via GitHub Settings → Branches → Add rule
gh api repos/PD2015/wildfire_mvp_v3/branches/main/protection \
  --method PUT \
  --field 'required_pull_request_reviews=null' \
  --field 'required_status_checks[strict]=true' \
  --field 'required_status_checks[contexts][]=Quality Gates' \
  --field 'enforce_admins=true'
```

---

## 🎓 Team Training Checklist

### For all developers:
- [ ] Read this document
- [ ] Practice local merge workflow
- [ ] Test staging environment validation
- [ ] Understand rollback procedures

### For release managers:
- [ ] Access to Firebase console
- [ ] GitHub approval permissions
- [ ] Monitoring dashboard access
- [ ] Emergency contact list

---

## 📚 Related Documentation

- **API Key Setup**: `docs/API_KEY_SETUP.md`
- **Security Controls**: `docs/MULTI_LAYER_SECURITY_CONTROLS.md`
- **Worktree Workflow**: `docs/WORKTREE_WORKFLOW.md`
- **Testing Guide**: `docs/TEST_COVERAGE.md`

---

**Last Updated**: 2025-11-01  
**Owner**: Engineering Team  
**Review**: After any deployment issue or quarterly
