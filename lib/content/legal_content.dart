/// Legal document metadata and content for WildFire app.
///
/// Contains all legal documents as embedded Dart strings for:
/// - Offline access during onboarding
/// - Version tracking for re-consent on updates
/// - GDPR compliance audit trail
library;

/// A legal document with metadata for display and version tracking.
class LegalDocument {
  /// Unique identifier for the document (e.g., 'terms', 'privacy')
  final String id;

  /// Display title for the document
  final String title;

  /// Document version string (e.g., '1.0')
  final String version;

  /// When this version became effective
  final DateTime effectiveDate;

  /// Full document content (Markdown formatted)
  final String content;

  const LegalDocument({
    required this.id,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.content,
  });
}

/// Static access to all legal documents.
///
/// Usage:
/// ```dart
/// final terms = LegalContent.termsOfService;
/// print(terms.title); // "Terms of Service"
/// ```
class LegalContent {
  LegalContent._();

  /// Content version - increment when any document changes.
  /// This triggers re-consent requirements.
  static const int contentVersion = 1;

  /// Terms of Service document.
  static final termsOfService = LegalDocument(
    id: 'terms',
    title: 'Terms of Service',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _termsContent,
  );

  /// Privacy Policy document.
  static final privacyPolicy = LegalDocument(
    id: 'privacy',
    title: 'Privacy Policy',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _privacyContent,
  );

  /// Emergency & Accuracy Disclaimer document.
  static final emergencyDisclaimer = LegalDocument(
    id: 'disclaimer',
    title: 'Emergency & Accuracy Disclaimer',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _disclaimerContent,
  );

  /// Data Sources & Attribution document.
  static final dataSources = LegalDocument(
    id: 'data-sources',
    title: 'Data Sources & Attribution',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _dataSourcesContent,
  );

  /// All documents in display order.
  static final List<LegalDocument> allDocuments = [
    termsOfService,
    privacyPolicy,
    emergencyDisclaimer,
    dataSources,
  ];

  // ─────────────────────────────────────────────────────────────
  // Document Content
  // ─────────────────────────────────────────────────────────────

  static const String _termsContent = '''
# WildFire — Terms of Service

**Version:** 1.0  
**Effective Date:** 18 December 2025
**Operator:** Independent Developer ("we", "us", "our")

---

## 1. Introduction

WildFire ("the App") provides general wildfire-risk information, environmental data, and satellite-detected fire activity for Scotland and surrounding regions.

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

**In an emergency:**
- **Call 999**
- For non-emergency concerns, call **101**
- Landowners and land managers should follow their organisation's established wildfire protocols

---

## 4. Eligibility

You must comply with applicable local laws when using the App. The App is intended for general audiences.

---

## 5. Data Sources

WildFire uses third-party data sources including:
- Copernicus Emergency Management Service – EFFIS (European Forest Fire Information System)
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

- The App is provided **"as is"** without warranties of any kind.
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

Use of the App is also governed by our **Privacy Policy**.

---

## 10. Governing Law

These Terms will be governed by the laws of Scotland.

---

## 11. Contact

If you have questions regarding these Terms, please use the app's feedback feature.
''';

  static const String _privacyContent = '''
# WildFire — Privacy Policy

**Version:** 1.0  
**Effective Date:** 18 December 2025
**Operator:** Independent Developer ("we", "us", "our")

---

## 1. Overview

This Privacy Policy explains how WildFire ("the App") processes personal data in accordance with the **UK General Data Protection Regulation (UK GDPR)**.

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

**Note (Web Version):** The web version uses browser local storage for essential caching functionality. This is required for the app to function and does not involve tracking or third-party data sharing.

---

## 3. What We Do Not Collect

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

Environmental data sources such as EFFIS do **not** receive any personal information from us.

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

For privacy-related queries, please use the app's feedback feature.
''';

  static const String _disclaimerContent = '''
# WildFire — Emergency & Accuracy Disclaimer

**Version:** 1.0  
**Effective Date:** 18 December 2025

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
- damages or losses of any kind arising from reliance on the App's data
''';

  static const String _dataSourcesContent = '''
# WildFire — Data Sources & Attribution

**Version:** 1.0  
**Effective Date:** 18 December 2025

---

## 1. Overview

WildFire relies on multiple publicly available environmental datasets to provide indicative wildfire-risk values and fire-activity information.

This document explains those sources and their limitations.

---

## 2. Primary Data Sources

### Copernicus Emergency Management Service — EFFIS

Wildfire-risk forecasts and satellite-detected fire activity may be sourced from the **European Forest Fire Information System (EFFIS)**.

**Attribution:**
> © European Union, Copernicus Emergency Management Service (EMS).
> Data may be delayed or incomplete.

EFFIS data is provided without warranty and may include false positives or false negatives.

---

### Google Maps Platform

Map display and location services are provided by **Google Maps Platform**.

**Attribution:**
> © Google LLC. Maps data © Google.

Google Maps is used under the Google Maps Platform Terms of Service. Map tiles and geocoding are subject to Google's Privacy Policy.

---

### what3words

The App may display **what3words** addresses for easy location sharing.

**Attribution:**
> what3words addresses are provided by what3words Limited.

what3words is a registered trademark of what3words Limited. The service is used to convert coordinates to memorable three-word addresses.

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

EFFIS and any other listed data providers do **not** endorse this App.

They provide data under their own terms and licences, without warranty.
''';
}
