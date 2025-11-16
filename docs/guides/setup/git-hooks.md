---
title: Git Hooks Setup Guide
status: active
last_updated: 2025-11-16
category: guides
subcategory: setup
related:
  - ../PREVENT_API_KEY_LEAKS.md
  - ../MULTI_LAYER_SECURITY_CONTROLS.md
---

# Git Hooks Setup Guide

## Overview

This project uses **tracked git hooks** in `.githooks/` to enforce code quality and security checks before every commit. These hooks prevent API key leaks, ensure code formatting, and run static analysis.

## Quick Setup

### Main Workspace Setup

```bash
# From project root
./scripts/setup-git-hooks.sh
```

This configures git to use `.githooks/` directory instead of the default `.git/hooks/`.

### Docker Workspace Setup

```bash
# From wildfire-agents directory
~/projects/wildfire-agents/init-docker-workspace.sh
```

This configures **all** Docker agent workspaces (wildfire-agent-a/b/c/d) at once.

## What Gets Checked

The pre-commit hook runs three checks on every commit:

### 1. Code Formatting (Auto-fix)
```bash
dart format .
```
- Automatically formats all Dart files
- Re-stages formatted files
- Ensures consistent code style

### 2. Static Analysis
```bash
flutter analyze --staged-files
```
- Checks for code quality issues
- Detects potential bugs
- Enforces linting rules
- **Blocks commit** if analysis fails

### 3. Secret Detection (Multi-layer)

#### Layer 1: Gitleaks (Primary)
```bash
gitleaks protect --staged --redact -v
```
- Scans for 100+ secret patterns
- Google Maps API keys: `AIzaSy[33 chars]`
- AWS keys: `AKIA[16 chars]`
- GitHub tokens: `ghp_[36+ chars]`
- Private keys, passwords, tokens

#### Layer 2: Documentation Protection
- Extra strict checking for markdown/text files
- Blocks real API keys even in code blocks
- Allows placeholders: `YOUR_API_KEY_HERE`, `AIzaSyXXXXX...`

#### Layer 3: Fallback Pattern Matching
- Used if gitleaks not installed
- Basic pattern detection for common secrets
- Checks for git-ignored files being staged

## Architecture: Single Source of Truth

### Why `.githooks/` Instead of `.git/hooks/`?

**Problem with `.git/hooks/`:**
- ❌ Not tracked in git (each developer has different hooks)
- ❌ No version control
- ❌ Manual setup required
- ❌ Inconsistent across team

**Solution: `.githooks/` (tracked)**
- ✅ Version controlled (team consistency)
- ✅ Updated via git pull
- ✅ Single source of truth
- ✅ One-time setup per workspace

### Configuration Mechanism

Git needs to be told to use `.githooks/` instead of `.git/hooks/`:

```bash
git config core.hooksPath .githooks
```

This is a **per-repository setting** stored in `.git/config`:

```ini
[core]
    hooksPath = .githooks
```

## Setup Verification

### Check Current Configuration

```bash
# Should output: .githooks
git config core.hooksPath
```

### Test Pre-commit Hook

```bash
# Create a file with a fake API key (placeholder format)
echo "const key = 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';" > test_secret.dart
git add test_secret.dart

# Try to commit (should be blocked)
git commit -m "test"

# Clean up
git reset HEAD test_secret.dart
rm test_secret.dart
```

Expected output:
```
🔍 Running dart format...
✅ Code formatting complete

🔍 Running flutter analyze...
✅ Static analysis passed

🔍 Checking for secrets with gitleaks...
❌ Gitleaks found secrets in staged files!
```

## Bypassing Hooks (Emergency Use Only)

If you have a **verified false positive**:

```bash
git commit --no-verify -m "your message"
```

⚠️ **WARNING:** Only use `--no-verify` if you're certain there are no secrets. All commits are reviewed in CI/CD.

## Troubleshooting

### Hooks Not Running

**Symptom:** Commits succeed without showing hook output

**Diagnosis:**
```bash
git config core.hooksPath
# If empty or not ".githooks", hooks aren't configured
```

**Fix:**
```bash
./scripts/setup-git-hooks.sh
```

### "Gitleaks Not Found" Warning

**Symptom:** Hook shows "⚠️  Gitleaks not installed, using basic pattern matching..."

**Fix (macOS):**
```bash
brew install gitleaks
```

**Fix (Linux):**
```bash
# Download from https://github.com/gitleaks/gitleaks/releases
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

### Flutter Analyze Fails in Worktree

**Symptom:** "version is 0.0.0-unknown" error

**Fix:** Hook automatically falls back to `dart analyze` for staged files.

### Docker Workspace Hooks Not Running

**Symptom:** Commits from Docker containers don't trigger hooks

**Diagnosis:**
```bash
cd ~/projects/wildfire-agents/wildfire-agent-b
git config core.hooksPath
# If empty, hooks not configured
```

**Fix:**
```bash
~/projects/wildfire-agents/init-docker-workspace.sh
```

## Docker Workspace Details

### Why Docker Workspaces Need Separate Setup

Docker containers mount the repository as **separate git workspaces**:
- `~/Desktop/wildfire_mvp_v3` - Main workspace
- `~/projects/wildfire-agents/wildfire-agent-a` - Docker agent A
- `~/projects/wildfire-agents/wildfire-agent-b` - Docker agent B
- `~/projects/wildfire-agents/wildfire-agent-c` - Docker agent C
- `~/projects/wildfire-agents/wildfire-agent-d` - Docker agent D

Each has its own `.git/config` file, so `core.hooksPath` must be set per workspace.

### Automatic Setup for New Containers

Add to Docker entrypoint or initialization script:

```bash
#!/bin/bash
# Container startup script

# Configure git hooks
git config core.hooksPath .githooks

# Rest of container setup...
```

## Hook Customization

### Adding New Checks

Edit `.githooks/pre-commit`:

```bash
#!/bin/sh

# Existing checks...

echo ""
echo "🔍 Running custom check..."
# Your custom validation here
```

### Adjusting Patterns

Edit `.gitleaksignore` to whitelist false positives:

```
# Allow specific test fixture
test/fixtures/api_response.json:AIzaSyTESTFIXTURE123456789
```

## CI/CD Integration

Pre-commit hooks are the **first line of defense**. CI/CD provides **second layer**:

1. **Local:** Pre-commit hooks (fast, immediate feedback)
2. **CI:** GitHub Actions workflows (comprehensive, enforced)

Even if hooks are bypassed locally, CI will catch issues.

## Security Incident Response

If a secret is committed despite hooks:

1. **Rotate the secret immediately** (Google Cloud Console, AWS Console, etc.)
2. **Remove from git history** (use `git filter-branch` or BFG Repo Cleaner)
3. **Investigate why hooks didn't catch it**
4. **Update `.gitleaksignore` or hook patterns** if needed

See: `docs/runbooks/incident-response/security-incidents.md`

## Related Documentation

- **API Key Management:** `docs/PREVENT_API_KEY_LEAKS.md`
- **Security Architecture:** `docs/MULTI_LAYER_SECURITY_CONTROLS.md`
- **Security Audit Report:** `docs/SECURITY_AUDIT_REPORT_2025-10-29.md`
- **Incident Response:** `docs/runbooks/incident-response/security-incidents.md`
