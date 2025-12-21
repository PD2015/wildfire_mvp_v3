# Data Model: 022 – Onboarding & Legal Integration

**Generated**: 2025-12-10  
**Status**: Complete

---

## 1. Persistent Storage (SharedPreferences)

### Keys & Schema

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `onboarding_version` | int | 0 | Completed onboarding version (0 = never completed) |
| `terms_accepted_version` | int | 0 | Which terms version user accepted |
| `terms_accepted_timestamp` | int | 0 | UTC milliseconds when terms accepted |
| `notification_radius_km` | int | 10 | Notification distance preference |

### Version Constants

```dart
// lib/services/onboarding_prefs.dart
abstract class OnboardingPrefs {
  /// Current onboarding version - increment when terms change
  static const int currentOnboardingVersion = 1;
  
  /// Current terms version - increment when legal content changes
  static const int currentTermsVersion = 1;
  
  /// Valid notification radius options
  static const List<int> validRadiusOptions = [0, 5, 10, 25, 50];
  
  /// Default notification radius
  static const int defaultRadiusKm = 10;
}
```

---

## 2. Domain Models

### ConsentRecord

```dart
// lib/models/consent_record.dart
import 'package:equatable/equatable.dart';

/// Immutable record of user's legal consent for GDPR audit
class ConsentRecord extends Equatable {
  final int termsVersion;
  final DateTime acceptedAt;
  
  const ConsentRecord({
    required this.termsVersion,
    required this.acceptedAt,
  });
  
  /// Check if consent is for current terms version
  bool get isCurrentVersion => 
    termsVersion >= OnboardingPrefs.currentTermsVersion;
  
  /// Format for display (e.g., "Accepted on 10 Dec 2025 at 14:30 UTC")
  String get formattedDate {
    final utc = acceptedAt.toUtc();
    return '${utc.day} ${_monthName(utc.month)} ${utc.year} at '
           '${utc.hour.toString().padLeft(2, '0')}:'
           '${utc.minute.toString().padLeft(2, '0')} UTC';
  }
  
  @override
  List<Object?> get props => [termsVersion, acceptedAt];
}
```

### OnboardingState

```dart
// lib/features/onboarding/models/onboarding_state.dart
import 'package:equatable/equatable.dart';

/// State for onboarding screen
sealed class OnboardingState extends Equatable {
  const OnboardingState();
}

/// Initial loading state while checking preferences
class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
  
  @override
  List<Object?> get props => [];
}

/// Active onboarding flow state
class OnboardingActive extends OnboardingState {
  final int currentPage;
  final int totalPages;
  final bool disclaimerChecked;
  final bool termsChecked;
  final int selectedRadiusKm;
  final bool locationPermissionGranted;
  final bool isRequestingLocation;
  
  const OnboardingActive({
    this.currentPage = 0,
    this.totalPages = 4,
    this.disclaimerChecked = false,
    this.termsChecked = false,
    this.selectedRadiusKm = 10,
    this.locationPermissionGranted = false,
    this.isRequestingLocation = false,
  });
  
  /// Can proceed to next page (pages 0-2 always allowed, page 3 requires checkboxes)
  bool get canProceed => currentPage < 3 || (disclaimerChecked && termsChecked);
  
  /// Can finish onboarding (must be on last page with both checked)
  bool get canFinish => currentPage == 3 && disclaimerChecked && termsChecked;
  
  OnboardingActive copyWith({
    int? currentPage,
    bool? disclaimerChecked,
    bool? termsChecked,
    int? selectedRadiusKm,
    bool? locationPermissionGranted,
    bool? isRequestingLocation,
  }) {
    return OnboardingActive(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages,
      disclaimerChecked: disclaimerChecked ?? this.disclaimerChecked,
      termsChecked: termsChecked ?? this.termsChecked,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      locationPermissionGranted: locationPermissionGranted ?? this.locationPermissionGranted,
      isRequestingLocation: isRequestingLocation ?? this.isRequestingLocation,
    );
  }
  
  @override
  List<Object?> get props => [
    currentPage, totalPages, disclaimerChecked, termsChecked,
    selectedRadiusKm, locationPermissionGranted, isRequestingLocation,
  ];
}

/// Onboarding complete - ready to navigate away
class OnboardingComplete extends OnboardingState {
  const OnboardingComplete();
  
  @override
  List<Object?> get props => [];
}

/// Version migration required - show update notice
class OnboardingMigration extends OnboardingState {
  final int previousVersion;
  final int currentVersion;
  
  const OnboardingMigration({
    required this.previousVersion,
    required this.currentVersion,
  });
  
  @override
  List<Object?> get props => [previousVersion, currentVersion];
}
```

---

## 3. Legal Content Structure

### LegalDocument

```dart
// lib/content/legal_content.dart

/// Legal document metadata and content
class LegalDocument {
  final String id;
  final String title;
  final String version;
  final DateTime effectiveDate;
  final String content;
  
  const LegalDocument({
    required this.id,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.content,
  });
}

/// All legal documents for the app
class LegalContent {
  static const int contentVersion = 1;
  
  static final termsOfService = LegalDocument(
    id: 'terms',
    title: 'Terms of Service',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _termsContent,
  );
  
  static final privacyPolicy = LegalDocument(
    id: 'privacy',
    title: 'Privacy Policy',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _privacyContent,
  );
  
  static final emergencyDisclaimer = LegalDocument(
    id: 'disclaimer',
    title: 'Emergency & Accuracy Disclaimer',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _disclaimerContent,
  );
  
  static final dataSources = LegalDocument(
    id: 'data-sources',
    title: 'Data Sources & Attribution',
    version: '1.0',
    effectiveDate: DateTime(2025, 12, 10),
    content: _dataSourcesContent,
  );
  
  // Content strings (imported from docs/onboarding_legal_draft.md)
  static const String _termsContent = '''...''';
  static const String _privacyContent = '''...''';
  static const String _disclaimerContent = '''...''';
  static const String _dataSourcesContent = '''...''';
}
```

---

## 4. Service Interface

### OnboardingPrefsService

```dart
// lib/services/onboarding_prefs.dart

/// Service for managing onboarding preferences
abstract class OnboardingPrefsService {
  /// Check if onboarding is required (version < current)
  Future<bool> isOnboardingRequired();
  
  /// Get current onboarding version (0 = never completed)
  Future<int> getOnboardingVersion();
  
  /// Get consent record if exists
  Future<ConsentRecord?> getConsentRecord();
  
  /// Get notification radius preference
  Future<int> getNotificationRadiusKm();
  
  /// Complete onboarding and save all preferences
  Future<void> completeOnboarding({
    required int radiusKm,
  });
  
  /// Check if this is a version migration (has old version, needs new)
  Future<bool> isMigrationRequired();
  
  /// Get previous version for migration display
  Future<int> getPreviousVersion();
}
```

---

## 5. Route Structure

### New Routes

| Path | Name | Widget | Bottom Nav |
|------|------|--------|------------|
| `/onboarding` | onboarding | OnboardingScreen | No |
| `/about` | about | AboutScreen | No |
| `/about/terms` | terms | LegalDocumentScreen | No |
| `/about/privacy` | privacy | LegalDocumentScreen | No |
| `/about/data-sources` | data-sources | LegalDocumentScreen | No |

### Route Parameters

```dart
// LegalDocumentScreen receives document type via extra
GoRoute(
  path: '/about/terms',
  name: 'terms',
  builder: (context, state) => LegalDocumentScreen(
    document: LegalContent.termsOfService,
  ),
),
```

---

## 6. Widget Tree

```
OnboardingScreen
├── PageView (4 pages)
│   ├── WelcomePage
│   │   ├── HeroBackground (gradient or image)
│   │   ├── AppLogo
│   │   ├── OnboardingCard
│   │   │   ├── Title
│   │   │   ├── Body
│   │   │   └── BulletList
│   │   └── ContinueButton
│   │
│   ├── SafetyDisclaimerPage
│   │   ├── OnboardingCard
│   │   │   ├── WarningIcon
│   │   │   ├── DisclaimerText (999, 101 emphasized)
│   │   │   └── ViewTermsLink
│   │   └── ContinueButton
│   │
│   ├── PrivacyPage
│   │   ├── OnboardingCard
│   │   │   ├── PrivacyBullets
│   │   │   └── ViewPrivacyLink
│   │   └── ContinueButton
│   │
│   └── SetupConsentPage
│       ├── OnboardingCard
│       │   ├── LocationSection
│       │   │   └── LocationAccessButton
│       │   ├── RadiusSection
│       │   │   └── RadiusSelector (SegmentedButton)
│       │   └── ConsentSection
│       │       ├── DisclaimerCheckbox
│       │       ├── TermsCheckbox
│       │       └── ViewDisclaimerLink
│       └── GetStartedButton (disabled until both checked)
│
└── PageIndicator (4 dots)
```

---

## 7. State Transitions

```
[App Launch]
    │
    ▼
┌─────────────────────────────────┐
│  Check onboarding_version < 1   │
└─────────────────────────────────┘
    │                    │
    ▼ (yes)              ▼ (no)
┌─────────────┐    ┌─────────────┐
│ /onboarding │    │     /       │
└─────────────┘    │  (home)     │
    │              └─────────────┘
    ▼
┌─────────────────────────────────┐
│  Page 1: Welcome                │
│  [Continue] → Page 2            │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Page 2: Safety Disclaimer      │
│  [Continue] → Page 3            │
│  [View Terms] → push /about     │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Page 3: Privacy                │
│  [Continue] → Page 4            │
│  [View Privacy] → push /about/privacy │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Page 4: Setup & Consent        │
│  [Location] → trigger resolver  │
│  [Radius] → update selection    │
│  [Checkboxes] → enable button   │
│  [Get Started] → save & go /    │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Save preferences:              │
│  - onboarding_version = 1       │
│  - terms_accepted_version = 1   │
│  - terms_accepted_timestamp     │
│  - notification_radius_km       │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Navigate to / (home)           │
└─────────────────────────────────┘
```

---

## Summary

**Entities**: 3 (ConsentRecord, OnboardingState, LegalDocument)  
**Services**: 1 (OnboardingPrefsService)  
**Routes**: 5 new routes  
**SharedPreferences Keys**: 4  

Ready for contract generation and task planning.
