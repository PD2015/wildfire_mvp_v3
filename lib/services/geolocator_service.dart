import 'package:geolocator/geolocator.dart';

/// Abstraction for Geolocator to enable dependency injection and testing
abstract class GeolocatorService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position?> getLastKnownPosition();
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.best,
    Duration? timeLimit,
  });
}

/// Production implementation using the real Geolocator
class GeolocatorServiceImpl implements GeolocatorService {
  @override
  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();
  
  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  
  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();
  
  @override
  Future<Position?> getLastKnownPosition() => Geolocator.getLastKnownPosition(
    forceAndroidLocationManager: false,
  );
  
  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.best,
    Duration? timeLimit,
  }) => Geolocator.getCurrentPosition(
    desiredAccuracy: desiredAccuracy,
    timeLimit: timeLimit,
  );
}