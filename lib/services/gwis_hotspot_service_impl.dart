import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../models/api_error.dart';
import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';
import 'gwis_hotspot_service.dart';
import 'utils/geo_utils.dart';

/// Production implementation of GwisHotspotService using GWIS WMS GetFeatureInfo
///
/// Retrieves VIIRS satellite hotspot detections from Global Wildfire Information System.
///
/// Part of 021-live-fire-data feature implementation.
class GwisHotspotServiceImpl implements GwisHotspotService {
  /// GWIS WMS endpoint for hotspot data
  static const String _baseUrl =
      'https://maps.effis.emergency.copernicus.eu/gwis';
  static const String _userAgent = 'WildFire/0.1 (prototype)';
  static const String _acceptHeader = 'application/json,*/*;q=0.8';

  final http.Client _httpClient;
  final Random _random;

  /// Creates GwisHotspotServiceImpl with injected HTTP client
  ///
  /// [httpClient] - Injectable HTTP client for network requests
  /// [random] - Injectable random generator for retry jitter
  GwisHotspotServiceImpl({required http.Client httpClient, Random? random})
      : _httpClient = httpClient,
        _random = random ?? Random();

  @override
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
    int maxRetries = 3,
  }) async {
    // Validate parameters
    if (timeout.inMilliseconds <= 0) {
      return Left(ApiError(message: 'Timeout must be positive duration'));
    }
    if (maxRetries < 0 || maxRetries > 10) {
      return Left(ApiError(message: 'maxRetries must be between 0 and 10'));
    }

    final sw = bounds.southwest;
    final ne = bounds.northeast;

    // C2 compliance: Log at 2dp only
    developer.log(
      'GwisHotspotService: Fetching ${timeFilter.gwisLayerName} hotspots for bounds ${GeographicUtils.logRedact(sw.latitude, sw.longitude)} to ${GeographicUtils.logRedact(ne.latitude, ne.longitude)}',
      name: 'GwisHotspotService',
    );

    // Build WMS GetMap URL with bounding box
    // GetFeatureInfo requires a point, but for viewport we use GetMap + parse response
    final url = _buildWfsUrl(bounds, timeFilter);

    developer.log(
      'GwisHotspotService: Request URL (domain only): ${Uri.parse(url).host}',
      name: 'GwisHotspotService',
    );

    // Attempt with retries
    int attempt = 0;
    ApiError? lastError;

    while (attempt <= maxRetries) {
      try {
        final response = await _httpClient.get(
          Uri.parse(url),
          headers: {'User-Agent': _userAgent, 'Accept': _acceptHeader},
        ).timeout(timeout);

        if (response.statusCode == 200) {
          return _parseResponse(response.body);
        }

        // Check if retriable error
        if (_isRetriable(response.statusCode)) {
          lastError = ApiError(
            message: 'GWIS service returned ${response.statusCode}',
            statusCode: response.statusCode,
          );
          attempt++;
          if (attempt <= maxRetries) {
            await _backoff(attempt);
            continue;
          }
        }

        // Non-retriable error
        return Left(
          ApiError(
            message: 'GWIS request failed with status ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      } on TimeoutException {
        lastError = ApiError(message: 'GWIS request timed out');
        attempt++;
        if (attempt <= maxRetries) {
          await _backoff(attempt);
          continue;
        }
      } on SocketException catch (e) {
        lastError = ApiError(message: 'Network error: ${e.message}');
        attempt++;
        if (attempt <= maxRetries) {
          await _backoff(attempt);
          continue;
        }
      } catch (e) {
        return Left(ApiError(message: 'Unexpected error: $e'));
      }
    }

    return Left(lastError ?? ApiError(message: 'GWIS request failed'));
  }

  /// Build WFS URL for hotspot query
  String _buildWfsUrl(LatLngBounds bounds, HotspotTimeFilter timeFilter) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;

    // WFS GetFeature request with GeoJSON output
    return '$_baseUrl?'
        'service=WFS&'
        'version=2.0.0&'
        'request=GetFeature&'
        'typeName=${timeFilter.gwisLayerName}&'
        'outputFormat=application/json&'
        'srsName=EPSG:4326&'
        'bbox=${sw.longitude},${sw.latitude},${ne.longitude},${ne.latitude},EPSG:4326';
  }

  /// Parse GeoJSON response to list of hotspots
  Either<ApiError, List<Hotspot>> _parseResponse(String body) {
    try {
      final json = jsonDecode(body);

      // Handle both FeatureCollection and direct features array
      List<dynamic> features;
      if (json is Map && json.containsKey('features')) {
        features = json['features'] as List<dynamic>;
      } else if (json is List) {
        features = json;
      } else {
        developer.log(
          'GwisHotspotService: Unexpected response format',
          name: 'GwisHotspotService',
        );
        return const Right([]);
      }

      final hotspots = <Hotspot>[];
      for (final feature in features) {
        try {
          hotspots.add(Hotspot.fromJson(feature as Map<String, dynamic>));
        } catch (e) {
          // Skip malformed features but continue parsing
          developer.log(
            'GwisHotspotService: Skipping malformed feature: $e',
            name: 'GwisHotspotService',
          );
        }
      }

      developer.log(
        'GwisHotspotService: Parsed ${hotspots.length} hotspots',
        name: 'GwisHotspotService',
      );

      return Right(hotspots);
    } on FormatException catch (e) {
      return Left(ApiError(message: 'Invalid JSON response: ${e.message}'));
    } catch (e) {
      return Left(ApiError(message: 'Failed to parse response: $e'));
    }
  }

  /// Check if HTTP status code is retriable
  bool _isRetriable(int statusCode) {
    return statusCode == 408 || statusCode == 503 || statusCode == 504;
  }

  /// Exponential backoff with jitter
  Future<void> _backoff(int attempt) async {
    // Base delay: 200ms, 400ms, 800ms, ...
    final baseDelay = 200 * (1 << (attempt - 1));
    // Add random jitter: 0-100ms
    final jitter = _random.nextInt(100);
    await Future.delayed(Duration(milliseconds: baseDelay + jitter));
  }
}
