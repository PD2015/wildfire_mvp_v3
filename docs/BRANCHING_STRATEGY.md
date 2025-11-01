---
title: Branching Strategy & Workflow
status: active
last_updated: 2025-11-01
category: guides
subcategory: workflow
related:
  - CI_CD_WORKFLOW_GUIDE.md
  - WORKTREE_WORKFLOW.md
---

# Branching Strategy & Workflow

**Last Updated**: 1 November 2025  
**Repository**: PD2015/wildfire_mvp_v3  
**Default Branch**: `staging`

---

## 📋 Branch Structure

```
main (production)
  ↑
  └── staging (integration/testing)
        ↑
        └── feature/XXX-aXX-feature-name (development)
```

### Branch Purposes

| Branch | Purpose | Auto-Deploy | Approval Required |
|--------|---------|-------------|-------------------|
| **feature/** | Development work | PR Preview (7d) | No |
| **staging** | Integration testing | staging.web.app (90d) | No |
| **main** | Production | web.app | ✅ Yes |

---

## 🚀 Standard Workflow

### 1. Create Feature Branch

```bash
# From staging branch
git checkout staging
git pull origin staging

# Create feature branch
git checkout -b 015-a12b-my-feature
```

### 2. Develop & Test Locally

```bash
# Make changes
# ... edit files ...

# Test locally
flutter test
dart format lib/ test/
flutter analyze

# Commit
git add .
git commit -m "feat(a12b): implement my feature"
```

### 3. Push & Create PR to Staging

```bash
# Push feature branch
git push origin 015-a12b-my-feature

# Create PR targeting staging (default)
gh pr create \
  --title "feat(a12b): implement my feature" \
  --body "Description of changes"

# Or explicitly specify staging
gh pr create --base staging \
  --title "feat(a12b): implement my feature" \
  --body "Description of changes"
```

**What happens**:
- ✅ CI runs (quality gates, tests, build)
- ✅ Preview deploys: `pr-X-hash.web.app` (7 days)
- ✅ Test preview deployment (soft-fail)

### 4. Test Preview & Merge to Staging

```bash
# After preview testing passes
gh pr merge <number> --squash --delete-branch
```

**What happens**:
- ✅ Feature merged to staging
- ✅ Auto-deploys to: `staging.web.app` (90 days)
- ✅ No manual approval needed
- ✅ Available for longer-term testing

### 5. Promote Staging to Production

```bash
# Create PR from staging to main
gh pr create --base main --head staging \
  --title "chore: promote staging to production" \
  --body "Includes features: A12b, A13, A14"

# After approval, merge
gh pr merge <number> --merge
```

**What happens**:
- ✅ CI runs on main
- ⏸️ **Waits for manual approval**
- ✅ Deploy to production after approval
- ✅ Production URL: `web.app`

---

## 🔒 Branch Protection Rules

### Main Branch Protection

**Settings** (GitHub → Settings → Branches → main):
- ✅ Require pull request before merging
- ✅ Require approvals: 1
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Restrict pushes (only from staging)

**Why**: Prevents accidental direct merges to production

### Staging Branch Protection

**Settings** (GitHub → Settings → Branches → staging):
- ✅ Require pull request before merging
- ✅ Require status checks to pass
- ❌ No approval required (for velocity)

**Why**: Allows fast iteration while enforcing quality gates

---

## 🎯 Common Scenarios

### Scenario 1: Hotfix for Production

```bash
# Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-issue

# Make fix, test, commit
# ... changes ...
git commit -m "fix: critical production issue"

# Push and create PR to main
git push origin hotfix/critical-issue
gh pr create --base main \
  --title "fix: critical production issue" \
  --body "Emergency hotfix bypassing staging"

# After approval, merge
gh pr merge <number> --squash

# Backport to staging
git checkout staging
git merge main
git push origin staging
```

### Scenario 2: Multiple Features in Parallel

```bash
# Use worktrees for parallel development
git worktree add ~/wildfire_a12b 015-a12b-feature-one
git worktree add ~/wildfire_a13 016-a13-feature-two

# Work in parallel
cd ~/wildfire_a12b  # Work on A12b
cd ~/wildfire_a13   # Work on A13

# Each creates its own PR to staging
# Each gets its own preview URL
```

### Scenario 3: Accidentally Created PR to Main

```bash
# Change PR base to staging
gh pr edit <number> --base staging

# PR will re-run CI and re-deploy preview
```

---

## 🚨 Anti-Patterns (Don't Do This)

❌ **Don't push directly to main**
```bash
git checkout main
git push origin main  # BLOCKED by branch protection
```

❌ **Don't merge feature → main directly**
```bash
gh pr create --base main  # Should go to staging first
```

❌ **Don't skip staging for non-emergency changes**
```bash
# BAD: Feature bypassing integration testing
gh pr create --base main --head feature/new-thing

# GOOD: Feature goes through staging first
gh pr create --base staging --head feature/new-thing
```

❌ **Don't merge staging → main without testing**
```bash
# Test staging.web.app FIRST before promoting to main
```

---

## 📊 Quick Reference

### Create Feature PR (Default Flow)
```bash
git checkout -b 015-a12b-feature
# ... develop ...
git push origin 015-a12b-feature
gh pr create  # Targets staging by default ✅
```

### Promote to Production
```bash
gh pr create --base main --head staging
# Wait for approval → Deploy to production
```

### Check Current Branch Protection
```bash
# Main branch
gh api repos/PD2015/wildfire_mvp_v3/branches/main/protection

# Staging branch
gh api repos/PD2015/wildfire_mvp_v3/branches/staging/protection
```

### View Repository Settings
```bash
# Default branch
gh repo view --json defaultBranchRef

# All branches
git branch -a
```

---

## 🔧 Troubleshooting

### "Why did my PR go to main?"

**Before Nov 1, 2025**: Default branch was `main`  
**After Nov 1, 2025**: Default branch changed to `staging`

**Fix**: `gh pr edit <number> --base staging`

### "Can I merge feature → main directly?"

**Only for emergencies** (hotfixes). Normal flow is:
```
feature → staging (test) → main (production)
```

### "How do I skip staging?"

**Don't.** Staging exists to catch issues before production. If staging is working well, promote it to main. If you need a hotfix, create from `main` branch.

---

## 📚 Related Documentation

- [CI/CD Workflow Guide](CI_CD_WORKFLOW_GUIDE.md)
- [Worktree Workflow](WORKTREE_WORKFLOW.md)
- [Preview Deployment Testing](guides/testing/preview-deployment-testing.md)
- [Firebase Deployment](FIREBASE_DEPLOYMENT.md)

---

**Last Updated**: 1 November 2025  
**Maintainer**: WildFire MVP Team
