---
title: Git Worktree Workflow
status: active
last_updated: 2025-11-01
category: explanation
subcategory: development
related:
  - DEPLOYMENT_WORKFLOW.md
  - DEPLOYMENT_DIAGRAMS.md
  - GITLEAKS_CONFIGURATION.md
  - guides/security/api-key-management.md
  - guides/deployment/3-tier-deployment.md
---

# Git Worktree Workflow for Multi-Agent Development

## Overview
This guide explains how to use git worktrees for parallel development with multiple agent instances, following the 3-tier deployment strategy (PR preview → staging → production).

## Current Repository State

**Main worktree**: `/Users/lizstevenson/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3`

**Active branches**:
- `main` - Production branch (deployed to production)
- `staging` - Integration branch (deployed to staging environment)
- `014-a12b-report-fire` - Current feature work

## ⚠️ IMPORTANT: Always Branch from Staging

**All new feature branches and worktrees MUST be created from `staging`, not `main`.**

### Why Branch from Staging?
1. ✅ Start with the latest integrated code
2. ✅ PR previews show accurate comparison with staging
3. ✅ Reduces merge conflicts when merging to staging
4. ✅ Maintains proper GitFlow: feature → staging → main

### ❌ Don't Do This (Branching from main):
```bash
# WRONG: Creates branch from outdated main
git worktree add ../wildfire_mvp_v3_feature -b feature/new main
```

### ✅ Do This (Branching from staging):
```bash
# CORRECT: Creates branch from current staging
git worktree add ../wildfire_mvp_v3_feature -b feature/new staging
#                                                            ↑
#                                                    Branch from staging!
```

## Creating a New Worktree

### For a new feature branch (RECOMMENDED):
```bash
# Create worktree with new branch from staging
git worktree add ../wildfire_mvp_v3_feature-name -b feature/feature-name staging

# Example: Create worktree for map improvements from staging
git worktree add ../wildfire_mvp_v3_map-improvements -b feature/map-improvements staging

# Example: Create worktree for bug fix from staging
git worktree add ../wildfire_mvp_v3_bug-fix -b fix/location-error staging

# Example: Create worktree for documentation from staging
git worktree add ../wildfire_mvp_v3_docs -b docs/update-readme staging
```

### For working on existing branch:
```bash
# Create worktree from existing branch
git worktree add ../wildfire_mvp_v3_branch-name branch-name

# Example: Create worktree for existing feature work
git worktree add ../wildfire_mvp_v3_a12b 014-a12b-report-fire
```

## Multi-Agent Workflow Pattern

### Scenario: Two agents working on different features

**Agent 1 (Main worktree)**: Working on Report Fire feature
```bash
cd ~/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3
git checkout 014-a12b-report-fire
# Agent 1 makes changes...
git push origin 014-a12b-report-fire
# Create PR to staging
gh pr create --base staging --head 014-a12b-report-fire
```

**Agent 2 (New worktree)**: Working on Map improvements from staging
```bash
cd ~/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter
# IMPORTANT: Branch from staging
git worktree add wildfire_mvp_v3_map-improvements -b feature/map-improvements staging
cd wildfire_mvp_v3_map-improvements
# Agent 2 makes changes...
git push origin feature/map-improvements
# Create PR to staging (triggers PR preview)
gh pr create --base staging --head feature/map-improvements
```

### Complete Feature Workflow (3-Tier Strategy):
```bash
# 1. Create worktree from staging
git worktree add ../wildfire_mvp_v3_new-feature -b feature/new-widget staging
cd ../wildfire_mvp_v3_new-feature

# 2. Make changes and commit
git add .
git commit -m "feat: add new widget"
git push origin feature/new-widget

# 3. Create PR to staging (triggers PR preview)
gh pr create --base staging --title "Add new widget" --body "Implements widget feature"
# ✅ PR preview deploys to: pr-{number}-wildfire-app.web.app

# 4. After review, merge PR to staging
# ✅ Staging environment auto-deploys

# 5. QA tests staging for 1-3 days
# Check staging at: wildfire-app-e11f8-staging.web.app

# 6. After QA approval, merge staging → main
git checkout main
git pull origin main
git merge staging
git push origin main
# ✅ Manual approval required for production deployment

# 7. Cleanup worktree
cd ~/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3
git worktree remove ../wildfire_mvp_v3_new-feature
```

### Benefits:
- ✅ Each agent has isolated working directory
- ✅ No branch switching conflicts
- ✅ All features branch from latest staging code
- ✅ PR previews show accurate staging comparison
- ✅ Follows proper GitFlow: feature → staging → main
- ✅ Can run different Flutter commands simultaneously
- ✅ Shared git history (commits are visible across worktrees)

## Worktree Management

### List all worktrees:
```bash
git worktree list
```

### Remove a worktree:
```bash
# Method 1: From any worktree
git worktree remove /path/to/worktree

# Method 2: Delete directory first, then prune
rm -rf /path/to/worktree
git worktree prune
```

### Move to worktree:
```bash
git worktree move /old/path /new/path
```

## Best Practices

### 1. **Always Branch from Staging** ⚠️ CRITICAL
```bash
# CORRECT: New features branch from staging
git worktree add ../wildfire_mvp_v3_feature -b feature/name staging

# WRONG: Don't branch from main (outdated code)
git worktree add ../wildfire_mvp_v3_feature -b feature/name main  # ❌
```

### 2. **Naming Convention**
Use descriptive suffixes for worktree directories:
```
wildfire_mvp_v3                    # Main worktree (staging branch)
wildfire_mvp_v3_report-fire        # Feature: Report Fire
wildfire_mvp_v3_map-improvements   # Feature: Map improvements
wildfire_mvp_v3_cache-optimization # Feature: Cache optimization
wildfire_mvp_v3_docs-update        # Documentation work
```

### 3. **One Branch Per Worktree**
- Never check out the same branch in multiple worktrees
- Git prevents this to avoid conflicts

### 4. **Cleanup After Merge**
```bash
# After feature is merged to staging
git worktree remove ../wildfire_mvp_v3_feature-name
git branch -d feature/feature-name

# Optional: Delete remote branch after merge
git push origin --delete feature/feature-name
```

### 5. **Environment Variables**
Each worktree can have its own environment:
```bash
# In worktree 1: Use mock data
cd wildfire_mvp_v3
flutter run --dart-define-from-file=env/dev.env.json

# In worktree 2: Use live data
cd wildfire_mvp_v3_map
flutter run --dart-define-from-file=env/prod.env.json
```

### 6. **Create PRs to Staging**
Always target staging as the base branch for pull requests:
```bash
# CORRECT: PR to staging
gh pr create --base staging --head feature/name

# WRONG: Direct PR to main (bypasses staging QA)
gh pr create --base main --head feature/name  # ❌
```

### 5. **JAVA_HOME Configuration**
System-wide JAVA_HOME (already set) works across all worktrees:
```bash
# Already configured in ~/.zshrc
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH
```

## Common Commands Reference

```bash
# Status of all worktrees
git worktree list

# Create worktree for new feature
git worktree add ../wildfire_mvp_v3_feature -b feature-name

# Create worktree from existing branch
git worktree add ../wildfire_mvp_v3_branch existing-branch

# Remove worktree (must be run from different worktree)
git worktree remove /path/to/worktree

# Prune deleted worktrees from git metadata
git worktree prune

# Lock worktree (prevent removal)
git worktree lock /path/to/worktree

# Unlock worktree
git worktree unlock /path/to/worktree
```

## Integration with VS Code

### Opening Multiple Worktrees:
1. Open main worktree: `code ~/Desktop/.../wildfire_mvp_v3`
2. Open second worktree: `code ~/Desktop/.../wildfire_mvp_v3_feature`
3. Each window is independent with its own:
   - Terminal sessions
   - Extension state
   - Debug configurations

### Multi-Root Workspace (Alternative):
```json
// File -> Add Folder to Workspace (save as wildfire.code-workspace)
{
  "folders": [
    {
      "name": "Main (a12b)",
      "path": "/Users/lizstevenson/Desktop/.../wildfire_mvp_v3"
    },
    {
      "name": "Map Feature",
      "path": "/Users/lizstevenson/Desktop/.../wildfire_mvp_v3_map"
    }
  ]
}
```

## Troubleshooting

### "Fatal: branch is already checked out"
**Problem**: Trying to checkout same branch in multiple worktrees.  
**Solution**: Use different branches for each worktree.

### Worktree directory deleted manually
**Problem**: Deleted worktree folder without using `git worktree remove`.  
**Solution**: Run `git worktree prune` to clean up metadata.

### VS Code shows wrong branch
**Problem**: VS Code cache not refreshed after branch change.  
**Solution**: Close and reopen the workspace folder.

### Flutter pub cache issues
**Problem**: Multiple worktrees sharing same pub cache.  
**Solution**: This is normal and expected - pub cache is global.

## Migration Notes (2025-10-30)

### Cleanup Performed:
- ✅ Removed extra worktree: `wildfire_mvp_v3_a11-ci-cd`
- ✅ Deleted 14 merged/stale branches
- ✅ Created `a12b` alias for convenience
- ✅ Pruned stale remote tracking branches

### Remaining Structure:
```
Local branches:
- main
- 014-a12b-report-fire (current work)
- a12b (alias to 014-a12b-report-fire)

Remote branches:
- origin/main
- origin/014-a12b-report-fire
- origin/* (historical feature branches - safe to ignore)
```

### Future Workflow:
1. **Main branch**: Production-ready code
2. **Feature branches**: Created as needed via worktrees
3. **Clean up**: Delete feature branches after merging to main

## See Also
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Project CI/CD Guide](./CI_CD_WORKFLOW_GUIDE.md)
- [Security Guidelines](./PREVENT_API_KEY_LEAKS.md)
