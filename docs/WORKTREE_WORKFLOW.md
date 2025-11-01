---
title: Git Worktree Workflow
status: active
last_updated: 2025-10-30
category: explanation
subcategory: development
related:
  - GITLEAKS_CONFIGURATION.md
  - guides/security/api-key-management.md
---

# Git Worktree Workflow for Multi-Agent Development

## Overview
This guide explains how to use git worktrees for parallel development with multiple agent instances.

## Current Repository State

**Main worktree**: `/Users/lizstevenson/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3`

**Active branches**:
- `main` - Production branch
- `014-a12b-report-fire` - Current feature work
- `a12b` - Alias for `014-a12b-report-fire` (for convenience)

## Creating a New Worktree

### For a new feature branch:
```bash
# Create worktree with new branch
git worktree add ../wildfire_mvp_v3_feature-name -b feature-name

# Example: Create worktree for map improvements
git worktree add ../wildfire_mvp_v3_map-improvements -b map-improvements
```

### For working on existing branch:
```bash
# Create worktree from existing branch
git worktree add ../wildfire_mvp_v3_branch-name branch-name

# Example: Create worktree for a12b work
git worktree add ../wildfire_mvp_v3_a12b a12b
```

## Multi-Agent Workflow Pattern

### Scenario: Two agents working on different features

**Agent 1 (Main worktree)**: Working on Report Fire feature
```bash
cd ~/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3
git checkout 014-a12b-report-fire
# Agent 1 makes changes...
```

**Agent 2 (New worktree)**: Working on Map improvements
```bash
cd ~/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter
git worktree add wildfire_mvp_v3_map-improvements -b map-improvements
cd wildfire_mvp_v3_map-improvements
# Agent 2 makes changes...
```

### Benefits:
- ✅ Each agent has isolated working directory
- ✅ No branch switching conflicts
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

### 1. **Naming Convention**
Use descriptive suffixes for worktree directories:
```
wildfire_mvp_v3          # Main worktree
wildfire_mvp_v3_a12b     # Feature: Report Fire
wildfire_mvp_v3_map      # Feature: Map improvements
wildfire_mvp_v3_cache    # Feature: Cache optimization
```

### 2. **One Branch Per Worktree**
- Never check out the same branch in multiple worktrees
- Git prevents this to avoid conflicts

### 3. **Cleanup After Merge**
```bash
# After feature is merged to main
git worktree remove ../wildfire_mvp_v3_feature-name
git branch -d feature-name
```

### 4. **Environment Variables**
Each worktree can have its own environment:
```bash
# In worktree 1: Use mock data
cd wildfire_mvp_v3
flutter run --dart-define-from-file=env/dev.env.json

# In worktree 2: Use live data
cd wildfire_mvp_v3_map
flutter run --dart-define-from-file=env/prod.env.json
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
