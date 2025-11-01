---
title: 3-Tier Deployment Environment Strategy
status: active
last_updated: 2025-11-01
category: guides
subcategory: deployment
related:
  - ../../DEPLOYMENT_WORKFLOW.md
  - ../../DEPLOYMENT_DIAGRAMS.md
---

# 3-Tier Deployment Environment Strategy

## Overview

WildFire MVP uses a **3-tier deployment strategy** to ensure code quality and safety before reaching production users.

## The Three Tiers

### TIER 1: PR Preview Channels (Code Review)
**Purpose**: Test individual features in isolation during code review

**URL Pattern**: `pr-{number}-wildfire-app-e11f8.web.app`

**Lifecycle**:
- Created automatically when you create a PR
- Expires after 7 days
- Deleted when PR is closed/merged

**Trigger**: Any pull request to any branch

**Example Flow**:
```bash
# You're on feature/new-widget
git push origin feature/new-widget

# Create PR to staging
gh pr create --base staging --head feature/new-widget

# ✅ GitHub automatically deploys: pr-123-wildfire-app-e11f8.web.app
# Now reviewers can test your feature in a real environment
```

**Key Point**: The preview deploys **YOUR feature branch**, not staging. It shows what staging would look like IF your code was merged.

---

### TIER 2: Staging Environment (QA Validation)
**Purpose**: Integration testing with all merged features before production

**URL**: `wildfire-app-e11f8-staging.web.app` (or via Firebase channel URL)

**Lifecycle**:
- Permanent environment (90-day Firebase channel)
- Always reflects latest `staging` branch
- Automatically deployed on every push to `staging`

**Trigger**: Push to `staging` branch (after PR merge)

**Example Flow**:
```bash
# PR approved and merged to staging
# ✅ Staging environment auto-deploys

# QA team tests at: wildfire-app-e11f8-staging.web.app
# Test for 1-3 days, catch integration issues
```

**Key Point**: This is where you catch issues that only appear when multiple features are combined.

---

### TIER 3: Production (Live Users)
**Purpose**: Serve actual users with stable, tested code

**URL**: `wildfire-app-e11f8.web.app`

**Lifecycle**:
- Permanent environment
- Only updated after manual approval
- Reflects `main` branch

**Trigger**: Push to `main` branch (requires manual approval via GitHub Environment)

**Example Flow**:
```bash
# After QA approves staging
git checkout main
git pull origin main
git merge staging  # Test locally first!
git push origin main

# ✅ GitHub Actions waits for manual approval
# Approve deployment in GitHub UI
# ✅ Production deploys
```

**Key Point**: Manual approval gate prevents accidental production deploys.

---

## Complete Feature-to-Production Flow

```
1. DEVELOP FEATURE
   └─ feature/new-widget branch
      └─ Make changes, commit locally

2. CREATE PR (→ TIER 1: Preview)
   └─ gh pr create --base staging --head feature/new-widget
      └─ ✅ Preview deploys: pr-123-wildfire-app.web.app
      └─ Review code + test preview
      └─ Approve PR

3. MERGE TO STAGING (→ TIER 2: Staging)
   └─ GitHub merges feature → staging
      └─ ✅ Staging deploys: staging-wildfire-app.web.app
      └─ QA tests for 1-3 days
      └─ QA approves release

4. MERGE TO MAIN (→ TIER 3: Production)
   └─ git merge staging (locally)
      └─ Test locally first!
      └─ git push origin main
      └─ ✅ GitHub Actions waits for approval
      └─ Manually approve in GitHub UI
      └─ ✅ Production deploys: wildfire-app.web.app
```

## Visual Comparison

| Tier | Environment | Branch | Trigger | Approval | Lifespan | Purpose |
|------|-------------|--------|---------|----------|----------|---------|
| 1 | PR Preview | `feature/*` | PR created | None | 7 days | Code review |
| 2 | Staging | `staging` | Push to staging | None | Permanent | QA/integration |
| 3 | Production | `main` | Push to main | **Manual** | Permanent | Live users |

## Key Differences

### PR Preview vs Staging

**PR Preview**:
- ✅ Tests YOUR feature in isolation
- ✅ Shows what staging WOULD look like
- ✅ Temporary (7 days)
- ✅ One per pull request
- ❌ Not for integration testing

**Staging**:
- ✅ Tests ALL merged features together
- ✅ Always reflects current staging branch
- ✅ Permanent environment
- ✅ Only one staging environment
- ✅ For integration testing

**Both coexist!** You can have 10 PR previews (pr-1, pr-2, ..., pr-10) AND the staging environment all running at the same time.

---

## Common Questions

### Q: Do PR previews still work with the staging branch?
**A**: Yes! PR previews deploy for ANY pull request, regardless of the base branch. Create a PR to `staging`, you get a preview. Create a PR to `main` (emergency hotfix), you get a preview.

### Q: What happens to the PR preview after I merge?
**A**: It expires after 7 days (configurable in workflow). The staging environment now has your changes.

### Q: Can I create a PR directly to main?
**A**: Technically yes (for emergency hotfixes), but the recommended flow is feature → staging → main. You can configure branch protection to prevent PRs directly to main if desired.

### Q: How do I access each environment?

```bash
# PR Preview (example for PR #123)
open https://pr-123-wildfire-app-e11f8.web.app

# Staging
open https://wildfire-app-e11f8-staging.web.app

# Production
open https://wildfire-app-e11f8.web.app

# Or get URLs from GitHub Actions:
gh run view --log  # Shows deployment URLs in logs
```

### Q: What if staging and production get out of sync?
**A**: That's actually intentional! Staging should always be ahead of production (contains new features being tested). When QA approves, you merge staging → main to sync them.

---

## Safety Mechanisms

### 1. PR Previews Don't Affect Staging
Creating a PR doesn't change staging. Only merging changes staging.

### 2. Staging Auto-Deploys (Good!)
Every push to `staging` deploys automatically. This ensures QA always tests the latest code.

### 3. Production Requires Approval (Safety!)
Manual approval prevents accidental production deploys. You must explicitly approve in GitHub UI.

### 4. Local Merge Before Production
Recommended workflow: Merge `staging → main` locally, test, THEN push. This catches merge conflicts and integration issues before they reach production.

---

## Troubleshooting

### PR preview shows 404
- Check Firebase Hosting console: Is the preview channel created?
- Check GitHub Actions logs: Did the deployment succeed?
- Verify the URL format: `pr-{number}-wildfire-app-e11f8.web.app`

### Staging not deploying
- Check `.github/workflows/flutter.yml`: Is `deploy-staging` job present?
- Verify branch name: Must be exactly `staging` (not `develop`, not `stage`)
- Check GitHub Actions: Did the workflow run?

### Production deployment pending forever
- Check GitHub Environment protection rules: Manual approval required
- Go to Actions → Click the workflow run → Click "Review deployments" → Approve

---

## Next Steps

1. ✅ **COMPLETED**: Staging branch created
2. ✅ **COMPLETED**: `deploy-staging` job added to workflow
3. ⏳ **TODO**: Configure branch protection rules
4. ⏳ **TODO**: Test complete flow end-to-end
5. ⏳ **TODO**: Train team on 3-tier strategy

---

## Related Documentation

- [Deployment Workflow Guide](../../DEPLOYMENT_WORKFLOW.md) - Complete GitFlow strategy
- [Deployment Diagrams](../../DEPLOYMENT_DIAGRAMS.md) - Visual flowcharts
- [GitHub Actions Workflow](../../../.github/workflows/flutter.yml) - CI/CD configuration
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting) - Preview channels and environments
