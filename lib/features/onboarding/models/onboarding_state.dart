import 'package:equatable/equatable.dart';

import 'package:wildfire_mvp_v3/models/consent_record.dart';

/// Base class for onboarding state hierarchy.
///
/// Uses sealed class pattern for exhaustive switch statements.
sealed class OnboardingState extends Equatable {
  const OnboardingState();
}

/// Initial loading state while checking preferences.
///
/// Displayed briefly while checking if onboarding is required.
class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();

  @override
  List<Object?> get props => [];
}

/// Active onboarding flow state with page tracking.
///
/// Tracks:
/// - Current page position (0-3)
/// - Consent checkbox states
/// - Notification radius selection
/// - Location permission status
class OnboardingActive extends OnboardingState {
  /// Current page index (0-3)
  final int currentPage;

  /// Total number of pages (always 4)
  final int totalPages;

  /// Whether the disclaimer checkbox is checked
  final bool disclaimerChecked;

  /// Whether the terms checkbox is checked
  final bool termsChecked;

  /// Selected notification radius in kilometers
  final int selectedRadiusKm;

  /// Whether location permission has been granted
  final bool locationPermissionGranted;

  /// Whether a location request is in progress
  final bool isRequestingLocation;

  const OnboardingActive({
    this.currentPage = 0,
    this.totalPages = 4,
    this.disclaimerChecked = false,
    this.termsChecked = false,
    this.selectedRadiusKm = OnboardingConfig.defaultRadiusKm,
    this.locationPermissionGranted = false,
    this.isRequestingLocation = false,
  });

  /// Whether the user can proceed to the next page.
  ///
  /// - Pages 0-2: Always allowed (informational)
  /// - Page 3: Requires both checkboxes to be checked
  bool get canProceed {
    if (currentPage < 3) {
      return true;
    }
    return disclaimerChecked && termsChecked;
  }

  /// Whether the user can finish onboarding.
  ///
  /// Must be on the last page (3) with both checkboxes checked.
  bool get canFinish => currentPage == 3 && disclaimerChecked && termsChecked;

  /// Whether there is a next page available.
  bool get hasNextPage => currentPage < totalPages - 1;

  /// Whether the user is on the final page.
  bool get isLastPage => currentPage == totalPages - 1;

  /// Create a copy with updated values.
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
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      isRequestingLocation: isRequestingLocation ?? this.isRequestingLocation,
    );
  }

  @override
  List<Object?> get props => [
        currentPage,
        totalPages,
        disclaimerChecked,
        termsChecked,
        selectedRadiusKm,
        locationPermissionGranted,
        isRequestingLocation,
      ];

  @override
  String toString() => 'OnboardingActive('
      'page: $currentPage/$totalPages, '
      'disclaimer: $disclaimerChecked, '
      'terms: $termsChecked, '
      'radius: ${selectedRadiusKm}km)';
}

/// Onboarding complete - ready to navigate to main app.
class OnboardingComplete extends OnboardingState {
  const OnboardingComplete();

  @override
  List<Object?> get props => [];
}

/// Version migration required - show update notice.
///
/// Used when a user has completed an older version of onboarding
/// and needs to acknowledge updated terms.
class OnboardingMigration extends OnboardingState {
  /// The version the user previously completed
  final int previousVersion;

  /// The current version that needs acceptance
  final int currentVersion;

  const OnboardingMigration({
    required this.previousVersion,
    required this.currentVersion,
  });

  @override
  List<Object?> get props => [previousVersion, currentVersion];

  @override
  String toString() =>
      'OnboardingMigration(from: $previousVersion, to: $currentVersion)';
}
