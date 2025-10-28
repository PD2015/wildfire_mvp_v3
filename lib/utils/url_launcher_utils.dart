import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';

/// Utilities for launching emergency calls using url_launcher
///
/// Provides safe URL launching with error handling and platform support
/// detection for emergency contact scenarios.
class UrlLauncherUtils {
  /// Launches an emergency call for the given contact
  ///
  /// Returns [CallResult] indicating the outcome of the call attempt.
  /// Handles platform-specific behavior and provides graceful error handling.
  ///
  /// Example:
  /// ```dart
  /// final result = await UrlLauncherUtils.launchEmergencyCall(
  ///   EmergencyContact.fireService
  /// );
  ///
  /// if (result == CallResult.failed) {
  ///   // Show SnackBar fallback
  /// }
  /// ```
  static Future<CallResult> launchEmergencyCall(
      EmergencyContact contact) async {
    try {
      debugPrint('🚨 Attempting emergency call: ${contact.displayText}');

      final uri = Uri.parse(contact.telUri);

      // Check if the platform can launch tel: URIs
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        debugPrint('❌ Platform cannot launch tel: URIs');
        return CallResult.unsupported;
      }

      // Attempt to launch the dialer
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Always use external dialer app
      );

      if (launched) {
        debugPrint('✅ Emergency call launched successfully');
        return CallResult.success;
      } else {
        debugPrint('❌ Failed to launch emergency call');
        return CallResult.failed;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception launching emergency call: $e');
      debugPrint('Stack trace: $stackTrace');
      return CallResult.failed;
    }
  }

  /// Validates a phone number format for emergency calling
  ///
  /// Performs basic validation to ensure the phone number is in a format
  /// suitable for emergency calling. Returns true if valid.
  ///
  /// Example:
  /// ```dart
  /// final isValid = UrlLauncherUtils.isValidPhoneNumber('999');     // true
  /// final isValid = UrlLauncherUtils.isValidPhoneNumber('');        // false
  /// final isValid = UrlLauncherUtils.isValidPhoneNumber('abc');     // false
  /// ```
  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;

    // Remove all non-digit characters for validation
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Must contain at least 3 digits (e.g., "999", "101")
    if (digitsOnly.length < 3) return false;

    // UK emergency/service numbers are typically 3-11 digits
    if (digitsOnly.length > 11) return false;

    return true;
  }

  /// Formats a phone number for tel: URI scheme
  ///
  /// Converts a human-readable phone number to the format required
  /// for tel: URIs by removing all non-digit characters.
  ///
  /// Example:
  /// ```dart
  /// final uri = UrlLauncherUtils.formatTelUri('0800 555 111');  // 'tel:0800555111'
  /// final uri = UrlLauncherUtils.formatTelUri('999');          // 'tel:999'
  /// ```
  static String formatTelUri(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return 'tel:$digitsOnly';
  }

  /// Generates user-friendly error message for failed emergency calls
  ///
  /// Creates appropriate error messages based on the call result and context.
  /// Used for SnackBar fallback messages when dialer cannot be launched.
  ///
  /// Example:
  /// ```dart
  /// final message = UrlLauncherUtils.getErrorMessage(
  ///   CallResult.unsupported,
  ///   EmergencyContact.fireService,
  /// );
  /// // Returns: "Could not open dialer. Please call 999 manually."
  /// ```
  static String getErrorMessage(CallResult result, EmergencyContact contact) {
    final phoneNumber = contact.phoneNumber;

    switch (result) {
      case CallResult.unsupported:
        return 'Could not open dialer. Please call $phoneNumber manually.';
      case CallResult.failed:
        return 'Could not open dialer for $phoneNumber. Please try again or dial manually.';
      case CallResult.cancelled:
        return 'Call to $phoneNumber was cancelled.';
      case CallResult.success:
        return 'Successfully opened dialer for $phoneNumber.';
    }
  }

  /// Checks if the current platform supports tel: URI launching
  ///
  /// Returns true if the platform can launch tel: URIs for dialing.
  /// Useful for showing appropriate UI elements based on capability.
  ///
  /// Note: This is an approximation based on platform detection.
  /// The actual capability is checked during launch attempts.
  static bool get platformSupportsDialing {
    // Web platforms typically don't support tel: URIs in embedded contexts
    if (kIsWeb) return false;

    // Mobile platforms support tel: URIs natively
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Creates a complete emergency call flow with error handling
  ///
  /// Handles the full flow of attempting an emergency call and provides
  /// a callback for UI feedback (e.g., showing SnackBar on failure).
  ///
  /// Example:
  /// ```dart
  /// await UrlLauncherUtils.handleEmergencyCall(
  ///   contact: EmergencyContact.fireService,
  ///   onFailure: (message) => ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text(message)),
  ///   ),
  /// );
  /// ```
  static Future<void> handleEmergencyCall({
    required EmergencyContact contact,
    required void Function(String message) onFailure,
  }) async {
    final result = await launchEmergencyCall(contact);

    if (result != CallResult.success) {
      final errorMessage = getErrorMessage(result, contact);
      onFailure(errorMessage);
    }
  }
}
