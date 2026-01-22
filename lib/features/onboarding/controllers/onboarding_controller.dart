import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/onboarding_state.dart';
import '../../../models/consent_record.dart';
import '../../../services/onboarding_prefs.dart';
import '../../../services/location_resolver.dart';

/// Controller for the onboarding flow.
///
/// Manages state transitions through the 4-page onboarding flow:
/// 1. Welcome - app introduction
/// 2. Disclaimer - safety information acknowledgment
/// 3. Privacy - data collection transparency
/// 4. Setup - notification preferences and consent
///
/// Responsibilities:
/// - Check onboarding/migration status on initialization
/// - Track page navigation state
/// - Manage consent checkbox states
/// - Handle location permission requests
/// - Save preferences on completion
///
/// Constitutional compliance:
/// - C1: Clean architecture with dependency injection
/// - C2: Privacy-compliant logging (no location data exposure)
class OnboardingController extends ChangeNotifier {
  final OnboardingPrefsService _prefsService;
  final LocationResolver? _locationResolver;

  OnboardingState _state = const OnboardingLoading();

  /// Current state of the onboarding flow
  OnboardingState get state => _state;

  /// Whether the user is currently on a page that allows proceeding
  bool get canProceed => switch (_state) {
    OnboardingActive(canProceed: final proceed) => proceed,
    _ => false,
  };

  /// Whether the user can complete onboarding
  bool get canComplete => switch (_state) {
    OnboardingActive(canFinish: final finish) => finish,
    _ => false,
  };

  /// Creates an OnboardingController with required dependencies.
  ///
  /// [prefsService] - Service for reading/writing onboarding preferences
  /// [locationResolver] - Optional service for location permission requests
  OnboardingController({
    required OnboardingPrefsService prefsService,
    LocationResolver? locationResolver,
  }) : _prefsService = prefsService,
       _locationResolver = locationResolver {
    developer.log('OnboardingController initialized', name: 'Onboarding');
  }

  /// Initialize the controller by checking onboarding status.
  ///
  /// Determines whether:
  /// - First-time onboarding is needed
  /// - Migration from older version is needed
  /// - Onboarding is already complete
  Future<void> initialize() async {
    developer.log('Checking onboarding status...', name: 'Onboarding');

    try {
      final isRequired = await _prefsService.isOnboardingRequired();

      if (!isRequired) {
        developer.log('Onboarding already complete', name: 'Onboarding');
        _updateState(const OnboardingComplete());
        return;
      }

      final isMigration = await _prefsService.isMigrationRequired();
      final previousRadius = await _prefsService.getNotificationRadiusKm();

      developer.log(
        'Onboarding required: isMigration=$isMigration',
        name: 'Onboarding',
      );

      if (isMigration) {
        final previousVersion = await _prefsService.getPreviousVersion();
        _updateState(
          OnboardingMigration(
            previousVersion: previousVersion,
            currentVersion: OnboardingConfig.currentOnboardingVersion,
          ),
        );
      } else {
        _updateState(
          OnboardingActive(
            currentPage: 0,
            selectedRadiusKm: previousRadius,
            termsChecked: false,
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Error checking onboarding status: $e',
        name: 'Onboarding',
        level: 1000, // Warning level
      );
      // Default to requiring onboarding on error
      _updateState(const OnboardingActive(currentPage: 0));
    }
  }

  /// Navigate to the next page in the onboarding flow.
  ///
  /// Only advances if currently on a page that allows proceeding.
  void nextPage() {
    final currentState = _state;
    if (currentState is! OnboardingActive) return;
    if (!currentState.canProceed) return;

    final nextPageIndex = currentState.currentPage + 1;
    if (nextPageIndex >= 4) return; // Max 4 pages (0-3)

    developer.log('Advancing to page $nextPageIndex', name: 'Onboarding');

    _updateState(currentState.copyWith(currentPage: nextPageIndex));
  }

  /// Navigate to a specific page.
  ///
  /// Used for backward navigation (e.g., returning from legal routes).
  void goToPage(int page) {
    final currentState = _state;
    if (currentState is! OnboardingActive) return;
    if (page < 0 || page >= 4) return;

    developer.log('Going to page $page', name: 'Onboarding');
    _updateState(currentState.copyWith(currentPage: page));
  }

  /// Update the terms checkbox state.
  void setTermsChecked(bool checked) {
    final currentState = _state;
    if (currentState is! OnboardingActive) return;

    developer.log('Terms checked: $checked', name: 'Onboarding');
    _updateState(currentState.copyWith(termsChecked: checked));
  }

  /// Update the selected notification radius.
  void setRadius(int radiusKm) {
    final currentState = _state;
    if (currentState is! OnboardingActive) return;

    if (!OnboardingConfig.validRadiusOptions.contains(radiusKm)) {
      developer.log(
        'Invalid radius: $radiusKm',
        name: 'Onboarding',
        level: 1000,
      );
      return;
    }

    developer.log('Radius selected: ${radiusKm}km', name: 'Onboarding');
    _updateState(currentState.copyWith(selectedRadiusKm: radiusKm));
  }

  /// Request location permission.
  ///
  /// Uses the LocationResolver to trigger permission request.
  /// This is optional and doesn't block onboarding completion.
  Future<void> requestLocation() async {
    if (_locationResolver == null) {
      developer.log(
        'No LocationResolver available',
        name: 'Onboarding',
        level: 1000,
      );
      return;
    }

    final currentState = _state;
    if (currentState is! OnboardingActive) return;

    developer.log('Requesting location permission...', name: 'Onboarding');
    _updateState(currentState.copyWith(isRequestingLocation: true));

    try {
      final result = await _locationResolver!.getLatLon();

      final success = result.fold((error) => false, (location) => true);

      if (success) {
        developer.log('Location permission granted', name: 'Onboarding');
      } else {
        developer.log(
          'Location permission denied or unavailable',
          name: 'Onboarding',
        );
      }

      // Update state regardless of result
      final updatedState = _state;
      if (updatedState is OnboardingActive) {
        _updateState(
          updatedState.copyWith(
            isRequestingLocation: false,
            locationPermissionGranted: success,
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Error requesting location: $e',
        name: 'Onboarding',
        level: 1000,
      );

      final updatedState = _state;
      if (updatedState is OnboardingActive) {
        _updateState(updatedState.copyWith(isRequestingLocation: false));
      }
    }
  }

  /// Complete onboarding and save preferences.
  ///
  /// Validates that all required consents are given, saves preferences
  /// via the PrefsService, and transitions to the Complete state.
  ///
  /// Returns true if completion was successful, false otherwise.
  Future<bool> completeOnboarding() async {
    final currentState = _state;
    if (currentState is! OnboardingActive) {
      developer.log(
        'Cannot complete: not in active state',
        name: 'Onboarding',
        level: 1000,
      );
      return false;
    }

    if (!currentState.canFinish) {
      developer.log(
        'Cannot complete: requirements not met',
        name: 'Onboarding',
        level: 1000,
      );
      return false;
    }

    developer.log(
      'Completing onboarding with radius: ${currentState.selectedRadiusKm}km',
      name: 'Onboarding',
    );

    try {
      await _prefsService.completeOnboarding(
        radiusKm: currentState.selectedRadiusKm,
      );

      developer.log('Onboarding completed successfully', name: 'Onboarding');
      _updateState(const OnboardingComplete());
      return true;
    } catch (e) {
      developer.log(
        'Error completing onboarding: $e',
        name: 'Onboarding',
        level: 1000,
      );
      return false;
    }
  }

  /// Reset onboarding state (for testing or re-onboarding).
  void reset() {
    developer.log('Resetting onboarding state', name: 'Onboarding');
    _updateState(const OnboardingLoading());
  }

  void _updateState(OnboardingState newState) {
    _state = newState;
    notifyListeners();
  }
}
