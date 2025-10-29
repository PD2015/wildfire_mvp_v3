# 🔒 Security Documentation Guidelines

**CRITICAL PRINCIPLE: Keys should NEVER be written down - not in code, not in docs, not anywhere in the repository.**

## ❌ NEVER Do This

### Bad Example 1: Including Literal Keys
```markdown
❌ The API key `AIzaSyDkZKOUu74f3XdwqyszBe_jEl4orL8MMxA` was exposed.
```

### Bad Example 2: "Redacted" Keys That Aren't
```markdown
❌ The key AIzaSy***REDACTED*** was found in commit abc123.
```
*Problem: Even partial keys help attackers narrow down possibilities.*

### Bad Example 3: Keys in Code Comments
```dart
❌ // Old key: AIzaSyDkZKOUu74f3XdwqyszBe_jEl4orL8MMxA (DO NOT USE)
```

### Bad Example 4: Keys in Examples
```markdown
❌ Example API key for testing: AIzaSyDkZKOUu74f3XdwqyszBe_jEl4orL8MMxA
```

## ✅ DO This Instead

### Good Example 1: Reference Commits, Not Keys
```markdown
✅ An API key was exposed in commit `b5d9310` (2025-10-20).
   See rotation procedures in API_KEY_SETUP.md.
```

### Good Example 2: Use Placeholders
```markdown
✅ The API key format is: AIzaSy + 33 random characters
   Example placeholder: AIzaSy___PLACEHOLDER_KEY_HERE___
```

### Good Example 3: Link to Key Management
```markdown
✅ **If you need the API key:**
   1. Check `env/dev.env.json` (git-ignored, local only)
   2. Ask team lead for 1Password vault access
   3. See docs/API_KEY_SETUP.md for setup instructions
```

### Good Example 4: Describe Impact, Not Content
```markdown
✅ **Security Incident Report:**
   - Date: 2025-10-20
   - Issue: Google Maps API key committed to git history
   - Commits affected: `b5d9310`, `13c510d`, `ef1d4d4`
   - Action taken: Keys rotated, restrictions added
   - Verification: gitleaks scan passed after rotation
```

## 📋 Documentation Checklist

Before committing ANY file (code or docs):

- [ ] **No literal keys**: Search file for `AIzaSy`, `sk_`, `pk_`, AWS patterns
- [ ] **No credentials**: No passwords, tokens, certificates
- [ ] **No sensitive paths**: No absolute paths with usernames
- [ ] **No PII**: No email addresses (except in commit metadata)
- [ ] **Placeholders only**: Use `YOUR_KEY_HERE`, `PLACEHOLDER`, `***`
- [ ] **Link to secrets management**: Point to where to get real keys
- [ ] **Review git diff**: Check staged changes before commit

## 🚨 If You Discover a Key in Git History

**DO NOT document the key - document the PROCESS:**

```markdown
# ❌ WRONG - Security Notice
The key AIzaSyXXXXXXXX was exposed in commit abc123.

# ✅ CORRECT - Security Incident
**Incident ID**: SEC-2025-001
**Date**: 2025-10-20
**Type**: API key in git history
**Commits**: b5d9310, 13c510d, ef1d4d4
**Status**: RESOLVED
**Actions**:
1. Keys rotated via Google Cloud Console
2. New keys stored in 1Password team vault
3. Repository scanned with gitleaks (passed)
4. Pre-commit hooks enhanced
5. Team training on 2025-10-21

**Verification**:
- [ ] Old keys revoked (confirmed 2025-10-20 12:45)
- [ ] New keys have restrictions (Android package + iOS bundle)
- [ ] Billing alerts configured (50%, 80% thresholds)
- [ ] All team members updated local env files

**References**:
- API Key Setup: docs/API_KEY_SETUP.md
- Rotation Procedure: docs/runbooks/rotate-api-keys.md
- Security Audit: docs/SECURITY_AUDIT.md
```

## 🎯 When Writing Security Docs

### Rule 1: Describe, Don't Display
❌ "The password was `secret123`"
✅ "A weak password was used"

### Rule 2: Reference, Don't Reproduce
❌ "Here's the exposed token: ghp_..."
✅ "Token exposed in commit abc123 (rotated)"

### Rule 3: Procedure, Not Proof
❌ "I found this key in the code: ..."
✅ "Follow rotation procedure in docs/runbooks/"

### Rule 4: Metadata, Not Material
❌ "API key: AIzaSy..."
✅ "API key type: Google Maps, exposed: 2025-10-20, rotated: 2025-10-20"

## 📚 Approved Patterns for Security Documentation

### For Incidents
```markdown
**Incident**: [Type] in [Location]
**Date**: YYYY-MM-DD
**Commits**: [hashes only]
**Resolution**: [Action taken]
**Verification**: [How confirmed secure]
```

### For Setup Guides
```markdown
**Step 1**: Obtain key from [secure location]
**Step 2**: Store in [git-ignored file]
**Step 3**: Verify with [test command]
**Never**: Commit keys to git, share via email/Slack
```

### For Troubleshooting
```markdown
**Error**: "API key invalid"
**Cause**: Key not configured
**Fix**: Check env/dev.env.json exists
**Not**: Sharing keys in issue comments
```

## 🔐 Key Storage Locations (Approved)

| Location | Purpose | Git Status | Approval |
|----------|---------|------------|----------|
| `env/dev.env.json` | Local development | ✅ Ignored | ✅ SAFE |
| `android/local.properties` | Android builds | ✅ Ignored | ✅ SAFE |
| GitHub Secrets | CI/CD | N/A (remote) | ✅ SAFE |
| 1Password | Team sharing | N/A (external) | ✅ SAFE |
| Documentation | **NEVER** | ❌ Tracked | ❌ **FORBIDDEN** |
| Code comments | **NEVER** | ❌ Tracked | ❌ **FORBIDDEN** |
| Git history | **NEVER** | ❌ Permanent | ❌ **FORBIDDEN** |

## 🎓 Training: Real vs Placeholder Keys

### Recognizing Real Keys
- **Google Maps**: `AIzaSy` + 33 chars = **REAL** (never commit)
- **AWS**: `AKIA` + 16 chars = **REAL** (never commit)
- **GitHub**: `ghp_`, `gho_`, `ghs_` = **REAL** (never commit)

### Safe Placeholders
- `YOUR_KEY_HERE` = Safe
- `PLACEHOLDER_` = Safe
- `***` or `[REDACTED]` = Safe for docs, but prefer commit references
- `example.com` = Safe domain
- `user@example.com` = Safe email

### Decision Tree
```
Does this string access a real service?
├─ YES → Real key → NEVER commit
└─ NO → Placeholder → Can commit (but verify it's clear it's fake)
```

## ✅ Pre-Commit Self-Review

Before every `git commit`, ask yourself:

1. **Would this let someone access our services?** → Don't commit
2. **Would this expose user data?** → Don't commit
3. **Would this embarrass us in a security audit?** → Don't commit
4. **Is this something I'd post publicly on Twitter?** → If no, don't commit

**Remember**: Git history is forever. Once committed, even if "deleted," keys remain in history forever.

## 🆘 Emergency Response

**If you accidentally commit a key:**

1. **STOP** - Don't push if you haven't already
2. **ROTATE** - Immediately revoke the key (don't wait)
3. **CLEAN** - Use `git reset --soft HEAD~1` if not pushed
4. **VERIFY** - Run `gitleaks detect --source .` before pushing
5. **REPORT** - Tell team lead immediately
6. **DOCUMENT** - Follow incident template above (without including the key!)

**After hours emergency**: Rotate key first, report later. Security > process.

---

**Last Updated**: 2025-10-29
**Owner**: Security Team
**Review Frequency**: Quarterly (or after any incident)
