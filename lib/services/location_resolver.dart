import 'package:dartz/dartz.dart';
import '../models/location_models.dart';

/// Abstract interface for location resolution service
///
/// Provides headless location services with configurable fallback behavior.
/// The service never triggers UI directly - callers handle manual entry dialogs
/// when receiving Left(LocationError) responses.
abstract class LocationResolver {
  /// Resolves current location using multi-tier fallback strategy
  ///
  /// Fallback chain:
  /// 1. Last known device position (instant)
  /// 2. GPS fix with timeout
  /// 3. SharedPreferences cached manual location
  /// 4. Manual entry (caller responsibility - return Left if allowDefault=false)
  /// 5. Scotland centroid (only if allowDefault=true)
  ///
  /// [allowDefault] - If false, returns Left(LocationError) instead of default location
  /// to trigger manual entry by caller (e.g., A6/Home component)
  ///
  /// Returns [Right(LatLng)] with resolved coordinates or [Left(LocationError)]
  /// indicating caller should handle manual entry or error state.
  Future<Either<LocationError, LatLng>> getLatLon({bool allowDefault = true});

  /// Saves manually entered location to persistent storage
  ///
  /// [location] - Validated coordinates to persist
  /// [placeName] - Optional human-readable location name for display
  ///
  /// This method is called by the manual entry dialog after successful
  /// coordinate validation and user confirmation.
  Future<void> saveManual(LatLng location, {String? placeName});
}
