# How to Prevent API Key Leaks (For Developers & AI Assistants)

**Date**: 2025-10-29  
**Purpose**: Multi-layer defense strategy to prevent API keys from being committed to git

> **📖 Documentation Structure**:
> - **This file** (human guide) - Comprehensive prevention guide for developers
> - **`.github/copilot-instructions.md`** (AI agent rules) - GitHub Copilot reads this automatically
> - **`docs/SECURITY_*.md`** - Supporting security documentation (audit reports, incident response, etc.)

---

## 🎯 The Problem

API keys can be leaked in multiple ways:
1. **Direct commits**: Hardcoding keys in source files
2. **Documentation**: Including real keys in tutorials/examples
3. **AI assistants**: LLMs creating files with keys from context
4. **Accidental staging**: Adding ignored files to git

---

## 🛡️ 8-Layer Defense Strategy (Already Implemented)

### Layer 1: Pre-Commit Hook ✅
**Location**: `.git/hooks/pre-commit`  
**What it does**: Scans staged files for 6 types of secrets before commit
**Version**: 2.0 (2025-10-29)

**Patterns Detected**:
- Google Maps API keys: `AIzaSy[33 chars]`
- AWS keys: `AKIA[16 chars]`
- GitHub tokens: `ghp_[36 chars]`, `github_pat_[82 chars]`
- Private keys: `BEGIN PRIVATE KEY`, `BEGIN RSA PRIVATE KEY`
- Generic secrets: `api_key`, `secret_key`, `password` with values
- JWT tokens: `eyJ[base64]`

**How to verify it's working**:
```bash
# Check hook is installed
ls -la .git/hooks/pre-commit

# View hook audit log
tail -20 .git/hooks/pre-commit.log
```

---

### Layer 2: Pre-Push Hook ✅
**Location**: `.git/hooks/pre-push`  
**What it does**: Runs gitleaks scan before pushing to remote

**How to test**:
```bash
# This will block if secrets detected
git push origin my-branch
```

---

### Layer 3: CI/CD Gitleaks Scan ✅
**Location**: `.github/workflows/flutter.yml` (step: "Secret scan with gitleaks")  
**What it does**: Scans all commits in PR/push for secrets  
**Blocks**: Deployment if secrets found

**How to check**:
```bash
# View latest CI run
gh run list --limit 1

# Check specific run for gitleaks results
gh run view <run-id> --log | grep "gitleaks"
```

---

### Layer 4: .gitignore ✅
**Location**: `.gitignore`  
**What it does**: Prevents committing files containing secrets

**Protected Files**:
```gitignore
# API keys and secrets
env/dev.env.json
env/prod.env.json
.env
.env.*

# Platform-specific secrets
android/local.properties
ios/Runner/GoogleService-Info.plist

# Build outputs (may contain injected keys)
build/
.dart_tool/
```

**How to verify**:
```bash
# Check what's gitignored
git check-ignore -v env/dev.env.json
```

---

### Layer 5: .gitleaksignore ✅
**Location**: `.gitleaksignore`  
**What it does**: Allows specific false positives (rotated keys in docs)

**Current Entries**:
- `docs/SECURITY_NOTICE.md` - Old rotated key (documentation only)
- Platform config files - Old rotated keys (already replaced)
- Test scripts - Mock/example keys (not real secrets)

**When to use**:
- ONLY for keys that are already rotated/deleted
- NEVER for active keys

---

### Layer 6: Documentation Guidelines ✅
**Location**: `docs/SECURITY_DOCUMENTATION_GUIDELINES.md`

**Rules**:
1. ❌ **NEVER** include literal API keys in documentation
2. ✅ Always use placeholders: `YOUR_API_KEY_HERE`, `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
3. ✅ Show file paths where keys belong: `env/dev.env.json`
4. ✅ Reference security controls, don't duplicate keys

**Examples**:

❌ **BAD**:
```markdown
# Setup
Add your API key to `env/dev.env.json`:
```json
{
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_WEB_API_KEY_HERE"
}
```

✅ **GOOD**:
```markdown
# Setup
Add your API key to `env/dev.env.json`:
```json
{
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_WEB_API_KEY_HERE"
}
```

See `env/dev.env.json.template` for the full structure.
```

---

### Layer 7: GitHub Secrets ✅
**Location**: GitHub repo → Settings → Secrets and variables → Actions

**Protected Secrets**:
- `GOOGLE_MAPS_API_KEY_WEB_PREVIEW` (updated 2025-10-27)
- `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION` (updated 2025-10-28)
- `FIREBASE_SERVICE_ACCOUNT`
- `FIREBASE_PROJECT_ID`

**How to manage**:
```bash
# List secrets (only shows names, not values)
gh secret list

# Set/update secret
gh secret set GOOGLE_MAPS_API_KEY_WEB_PRODUCTION --body "new_key_here"

# Delete secret
gh secret delete OLD_SECRET_NAME
```

---

### Layer 8: Audit Logging ✅
**Location**: `.git/hooks/pre-commit.log`

**What it logs**:
- Timestamp of each commit attempt
- User name and email
- Files scanned
- Secrets detected (pattern only, not actual key)

**How to review**:
```bash
# View recent commits
tail -50 .git/hooks/pre-commit.log

# Search for blocked commits
grep "ERROR" .git/hooks/pre-commit.log
```

---

## 🤖 Specific Guidance for AI Assistants (GitHub Copilot, Claude, etc.)

### What AI Assistants Should Do:

1. **Never Include Real API Keys**
   - Use placeholders: `YOUR_API_KEY_HERE`, `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
   - Reference where keys should be: "Add your key to `env/dev.env.json`"

2. **Check Context Before Writing**
   - If you see an API key in chat/context, use a placeholder in files
   - If creating documentation, always use safe examples

3. **Verify Before Committing**
   - Run `git diff` to check for accidental keys
   - Scan your generated files: `grep -r "AIzaSy[A-Za-z0-9_-]{33}" .`

4. **Use Template Files**
   - Reference `env/dev.env.json.template` instead of real `env/dev.env.json`
   - Copy templates, don't expose actual config files

### Example AI Prompt Template:

```
When creating files or documentation:
1. Use placeholders for ALL API keys (YOUR_API_KEY_HERE, AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)
2. Reference where keys belong (env/dev.env.json) without showing actual values
3. If you see a real API key in context, replace it with a placeholder in generated files
4. Never commit files from env/ directory
```

---

## 🧪 Testing Your Defense Layers

### Test 1: Pre-Commit Hook
```bash
# Create test file with fake key
echo "const key = 'AIzaSyTestKey12345678901234567890123';" > test_key.dart

# Try to commit (should be blocked)
git add test_key.dart
git commit -m "test: intentional API key"
# Expected: ❌ ERROR: Google Maps API key detected!

# Clean up
rm test_key.dart
git reset HEAD test_key.dart
```

### Test 2: Gitleaks CI Scan
```bash
# Push to a test branch
git checkout -b test/security-check
echo "key: AIzaSyTestKey12345678901234567890123" > test.md
git add test.md
git commit -m "test: security scan"
git push origin test/security-check

# Check CI (should fail on gitleaks)
gh run list --branch test/security-check --limit 1

# Clean up
git checkout main
git branch -D test/security-check
git push origin --delete test/security-check
```

### Test 3: .gitignore
```bash
# Try to add ignored file
git add env/dev.env.json
# Expected: The following paths are ignored by one of your .gitignore files

# Verify gitignore
git check-ignore -v env/dev.env.json
```

---

## 🚨 What to Do If a Key Leaks

**Immediate Actions** (within 1 hour):

1. **Rotate the key immediately**
   ```bash
   # Go to Google Cloud Console → Credentials
   # Delete or restrict the exposed key
   # Generate a new key
   ```

2. **Update all locations**
   - Local: `env/dev.env.json`
   - GitHub Secrets: `gh secret set GOOGLE_MAPS_API_KEY_WEB_PRODUCTION`
   - Team members: Share new key securely (1Password, etc.)

3. **Remove from git history** (if committed)
   ```bash
   # Use BFG Repo-Cleaner or git-filter-repo
   # See docs/SECURITY_NOTICE.md for detailed steps
   ```

4. **Document the incident**
   - Create `docs/SECURITY_INCIDENT_RESPONSE_YYYY-MM-DD.md`
   - Log: what happened, when, how you responded, lessons learned

---

## 📋 Daily Checklist for Developers

- [ ] Pre-commit hook installed: `ls -la .git/hooks/pre-commit`
- [ ] .gitignore covers secrets: `git check-ignore -v env/dev.env.json`
- [ ] No keys in documentation: `grep -r "AIzaSy[A-Za-z0-9_-]{33}" docs/`
- [ ] GitHub Secrets up to date: `gh secret list`
- [ ] CI passing gitleaks check: `gh run list --limit 1`

---

## 📚 Additional Resources

- **API Key Setup Guide**: `docs/API_KEY_SETUP.md`
- **Security Checklist**: `docs/API_KEY_SECURITY_CHECKLIST.md`
- **Incident Response**: `docs/SECURITY_INCIDENT_RESPONSE_2025-10-29.md`
- **Multi-Layer Defense**: `docs/MULTI_LAYER_SECURITY_CONTROLS.md`
- **Documentation Guidelines**: `docs/SECURITY_DOCUMENTATION_GUIDELINES.md`

---

## ✅ Summary: How to Stop API Key Leaks

**For Humans**:
1. Install git hooks: `.git/hooks/pre-commit`, `.git/hooks/pre-push`
2. Never commit `env/dev.env.json`
3. Use placeholders in docs
4. Review `git diff` before committing

**For AI Assistants**:
1. Always use placeholders in generated files
2. Never copy real keys from context to files
3. Reference `env/dev.env.json.template`, not actual config
4. Scan your generated code: `grep -r "AIzaSy[A-Za-z0-9_-]{33}" .`

**For CI/CD**:
1. Gitleaks scan in pipeline
2. Secrets in GitHub Secrets, never in code
3. Build-time key injection (`scripts/build_web.sh`)

---

**Last Updated**: 2025-10-29  
**Next Security Audit**: 2025-01-29 (90 days)
