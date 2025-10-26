# Google Maps API Key Setup

## Security Notice

⚠️ **IMPORTANT**: Never commit API keys to git. This repository uses environment files to manage secrets securely.

## Quick Setup (Development)

1. **Copy the template file**:
   ```bash
   cp env/dev.env.json.template env/dev.env.json
   ```

2. **Add your API key to `env/dev.env.json`**:
   ```json
   {
     "GOOGLE_MAPS_API_KEY_ANDROID": "your_actual_key_here",
     "GOOGLE_MAPS_API_KEY_IOS": "your_actual_key_here"
   }
   ```
   
3. **Run the app with the env file**:
   ```bash
   # Android
   flutter run -d emulator-5554 --dart-define-from-file=env/dev.env.json
   
   # iOS
   flutter run -d ios --dart-define-from-file=env/dev.env.json
   
   # macOS (development)
   flutter run -d macos --dart-define-from-file=env/dev.env.json
   ```

## File Structure

```
env/
├── .gitignore              # Excludes *.env.json from git
├── ci.env.json             # CI/CD config (no secrets)
├── dev.env.json.template   # Template with placeholders
└── dev.env.json            # ← Your actual keys (git-ignored)
```

## Creating a Google Maps API Key

### Step 1: Enable APIs in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**

### Step 2: Create API Key

1. Navigate to **APIs & Services → Credentials**
2. Click **Create Credentials → API Key**
3. Copy the API key

### Step 3: Restrict the API Key (Recommended for Production)

#### Android Restrictions:
1. Edit the API key
2. Select **Application restrictions → Android apps**
3. Add package name: `com.example.wildfire_mvp_v3`
4. Get your SHA-1 fingerprint:
   ```bash
   # Debug keystore
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   
   # Release keystore (production)
   keytool -list -v -keystore /path/to/release.keystore \
     -alias your_alias
   ```
5. Add the SHA-1 fingerprint to the API key restrictions

#### iOS Restrictions:
1. Edit the API key
2. Select **Application restrictions → iOS apps**
3. Add bundle ID: `com.example.wildfire_mvp_v3`

### Step 4: No Restrictions (Development Only)

For development/testing, you can create an **unrestricted API key**:
- ⚠️ **WARNING**: Unrestricted keys can be used by anyone
- Set up billing alerts at 50% and 80% of free tier quota
- Rotate the key if exposed publicly
- Never commit unrestricted keys to git

## CI/CD Setup

For GitHub Actions or other CI/CD:

1. **Store API key as repository secret**:
   - GitHub: Settings → Secrets → Actions → New repository secret
   - Name: `GOOGLE_MAPS_API_KEY`

2. **Use in workflow**:
   ```yaml
   - name: Run tests
     env:
       GOOGLE_MAPS_API_KEY_ANDROID: ${{ secrets.GOOGLE_MAPS_API_KEY }}
       GOOGLE_MAPS_API_KEY_IOS: ${{ secrets.GOOGLE_MAPS_API_KEY }}
     run: flutter test
   ```

## Troubleshooting

### Android: "Authorization failure" error

**Symptom**:
```
E/Google Android Maps SDK: Authorization failure
E/Google Android Maps SDK: API Key: YOUR_API_KEY_HERE
```

**Solutions**:
1. ✅ Verify `env/dev.env.json` exists with actual key
2. ✅ Run with `--dart-define-from-file=env/dev.env.json`
3. ✅ Check package name matches: `com.example.wildfire_mvp_v3`
4. ✅ Verify SHA-1 fingerprint is correct (if restricted)
5. ✅ Ensure "Maps SDK for Android" is enabled in Google Cloud

### iOS: Map tiles not loading

**Symptom**: Blank map area, no tiles visible

**Solutions**:
1. ✅ Verify `env/dev.env.json` exists with actual key
2. ✅ Run with `--dart-define-from-file=env/dev.env.json`
3. ✅ Check bundle ID matches: `com.example.wildfire_mvp_v3`
4. ✅ Ensure "Maps SDK for iOS" is enabled in Google Cloud

### Key exposed in git history

**If you accidentally committed an API key**:

1. **Rotate the key immediately**:
   - Go to Google Cloud Console → Credentials
   - Delete or restrict the exposed key
   - Create a new key

2. **Remove from git history** (optional, advanced):
   ```bash
   # WARNING: Rewrites git history - coordinate with team
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch android/app/build.gradle.kts" \
     --prune-empty --tag-name-filter cat -- --all
   
   # Or use BFG Repo-Cleaner (easier)
   bfg --replace-text passwords.txt
   ```

3. **Force push** (⚠️ only if safe to do so):
   ```bash
   git push origin --force --all
   git push origin --force --tags
   ```

## Best Practices

✅ **DO**:
- Use environment files (`env/dev.env.json`)
- Add `env/*.env.json` to `.gitignore`
- Restrict API keys by package/bundle ID
- Set up billing alerts
- Rotate keys if exposed
- Use different keys for dev/staging/prod

❌ **DON'T**:
- Hardcode API keys in source code
- Commit API keys to git
- Share API keys in chat/email/docs
- Use unrestricted keys in production
- Use production keys in development

## References

- [Google Maps Platform - Get API Key](https://developers.google.com/maps/documentation/android-sdk/get-api-key)
- [Android SDK Setup](https://developers.google.com/maps/documentation/android-sdk/start)
- [iOS SDK Setup](https://developers.google.com/maps/documentation/ios-sdk/start)
- [API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
