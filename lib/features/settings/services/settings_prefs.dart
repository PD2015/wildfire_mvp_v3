import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing settings preferences.
///
/// Provides persistent storage for user settings including:
/// - Notification preferences (UI placeholders, not yet implemented)
/// - Developer options unlock state
///
/// All settings use SharedPreferences for local persistence.
class SettingsPrefs {
  final SharedPreferences _prefs;

  /// SharedPreferences keys for settings
  static const String keyAlertsEnabled = 'settings_alerts_enabled';
  static const String keyAlertDistanceKm = 'settings_alert_distance_km';
  static const String keyDevOptionsUnlocked = 'settings_dev_unlocked';

  /// Default values
  static const bool defaultAlertsEnabled = false;
  static const double defaultAlertDistanceKm = 25.0;

  /// Create a new instance with injected SharedPreferences.
  ///
  /// Use [SharedPreferences.getInstance()] to obtain the instance:
  /// ```dart
  /// final prefs = await SharedPreferences.getInstance();
  /// final settingsPrefs = SettingsPrefs(prefs);
  /// ```
  SettingsPrefs(this._prefs);

  // ─────────────────────────────────────────────────────────────
  // Notification Settings (UI placeholders - not yet functional)
  // ─────────────────────────────────────────────────────────────

  /// Check if alerts are enabled.
  ///
  /// Note: This is a UI placeholder. Actual push notifications
  /// are not yet implemented.
  bool get alertsEnabled =>
      _prefs.getBool(keyAlertsEnabled) ?? defaultAlertsEnabled;

  /// Set alerts enabled state.
  ///
  /// Note: This is a UI placeholder. Actual push notifications
  /// are not yet implemented.
  Future<void> setAlertsEnabled(bool enabled) async {
    await _prefs.setBool(keyAlertsEnabled, enabled);
  }

  /// Get the alert distance radius in kilometers.
  ///
  /// Note: This is a UI placeholder. Actual push notifications
  /// are not yet implemented.
  double get alertDistanceKm =>
      _prefs.getDouble(keyAlertDistanceKm) ?? defaultAlertDistanceKm;

  /// Set the alert distance radius in kilometers.
  ///
  /// Note: This is a UI placeholder. Actual push notifications
  /// are not yet implemented.
  Future<void> setAlertDistanceKm(double km) async {
    await _prefs.setDouble(keyAlertDistanceKm, km);
  }

  // ─────────────────────────────────────────────────────────────
  // Developer Options
  // ─────────────────────────────────────────────────────────────

  /// Check if developer options have been unlocked.
  ///
  /// In release builds, developer options are hidden by default and
  /// require tapping the version number 7 times to unlock.
  /// In debug builds, they are always visible.
  bool get devOptionsUnlocked => _prefs.getBool(keyDevOptionsUnlocked) ?? false;

  /// Unlock developer options.
  ///
  /// Once unlocked, developer options remain visible until
  /// explicitly locked or app data is cleared.
  Future<void> unlockDevOptions() async {
    await _prefs.setBool(keyDevOptionsUnlocked, true);
  }

  /// Lock developer options.
  ///
  /// Hides the developer options section in settings
  /// (only relevant in release builds).
  Future<void> lockDevOptions() async {
    await _prefs.setBool(keyDevOptionsUnlocked, false);
  }

  // ─────────────────────────────────────────────────────────────
  // Debug Utilities
  // ─────────────────────────────────────────────────────────────

  /// Reset all settings to defaults.
  ///
  /// This is primarily for testing and development.
  Future<void> resetAll() async {
    await _prefs.remove(keyAlertsEnabled);
    await _prefs.remove(keyAlertDistanceKm);
    await _prefs.remove(keyDevOptionsUnlocked);
  }
}
