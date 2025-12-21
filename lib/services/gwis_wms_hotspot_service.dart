import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import '../models/api_error.dart';
import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/location_models.dart';
import '../models/fire_data_mode.dart';
import 'hotspot_service.dart';
import 'utils/geo_utils.dart';

/// GWIS WMS implementation of HotspotService using GetFeatureInfo grid queries.
///
/// This service queries GWIS using WMS GetFeatureInfo because GWIS hotspot layers
/// only support WMS (not WFS). To cover a viewport, it sends a 3x3 grid of queries
/// and merges/deduplicates the results.
///
/// IMPORTANT: This is a fallback service. Use [FirmsHotspotService] as primary
/// since it has better performance (1 REST request vs 9 WMS requests).
///
/// Part of 021-live-fire-data feature implementation.
class GwisWmsHotspotService implements HotspotService {
  /// GWIS WMS endpoint for hotspot data
  static const String _baseUrl =
      'https://maps.effis.emergency.copernicus.eu/gwis';
  static const String _userAgent = 'WildFire/0.1 (prototype)';
  static const String _acceptHeader =
      'text/xml,application/gml+xml;q=0.9,*/*;q=0.8';

  /// Grid size for viewport coverage (3x3 = 9 queries)
  static const int _gridSize = 3;

  /// Image dimensions for WMS queries
  static const int _imageWidth = 256;
  static const int _imageHeight = 256;

  /// Feature info radius in pixels
  static const int _queryRadius = 25;

  final http.Client _httpClient;
  final Random _random;

  /// Creates GwisWmsHotspotService with injected HTTP client
  ///
  /// [httpClient] - Injectable HTTP client for network requests
  /// [random] - Injectable random generator for retry jitter
  GwisWmsHotspotService({required http.Client httpClient, Random? random})
    : _httpClient = httpClient,
      _random = random ?? Random();

  @override
  String get serviceName => 'GWIS WMS';

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
      'GwisWmsHotspotService: Fetching ${timeFilter.gwisLayerName} hotspots '
      'for bounds ${GeographicUtils.logRedact(sw.latitude, sw.longitude)} '
      'to ${GeographicUtils.logRedact(ne.latitude, ne.longitude)}',
      name: 'GwisWmsHotspotService',
    );

    // Generate 3x3 grid of query points
    final queryPoints = _generateGridPoints(bounds);

    developer.log(
      'GwisWmsHotspotService: Querying ${queryPoints.length} grid points',
      name: 'GwisWmsHotspotService',
    );

    // Execute all queries in parallel
    final allHotspots = <Hotspot>[];
    final errors = <String>[];
    int successCount = 0;

    // Use per-request timeout (total timeout / grid size with buffer)
    final perRequestTimeout = Duration(
      milliseconds: (timeout.inMilliseconds / _gridSize).round(),
    );

    // Execute queries in parallel
    final futures = queryPoints.map(
      (point) => _queryPoint(
        bounds: bounds,
        queryPoint: point,
        timeFilter: timeFilter,
        timeout: perRequestTimeout,
        maxRetries: maxRetries,
      ),
    );

    final results = await Future.wait(futures);

    for (final result in results) {
      result.fold((error) => errors.add(error.message), (hotspots) {
        successCount++;
        allHotspots.addAll(hotspots);
      });
    }

    developer.log(
      'GwisWmsHotspotService: $successCount/${queryPoints.length} queries succeeded, '
      '${allHotspots.length} total hotspots before deduplication',
      name: 'GwisWmsHotspotService',
    );

    // If all queries failed, return error
    if (successCount == 0) {
      return Left(
        ApiError(
          message: 'All GWIS WMS queries failed: ${errors.take(3).join("; ")}',
        ),
      );
    }

    // Deduplicate hotspots by ID
    final deduplicated = _deduplicateHotspots(allHotspots);

    developer.log(
      'GwisWmsHotspotService: ${deduplicated.length} hotspots after deduplication',
      name: 'GwisWmsHotspotService',
    );

    return Right(deduplicated);
  }

  /// Generate grid points for WMS GetFeatureInfo queries
  ///
  /// Creates a 3x3 grid of query points across the viewport bounds
  List<LatLng> _generateGridPoints(LatLngBounds bounds) {
    final points = <LatLng>[];
    final sw = bounds.southwest;
    final ne = bounds.northeast;

    final latStep = (ne.latitude - sw.latitude) / (_gridSize + 1);
    final lngStep = (ne.longitude - sw.longitude) / (_gridSize + 1);

    for (int row = 1; row <= _gridSize; row++) {
      for (int col = 1; col <= _gridSize; col++) {
        points.add(
          LatLng(sw.latitude + (row * latStep), sw.longitude + (col * lngStep)),
        );
      }
    }

    return points;
  }

  /// Query a single point using WMS GetFeatureInfo
  Future<Either<ApiError, List<Hotspot>>> _queryPoint({
    required LatLngBounds bounds,
    required LatLng queryPoint,
    required HotspotTimeFilter timeFilter,
    required Duration timeout,
    required int maxRetries,
  }) async {
    final url = _buildGetFeatureInfoUrl(
      bounds: bounds,
      queryPoint: queryPoint,
      timeFilter: timeFilter,
    );

    int attempt = 0;
    ApiError? lastError;

    while (attempt <= maxRetries) {
      try {
        final response = await _httpClient
            .get(
              Uri.parse(url),
              headers: {'User-Agent': _userAgent, 'Accept': _acceptHeader},
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return _parseGmlResponse(response.body);
        }

        // Check if retriable error
        if (_isRetriable(response.statusCode)) {
          lastError = ApiError(
            message: 'GWIS WMS returned ${response.statusCode}',
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
            message:
                'GWIS WMS request failed with status ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      } on TimeoutException {
        lastError = ApiError(message: 'GWIS WMS request timed out');
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

    return Left(lastError ?? ApiError(message: 'GWIS WMS request failed'));
  }

  /// Build WMS GetFeatureInfo URL for a specific query point
  String _buildGetFeatureInfoUrl({
    required LatLngBounds bounds,
    required LatLng queryPoint,
    required HotspotTimeFilter timeFilter,
  }) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;

    // Calculate pixel coordinates for query point within image
    final pixelX =
        ((queryPoint.longitude - sw.longitude) /
                (ne.longitude - sw.longitude) *
                _imageWidth)
            .round()
            .clamp(0, _imageWidth - 1);
    final pixelY =
        ((ne.latitude - queryPoint.latitude) /
                (ne.latitude - sw.latitude) *
                _imageHeight)
            .round()
            .clamp(0, _imageHeight - 1);

    // WMS 1.3.0 GetFeatureInfo request
    // Note: GWIS returns GML format for GetFeatureInfo
    return '$_baseUrl?'
        'service=WMS&'
        'version=1.3.0&'
        'request=GetFeatureInfo&'
        'layers=${timeFilter.gwisLayerName}&'
        'query_layers=${timeFilter.gwisLayerName}&'
        'info_format=application/gml+xml&'
        'crs=EPSG:4326&'
        'bbox=${sw.latitude},${sw.longitude},${ne.latitude},${ne.longitude}&'
        'width=$_imageWidth&'
        'height=$_imageHeight&'
        'i=$pixelX&'
        'j=$pixelY&'
        'feature_count=50&' // Max features to return per query
        'buffer=$_queryRadius'; // Search radius in pixels
  }

  /// Parse GML (Geography Markup Language) response to list of hotspots
  Either<ApiError, List<Hotspot>> _parseGmlResponse(String body) {
    try {
      // Handle empty responses
      if (body.trim().isEmpty) {
        return const Right([]);
      }

      final document = xml.XmlDocument.parse(body);
      final hotspots = <Hotspot>[];

      // Find all feature members in GML response
      // GWIS typically returns gml:featureMember or gml:featureMembers elements
      final featureMembers = document.findAllElements('gml:featureMember');

      for (final member in featureMembers) {
        try {
          final hotspot = _parseGmlFeature(member);
          if (hotspot != null) {
            hotspots.add(hotspot);
          }
        } catch (e) {
          // Skip malformed features but continue parsing
          developer.log(
            'GwisWmsHotspotService: Skipping malformed GML feature: $e',
            name: 'GwisWmsHotspotService',
          );
        }
      }

      // Also check for wfs:member elements (some WMS services use this)
      final wfsMembers = document.findAllElements('wfs:member');
      for (final member in wfsMembers) {
        try {
          final hotspot = _parseGmlFeature(member);
          if (hotspot != null) {
            hotspots.add(hotspot);
          }
        } catch (e) {
          developer.log(
            'GwisWmsHotspotService: Skipping malformed WFS feature: $e',
            name: 'GwisWmsHotspotService',
          );
        }
      }

      return Right(hotspots);
    } on xml.XmlParserException catch (e) {
      // If response isn't valid XML, check if it's an empty/error response
      if (body.contains('no features') ||
          body.contains('ServiceException') ||
          body.trim().isEmpty) {
        return const Right([]);
      }
      return Left(ApiError(message: 'Invalid GML response: ${e.message}'));
    } catch (e) {
      return Left(ApiError(message: 'Failed to parse GML response: $e'));
    }
  }

  /// Parse a single GML feature member to Hotspot
  ///
  /// GWIS VIIRS hotspot features typically contain:
  /// - latitude/longitude or gml:Point geometry
  /// - firedate or acq_date (acquisition date)
  /// - frp (Fire Radiative Power in MW)
  /// - confidence (detection confidence 0-100)
  /// - satellite and instrument identifiers
  Hotspot? _parseGmlFeature(xml.XmlElement member) {
    // Find the actual feature element (child of featureMember)
    final featureElement = member.children
        .whereType<xml.XmlElement>()
        .firstOrNull;

    if (featureElement == null) return null;

    // Extract coordinates - try various common patterns
    double? latitude;
    double? longitude;

    // Pattern 1: Direct lat/lon elements
    final latElement =
        featureElement.findElements('latitude').firstOrNull ??
        featureElement.findElements('lat').firstOrNull;
    final lonElement =
        featureElement.findElements('longitude').firstOrNull ??
        featureElement.findElements('lon').firstOrNull;

    if (latElement != null && lonElement != null) {
      latitude = double.tryParse(latElement.innerText);
      longitude = double.tryParse(lonElement.innerText);
    }

    // Pattern 2: GML Point geometry
    if (latitude == null || longitude == null) {
      final pointElement = featureElement
          .findAllElements('gml:Point')
          .firstOrNull;
      if (pointElement != null) {
        final posElement = pointElement.findElements('gml:pos').firstOrNull;
        if (posElement != null) {
          final coords = posElement.innerText.trim().split(RegExp(r'\s+'));
          if (coords.length >= 2) {
            // GML 3.x: lat lon order for EPSG:4326
            latitude = double.tryParse(coords[0]);
            longitude = double.tryParse(coords[1]);
          }
        }
      }
    }

    // Pattern 3: GML coordinates element
    if (latitude == null || longitude == null) {
      final coordsElement = featureElement
          .findAllElements('gml:coordinates')
          .firstOrNull;
      if (coordsElement != null) {
        final coords = coordsElement.innerText.trim().split(',');
        if (coords.length >= 2) {
          // coordinates: lon,lat order
          longitude = double.tryParse(coords[0].trim());
          latitude = double.tryParse(coords[1].trim());
        }
      }
    }

    if (latitude == null || longitude == null) {
      return null; // Can't parse without coordinates
    }

    // Extract FRP (Fire Radiative Power)
    final frpElement =
        featureElement.findElements('frp').firstOrNull ??
        featureElement.findElements('FRP').firstOrNull;
    final frp = frpElement != null
        ? double.tryParse(frpElement.innerText) ?? 0.0
        : 0.0;

    // Extract confidence
    final confElement =
        featureElement.findElements('confidence').firstOrNull ??
        featureElement.findElements('CONFIDENCE').firstOrNull;
    final confidence = confElement != null
        ? double.tryParse(confElement.innerText) ?? 50.0
        : 50.0;

    // Extract date
    final dateElement =
        featureElement.findElements('firedate').firstOrNull ??
        featureElement.findElements('acq_date').firstOrNull ??
        featureElement.findElements('ACQ_DATE').firstOrNull;
    DateTime detectedAt;
    if (dateElement != null) {
      detectedAt =
          DateTime.tryParse(dateElement.innerText) ?? DateTime.now().toUtc();
    } else {
      detectedAt = DateTime.now().toUtc();
    }

    // Generate unique ID from coordinates + date
    final id =
        'gwis_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_${detectedAt.millisecondsSinceEpoch}';

    return Hotspot(
      id: id,
      location: LatLng(latitude, longitude),
      detectedAt: detectedAt,
      frp: frp,
      confidence: confidence,
    );
  }

  /// Deduplicate hotspots by ID, keeping the one with highest FRP
  List<Hotspot> _deduplicateHotspots(List<Hotspot> hotspots) {
    final byId = <String, Hotspot>{};

    for (final hotspot in hotspots) {
      final existing = byId[hotspot.id];
      if (existing == null || hotspot.frp > existing.frp) {
        byId[hotspot.id] = hotspot;
      }
    }

    return byId.values.toList();
  }

  /// Check if HTTP status code is retriable
  bool _isRetriable(int statusCode) {
    return statusCode == 408 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  /// Exponential backoff with jitter
  Future<void> _backoff(int attempt) async {
    // Base delay: 100ms, 200ms, 400ms, ... (faster than REST since many queries)
    final baseDelay = 100 * (1 << (attempt - 1));
    // Add random jitter: 0-50ms
    final jitter = _random.nextInt(50);
    await Future.delayed(Duration(milliseconds: baseDelay + jitter));
  }
}
