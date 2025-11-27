import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/place_search_result.dart';
import 'geocoding_service.dart';

/// Implementation of [GeocodingService] using Google Geocoding API
///
/// API documentation: https://developers.google.com/maps/documentation/geocoding
/// Uses same API key as Google Maps.
class GeocodingServiceImpl implements GeocodingService {
  static const String _geocodeBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _staticMapBaseUrl =
      'https://maps.googleapis.com/maps/api/staticmap';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;
  final String _apiKey;

  GeocodingServiceImpl({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? FeatureFlags.googleMapsApiKey;

  @override
  Future<Either<GeocodingError, List<PlaceSearchResult>>> searchPlaces({
    required String query,
    int maxResults = 5,
  }) async {
    if (_apiKey.isEmpty) {
      return const Left(
          GeocodingApiError('Google Maps API key not configured'));
    }

    if (query.trim().isEmpty) {
      return const Right([]);
    }

    // Bias results toward UK
    final url = Uri.parse(_geocodeBaseUrl).replace(
      queryParameters: {
        'address': query,
        'key': _apiKey,
        'region': 'uk',
        'components': 'country:GB',
      },
    );

    debugPrint('Geocoding: Searching for "$query"');

    try {
      final response = await _client.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] as String?;

        if (status == 'OK') {
          final results = (json['results'] as List<dynamic>)
              .take(maxResults)
              .map((r) => _parseResult(r as Map<String, dynamic>))
              .toList();

          debugPrint('Geocoding: Found ${results.length} results');
          return Right(results);
        } else if (status == 'ZERO_RESULTS') {
          return const Right([]);
        } else if (status == 'REQUEST_DENIED') {
          return const Left(
              GeocodingApiError('API request denied - check API key'));
        } else if (status == 'OVER_QUERY_LIMIT') {
          return const Left(GeocodingApiError('API quota exceeded'));
        } else {
          return Left(GeocodingApiError('API error: $status'));
        }
      } else {
        return Left(GeocodingApiError(
          'HTTP error',
          statusCode: response.statusCode,
        ));
      }
    } on http.ClientException catch (e) {
      debugPrint('Geocoding: Network error - $e');
      return Left(GeocodingNetworkError(e.message));
    } catch (e) {
      debugPrint('Geocoding: Unexpected error - $e');
      return Left(GeocodingNetworkError(e.toString()));
    }
  }

  @override
  Future<Either<GeocodingError, String>> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    if (_apiKey.isEmpty) {
      return const Left(
          GeocodingApiError('Google Maps API key not configured'));
    }

    final url = Uri.parse(_geocodeBaseUrl).replace(
      queryParameters: {
        'latlng': '$lat,$lon',
        'key': _apiKey,
        'result_type':
            'locality|administrative_area_level_2|administrative_area_level_1',
      },
    );

    debugPrint(
        'Geocoding: Reverse geocoding ${LocationUtils.logRedact(lat, lon)}');

    try {
      final response = await _client.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] as String?;

        if (status == 'OK') {
          final results = json['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            final firstResult = results.first as Map<String, dynamic>;
            final address = firstResult['formatted_address'] as String?;

            // Try to get a shorter, more useful name
            final placeName =
                _extractPlaceName(firstResult) ?? address ?? 'Unknown location';
            debugPrint('Geocoding: Resolved to "$placeName"');
            return Right(placeName);
          }
          return const Left(GeocodingNoResultsError('coordinates'));
        } else if (status == 'ZERO_RESULTS') {
          return const Left(GeocodingNoResultsError('coordinates'));
        } else {
          return Left(GeocodingApiError('API error: $status'));
        }
      } else {
        return Left(GeocodingApiError(
          'HTTP error',
          statusCode: response.statusCode,
        ));
      }
    } on http.ClientException catch (e) {
      debugPrint('Geocoding: Network error - $e');
      return Left(GeocodingNetworkError(e.message));
    } catch (e) {
      debugPrint('Geocoding: Unexpected error - $e');
      return Left(GeocodingNetworkError(e.toString()));
    }
  }

  @override
  Future<Either<GeocodingError, LatLng>> getPlaceCoordinates({
    required String placeId,
  }) async {
    if (_apiKey.isEmpty) {
      return const Left(
          GeocodingApiError('Google Maps API key not configured'));
    }

    final url = Uri.parse(_geocodeBaseUrl).replace(
      queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
      },
    );

    debugPrint('Geocoding: Resolving place_id $placeId');

    try {
      final response = await _client.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] as String?;

        if (status == 'OK') {
          final results = json['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            final firstResult = results.first as Map<String, dynamic>;
            final geometry = firstResult['geometry'] as Map<String, dynamic>?;
            final location = geometry?['location'] as Map<String, dynamic>?;

            if (location != null) {
              final lat = (location['lat'] as num).toDouble();
              final lng = (location['lng'] as num).toDouble();
              debugPrint(
                  'Geocoding: Resolved to ${LocationUtils.logRedact(lat, lng)}');
              return Right(LatLng(lat, lng));
            }
          }
          return const Left(GeocodingNoResultsError('place_id'));
        } else if (status == 'ZERO_RESULTS') {
          return Left(GeocodingNoResultsError(placeId));
        } else {
          return Left(GeocodingApiError('API error: $status'));
        }
      } else {
        return Left(GeocodingApiError(
          'HTTP error',
          statusCode: response.statusCode,
        ));
      }
    } on http.ClientException catch (e) {
      debugPrint('Geocoding: Network error - $e');
      return Left(GeocodingNetworkError(e.message));
    } catch (e) {
      debugPrint('Geocoding: Unexpected error - $e');
      return Left(GeocodingNetworkError(e.toString()));
    }
  }

  @override
  String buildStaticMapUrl({
    required double lat,
    required double lon,
    int zoom = 14,
    int width = 300,
    int height = 200,
    String markerColor = 'red',
  }) {
    // URL-encode the parameters
    final url = Uri.parse(_staticMapBaseUrl).replace(
      queryParameters: {
        'center': '$lat,$lon',
        'zoom': zoom.toString(),
        'size': '${width}x$height',
        'markers': 'color:$markerColor|$lat,$lon',
        'key': _apiKey,
        'scale': '2', // Retina display support
        'maptype': 'roadmap',
      },
    );

    return url.toString();
  }

  /// Parse a geocoding result into a PlaceSearchResult
  PlaceSearchResult _parseResult(Map<String, dynamic> result) {
    final placeId = result['place_id'] as String? ?? '';
    final formattedAddress = result['formatted_address'] as String? ?? '';

    // Extract a shorter name from address components
    final name = _extractPlaceName(result) ?? formattedAddress;

    // Get coordinates if available
    LatLng? coords;
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location != null) {
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        coords = LatLng(lat, lng);
      }
    }

    return PlaceSearchResult(
      placeId: placeId,
      name: name,
      formattedAddress: formattedAddress,
      coordinates: coords,
    );
  }

  /// Extract a concise place name from address components
  String? _extractPlaceName(Map<String, dynamic> result) {
    final components = result['address_components'] as List<dynamic>?;
    if (components == null || components.isEmpty) return null;

    // Priority order for place names
    const priorityTypes = [
      'locality', // City/town
      'administrative_area_level_2', // County
      'administrative_area_level_1', // Region/country
      'postal_town',
    ];

    for (final type in priorityTypes) {
      for (final component in components) {
        final comp = component as Map<String, dynamic>;
        final types = (comp['types'] as List<dynamic>).cast<String>();
        if (types.contains(type)) {
          return comp['long_name'] as String?;
        }
      }
    }

    return null;
  }
}
