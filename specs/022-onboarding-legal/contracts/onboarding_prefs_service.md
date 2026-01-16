# Contract: OnboardingPrefsService

**Version**: 1.0  
**Status**: Draft

---

## Interface Definition

```dart
/// Service for managing onboarding and consent preferences
/// 
/// Responsibilities:
/// - Check onboarding/migration status
/// - Retrieve consent records for GDPR compliance
/// - Save user preferences on onboarding completion
/// 
/// Dependencies:
/// - SharedPreferences (injected)
abstract class OnboardingPrefsService {
  // ─────────────────────────────────────────────────────────────
  // Status Checks
  // ─────────────────────────────────────────────────────────────
  
  /// Check if onboarding flow is required
  /// 
  /// Returns true if:
  /// - onboarding_version < currentOnboardingVersion
  /// - OR onboarding_version key doesn't exist (first launch)
  /// 
  /// Returns false if:
  /// - onboarding_version >= currentOnboardingVersion
  Future<bool> isOnboardingRequired();
  
  /// Check if version migration is required
  /// 
  /// Returns true if:
  /// - onboarding_version > 0 (has completed onboarding before)
  /// - AND onboarding_version < currentOnboardingVersion (needs update)
  /// 
  /// This is used to show "What's New" style migration screens
  Future<bool> isMigrationRequired();
  
  // ─────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────
  
  /// Get the completed onboarding version
  /// 
  /// Returns:
  /// - 0 if never completed onboarding
  /// - N where N is the last completed version
  Future<int> getOnboardingVersion();
  
  /// Get user's consent record for GDPR audit
  /// 
  /// Returns:
  /// - ConsentRecord with termsVersion and acceptedAt if exists
  /// - null if no consent recorded
  Future<ConsentRecord?> getConsentRecord();
  
  /// Get notification radius preference
  /// 
  /// Returns:
  /// - User's selected radius in km
  /// - Defaults to 10 if not set
  Future<int> getNotificationRadiusKm();
  
  /// Get previous onboarding version for migration display
  /// 
  /// Returns:
  /// - Previous version number (before migration)
  /// - 0 if no previous version
  Future<int> getPreviousVersion();
  
  // ─────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────
  
  /// Complete onboarding and save all preferences
  /// 
  /// This atomically saves:
  /// - onboarding_version = currentOnboardingVersion
  /// - terms_accepted_version = currentTermsVersion
  /// - terms_accepted_timestamp = DateTime.now().millisecondsSinceEpoch
  /// - notification_radius_km = radiusKm
  /// 
  /// Throws:
  /// - ArgumentError if radiusKm not in validRadiusOptions
  Future<void> completeOnboarding({required int radiusKm});
  
  /// Update notification radius only
  /// 
  /// Throws:
  /// - ArgumentError if radiusKm not in validRadiusOptions
  Future<void> updateNotificationRadius({required int radiusKm});
}
```

---

## Constants

```dart
/// Onboarding configuration constants
class OnboardingConfig {
  OnboardingConfig._();
  
  /// Current onboarding version - increment when flow changes
  static const int currentOnboardingVersion = 1;
  
  /// Current terms version - increment when legal content changes
  static const int currentTermsVersion = 1;
  
  /// Valid notification radius options (km)
  static const List<int> validRadiusOptions = [0, 5, 10, 25, 50];
  
  /// Default notification radius (km)
  static const int defaultRadiusKm = 10;
  
  /// SharedPreferences keys
  static const String keyOnboardingVersion = 'onboarding_version';
  static const String keyTermsVersion = 'terms_accepted_version';
  static const String keyTermsTimestamp = 'terms_accepted_timestamp';
  static const String keyNotificationRadius = 'notification_radius_km';
}
```

---

## Implementation Contract

### Pre-conditions

| Method | Pre-condition |
|--------|---------------|
| `completeOnboarding` | radiusKm ∈ validRadiusOptions |
| `updateNotificationRadius` | radiusKm ∈ validRadiusOptions |

### Post-conditions

| Method | Post-condition |
|--------|----------------|
| `completeOnboarding` | All 4 keys written to SharedPreferences |
| `completeOnboarding` | timestamp is UTC milliseconds since epoch |
| `getConsentRecord` | Returns null if any required key missing |
| `getNotificationRadiusKm` | Returns defaultRadiusKm if key missing |

### Error Handling

| Scenario | Behavior |
|----------|----------|
| SharedPreferences unavailable | Rethrow (fatal) |
| Invalid radius value | Throw ArgumentError |
| Missing keys on read | Return default/null |
| Corrupted timestamp | Return null for ConsentRecord |

---

## Test Cases

### Unit Tests

```dart
group('OnboardingPrefsService', () {
  group('isOnboardingRequired', () {
    test('returns true when no onboarding_version exists', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingPrefsServiceImpl();
      expect(await service.isOnboardingRequired(), isTrue);
    });
    
    test('returns true when version < current', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_version': 0,
      });
      final service = OnboardingPrefsServiceImpl();
      expect(await service.isOnboardingRequired(), isTrue);
    });
    
    test('returns false when version >= current', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_version': 1,
      });
      final service = OnboardingPrefsServiceImpl();
      expect(await service.isOnboardingRequired(), isFalse);
    });
  });
  
  group('isMigrationRequired', () {
    test('returns false for first-time users', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingPrefsServiceImpl();
      expect(await service.isMigrationRequired(), isFalse);
    });
    
    test('returns true when has old version and needs update', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_version': 1,
      });
      // Simulate version bump
      // currentOnboardingVersion = 2
      final service = OnboardingPrefsServiceImpl();
      expect(await service.isMigrationRequired(), isTrue);
    });
  });
  
  group('completeOnboarding', () {
    test('saves all 4 preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingPrefsServiceImpl();
      
      await service.completeOnboarding(radiusKm: 25);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('onboarding_version'), equals(1));
      expect(prefs.getInt('terms_accepted_version'), equals(1));
      expect(prefs.getInt('terms_accepted_timestamp'), isNotNull);
      expect(prefs.getInt('notification_radius_km'), equals(25));
    });
    
    test('throws ArgumentError for invalid radius', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingPrefsServiceImpl();
      
      expect(
        () => service.completeOnboarding(radiusKm: 15),
        throwsArgumentError,
      );
    });
  });
  
  group('getConsentRecord', () {
    test('returns null when not consented', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingPrefsServiceImpl();
      expect(await service.getConsentRecord(), isNull);
    });
    
    test('returns ConsentRecord when consented', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'terms_accepted_version': 1,
        'terms_accepted_timestamp': timestamp,
      });
      final service = OnboardingPrefsServiceImpl();
      
      final record = await service.getConsentRecord();
      expect(record, isNotNull);
      expect(record!.termsVersion, equals(1));
      expect(record.acceptedAt.millisecondsSinceEpoch, equals(timestamp));
    });
  });
});
```

---

## Mock Implementation

```dart
/// Test mock for OnboardingPrefsService
class MockOnboardingPrefsService implements OnboardingPrefsService {
  bool _onboardingRequired = true;
  bool _migrationRequired = false;
  int _onboardingVersion = 0;
  int _radiusKm = 10;
  ConsentRecord? _consentRecord;
  
  void setOnboardingRequired(bool value) => _onboardingRequired = value;
  void setMigrationRequired(bool value) => _migrationRequired = value;
  void setOnboardingVersion(int value) => _onboardingVersion = value;
  void setConsentRecord(ConsentRecord? record) => _consentRecord = record;
  
  @override
  Future<bool> isOnboardingRequired() async => _onboardingRequired;
  
  @override
  Future<bool> isMigrationRequired() async => _migrationRequired;
  
  @override
  Future<int> getOnboardingVersion() async => _onboardingVersion;
  
  @override
  Future<ConsentRecord?> getConsentRecord() async => _consentRecord;
  
  @override
  Future<int> getNotificationRadiusKm() async => _radiusKm;
  
  @override
  Future<int> getPreviousVersion() async => _onboardingVersion;
  
  @override
  Future<void> completeOnboarding({required int radiusKm}) async {
    _onboardingVersion = OnboardingConfig.currentOnboardingVersion;
    _radiusKm = radiusKm;
    _onboardingRequired = false;
    _consentRecord = ConsentRecord(
      termsVersion: OnboardingConfig.currentTermsVersion,
      acceptedAt: DateTime.now(),
    );
  }
  
  @override
  Future<void> updateNotificationRadius({required int radiusKm}) async {
    _radiusKm = radiusKm;
  }
}
```

---

## Integration Points

| Consumer | Usage |
|----------|-------|
| `main.dart` | Pre-load prefs, pass to app |
| `app.dart` | Router redirect checks `isOnboardingRequired()` |
| `OnboardingController` | Calls `completeOnboarding()` on finish |
| `SettingsScreen` | Calls `getConsentRecord()` for audit display |
| `NotificationService` (future) | Calls `getNotificationRadiusKm()` |
