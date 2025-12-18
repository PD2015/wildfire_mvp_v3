# Legal Documentation: Pre-Public Distribution Checklist

**Created:** 18 December 2025  
**Status:** For implementation before public App Store / Play Store release  
**Current Status:** Documents ready for tester/friends distribution

---

## ✅ Completed (Tester Distribution Ready)

- [x] Emergency numbers correct (999, 101)
- [x] EFFIS attribution with proper Copernicus credit
- [x] 6-hour cache TTL documented (matches code)
- [x] Geohash privacy (~1-5km redaction) described
- [x] No analytics/tracking statement (accurate)
- [x] Local-only storage described (SharedPreferences)
- [x] UK GDPR rights listed
- [x] Non-emergency disclaimer prominent
- [x] Removed SEPA references (service not implemented)
- [x] Consistent "WildFire" app name (not "WildFire App")
- [x] Current effective dates (18 December 2025)

---

## 🔲 Required Before Public Distribution

### High Priority

#### 1. Google Maps Attribution
**Location:** Data Sources document  
**Requirement:** Google ToS requires attribution for Maps usage  
**Action:** Add section:
```markdown
### Google Maps Platform

Map display and location services are provided by Google Maps Platform.

**Attribution:**
> © Google LLC. Google Maps is used under the Google Maps Platform Terms of Service.
```

#### 2. Developer Identity Disclosure
**Location:** Terms of Service, Section 1 (Introduction)  
**Current:** "Operated by an independent developer"  
**Issue:** Too vague for legal purposes  
**Options:**
- Add trading name: "Operated by [Name] trading as WildFire Scotland"
- Register company and use registered name
- At minimum: provide contact email for legal correspondence

---

### Medium Priority

#### 3. ICO Registration Statement
**Location:** Privacy Policy, Section 10 (Contact)  
**Requirement:** UK apps processing personal data should clarify ICO status  
**Action:** Add:
```markdown
**UK Regulatory Status:** This App processes only minimal, non-identifiable 
location data stored locally on your device. No registration with the 
Information Commissioner's Office is required. If you have concerns, 
you may contact the ICO at [ico.org.uk](https://ico.org.uk).
```

#### 4. Web Platform Storage Clarification
**Location:** Privacy Policy, Section 2e (No Analytics, No Tracking)  
**Issue:** "No cookies" is accurate for native but web uses localStorage  
**Action:** Clarify:
```markdown
**Note (Web Version):** The web version uses browser local storage for 
essential caching functionality. This is required for the app to function 
and does not involve tracking or third-party data sharing.
```

---

### Low Priority (Consider Before Public Release)

#### 5. Governing Law Review
**Current:** England and Wales  
**Consider:** Scottish law may be more appropriate for Scotland-focused app  
**Decision needed:** Consult legal advice or keep England/Wales (simpler)

#### 6. what3words Attribution (If Implemented)
**Status:** Spec exists but implementation status unclear  
**Action:** If what3words is active, add to Data Sources:
```markdown
### what3words

Location display may use what3words addressing.

**Attribution:**
> what3words addresses are provided by what3words Limited.
```

#### 7. App Store Specific Requirements
**For iOS App Store:**
- Privacy nutrition label will need completing
- May need more specific data collection declarations

**For Google Play:**
- Data safety section will need completing
- Similar declarations required

---

## Document Locations

All legal content is in: `lib/content/legal_content.dart`

| Document | Static Getter |
|----------|---------------|
| Terms of Service | `LegalContent.termsOfService` |
| Privacy Policy | `LegalContent.privacyPolicy` |
| Disclaimer | `LegalContent.disclaimer` |
| Data Sources | `LegalContent.dataSources` |

---

## Review History

| Date | Reviewer | Changes |
|------|----------|---------|
| 18 Dec 2025 | Agent review | Initial audit, removed SEPA, standardized naming |

---

*This checklist should be reviewed and items completed before submitting to public app stores.*
