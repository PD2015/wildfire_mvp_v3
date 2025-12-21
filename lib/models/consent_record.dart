import 'package:equatable/equatable.dart';

/// Configuration constants for onboarding and consent tracking.
///
/// Version numbers should be incremented when:
/// - [currentOnboardingVersion]: The onboarding flow structure changes
/// - [currentTermsVersion]: Legal document content changes
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
  static const String keyDisclaimerTimestamp =
      'disclaimer_acknowledged_timestamp';
  static const String keyNotificationRadius = 'notification_radius_km';
}

/// Immutable record of user's legal consent for GDPR audit trail.
///
/// Stores which version of terms the user accepted and when.
/// Used for:
/// - Displaying consent status in settings
/// - Auditing GDPR compliance
/// - Detecting when re-consent is needed after terms updates
class ConsentRecord extends Equatable {
  /// The version of terms that was accepted
  final int termsVersion;

  /// UTC timestamp when consent was given
  final DateTime acceptedAt;

  const ConsentRecord({required this.termsVersion, required this.acceptedAt});

  /// Check if consent is for current terms version.
  ///
  /// Returns `true` if the user has accepted the current or newer terms.
  /// Returns `false` if terms have been updated since consent was given.
  bool get isCurrentVersion =>
      termsVersion >= OnboardingConfig.currentTermsVersion;

  /// Format the acceptance timestamp for display.
  ///
  /// Returns a human-readable string like "10 Dec 2025 at 14:30 UTC".
  String get formattedDate {
    final utc = acceptedAt.toUtc();
    return '${utc.day} ${_monthName(utc.month)} ${utc.year} at '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')} UTC';
  }

  /// Convert month number to abbreviated name.
  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  List<Object?> get props => [termsVersion, acceptedAt];

  @override
  String toString() =>
      'ConsentRecord(termsVersion: $termsVersion, acceptedAt: $acceptedAt)';
}
