Onboarding & Legal Integration

## Goal

Add a first-launch onboarding flow to the WildFire app that:

- Introduces what the app is and is not.
- Shows a short emergency disclaimer and links to full legal docs.
- Lets the user choose a preferred notification distance from fires (stored for future use).
- Marks onboarding as complete so it's skipped on subsequent launches.

**Style**: Use the existing WildFire theme (Material 3) with "Option B" flavour – full-bleed background colour/illustration and a central card for content.

---

## 1. New Persistent Settings

Implement via SharedPreferences (or your existing abstraction):

### `onboarding_complete_v1`: bool

- Default: `false` (or absent).
- Set to `true` after the user taps "Get started" on the final onboarding step.

### `notification_radius_km`: int

- Default: `10` (safe baseline).
- Values allowed (for now): `0`, `5`, `10`, `25`, `50`.

These are app-level settings (no account).

---

## 2. Routing & Navigation

Assuming existing go_router usage.

### New routes

```dart
GoRoute(
  path: '/onboarding',
  name: 'onboarding',
  builder: (context, state) => const OnboardingScreen(),
),
```

Optional nested routes if you want separate pages, but simplest is a single `OnboardingScreen` with internal `PageView` state.

### Redirect logic

In your root router or "shell":

- On app startup, before building the main shell, check `onboarding_complete_v1`.
- If `false` → route to `/onboarding`.
- If `true` → continue to normal initial route (`/` / home).

Example (high level):

```dart
// Pseudocode – adapt to existing router setup

// In router redirect or initialRoute logic:
final prefs = await SharedPreferences.getInstance();
final completed = prefs.getBool('onboarding_complete_v1') ?? false;

if (!completed && state.subloc != '/onboarding') {
  return '/onboarding';
}
```

On finishing onboarding:

```dart
await prefs.setBool('onboarding_complete_v1', true);
context.go('/'); // or your main/home route
```

---

## 3. Onboarding Flow – Screens & Content

Implement as one `OnboardingScreen` with 3–4 pages inside a `PageView`:

### 3.1 Layout & Styling (Option B flavour)

**Structure:**

- **Background**: Scaffold with background colour from your theme (e.g. `BrandPalette.forest900` or `colorScheme.surface` in dark mode, `colorScheme.background` in light).
- **Top**: app logo / pin icon and "WildFire" title.
- **Middle**: card with rounded corners that fits with rest of app theme, elevation or soft shadow, using `colorScheme.surface`.
- **Bottom**:
  - Primary button ("Continue" / "Get started")
  - Secondary text ("Skip", if you want)
  - Page indicator dots (3–4 steps).

**Styling hints:**

- Use Material 3 `FilledButton` for primary actions.
- Use `TextButton` for secondary.
- Use `AnimatedSmoothIndicator` if you already have it, otherwise a simple `Row` of `Container` dots.
- Respect your existing typography (`Theme.of(context).textTheme.*`).

**Accessibility:**

- All buttons ≥44dp height.
- Semantics labels on the primary action button per page, e.g. "Continue onboarding, step 1 of 3".

---

## 4. Onboarding Content (Per Page)

### Page 1 – Welcome / What the app is

**Purpose**: friendly intro + scope.

**Content** (paraphrase for UI, not legal text):

- **Title**: "Welcome to the Scottish Wildfire Tracker"
- **Body** (1–2 short paragraphs):
  - "This app helps you stay aware of wildfire risk and recent fire activity across Scotland."
  - "Data is based on environmental models and satellite detections and may be delayed or incomplete."
- **Optional bullet list**:
  - "Check today's wildfire risk where you are."
  - "Explore satellite-detected hotspots."
  - "Plan ahead for days with higher risk."
  - "Pick a location with accurate coordinates to help reporting"
**Buttons:**

- Primary: "Continue"
- Secondary (optional): "Skip for now" (if pressed, still set `onboarding_complete_v1=true` but keep defaults for other settings).

---

### Page 2 – Safety & Emergency Disclaimer

Bind to the short-form emergency disclaimer from the legal pack.

**Use text:**

> WildFire provides general wildfire-risk information and satellite-detected hotspots.
> This app is not a real-time emergency alert system.
> If you see fire or believe life or property is at risk, call 999 immediately.
> For non-emergency fire concerns, call 101.

**Layout:**

- Icon: warning/alert icon in your risk palette (e.g. amber/red).
- Short bullets or bold emphasised lines for 999 and 101.
- Link button: "View full Terms & Privacy" → opens your `/about` or pushes a `TermsScreen` where you show full text (or launches browser to `https://wildfire.scot/legal/terms`).

**Buttons:**

- Primary: "I understand" or "Continue"
- Secondary text: "View full Terms & Privacy"

---

### Page 3 – Data & Privacy Snapshot

Short privacy summary pulled from the Privacy Policy (informational only):

**Point form:**

- "We don't collect names, emails, or account data."
- "We don't store your exact GPS location. Logged locations are privacy-safe and approximate."
- "We don't use tracking or advertising SDKs."
- "You can turn location off in your device settings at any time."

**Also add:**

- Link: "Read the full Privacy Policy" → same `/about/privacy` route or external URL.

**Buttons:**

- Primary: "Continue"

---



### Page 4 
**Title**: Set Up Your App

Location Access

**Button:** Allow Location Access /deny

**Body:**

Notification Radius

Label: Notify me about active fires within:

Off / 5 km / 10 km / 20 km (Material 3 segmented control)

**UI control:**

Either:
- Segmented buttons: '0km/off`, `5 km`, `10 km`, `25 km`, `50 km`
- or a Slider from 5–50 km with labelled stops.

Legal Disclaimer Checkbox

□ I understand this app is informational only and is not an emergency alert system.
□ I agree to the terms and privacy notice.

Link: View full disclaimer →

CTA: "Get started'

**Implementation detail:**

- When the user changes selection, update an in-memory `selectedRadiusKm` (default 10).
- On "Get started" tap → persist to `notification_radius_km`.

**Buttons:**

- Primary: "Get started"
  - Saves prefs:
    - `onboarding_complete_v1 = true`
    - `notification_radius_km = selectedRadiusKm`
  - Navigates: `context.go('/')`
- Secondary: (optional) "Skip for now":
  - Use default radius (10 km), still set `onboarding_complete_v1 = true`.

---



## 5. Integration with Legal Screens

You already have/plan:

- `/about` → Legal & About hub
- `/about/terms` → Terms of Service
- `/about/privacy` → Privacy Policy
- `/about/data-sources` → Data sources & attribution

**Onboarding must:**

Link to at least one of:
- In-app legal screens (`/about/*`), or
- External URLs (`https://wildfire.scot/legal/*`).

**Implementation guidance:**

- Add a small text button under the card on pages 2 and 3:
  - "Terms & Privacy"
  - `onPressed` → `context.push('/about')` or `launchUrl(Uri.parse('https://wildfire.scot/legal/terms'))`.

**Ensure:**

- If the user taps back from `/about`, they return to the same onboarding step instead of exiting the app.

---

## 6. Home Screen Disclaimer & Legal Hooks

Tie onboarding to rest of app:

### Home screen footer

Under your risk banner, add a small caption:

> Not for emergency use. Data from EFFIS/SEPA. Call 999 in an emergency.

**Implementation:**

- Text with `Theme.of(context).textTheme.bodySmall` and reduced opacity.
- Wrap in `Semantics` with label including the "call 999" bit so screen readers pick it up.

### Map Fire Marker bottom sheet

Add text:

> Satellite-detected thermal anomaly. May include non-wildfire heat sources. Accuracy varies.

- Place at bottom of the bottom sheet in smaller text.
- No extra routing needed; just static text.

---

## 7. Files / Areas to Touch

(Task breakdown hint)

### `lib/main.dart` or wherever GoRouter is configured

- Add `/onboarding` route and redirect logic based on `onboarding_complete_v1`.

### `lib/features/onboarding/` (new)

#### `onboarding_screen.dart`

- Implements `PageView` with 3–4 pages, card layout, progress dots, and navigation buttons.
- Holds `selectedRadiusKm` state.
- Saves prefs and navigates to `/` on completion.

### `lib/services/preferences/` or wherever you centralise prefs (optional)

Add helper getters/setters:

```dart
Future<bool> isOnboardingCompleteV1()
Future<void> setOnboardingCompleteV1(bool value)
Future<int> getNotificationRadiusKm()
Future<void> setNotificationRadiusKm(int km)
```

### `lib/features/home/home_screen.dart`

- Add footer disclaimer text under the risk banner.

### `lib/features/map/widgets/fire_details_bottom_sheet.dart` (or similar)

- Append satellite anomaly disclaimer line.

---

## 8. Non-Goals / Constraints

- **Do not** implement real notifications in this spec – just capture the distance preference.
- **Do not** add new analytics/trackers – keep to existing "no tracking" stance.
- Onboarding must be skippable (either explicit "Skip" or by quickly progressing); don't hard-block users behind long content.
- Respect existing privacy rules (no raw GPS in logs, use existing `LocationUtils.logRedact()` for any debug logs you add).


--------
# WildFire App — Terms of Service
**Version:** 1.0  
**Effective Date:** <insert date>  
**Operator:** Independent Developer (“we”, “us”, “our”)

---

## 1. Introduction
WildFire (“the App”) provides general wildfire-risk information, environmental data, and satellite-detected fire activity for Scotland and surrounding regions.

By downloading or using the App, you agree to these Terms of Service. If you do not agree, you must uninstall the App and discontinue use.

---

## 2. Purpose of the App
WildFire is provided for **informational purposes only**.  
It is **not** an emergency-warning tool, life-safety system, or certified fire-detection service.

Data shown in the App may be:
- delayed  
- incomplete  
- unavailable  
- inaccurate  
- influenced by cloud cover, satellite limitations, or model uncertainty  

You must always seek and follow official guidance from emergency services and local authorities.

---

## 3. No Emergency Use
You must not rely on this App as your primary or sole source of fire safety information.

In an emergency:
- **Call 999**  
- For non-emergency concerns, call **101**  
- Landowners and land managers should follow their organisation’s established wildfire protocols  

---

## 4. Eligibility
You must comply with applicable local laws when using the App. The App is intended for general audiences.

---

## 5. Data Sources
WildFire uses third-party data sources including, where available:
- Copernicus Emergency Management Service – EFFIS  
- SEPA wildfire-related datasets  
- Local device location (when permitted by the user)  
- Cached data  
- Mock data when live services are unavailable  

These providers **do not endorse this App** and we cannot guarantee the accuracy or availability of their data.

---

## 6. User Responsibilities
By using the App, you agree that you:
- will verify conditions with official authorities  
- understand that wildfire risk changes rapidly  
- accept that data shown may not reflect real-time fire conditions  
- will not use the App in place of emergency notifications or professional advice  

---

## 7. Limitation of Liability
To the fullest extent permitted by law:

- The App is provided **“as is”** without warranties of any kind.  
- We disclaim all liability for any loss, harm, damage, or decisions made using information from the App.  
- We are not responsible for:
  - use or misuse of data  
  - delayed or unavailable data  
  - satellite false-positives or false-negatives  
  - impacts on property, safety, travel, or land-management decisions  

Your only remedy for dissatisfaction with the App is to stop using it.

---

## 8. App Availability and Modifications
We may modify, update, suspend, or discontinue the App at any time without notice.

These Terms may be updated periodically. Continued use constitutes acceptance of the updated Terms.

---

## 9. Privacy
Use of the App is also governed by our **Privacy Policy**:  
<insert URL e.g., https://wildfire.scot/legal/privacy>

---

## 10. Governing Law
These Terms will be governed by the laws of Scotland.

---

## 11. Contact
If you have questions regarding these Terms, contact:  
**Email:** <your email>  


-----------------
# WildFire App — Privacy Policy
**Version:** 1.0  
**Effective Date:** <insert date>  
**Operator:** Independent Developer (“we”, “us”, “our”)

---

## 1. Overview
This Privacy Policy explains how WildFire (“the App”) processes personal data in accordance with the **UK General Data Protection Regulation (UK GDPR)**.

We are committed to minimising data collection and ensuring user privacy. The App does not require user accounts and does not collect identifying personal information.

---

## 2. What Data We Process

### a) Approximate Location (for wildfire-risk lookup)
The App may process your device location to retrieve nearby wildfire-risk values.  
If permission is granted, the device provides a coordinate, which is used **only for the immediate risk lookup**.

We do **not**:
- store exact GPS coordinates  
- create a location history  
- transmit GPS data to third parties  

For internal debugging and caching, the App applies **privacy redaction** (rounded coordinates or geohash grids of approx. 1–5 km resolution).

### b) Manual Location
Users may enter a manual location.  
This is stored locally on the device in simple preferences.

### c) Local Cache
The App stores:
- wildfire-risk results  
- timestamps  
- approximate geohash keys  

Cache entries automatically expire after a maximum of **6 hours**.

### d) Device Information
The following device information may be processed automatically to allow the App to function:
- operating system version  
- basic configuration needed to display maps and screens  

### e) No Analytics, No Tracking
The App does **not** use:
- advertising identifiers  
- analytics trackers  
- third-party behavioural tracking  
- cookies  

---

## 3. What We Do **Not** Collect
We do **not** collect:
- names  
- email addresses  
- phone numbers  
- precise or long-term location logs  
- device identifiers  
- IP addresses (beyond temporary network transport)  
- usage analytics  

---

## 4. Legal Basis for Processing
We process minimal data under:

- **Legitimate Interests** — providing wildfire-risk lookups requiring approximate location  
- **Consent** — when you grant location permissions on your device  

You may revoke permission at any time through device settings.

---

## 5. Data Sharing
We share **no personal data** with third parties.

Environmental data sources such as EFFIS or SEPA do **not** receive any personal information from us.

---

## 6. Data Retention
We retain only local cache data, which expires automatically within **6 hours**.

We do not store any identifiable personal information.

---

## 7. Your Rights
Under UK GDPR, you have the right to:
- access information we hold  
- request deletion  
- withdraw consent  
- object to processing  

Because we store no identifiable personal data, we will generally confirm that no such data is held.

---

## 8. Children
The App does not knowingly collect personal data from children.

---

## 9. Changes to This Policy
We may update this Privacy Policy periodically.  
The version number and effective date will be shown above.

---

## 10. Contact
For privacy-related queries, contact:  
**Email:** <your email>  

-----


# WildFire App — Emergency & Accuracy Disclaimer
**Version:** 1.0  
**Effective Date:** <insert date>

---

## 1. General Disclaimer
WildFire provides **general wildfire-risk information** and **satellite-detected heat anomalies** for Scotland and surrounding areas.

The App is **not a real-time emergency alert tool** and must not be relied upon as your sole source of fire-safety information.

Data may be:
- delayed  
- incomplete  
- inaccurate  
- unavailable due to cloud cover, satellite limitations, or service outages  

---

## 2. Emergency Guidance
If you see fire or believe life or property is at risk:

### **Call 999 immediately.**

For non-emergency fire concerns, contact:
- **101**  
- local land managers or estate staff  

---

## 3. No Guarantee of Accuracy
Wildfire-risk forecasts, environmental indices, and satellite detections are subject to uncertainty.  
Satellite heat pixels may include **non-wildfire sources**, such as:
- machinery  
- industrial heat  
- sun-heated surfaces  
- agricultural burns  

No guarantee is provided for the accuracy, completeness, or timeliness of the information.

---

## 4. User Responsibility
You remain fully responsible for:
- verifying conditions with authoritative sources  
- assessing personal and land-management risk  
- taking appropriate safety actions  

---

## 5. Liability
To the fullest extent permitted by law, the App operator disclaims all liability for:
- decisions made based on the App  
- missed or incorrect fire detections  
- damages or losses of any kind arising from reliance on the App’s data  

---

---------- 
# WildFire App — Data Sources & Attribution
**Version:** 1.0  
**Effective Date:** <insert date>

---

## 1. Overview
WildFire relies on multiple publicly available environmental datasets to provide indicative wildfire-risk values and fire-activity information.  
This document explains those sources and their limitations.

---

## 2. Primary Data Sources

### **Copernicus Emergency Management Service — EFFIS**
Wildfire-risk forecasts and satellite-detected fire activity may be sourced from the **European Forest Fire Information System (EFFIS)**.

Attribution:
> © European Union, Copernicus Emergency Management Service (EMS).  
> Data may be delayed or incomplete.

EFFIS data is provided without warranty and may include false positives or false negatives.

---

### **SEPA — Scottish Environment Protection Agency**
Where available, the App may use relevant wildfire-related or environmental datasets provided by SEPA.  
SEPA does not endorse or validate the App, and data availability may vary.

---

## 3. Other Data and Models
Additional information may be derived from:
- meteorological forecast models  
- device geolocation (with privacy redaction)  
- developer-provided fallback or mock datasets when live sources are unavailable  

---

## 4. Data Processing Notes
- All coordinates used for logging or caching are **redacted** (rounded or geohashed).  
- Timestamps reflect the moment data was retrieved, not the time of original measurement.  
- Cached data may be shown if live services are unreachable.  
- Mock data may appear if no valid live or cached data exists.

---

## 5. Limitations
All environmental and satellite datasets include uncertainty.  
Factors affecting accuracy include:
- cloud cover  
- sensor resolution  
- processing delay  
- localised weather  
- rapidly changing wildfire conditions  

---

## 6. No Endorsement
EFFIS, SEPA, and any other listed providers do **not** endorse this App.  
They provide data under their own terms and licences, without warranty.

---

