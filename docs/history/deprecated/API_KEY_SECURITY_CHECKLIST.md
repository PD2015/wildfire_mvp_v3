# Google Maps API Key Security Checklist

## ✅ Why API Keys Are Visible in Browser
Google Maps API keys are **client-side keys** that must be sent with every map request. They are designed to be visible in:
- Network requests (Headers: `x-goog-api-key`)
- Browser DevTools Network tab
- Page source code (for web implementation)

**This is normal and expected behavior** - security comes from restrictions, not secrecy.

## 🔒 Required Security Restrictions

### Production API Key Restrictions

**Check your new API key in Google Cloud Console:**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Find your production web API key
3. Verify these restrictions are enabled:

#### Application Restrictions (Choose ONE):
- ✅ **HTTP referrers (websites)** ← RECOMMENDED for web
  - Add: `https://wildfire-app-e11f8.web.app/*`
  - Add: `https://wildfire-app-e11f8.firebaseapp.com/*`
  - Add: `https://*.web.app/*` (if using preview channels)

#### API Restrictions:
- ✅ **Restrict key** (don't use unrestricted)
- ✅ Enable ONLY these APIs:
  - Maps JavaScript API
  - Maps SDK for Android (if mobile)
  - Maps SDK for iOS (if mobile)

### Why These Restrictions Matter

**Without restrictions:**
- ❌ Anyone can copy your key from the browser
- ❌ They can use it on their own website
- ❌ You'll be billed for their usage
- ❌ Could hit quota limits quickly

**With restrictions:**
- ✅ Key only works on your domain (wildfire-app-e11f8.web.app)
- ✅ Requests from other domains are rejected
- ✅ Only specified Google Maps APIs can be called
- ✅ You control the billing

## 🚨 How to Verify Your Restrictions

### Test 1: Key Works on Your Site
```bash
# Open your production site - map should load
open "https://wildfire-app-e11f8.web.app"
```
✅ Expected: Map loads without errors

### Test 2: Key Doesn't Work on Other Sites
```bash
# Try using your key on a different domain
# Create a simple HTML file locally and try to load Google Maps
```
✅ Expected: Error "RefererNotAllowedMapError"

### Test 3: Check Console for Warnings
```
Open browser DevTools → Console tab
```
✅ Expected: No "API key restricted" warnings

## 📊 Monitoring Usage

### Set Up Billing Alerts
1. Go to: https://console.cloud.google.com/billing
2. Set up budget alerts:
   - Alert at 50% of free tier ($200/month)
   - Alert at 80% of free tier ($200/month)
   - Alert at 100% ($200/month)

### Monitor Daily Usage
1. Go to: https://console.cloud.google.com/apis/dashboard
2. Select: Maps JavaScript API
3. Check daily request counts

## 🔄 Key Rotation Schedule

- **Development keys**: Rotate every 90 days
- **Production keys**: Rotate every 180 days (6 months)
- **Exposed keys**: Rotate immediately

### Quick Rotation Steps
```bash
# 1. Generate new key in Google Cloud Console
# 2. Update GitHub Secret
gh secret set GOOGLE_MAPS_API_KEY_WEB_PRODUCTION --body "new_key_here"

# 3. Trigger production deployment
git commit --allow-empty -m "chore: rotate API key"
git push origin main

# 4. After deployment succeeds, delete old key
# Go to Google Cloud Console → Delete old key
```

## ❓ FAQ

**Q: My API key is visible in the browser. Is this a security issue?**
A: No, this is expected for client-side API keys. Security comes from HTTP referrer restrictions.

**Q: Someone copied my API key from DevTools. Can they use it?**
A: No, if you have HTTP referrer restrictions set up. Their requests will be rejected.

**Q: Should I use a proxy to hide the API key?**
A: Not necessary. Google designed these keys to be visible with restriction-based security.

**Q: What if I see unexpected usage in billing?**
A: Check the API Dashboard for request sources. If suspicious, rotate the key immediately.

## 📚 References

- [Google Maps API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Restricting API Keys](https://cloud.google.com/docs/authentication/api-keys#securing_an_api_key)
- [Using API Keys](https://developers.google.com/maps/documentation/javascript/get-api-key)

---

**Last Updated**: 2025-10-29
**Status**: ✅ Production key rotated, restrictions should be verified
