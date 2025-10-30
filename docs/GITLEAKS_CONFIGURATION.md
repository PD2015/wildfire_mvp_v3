---
title: Gitleaks Configuration Guide
status: active
last_updated: 2025-10-30
category: guides
subcategory: security
related:
  - guides/security/api-key-management.md
  - WORKTREE_WORKFLOW.md
---

# Gitleaks Configuration Guide

## Overview

This project uses [Gitleaks](https://github.com/gitleaks/gitleaks) to prevent secrets (API keys, tokens, passwords) from being committed to the repository. Gitleaks runs in three places:

1. **Local pre-commit hook** - Scans staged files before commit
2. **GitHub Actions CI/CD** - Scans entire codebase on push
3. **Manual execution** - Can be run anytime with `gitleaks detect`

## Configuration Files

### `.gitleaks.toml` (Primary Configuration)

**Purpose**: Extends default gitleaks rules and defines path-based allowlists for build artifacts.

**Location**: Root of repository

**Key Features**:
- Extends built-in gitleaks rules (`useDefault = true`)
- Ignores build artifacts (`.dart_tool/`, `build/`, `coverage/`)
- Ignores git-ignored secret files (`env/dev.env.json`, `android/local.properties`)
- Auto-discovered by gitleaks commands

**Example**:
```toml
[extend]
useDefault = true

[[allowlists]]
description = "Ignore Flutter/Dart build artifacts"
paths = [
  '''\.dart_tool/''',
  '''build/''',
  '''coverage/''',
]
```

### `.gitleaksignore` (Specific Finding Suppression)

**Purpose**: Ignores specific findings by fingerprint (not path patterns).

**Location**: Root of repository

**Key Features**:
- Uses **fingerprints only** (format: `file:rule:line`)
- For documenting old rotated keys in security docs
- NOT for ignoring entire directories (use `.gitleaks.toml` instead)

**Example**:
```
# Old rotated key documented in security audit
docs/SECURITY_AUDIT_REPORT_2025-10-29.md:gcp-api-key:23
```

**How to get a fingerprint**:
```bash
# Run gitleaks and copy the Fingerprint from output
gitleaks detect --source . --no-git -v
# Look for: Fingerprint: path/to/file:rule-id:line
```

### `.githooks/pre-commit` (Local Hook)

**Purpose**: Runs gitleaks on staged files before allowing commit.

**Execution**: Automatic on `git commit` (can bypass with `--no-verify`)

**Command used**:
```bash
gitleaks protect --staged --redact -v
```
- `protect`: Pre-commit mode (scans unstaged changes)
- `--staged`: Only scan files in git staging area
- `--redact`: Hide secret values in output
- `-v`: Verbose output

**Auto-discovers**: `.gitleaks.toml` configuration file

### `.github/workflows/flutter.yml` (CI/CD)

**Purpose**: Runs gitleaks on entire codebase in GitHub Actions.

**Execution**: Automatic on push to any branch

**Command used**:
```yaml
uses: gitleaks/gitleaks-action@v2
with:
  args: detect --source . --no-git -v
```
- `detect`: Full scan mode
- `--source .`: Scan current directory
- `--no-git`: Scan filesystem (not git history)
- `-v`: Verbose output

**Auto-discovers**: `.gitleaks.toml` configuration file

## Why Local and Remote Were Different

### The Problem

**Before fix**:
- Local: `gitleaks protect --staged` ✅ Only scanned staged files
- Remote: `gitleaks detect --source . --no-git` ❌ Scanned ALL files including build artifacts

**Result**: 
- Local passed (no build artifacts in staged files)
- CI/CD failed (found fake secrets in `.dart_tool/chrome-device/` browser cache)

### The Solution

Created `.gitleaks.toml` with path allowlists to ignore build artifacts globally:

```toml
[[allowlists]]
paths = [
  '''\.dart_tool/''',  # Flutter tooling cache
  '''build/''',         # Build outputs
  '''coverage/''',      # Test coverage
]
```

**Result**:
- Local: Still scans only staged files (fast pre-commit)
- Remote: Scans all files but ignores build artifacts (comprehensive CI/CD)
- Both use same `.gitleaks.toml` rules

## Best Practices

### ✅ DO

1. **Use `.gitleaks.toml` for path-based ignores**
   - Build artifacts (`.dart_tool/`, `build/`)
   - IDE files (`.vscode/`, `.idea/`)
   - OS files (`.DS_Store`)

2. **Use `.gitleaksignore` for specific findings**
   - Old rotated keys in security documentation
   - Known false positives that can't be fixed

3. **Keep secrets in git-ignored files**
   - `env/dev.env.json` (local development)
   - `android/local.properties` (Android builds)
   - GitHub Secrets (CI/CD)

4. **Use placeholders in documentation**
   - `YOUR_API_KEY_HERE`
   - `YOUR_WEB_API_KEY_HERE`
   - `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` (correct length)

### ❌ DON'T

1. **Don't use glob patterns in `.gitleaksignore`**
   - ❌ `.dart_tool/**` (invalid syntax)
   - ✅ Use `.gitleaks.toml` paths instead

2. **Don't commit real API keys**
   - Even in "example" or "test" files
   - Use environment variables or git-ignored files

3. **Don't bypass pre-commit without review**
   - `git commit --no-verify` skips all checks
   - Only use when you're certain it's a false positive

4. **Don't ignore entire categories in `.gitleaksignore`**
   - Be specific with fingerprints
   - Document WHY each finding is ignored

## Testing Your Configuration

### Local Test (Full Scan)
```bash
# Scan entire codebase like CI/CD does
gitleaks detect --source . --no-git -v

# Expected: "no leaks found" (build artifacts ignored)
```

### Local Test (Pre-commit Simulation)
```bash
# Stage some files
git add file1.dart file2.dart

# Scan staged files only
gitleaks protect --staged --redact -v

# Expected: Pass if no secrets in staged files
```

### CI/CD Test
```bash
# Push to GitHub and watch CI/CD
git push origin your-branch

# Monitor in GitHub Actions
gh run list --limit 1
gh run watch <run-id>

# Expected: "Secret scan with gitleaks (C2)" passes
```

## Troubleshooting

### Local passes, CI/CD fails

**Symptom**: Pre-commit hook succeeds but GitHub Actions fails

**Cause**: CI/CD scans files not in staging area (build artifacts, etc.)

**Fix**: Add path to `.gitleaks.toml` allowlist:
```toml
[[allowlists]]
paths = ['''your/path/here/''']
```

### False positive in documentation

**Symptom**: Gitleaks detects placeholder or example code as secret

**Fix 1**: Use inline comment `gitleaks:allow`
```dart
const apiKey = "YOUR_API_KEY_HERE"; // gitleaks:allow
```

**Fix 2**: Add fingerprint to `.gitleaksignore`
```
docs/example.md:gcp-api-key:42
```

### Real secret committed accidentally

**Response**:
1. **Stop immediately** - Don't push to GitHub
2. **Remove from staging**: `git reset HEAD <file>`
3. **Move to git-ignored file**: `env/dev.env.json`
4. **If already pushed**: Rotate the key immediately
5. **See**: `docs/API_KEY_ROTATION_GUIDE.md`

## Maintenance

### Updating Rules

Gitleaks rules are updated automatically when you update the binary:
```bash
brew upgrade gitleaks  # macOS
```

GitHub Actions uses `gitleaks/gitleaks-action@v2` which auto-updates.

### Adding New Allowlists

Edit `.gitleaks.toml`:
```bash
# Add new path pattern
vim .gitleaks.toml

# Test locally
gitleaks detect --source . --no-git -v

# Commit if working
git add .gitleaks.toml
git commit -m "chore(security): add new build artifact to gitleaks allowlist"
```

### Auditing Ignored Findings

Periodically review `.gitleaksignore`:
```bash
# List all ignored fingerprints
cat .gitleaksignore | grep -v "^#" | grep -v "^$"

# Verify each entry is still valid
# Remove entries for files that no longer exist
```

## Additional Resources

- **Gitleaks Documentation**: https://github.com/gitleaks/gitleaks
- **API Key Setup**: `docs/API_KEY_SETUP.md`
- **Key Rotation**: `docs/API_KEY_ROTATION_GUIDE.md`
- **Security Audit**: `docs/SECURITY_AUDIT_REPORT_2025-10-29.md`
- **Prevention Guide**: `docs/PREVENT_API_KEY_LEAKS.md`

## Summary

| Aspect | Local Pre-commit | CI/CD GitHub Actions |
|--------|------------------|----------------------|
| **Command** | `gitleaks protect --staged` | `gitleaks detect --source . --no-git` |
| **Scope** | Staged files only | Entire filesystem |
| **Config** | `.gitleaks.toml` (auto-discovered) | `.gitleaks.toml` (auto-discovered) |
| **Ignores** | Same allowlists from `.gitleaks.toml` | Same allowlists from `.gitleaks.toml` |
| **Speed** | Fast (<1s typically) | Slower (3-5s, scans all files) |
| **Bypass** | `git commit --no-verify` | Cannot bypass |
| **Purpose** | Prevent accidental commits | Comprehensive security gate |

**Key Insight**: Both local and remote use the **same `.gitleaks.toml` configuration**, ensuring consistent secret detection rules across all environments.
