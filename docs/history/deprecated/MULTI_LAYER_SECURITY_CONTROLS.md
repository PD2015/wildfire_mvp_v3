# 🛡️ Multi-Layer Security Controls

**Version**: 2.0 (2025-10-29)  
**Purpose**: Prevent API keys and secrets from entering git repository  
**Principle**: "Keys should NEVER be written down" - Defense in depth

## 🔴 Incident That Led to These Controls

**What Happened:**
- **Date**: 2025-10-20
- **Issue**: API key committed to `docs/SECURITY_NOTICE.md` (commit `b5d9310`)
- **Root Cause**: Pre-commit hook wasn't installed yet (added 8 days later on 2025-10-28)
- **Key Finding**: Documentation about security incident **included the literal key** it was documenting

**Lessons Learned:**
1. ❌ **Never include literal keys** - even in security incident reports
2. ❌ **Security tooling must exist BEFORE first commit** - not added retroactively
3. ❌ **Single layer defense is insufficient** - hooks can be bypassed with `--no-verify`
4. ✅ **Multiple layers required** - local hooks + CI checks + documentation guidelines + branch protection

## 🎯 8-Layer Defense Strategy

### Layer 1: Pre-Commit Hook (Local - Instant)
**Status**: ✅ Installed (Version 2.0)  
**Location**: `.git/hooks/pre-commit`  
**Checks**:
- Google Maps API keys (`AIzaSy[33 chars]`)
- AWS keys (`AKIA`, `ASIA`)
- GitHub tokens (`ghp_`, `gho_`, etc.)
- Private keys (`BEGIN...PRIVATE KEY`)
- Secret files (`env/dev.env.json`, `android/local.properties`)
- Documentation files (stricter checks for `.md`, `.txt`)

**Features**:
- 6 scanning layers
- Audit logging to `.git/hooks/pre-commit.log`
- Color-coded output
- Helpful fix instructions
- Can bypass with `--no-verify` (logged)

**Test**:
```bash
# Should block this:
echo "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" > test.txt
git add test.txt
git commit -m "test"  # ❌ BLOCKED

# Should allow this:
echo "AIzaSy___PLACEHOLDER_KEY_HERE___" > test.txt
git add test.txt
git commit -m "test"  # ✅ ALLOWED
```

### Layer 2: Pre-Push Hook (Local - Before Remote)
**Status**: ✅ Installed (Version 1.0)  
**Location**: `.git/hooks/pre-push`  
**Purpose**: Last chance to catch secrets before they reach GitHub

**Checks**:
- Runs `gitleaks detect` on all commits being pushed
- Catches secrets missed by pre-commit (if bypassed)

**Requirements**:
```bash
# Install gitleaks
brew install gitleaks
```

**Test**:
```bash
# Bypass pre-commit but pre-push catches it
git commit --no-verify -m "test"
git push  # ❌ BLOCKED by pre-push hook
```

### Layer 3: CI Gitleaks Scan (GitHub Actions - Required)
**Status**: ✅ Active  
**Location**: `.github/workflows/flutter.yml`  
**Purpose**: Server-side secret scanning (can't be bypassed)

**Features**:
- Runs on every push/PR
- Uses `.gitleaksignore` for known rotated keys
- Blocks merge if secrets found
- Part of constitutional gates (Phase 1)

**Bypass Protection**:
- Runs on GitHub servers (developers can't disable)
- Required status check (must pass before merge)

### Layer 4: Documentation Guidelines (Education)
**Status**: ✅ Created  
**Location**: `docs/SECURITY_DOCUMENTATION_GUIDELINES.md`  
**Purpose**: Teach team to document securely

**Key Rules**:
- ❌ Never include literal keys (even rotated ones)
- ✅ Reference commits instead: "Key in commit abc123"
- ✅ Use placeholders: `YOUR_KEY_HERE`, `PLACEHOLDER`
- ✅ Link to key management: "See env/dev.env.json"

**Example Good vs Bad**:
```markdown
# ❌ BAD
The exposed key was: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# ✅ GOOD
API key exposed in commit b5d9310 (rotated on 2025-10-20).
See docs/API_KEY_SETUP.md for current key location.
```

### Layer 5: Branch Protection Rules (GitHub - Server-Side)
**Status**: ⏳ TO BE CONFIGURED  
**Required Settings**:

```yaml
Repository Settings → Branches → Branch protection rules for `main`:
☑ Require a pull request before merging
  ☑ Require approvals (1 minimum)
☑ Require status checks to pass before merging
  ☑ Require branches to be up to date
  ☑ Status checks that are required:
    - constitutional-gates
    - gitleaks
☑ Require signed commits
☑ Include administrators (no one can bypass)
☑ Require linear history
```

**Configuration**:
```bash
# Via GitHub CLI
gh api repos/PD2015/wildfire_mvp_v3/branches/main/protection \
  --method PUT \
  --field 'required_status_checks[strict]=true' \
  --field 'required_status_checks[contexts][]=constitutional-gates' \
  --field 'required_status_checks[contexts][]=gitleaks' \
  --field 'required_pull_request_reviews[required_approving_review_count]=1' \
  --field 'enforce_admins=true' \
  --field 'required_linear_history=true'
```

### Layer 6: Audit Trail & Monitoring (Observability)
**Status**: ✅ Implemented  
**Locations**:
- `.git/hooks/pre-commit.log` - Local commit attempts
- GitHub Actions logs - CI scan results
- `.gitleaksignore` - Known rotated keys

**Log Format**:
```
[2025-10-29 12:34:56 UTC] Pre-commit hook executed by John Doe <john@example.com>
[2025-10-29 12:34:57 UTC] PASSED: No issues found
```

**Monitoring**:
```bash
# Check recent commit attempts
tail -20 .git/hooks/pre-commit.log

# Find blocked commits
grep "BLOCKED" .git/hooks/pre-commit.log

# Check CI failures
gh run list --workflow="Flutter CI/CD" --status=failure | grep gitleaks
```

### Layer 7: Regular Security Audits (Scheduled)
**Status**: ⏳ TO BE SCHEDULED  
**Frequency**: Monthly (first Monday)  
**Owner**: Security Lead

**Audit Checklist**:
```bash
# 1. Scan entire git history
gitleaks detect --source . --log-opts="--all" --verbose

# 2. Check .gitleaksignore is up to date
cat .gitleaksignore
# Verify all fingerprints are for rotated keys

# 3. Review pre-commit log
grep "BLOCKED" .git/hooks/pre-commit.log
# Investigate any --no-verify bypasses

# 4. Verify hooks are installed on all workspaces
ls -la .git/hooks/pre-commit .git/hooks/pre-push

# 5. Check branch protection rules
gh api repos/PD2015/wildfire_mvp_v3/branches/main/protection

# 6. Review GitHub Secrets expiry
gh secret list

# 7. Test hooks with dummy secrets
echo "test-AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" > /tmp/test.txt
git add /tmp/test.txt
git commit -m "test"  # Should be blocked
git reset HEAD~1
```

**Audit Report Template**:
```markdown
# Security Audit - [DATE]

## Summary
- Secrets scanned: [N commits]
- Hooks status: [OK/Issues]
- Branch protection: [Enabled/Disabled]
- Known issues: [Count]

## Findings
1. [Finding 1]
2. [Finding 2]

## Actions Required
- [ ] [Action 1]
- [ ] [Action 2]

## Sign-off
Auditor: [Name]
Date: [Date]
```

### Layer 8: Team Training & Onboarding (Human Layer)
**Status**: ✅ Documentation Created  
**Required Reading**:
1. `docs/SECURITY_DOCUMENTATION_GUIDELINES.md` (must read)
2. `docs/API_KEY_SETUP.md` (setup guide)
3. `docs/MULTI_LAYER_SECURITY_CONTROLS.md` (this document)

**Onboarding Checklist for New Developers**:
```markdown
- [ ] Read security documentation (above 3 files)
- [ ] Install git hooks: `ls -la .git/hooks/pre-commit .git/hooks/pre-push`
- [ ] Install gitleaks: `brew install gitleaks`
- [ ] Verify hooks work: Try committing a test API key (should be blocked)
- [ ] Setup local secrets: `cp env/dev.env.json.template env/dev.env.json`
- [ ] Get real API key from team lead (1Password)
- [ ] Test build: `flutter run -d chrome --dart-define-from-file=env/dev.env.json`
- [ ] Understand bypass = logged: Never use `--no-verify` without approval
```

**Training Session** (30 minutes):
1. **Incident review** (5 min): Show the SECURITY_NOTICE.md commit as example
2. **Tool demo** (10 min): Show hooks blocking commits in real-time
3. **Best practices** (10 min): Review documentation guidelines
4. **Q&A** (5 min): Answer team questions

## 🧪 Testing the Defense Layers

### Test 1: Pre-Commit Hook Blocks API Keys
```bash
# Create file with real key pattern
echo "const apiKey = 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';" > test_key.dart
git add test_key.dart
git commit -m "test: add API key"

# Expected: ❌ COMMIT BLOCKED
# Output should show:
# [1/6] Checking for Google Maps API keys...
# ❌ ERROR: Google Maps API key detected!
# Files with API keys:
#   - test_key.dart

# Cleanup
git reset HEAD test_key.dart
rm test_key.dart
```

### Test 2: Pre-Commit Hook Allows Placeholders
```bash
# Create file with placeholder
echo "const apiKey = 'AIzaSy___PLACEHOLDER_KEY_HERE___';" > test_placeholder.dart
git add test_placeholder.dart
git commit -m "docs: add API key placeholder"

# Expected: ✅ PASSED
# Output should show:
# [1/6] Checking for Google Maps API keys...
# [2/6] Checking documentation files...
# ...
# ✓ Security scan passed

# Cleanup
git reset HEAD~1
rm test_placeholder.dart
```

### Test 3: Documentation Check
```bash
# Create markdown with real key
echo "The key AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX was exposed" > test.md
git add test.md
git commit -m "docs: security incident"

# Expected: ❌ COMMIT BLOCKED
# Output should show:
# [2/6] Checking documentation files...
# ❌ ERROR: API key found in documentation!
# Documentation should NEVER contain real keys

# Cleanup
git reset HEAD test.md
rm test.md
```

### Test 4: Pre-Push Hook (Backup Layer)
```bash
# Bypass pre-commit hook
echo "const key = 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';" > test.dart
git add test.dart
git commit --no-verify -m "bypass test"

# Try to push
git push origin test-branch

# Expected: ❌ PUSH BLOCKED
# Output should show:
# 🔒 Running pre-push security scan...
# Scanning commits for secrets...
# ❌ PUSH BLOCKED: Secrets detected by gitleaks

# Cleanup
git reset --hard HEAD~1
```

### Test 5: CI Gitleaks (Ultimate Backstop)
```bash
# If somehow both hooks were bypassed:
# 1. Create PR with secret
# 2. GitHub Actions runs
# 3. constitutional-gates job runs gitleaks
# 4. PR is blocked (red X)
# 5. Can't merge until fixed

# Check CI status
gh pr checks
# Expected: gitleaks - ❌ Failed
```

## 🚨 Emergency Response Procedures

### Scenario 1: Key Accidentally Committed Locally
**If not pushed yet:**
```bash
# 1. STOP - Don't push!
# 2. Remove the commit
git reset --soft HEAD~1

# 3. Fix the file (remove key)
# Edit files to remove keys

# 4. Recommit without keys
git add <files>
git commit -m "fix: remove hardcoded secrets"

# 5. Verify clean
gitleaks detect --source . --verbose
```

### Scenario 2: Key Pushed to Remote
**Immediate actions:**
```bash
# 1. ROTATE KEY IMMEDIATELY (don't wait!)
# Go to Google Cloud Console → Credentials → Delete key

# 2. Create new restricted key
# Add restrictions (package name, bundle ID)

# 3. Update local secrets
# Edit env/dev.env.json with new key

# 4. Update CI secrets
gh secret set GOOGLE_MAPS_API_KEY_WEB_PRODUCTION --body "new_key_here"

# 5. Clean git history (advanced - rewrites history)
# Only if repository is private and recent commit
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/file" \
  --prune-empty --tag-name-filter cat -- --all

# 6. Force push (requires team coordination)
git push origin --force --all
git push origin --force --tags

# 7. Add to .gitleaksignore (old key fingerprint)
gitleaks detect --source . --no-git --verbose | grep "Fingerprint"
# Copy fingerprint to .gitleaksignore

# 8. Document incident
# See docs/SECURITY_DOCUMENTATION_GUIDELINES.md for template
```

### Scenario 3: Key in Public Repository
**Critical actions:**
```bash
# 1. ASSUME KEY IS COMPROMISED - Rotate immediately
# 2. Check billing for unexpected usage
# 3. Consider key already used by attackers
# 4. Set billing alerts ASAP
# 5. Report to security team
# 6. Consider making repository private temporarily
# 7. Follow Scenario 2 cleanup steps
# 8. Add monitoring for unusual API usage patterns
```

## 📊 Success Metrics

### Metric 1: Hook Effectiveness
**Target**: 100% of commits scanned  
**Measure**:
```bash
# Total commits
git rev-list --count HEAD

# Hook executions
wc -l < .git/hooks/pre-commit.log

# Should be equal or greater (multiple attempts count)
```

### Metric 2: Block Rate
**Target**: <5% false positives  
**Measure**:
```bash
# Blocked commits
grep "BLOCKED" .git/hooks/pre-commit.log | wc -l

# Passed commits
grep "PASSED" .git/hooks/pre-commit.log | wc -l

# False positive rate
# (Manual review of blocked commits / total blocked) × 100
```

### Metric 3: Zero Secrets in Main
**Target**: 0 secrets in main branch  
**Measure**:
```bash
# Scan main branch
git checkout main
gitleaks detect --source . --log-opts="main" --verbose

# Expected: "No leaks found"
```

### Metric 4: CI Gate Success Rate
**Target**: >95% pass rate  
**Measure**:
```bash
# Check CI runs
gh run list --workflow="Flutter CI/CD" --limit 100 --json conclusion | \
  jq '[.[] | select(.conclusion == "success")] | length'
```

## 🔄 Hook Synchronization Across Worktrees

**Problem**: Git worktrees share `.git/hooks/` but may be out of sync

**Solution**: Install hooks in each worktree
```bash
# In main workspace
cd /path/to/wildfire_mvp_v3
ls -la .git/hooks/pre-commit .git/hooks/pre-push

# In worktree
cd /path/to/wildfire_mvp_v3_a11-ci-cd
ls -la .git/hooks/pre-commit .git/hooks/pre-push

# If hooks missing in worktree, copy from main
cp /path/to/wildfire_mvp_v3/.git/hooks/pre-commit .git/hooks/
cp /path/to/wildfire_mvp_v3/.git/hooks/pre-push .git/hooks/
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```

## 📚 Additional Resources

- **API Key Setup**: `docs/API_KEY_SETUP.md`
- **Security Documentation**: `docs/SECURITY_DOCUMENTATION_GUIDELINES.md`
- **Security Audit**: `docs/SECURITY_AUDIT.md`
- **CI/CD Workflow**: `docs/CI_CD_WORKFLOW_GUIDE.md`
- **Gitleaks Docs**: https://github.com/gitleaks/gitleaks
- **GitHub Security**: https://docs.github.com/en/code-security

## 🎓 Key Takeaways

1. **"Keys should NEVER be written down"** - Not in code, not in docs, nowhere in git
2. **Multiple layers required** - No single tool is perfect
3. **Education matters** - Tools + training = security
4. **Audit regularly** - Trust but verify
5. **Document without exposing** - Reference commits, not keys
6. **Assume breach** - Rotate keys immediately when exposed
7. **Defense in depth** - Local hooks + CI + branch protection + training

---

**Last Updated**: 2025-10-29  
**Version**: 2.0  
**Owner**: Security Team  
**Review**: After any security incident or quarterly
