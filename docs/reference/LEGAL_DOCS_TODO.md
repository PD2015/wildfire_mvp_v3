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
- [x] Google Maps attribution added to Data Sources
- [x] what3words attribution added to Data Sources
- [x] Web localStorage clarification in Privacy Policy

---

## 🔲 Required Before Public Distribution

### High Priority

#### 1. Developer Identity Disclosure
**Location:** Terms of Service, Section 1 (Introduction)  
**Current:** "Operated by an independent developer"  
**Issue:** Too vague for legal purposes  
**Options:**
- Add trading name: "Operated by [Name] trading as WildFire Scotland"
- Register company and use registered name
- At minimum: provide contact email for legal correspondence

---

### Medium Priority

#### 2. ICO Registration Statement
**Location:** Privacy Policy, Section 10 (Contact)  
**Requirement:** UK apps processing personal data should clarify ICO status  
**Action:** Add:
```markdown
**UK Regulatory Status:** This App processes only minimal, non-identifiable 
location data stored locally on your device. No registration with the 
Information Commissioner's Office is required. If you have concerns, 
you may contact the ICO at [ico.org.uk](https://ico.org.uk).
```

---

### Low Priority (Consider Before Public Release)

#### 3. Governing Law Review
**Current:** England and Wales  
**Consider:** Scottish law may be more appropriate for Scotland-focused app  
**Decision needed:** Consult legal advice or keep England/Wales (simpler)

#### 4. App Store Specific Requirements
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
