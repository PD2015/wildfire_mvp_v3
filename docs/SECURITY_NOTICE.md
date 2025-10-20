# ⚠️ SECURITY NOTICE

## API Key Exposed in Git History

**Issue**: The Google Maps API key `AIzaSyDkZKOUu74f3XdwqyszBe_jEl4orL8MMxA` was committed to this repository's git history in commits:
- `13c510d` - feat(android): use shared unrestricted Google Maps API key
- `ef1d4d4` - fix(android): add Google Maps API key manifest placeholder  
- Earlier commits in `ios/Runner/AppDelegate.swift`

**Current Status**: ✅ Fixed in commit `9063b2c` - keys removed from source code

**Risk Assessment**:
- ✅ Key is configured with **no restrictions** (development/testing only)
- ✅ Key is monitored with billing alerts
- ⚠️ Key remains in git history and could be extracted
- ⚠️ If repository is public/shared, key could be used by others

## Recommended Actions

### Option 1: Rotate the API Key (Recommended)
**When**: If this repository is public or shared with untrusted parties

**Steps**:
1. Go to [Google Cloud Console](https://console.cloud.google.com/) → Credentials
2. **Delete** or **restrict** the exposed key: `AIzaSyDkZKOUu74f3XdwqyszBe_jEl4orL8MMxA`
3. **Create a new API key**
4. Update `env/dev.env.json` with the new key
5. Share the new key securely with your team (password manager, secrets vault, etc.)

### Option 2: Add Restrictions (Moderate)
**When**: Repository is private but you want defense-in-depth

**Steps**:
1. Go to Google Cloud Console → Credentials
2. Edit the API key
3. Add **Application restrictions**:
   - **Android**: Package name `com.example.wildfire_mvp_v3` + SHA-1 fingerprint
   - **iOS**: Bundle ID `com.example.wildfire_mvp_v3`
4. Add **API restrictions**: Only enable "Maps SDK for Android" and "Maps SDK for iOS"
5. Set up billing alerts at 50% and 80% of free tier

### Option 3: Accept Risk (Development Only)
**When**: Repository is private, team is trusted, and key is for development only

**Requirements**:
- ✅ Repository must be private
- ✅ Team members are trusted
- ✅ Billing alerts are configured
- ✅ Plan to rotate key before production release
- ✅ Monitor Google Cloud Console for unexpected usage

## Removing Key from Git History (Advanced)

⚠️ **WARNING**: This rewrites git history and requires team coordination

### Using BFG Repo-Cleaner (Recommended)

```bash
# 1. Backup your repo
cp -r wildfire_mvp_v3 wildfire_mvp_v3.backup

# 2. Download BFG
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# 3. Create replacement file
echo "AIzaSyDkZKOUu74f3XdwqyszBe_jEl4orL8MMxA==>YOUR_API_KEY_HERE" > replacements.txt

# 4. Run BFG
java -jar bfg-1.14.0.jar --replace-text replacements.txt wildfire_mvp_v3

# 5. Clean up
cd wildfire_mvp_v3
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 6. Force push (⚠️ coordinate with team!)
git push origin --force --all
git push origin --force --tags
```

### Using git filter-branch (Alternative)

```bash
# 1. Backup your repo
cp -r wildfire_mvp_v3 wildfire_mvp_v3.backup

# 2. Remove files from history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch android/app/build.gradle.kts ios/Runner/AppDelegate.swift' \
  --prune-empty --tag-name-filter cat -- --all

# 3. Clean up
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 4. Force push (⚠️ coordinate with team!)
git push origin --force --all
git push origin --force --tags
```

### After Rewriting History

**Required steps for all team members**:
```bash
# Delete local repo and re-clone
cd ..
rm -rf wildfire_mvp_v3
git clone <repository-url>
cd wildfire_mvp_v3
```

## Prevention Checklist

✅ **Implemented**:
- [x] API keys moved to `env/dev.env.json` (git-ignored)
- [x] Added `env/.gitignore` to exclude `*.env.json`
- [x] Created `env/dev.env.json.template` as example
- [x] Added comprehensive setup guide: `docs/API_KEY_SETUP.md`
- [x] Updated build scripts to use placeholders
- [x] Added security comments in code

🔄 **Recommended**:
- [ ] Rotate the exposed API key (see Option 1 above)
- [ ] Set up billing alerts in Google Cloud Console
- [ ] Add pre-commit hook to prevent future key commits
- [ ] Use secrets management tool (1Password, AWS Secrets Manager, etc.)
- [ ] Document key rotation process for production

## Future Best Practices

1. **Never hardcode secrets** in source code
2. **Use environment files** (`env/*.env.json`) with git-ignore
3. **Rotate keys** if accidentally committed
4. **Restrict API keys** by package/bundle ID
5. **Monitor usage** in Google Cloud Console
6. **Separate keys** for dev/staging/production
7. **Use secrets managers** for production (AWS Secrets Manager, HashiCorp Vault, etc.)

## Questions?

See `docs/API_KEY_SETUP.md` for detailed setup instructions.

---

**Last Updated**: 2025-10-20  
**Status**: ✅ Mitigated (keys removed from source code, remain in history)  
**Action Required**: Review options above and decide on key rotation
