import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/models/consent_record.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs.dart';

/// SharedPreferences implementation of [OnboardingPrefsService].
///
/// Stores all onboarding-related preferences persistently.
class OnboardingPrefsImpl implements OnboardingPrefsService {
  final SharedPreferences _prefs;

  /// Create a new instance with injected SharedPreferences.
  ///
  /// Use [SharedPreferences.getInstance()] to obtain the instance:
  /// ```dart
  /// final prefs = await SharedPreferences.getInstance();
  /// final service = OnboardingPrefsImpl(prefs);
  /// ```
  OnboardingPrefsImpl(this._prefs);

  // ─────────────────────────────────────────────────────────────
  // Status Checks
  // ─────────────────────────────────────────────────────────────

  @override
  Future<bool> isOnboardingRequired() async {
    final version = _prefs.getInt(OnboardingConfig.keyOnboardingVersion) ?? 0;
    return version < OnboardingConfig.currentOnboardingVersion;
  }

  @override
  Future<bool> isMigrationRequired() async {
    final version = _prefs.getInt(OnboardingConfig.keyOnboardingVersion) ?? 0;
    // Migration is required if:
    // 1. User has completed onboarding before (version > 0)
    // 2. Their version is behind the current version
    return version > 0 && version < OnboardingConfig.currentOnboardingVersion;
  }

  // ─────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────

  @override
  Future<int> getOnboardingVersion() async {
    return _prefs.getInt(OnboardingConfig.keyOnboardingVersion) ?? 0;
  }

  @override
  Future<ConsentRecord?> getConsentRecord() async {
    final version = _prefs.getInt(OnboardingConfig.keyTermsVersion);
    final timestamp = _prefs.getInt(OnboardingConfig.keyTermsTimestamp);

    // Both values required for valid consent record
    if (version == null || timestamp == null) {
      return null;
    }

    // Validate timestamp is reasonable (after year 2020)
    if (timestamp < 1577836800000) {
      // 2020-01-01 in milliseconds
      return null;
    }

    try {
      return ConsentRecord(
        termsVersion: version,
        acceptedAt: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
      );
    } catch (e) {
      // Handle any DateTime conversion errors
      return null;
    }
  }

  @override
  Future<int> getNotificationRadiusKm() async {
    return _prefs.getInt(OnboardingConfig.keyNotificationRadius) ??
        OnboardingConfig.defaultRadiusKm;
  }

  @override
  Future<int> getPreviousVersion() async {
    return _prefs.getInt(OnboardingConfig.keyOnboardingVersion) ?? 0;
  }

  // ─────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> completeOnboarding({required int radiusKm}) async {
    _validateRadius(radiusKm);

    final now = DateTime.now().toUtc();

    // Save all preferences atomically
    await Future.wait([
      _prefs.setInt(
        OnboardingConfig.keyOnboardingVersion,
        OnboardingConfig.currentOnboardingVersion,
      ),
      _prefs.setInt(
        OnboardingConfig.keyTermsVersion,
        OnboardingConfig.currentTermsVersion,
      ),
      _prefs.setInt(
        OnboardingConfig.keyTermsTimestamp,
        now.millisecondsSinceEpoch,
      ),
      _prefs.setInt(
        OnboardingConfig.keyDisclaimerTimestamp,
        now.millisecondsSinceEpoch,
      ),
      _prefs.setInt(OnboardingConfig.keyNotificationRadius, radiusKm),
    ]);
  }

  @override
  Future<void> updateNotificationRadius({required int radiusKm}) async {
    _validateRadius(radiusKm);
    await _prefs.setInt(OnboardingConfig.keyNotificationRadius, radiusKm);
  }

  @override
  Future<void> resetOnboarding() async {
    await Future.wait([
      _prefs.remove(OnboardingConfig.keyOnboardingVersion),
      _prefs.remove(OnboardingConfig.keyTermsVersion),
      _prefs.remove(OnboardingConfig.keyTermsTimestamp),
      _prefs.remove(OnboardingConfig.keyDisclaimerTimestamp),
      _prefs.remove(OnboardingConfig.keyNotificationRadius),
    ]);
  }

  // ─────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────

  void _validateRadius(int radiusKm) {
    if (!OnboardingConfig.validRadiusOptions.contains(radiusKm)) {
      throw ArgumentError(
        'Invalid radius: $radiusKm. '
        'Must be one of: ${OnboardingConfig.validRadiusOptions.join(', ')}',
      );
    }
  }
}
