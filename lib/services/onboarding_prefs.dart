import 'package:wildfire_mvp_v3/models/consent_record.dart';

/// Service for managing onboarding and consent preferences.
///
/// Responsibilities:
/// - Check onboarding/migration status
/// - Retrieve consent records for GDPR compliance
/// - Save user preferences on onboarding completion
///
/// Dependencies:
/// - SharedPreferences (injected via implementation)
abstract class OnboardingPrefsService {
  // ─────────────────────────────────────────────────────────────
  // Status Checks
  // ─────────────────────────────────────────────────────────────

  /// Check if onboarding flow is required.
  ///
  /// Returns true if:
  /// - onboarding_version < currentOnboardingVersion
  /// - OR onboarding_version key doesn't exist (first launch)
  ///
  /// Returns false if:
  /// - onboarding_version >= currentOnboardingVersion
  Future<bool> isOnboardingRequired();

  /// Check if version migration is required.
  ///
  /// Returns true if:
  /// - onboarding_version > 0 (has completed onboarding before)
  /// - AND onboarding_version < currentOnboardingVersion (needs update)
  ///
  /// This is used to show "What's New" style migration screens
  /// for users upgrading from an older version.
  Future<bool> isMigrationRequired();

  // ─────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────

  /// Get the completed onboarding version.
  ///
  /// Returns:
  /// - 0 if never completed onboarding
  /// - N where N is the last completed version
  Future<int> getOnboardingVersion();

  /// Get user's consent record for GDPR audit.
  ///
  /// Returns:
  /// - ConsentRecord with termsVersion and acceptedAt if exists
  /// - null if no consent recorded or data is corrupted
  Future<ConsentRecord?> getConsentRecord();

  /// Get notification radius preference.
  ///
  /// Returns:
  /// - User's selected radius in km
  /// - Defaults to [OnboardingConfig.defaultRadiusKm] if not set
  Future<int> getNotificationRadiusKm();

  /// Get previous onboarding version for migration display.
  ///
  /// Returns:
  /// - Previous version number (before current session)
  /// - 0 if no previous version exists
  Future<int> getPreviousVersion();

  // ─────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────

  /// Complete onboarding and save all preferences.
  ///
  /// This atomically saves:
  /// - onboarding_version = currentOnboardingVersion
  /// - terms_accepted_version = currentTermsVersion
  /// - terms_accepted_timestamp = DateTime.now().millisecondsSinceEpoch
  /// - notification_radius_km = radiusKm
  ///
  /// Throws:
  /// - [ArgumentError] if radiusKm not in [OnboardingConfig.validRadiusOptions]
  Future<void> completeOnboarding({required int radiusKm});

  /// Update notification radius only.
  ///
  /// For use in settings screen to change radius without
  /// re-accepting terms.
  ///
  /// Throws:
  /// - [ArgumentError] if radiusKm not in [OnboardingConfig.validRadiusOptions]
  Future<void> updateNotificationRadius({required int radiusKm});
}
