import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/location_name.dart';
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

  /// Creates a GeocodingService using the dedicated Geocoding API key.
  ///
  /// The [apiKey] defaults to [FeatureFlags.geocodingApiKey] which is a
  /// separate key from the Maps JS API key. This key should have no
  /// application restriction (HTTP referrer), only API restriction to
  /// "Geocoding API" for security.
  ///
  /// If no geocoding key is configured, falls back to [FeatureFlags.googleMapsApiKey]
  /// for backwards compatibility during migration.
  GeocodingServiceImpl({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ??
            (FeatureFlags.geocodingApiKey.isNotEmpty
                ? FeatureFlags.geocodingApiKey
                : FeatureFlags.googleMapsApiKey);

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

    // Request multiple result types to get the most specific available
    // Priority: locality > postal_town > sublocality > natural_feature > admin areas
    // Note: Google returns best matches first, but we reorder by our priority
    final url = Uri.parse(_geocodeBaseUrl).replace(
      queryParameters: {
        'latlng': '$lat,$lon',
        'key': _apiKey,
        // Request specific location types first, then fallback to admin areas
        'result_type':
            'locality|postal_town|sublocality|natural_feature|administrative_area_level_2|administrative_area_level_1',
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
            // Extract the best place name from all results
            final locationName = _extractBestLocationName(results);
            debugPrint(
                'Geocoding: Resolved to "${locationName.displayName}" (${locationName.detailLevel.name})');
            return Right(locationName.displayName);
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
    final name = _extractPlaceNameFromResult(result) ?? formattedAddress;

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

  /// Extract the best location name from all geocoding results
  ///
  /// Searches through all results to find the most specific location name.
  /// Priority: locality > postal_town > sublocality > natural_feature > admin areas
  /// Natural features are formatted as "Near {featureName}"
  LocationName _extractBestLocationName(List<dynamic> results) {
    String? locality;
    String? postalTown;
    String? sublocality;
    String? naturalFeature;
    String? adminArea2; // County/council level
    String? adminArea1; // Region level
    String? rawAddress;

    // Scan all results to find best candidates for each type
    for (final result in results) {
      final r = result as Map<String, dynamic>;
      final types = (r['types'] as List<dynamic>?)?.cast<String>() ?? [];
      final components = r['address_components'] as List<dynamic>?;

      // Capture raw address from first result
      rawAddress ??= r['formatted_address'] as String?;

      // Check result types
      if (types.contains('locality') && locality == null) {
        locality = _getComponentName(components, 'locality');
      }
      if (types.contains('postal_town') && postalTown == null) {
        postalTown = _getComponentName(components, 'postal_town');
      }
      if (types.contains('sublocality') && sublocality == null) {
        sublocality = _getComponentName(components, 'sublocality');
      }
      if (types.contains('natural_feature') && naturalFeature == null) {
        naturalFeature = _getComponentName(components, 'natural_feature');
      }
      if (types.contains('administrative_area_level_2') && adminArea2 == null) {
        adminArea2 =
            _getComponentName(components, 'administrative_area_level_2');
      }
      if (types.contains('administrative_area_level_1') && adminArea1 == null) {
        adminArea1 =
            _getComponentName(components, 'administrative_area_level_1');
      }

      // Also check inside address components for these types
      if (components != null) {
        for (final comp in components) {
          final c = comp as Map<String, dynamic>;
          final compTypes = (c['types'] as List<dynamic>).cast<String>();
          final name = c['long_name'] as String?;
          if (name == null) continue;

          if (compTypes.contains('locality') && locality == null) {
            locality = name;
          }
          if (compTypes.contains('postal_town') && postalTown == null) {
            postalTown = name;
          }
          if (compTypes.contains('sublocality') && sublocality == null) {
            sublocality = name;
          }
          if (compTypes.contains('natural_feature') && naturalFeature == null) {
            naturalFeature = name;
          }
          if (compTypes.contains('administrative_area_level_2') &&
              adminArea2 == null) {
            // Filter out council-style names if we have better options
            adminArea2 = name;
          }
          if (compTypes.contains('administrative_area_level_1') &&
              adminArea1 == null) {
            adminArea1 = name;
          }
        }
      }
    }

    // Return best match in priority order
    if (locality != null) {
      return LocationName(
        displayName: locality,
        rawAddress: rawAddress,
        detailLevel: LocationNameDetailLevel.locality,
      );
    }

    if (postalTown != null) {
      return LocationName(
        displayName: postalTown,
        rawAddress: rawAddress,
        detailLevel: LocationNameDetailLevel.postalTown,
      );
    }

    if (sublocality != null) {
      return LocationName(
        displayName: sublocality,
        rawAddress: rawAddress,
        detailLevel: LocationNameDetailLevel.sublocality,
      );
    }

    // Natural features get "Near X" prefix
    if (naturalFeature != null) {
      return LocationName(
        displayName: 'Near $naturalFeature',
        rawAddress: rawAddress,
        detailLevel: LocationNameDetailLevel.naturalFeature,
      );
    }

    // Fall back to admin areas (least specific)
    // Prefer adminArea2 if it's not a generic council name, otherwise use adminArea1
    if (adminArea2 != null && !_isGenericCouncilName(adminArea2)) {
      return LocationName(
        displayName: adminArea2,
        rawAddress: rawAddress,
        detailLevel: LocationNameDetailLevel.adminArea,
      );
    }

    if (adminArea1 != null) {
      return LocationName(
        displayName: adminArea1,
        rawAddress: rawAddress,
        detailLevel: LocationNameDetailLevel.adminArea,
      );
    }

    if (adminArea2 != null) {
      return LocationName(
        displayName: adminArea2,
        rawAddress: rawAddress,
        detailLevel: LocationNameDetailLevel.adminArea,
      );
    }

    // Ultimate fallback
    return LocationName(
      displayName: rawAddress ?? 'Unknown location',
      rawAddress: rawAddress,
      detailLevel: LocationNameDetailLevel.coordinatesFallback,
    );
  }

  /// Check if admin area name is a generic council-style name
  ///
  /// These are less useful for users as they cover very large areas.
  /// Prefer more specific names when available.
  bool _isGenericCouncilName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('council') ||
        lower.contains('county') ||
        lower.endsWith(' area');
  }

  /// Get component name for a specific type from address components
  String? _getComponentName(List<dynamic>? components, String type) {
    if (components == null) return null;

    for (final comp in components) {
      final c = comp as Map<String, dynamic>;
      final types = (c['types'] as List<dynamic>).cast<String>();
      if (types.contains(type)) {
        return c['long_name'] as String?;
      }
    }
    return null;
  }

  /// Extract a concise place name from a single result (for search)
  String? _extractPlaceNameFromResult(Map<String, dynamic> result) {
    final components = result['address_components'] as List<dynamic>?;
    if (components == null || components.isEmpty) return null;

    // Priority order for place names
    const priorityTypes = [
      'locality', // City/town
      'postal_town',
      'sublocality',
      'natural_feature',
      'administrative_area_level_2', // County
      'administrative_area_level_1', // Region/country
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
