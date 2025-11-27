import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

/// Service interface for what3words API operations
///
/// Provides conversion between coordinates and what3words addresses.
/// Implementations should handle rate limiting and error recovery.
abstract class What3wordsService {
  /// Convert coordinates to a what3words address
  ///
  /// Returns [What3wordsAddress] on success, [What3wordsError] on failure.
  /// Coordinates must be valid WGS84 lat/lon values.
  ///
  /// Example:
  /// ```dart
  /// final result = await service.convertTo3wa(
  ///   lat: 55.9533,
  ///   lon: -3.1883,
  /// );
  /// result.fold(
  ///   (error) => print('Failed: $error'),
  ///   (address) => print('Address: ${address.words}'), // e.g., "daring.lion.race"
  /// );
  /// ```
  Future<Either<What3wordsError, What3wordsAddress>> convertTo3wa({
    required double lat,
    required double lon,
  });

  /// Convert a what3words address to coordinates
  ///
  /// Returns [LatLng] on success, [What3wordsError] on failure.
  /// Address must be valid three-word format (e.g., "word.word.word").
  ///
  /// Example:
  /// ```dart
  /// final result = await service.convertToCoordinates(
  ///   words: 'daring.lion.race',
  /// );
  /// result.fold(
  ///   (error) => print('Failed: $error'),
  ///   (coords) => print('Location: ${coords.latitude}, ${coords.longitude}'),
  /// );
  /// ```
  Future<Either<What3wordsError, LatLng>> convertToCoordinates({
    required String words,
  });
}
