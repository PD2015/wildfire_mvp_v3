import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/geolocator_service.dart';

/// Fake timer for controlling time-dependent operations in tests
class FakeTimer {
  final List<Timer> _timers = [];
  Duration _elapsed = Duration.zero;

  /// Create a fake timer that can be controlled in tests
  Timer createTimer(Duration duration, VoidCallback callback) {
    final timer = Timer(duration, callback);
    _timers.add(timer);
    return timer;
  }

  /// Advance time by the given duration and trigger any expired timers
  void advance(Duration duration) {
    _elapsed += duration;
    // In real implementation, would trigger expired timers
    // For simplicity, we'll just track elapsed time
  }

  /// Get total elapsed time
  Duration get elapsed => _elapsed;

  /// Clear all timers
  void clear() {
    _timers.clear();
    _elapsed = Duration.zero;
  }
}

/// Fake Geolocator for testing GPS operations without real hardware
class FakeGeolocator implements GeolocatorService {
  bool _isLocationServiceEnabled = true;
  LocationPermission _permission = LocationPermission.whileInUse;
  Position? _lastKnownPosition;
  Position? _currentPosition;
  Duration _responseDelay = const Duration(milliseconds: 100);
  Exception? _exception;

  /// Configure whether location services are enabled
  void setLocationServiceEnabled(bool enabled) {
    _isLocationServiceEnabled = enabled;
  }

  /// Configure the permission status
  void setPermission(LocationPermission permission) {
    _permission = permission;
  }

  /// Set the last known position to return
  void setLastKnownPosition(Position? position) {
    _lastKnownPosition = position;
  }

  /// Set the current position to return
  void setCurrentPosition(Position? position) {
    _currentPosition = position;
  }

  /// Set delay for GPS responses (simulates slow GPS)
  void setResponseDelay(Duration delay) {
    _responseDelay = delay;
  }

  /// Configure an exception to throw
  void setException(Exception? exception) {
    _exception = exception;
  }

  /// Mock implementation of isLocationServiceEnabled
  @override
  Future<bool> isLocationServiceEnabled() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _isLocationServiceEnabled;
  }

  /// Mock implementation of checkPermission
  @override
  Future<LocationPermission> checkPermission() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _permission;
  }

  /// Mock implementation of requestPermission
  @override
  Future<LocationPermission> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Simulate user interaction delay
    return _permission;
  }

  /// Mock implementation of getLastKnownPosition
  @override
  Future<Position?> getLastKnownPosition() async {
    await Future.delayed(const Duration(milliseconds: 5));
    if (_exception != null) throw _exception!;
    return _lastKnownPosition;
  }

  /// Mock implementation of getCurrentPosition
  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.best,
    Duration? timeLimit,
  }) async {
    await Future.delayed(_responseDelay);

    if (_exception != null) throw _exception!;

    if (_currentPosition == null) {
      throw const LocationServiceDisabledException();
    }

    // Simulate timeout if response delay exceeds timeLimit
    if (timeLimit != null && _responseDelay > timeLimit) {
      throw TimeoutException('GPS timeout', timeLimit);
    }

    return _currentPosition!;
  }

  /// Reset all configuration to defaults
  void reset() {
    _isLocationServiceEnabled = true;
    _permission = LocationPermission.whileInUse;
    _lastKnownPosition = null;
    _currentPosition = null;
    _responseDelay = const Duration(milliseconds: 100);
    _exception = null;
  }
}

/// Fake SharedPreferences for testing persistence without real storage
class FakeSharedPreferences {
  final Map<String, dynamic> _storage = {};
  bool _throwOnRead = false;
  bool _throwOnWrite = false;

  /// Configure to throw exception on read operations
  void setThrowOnRead(bool shouldThrow) {
    _throwOnRead = shouldThrow;
  }

  /// Configure to throw exception on write operations
  void setThrowOnWrite(bool shouldThrow) {
    _throwOnWrite = shouldThrow;
  }

  /// Mock implementation of getString
  String? getString(String key) {
    if (_throwOnRead) throw Exception('SharedPreferences read error');
    return _storage[key] as String?;
  }

  /// Mock implementation of getDouble
  double? getDouble(String key) {
    if (_throwOnRead) throw Exception('SharedPreferences read error');
    return _storage[key] as double?;
  }

  /// Mock implementation of getInt
  int? getInt(String key) {
    if (_throwOnRead) throw Exception('SharedPreferences read error');
    return _storage[key] as int?;
  }

  /// Mock implementation of setString
  Future<bool> setString(String key, String value) async {
    if (_throwOnWrite) throw Exception('SharedPreferences write error');
    _storage[key] = value;
    return true;
  }

  /// Mock implementation of setDouble
  Future<bool> setDouble(String key, double value) async {
    if (_throwOnWrite) throw Exception('SharedPreferences write error');
    _storage[key] = value;
    return true;
  }

  /// Mock implementation of setInt
  Future<bool> setInt(String key, int value) async {
    if (_throwOnWrite) throw Exception('SharedPreferences write error');
    _storage[key] = value;
    return true;
  }

  /// Mock implementation of remove
  Future<bool> remove(String key) async {
    if (_throwOnWrite) throw Exception('SharedPreferences write error');
    _storage.remove(key);
    return true;
  }

  /// Clear all stored values
  void clear() {
    _storage.clear();
  }

  /// Reset all configuration
  void reset() {
    _storage.clear();
    _throwOnRead = false;
    _throwOnWrite = false;
  }

  /// Get all stored keys (for testing)
  Set<String> getKeys() => _storage.keys.toSet();

  /// Check if key exists
  bool containsKey(String key) => _storage.containsKey(key);
}

/// Log spy for capturing and analyzing log output in tests
class LogSpy {
  final List<String> _logs = [];

  /// Capture a log message
  void log(String message) {
    _logs.add(message);
  }

  /// Get all captured logs
  List<String> get logs => List.unmodifiable(_logs);

  /// Check if any log contains raw coordinates (privacy violation)
  bool hasRawCoordinates() {
    // Look for coordinates with more than 2 decimal places
    final rawCoordPattern = RegExp(r'-?\d+\.\d{3,}');
    return _logs.any((log) => rawCoordPattern.hasMatch(log));
  }

  /// Check if logs contain redacted coordinates (privacy compliant)
  bool hasRedactedCoordinates() {
    // Look for coordinates with exactly 2 decimal places
    final redactedPattern = RegExp(r'-?\d+\.\d{2},-?\d+\.\d{2}');
    return _logs.any((log) => redactedPattern.hasMatch(log));
  }

  /// Get logs containing coordinate data
  List<String> getCoordinateLogs() {
    final coordPattern = RegExp(r'-?\d+\.\d+,-?\d+\.\d+');
    return _logs.where((log) => coordPattern.hasMatch(log)).toList();
  }

  /// Clear all captured logs
  void clear() {
    _logs.clear();
  }
}

/// Test utilities for creating common test data
class TestData {
  // Common test coordinates
  static const LatLng edinburgh = LatLng(55.9533, -3.1883);
  static const LatLng london = LatLng(51.5074, -0.1278);
  static const LatLng glasgow = LatLng(55.8642, -4.2518);
  static const LatLng scotlandCentroid =
      LatLng(57.2, -3.8); // Aviemore, UK - matches location_resolver_impl.dart

  // Invalid coordinates for testing
  static const LatLng invalidLat = LatLng(999.0, -3.1883);
  static const LatLng invalidLon = LatLng(55.9533, 999.0);
  static const LatLng bothInvalid = LatLng(999.0, 999.0);

  // Boundary test coordinates
  static const LatLng northPole = LatLng(90.0, 0.0);
  static const LatLng southPole = LatLng(-90.0, 0.0);
  static const LatLng dateLine = LatLng(0.0, 180.0);
  static const LatLng antiMeridian = LatLng(0.0, -180.0);

  /// Create a mock Position for geolocator
  static Position createPosition({
    required double latitude,
    required double longitude,
    double accuracy = 10.0,
    DateTime? timestamp,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: accuracy,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  /// Create test SharedPreferences data
  static Map<String, dynamic> createCacheData({
    required LatLng location,
    String? placeName,
    DateTime? timestamp,
  }) {
    final data = <String, dynamic>{
      'manual_location_version': '1.0',
      'manual_location_lat': location.latitude,
      'manual_location_lon': location.longitude,
      'manual_location_timestamp':
          (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
    };

    if (placeName != null) {
      data['manual_location_place'] = placeName;
    }

    return data;
  }
}
