# Google Maps Setup Guide

## Overview
This guide covers setting up Google Maps API keys for iOS and Android platforms.

## Prerequisites
- Google Cloud Platform account
- Project with billing enabled
- Maps SDK for Android enabled
- Maps SDK for iOS enabled

## API Key Creation

### 1. Create API Keys
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services > Credentials**
4. Click **Create Credentials > API Key**
5. Create separate keys for Android and iOS

### 2. Android Key Restrictions
1. Click on the Android API key
2. Under **Application restrictions**, select **Android apps**
3. Click **Add an item**
4. Add your app's package name: `com.example.wildfire_mvp_v3`
5. Get SHA-1 fingerprint:
   ```bash
   # Debug certificate
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release certificate (use your keystore path)
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your_alias
   ```
6. Add SHA-1 fingerprint to the key restrictions
7. Save changes

### 3. iOS Key Restrictions
1. Click on the iOS API key
2. Under **Application restrictions**, select **iOS apps**
3. Click **Add an item**
4. Add your app's bundle ID (found in `ios/Runner.xcodeproj`)
5. Save changes

## Configuration

### 4. Set Environment Variables
1. Copy the template:
   ```bash
   cp env/dev.env.json.template env/dev.env.json
   ```

2. Edit `env/dev.env.json` and add your API keys:
   ```json
   {
     "GOOGLE_MAPS_API_KEY_ANDROID": "your_android_key_here",
     "GOOGLE_MAPS_API_KEY_IOS": "your_ios_key_here"
   }
   ```

3. **NEVER commit `env/dev.env.json`** - it's in `.gitignore`

### 5. Run with Environment File
```bash
# Development with your keys
flutter run --dart-define-from-file=env/dev.env.json

# CI/CD (uses placeholder keys)
flutter run --dart-define-from-file=env/ci.env.json
```

## Cost Monitoring

### 6. Set Up Billing Alerts
Google Maps offers $200/month free tier. Set up alerts to avoid unexpected charges:

1. Go to **Billing > Budgets & alerts**
2. Create budget for your project
3. Set alerts at:
   - **50% threshold** ($100/month) - Warning
   - **80% threshold** ($160/month) - Critical

### 7. API Usage Quotas
- **Maps SDK for Android**: 28,000 loads/month free
- **Maps SDK for iOS**: 28,000 loads/month free
- Monitor usage in **APIs & Services > Dashboard**

## Troubleshooting

### API Key Not Working
- Verify key restrictions match your app's package name/bundle ID
- Check SHA-1 fingerprint is correct (debug vs release)
- Ensure Maps SDK is enabled in GCP console
- Wait 5-10 minutes after key creation for propagation

### Quota Exceeded
- Check current usage in GCP console
- Implement caching to reduce API calls (already done via CacheService)
- Consider upgrading billing if needed

### Map Not Displaying
- Check Android `AndroidManifest.xml` has correct meta-data
- Check iOS `Info.plist` has `GMSApiKey` entry
- Verify API keys are in environment file
- Check device/emulator has internet connection

## Security Best Practices
- Never commit API keys to version control
- Use key restrictions (package name, bundle ID, SHA-1)
- Rotate keys periodically
- Monitor usage for anomalies
- Use separate keys for dev/staging/production

## References
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Maps SDK for Android Setup](https://developers.google.com/maps/documentation/android-sdk/start)
- [Maps SDK for iOS Setup](https://developers.google.com/maps/documentation/ios-sdk/start)
