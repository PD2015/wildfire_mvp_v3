import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/api_error.dart';
import '../models/burnt_area.dart';
import '../models/lat_lng_bounds.dart';
import '../models/location_models.dart';
import '../models/fire_data_mode.dart';
import 'effis_burnt_area_service.dart';
import 'utils/geo_utils.dart';
import 'utils/polygon_simplifier.dart';

/// Production implementation of EffisBurntAreaService using EFFIS WFS
///
/// Retrieves MODIS burnt area polygons from EFFIS Web Feature Service.
/// Applies Douglas-Peucker simplification for large polygons.
///
/// IMPORTANT: Uses GML3 output format instead of JSON because JSON output
/// fails silently with bbox spatial filters on the EFFIS server.
///
/// Part of 021-live-fire-data feature implementation.
class EffisBurntAreaServiceImpl implements EffisBurntAreaService {
  /// EFFIS WFS endpoint for burnt area data
  static const String _baseUrl =
      'https://maps.effis.emergency.copernicus.eu/effis';
  static const String _userAgent = 'WildFire/0.1 (prototype)';
  // Request GML3 format - JSON fails with bbox filters
  static const String _acceptHeader = 'application/xml,*/*;q=0.8';

  /// WFS layer name for burnt area polygons
  /// Note: EFFIS does NOT have a pre-filtered season layer, so we use the
  /// generic poly layer for all queries and apply client-side year filtering.
  /// Available layers: modis.ba.poly (all), modis.ba.poly.today (today only)
  static const String _polyLayer = 'ms:modis.ba.poly';

  final http.Client _httpClient;
  final Random _random;

  /// Creates EffisBurntAreaServiceImpl with injected HTTP client
  ///
  /// [httpClient] - Injectable HTTP client for network requests
  /// [random] - Injectable random generator for retry jitter
  EffisBurntAreaServiceImpl({required http.Client httpClient, Random? random})
      : _httpClient = httpClient,
        _random = random ?? Random();

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
    bool skipLiveApi =
        false, // Ignored by live service - always makes API calls
  }) async {
    // Validate parameters
    if (timeout.inMilliseconds <= 0) {
      return Left(ApiError(message: 'Timeout must be positive duration'));
    }
    if (maxRetries < 0 || maxRetries > 10) {
      return Left(ApiError(message: 'maxRetries must be between 0 and 10'));
    }
    if (maxFeatures != null && (maxFeatures < 1 || maxFeatures > 2000)) {
      return Left(ApiError(message: 'maxFeatures must be between 1 and 2000'));
    }

    final sw = bounds.southwest;
    final ne = bounds.northeast;

    // C2 compliance: Log at 2dp only
    developer.log(
      'EffisBurntAreaService: Fetching ${seasonFilter.displayLabel} (${seasonFilter.year}) burnt areas for bounds ${GeographicUtils.logRedact(sw.latitude, sw.longitude)} to ${GeographicUtils.logRedact(ne.latitude, ne.longitude)}',
      name: 'EffisBurntAreaService',
    );

    // Build WFS URL with optional feature limit
    final url = _buildWfsUrl(bounds, seasonFilter, maxFeatures: maxFeatures);

    developer.log(
      'EffisBurntAreaService: Request URL (domain only): ${Uri.parse(url).host}',
      name: 'EffisBurntAreaService',
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
          // IMPORTANT: Use bodyBytes + utf8.decode instead of response.body
          // The EFFIS server returns non-standard content-type header:
          // "text/xml; subtype=gml/3.1.1; charset=UTF-8"
          // The "/" in "gml/3.1.1" causes MediaType.parse() to fail with:
          // "Invalid media type: expected no more input"
          // Using bodyBytes bypasses the automatic encoding detection.
          final bodyString = utf8.decode(response.bodyBytes);
          final parseResult = _parseResponse(bodyString);

          // Apply client-side year filtering
          // The CQL filter doesn't always work correctly, so we filter here
          return parseResult.map((areas) {
            final targetYear = seasonFilter.year;
            final filtered = areas
                .where((area) => area.fireDate.year == targetYear)
                .toList();

            if (filtered.length != areas.length) {
              developer.log(
                'EffisBurntAreaService: Filtered ${areas.length - filtered.length} areas from wrong year (kept ${filtered.length} from $targetYear)',
                name: 'EffisBurntAreaService',
              );
            }

            return filtered;
          });
        }

        // Check if retriable error
        if (_isRetriable(response.statusCode)) {
          lastError = ApiError(
            message: 'EFFIS service returned ${response.statusCode}',
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
            message: 'EFFIS request failed with status ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      } on TimeoutException {
        lastError = ApiError(message: 'EFFIS request timed out');
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
      } on http.ClientException catch (e) {
        // Handle connection closed errors (large response, server timeout)
        // and content-type parsing issues (EFFIS returns non-standard
        // "text/xml; subtype=gml/3.1.1" which Dart's http parser rejects)
        final message = e.message;
        developer.log(
          'EffisBurntAreaService: ClientException: $message',
          name: 'EffisBurntAreaService',
        );

        // Connection closed is retriable (network instability, large payload)
        if (message.contains('Connection closed')) {
          lastError = ApiError(message: 'Connection interrupted: $message');
          attempt++;
          if (attempt <= maxRetries) {
            await _backoff(attempt);
            continue;
          }
        }

        // Other ClientExceptions (e.g., media type parsing) are not retriable
        return Left(ApiError(message: 'HTTP client error: $message'));
      } catch (e) {
        return Left(ApiError(message: 'Unexpected error: $e'));
      }
    }

    return Left(lastError ?? ApiError(message: 'EFFIS request failed'));
  }

  /// Build WFS URL for burnt area query
  ///
  /// [maxFeatures] limits the number of features returned to prevent
  /// large responses that timeout on mobile networks. The EFFIS server
  /// returns ~4KB per feature (GML polygon data).
  ///
  /// Note: EFFIS doesn't have pre-filtered season layers, so we fetch all
  /// data and apply client-side year filtering after parsing.
  ///
  /// Sorting strategy (CRITICAL for maxFeatures to work correctly):
  /// - thisSeason: Sort DESCENDING (D) - newest data first, 2025 data at top
  /// - lastSeason: Sort ASCENDING (A) - oldest data first, 2024 data comes
  ///   before 2025, so we find it within maxFeatures limit
  String _buildWfsUrl(
    LatLngBounds bounds,
    BurntAreaSeasonFilter seasonFilter, {
    int? maxFeatures,
  }) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;

    // Use the generic poly layer for all queries
    // Client-side filtering handles year selection after parsing
    // Available layers: modis.ba.poly (all), modis.ba.poly.today (today only)

    // CRITICAL: Sort direction depends on which season we want:
    // - thisSeason (2025): Descending - newest first (2025 data at top)
    // - lastSeason (2024): Ascending - oldest first (2024 comes before 2025)
    // This ensures maxFeatures limit captures the target year's data
    final sortDirection = seasonFilter == BurntAreaSeasonFilter.thisSeason
        ? 'D' // Descending - newest first
        : 'A'; // Ascending - oldest first

    // WFS 1.1.0 GetFeature request
    // CRITICAL: Use GML3 format - JSON fails silently with bbox filters!
    var url = '$_baseUrl?'
        'service=WFS&'
        'version=1.1.0&'
        'request=GetFeature&'
        'typeName=$_polyLayer&'
        'outputFormat=GML3&'
        'srsName=EPSG:4326&'
        'sortBy=FIREDATE+$sortDirection&'
        'bbox=${sw.latitude},${sw.longitude},${ne.latitude},${ne.longitude},EPSG:4326';

    // Add maxFeatures limit if specified (prevents mobile network timeouts)
    if (maxFeatures != null) {
      url += '&maxFeatures=$maxFeatures';
    }

    return url;
  }

  /// Parse GML3 response to list of burnt areas
  Either<ApiError, List<BurntArea>> _parseResponse(String body) {
    try {
      final document = xml.XmlDocument.parse(body);
      final root = document.rootElement;

      // Find all feature members - GML3 uses gml:featureMember or gml:featureMembers
      final featureMembers = root.findAllElements('gml:featureMember');

      if (featureMembers.isEmpty) {
        // Also check for ms: namespace prefix
        final msFeatures = root.findAllElements('ms:modis.ba.poly.season');
        if (msFeatures.isEmpty) {
          developer.log(
            'EffisBurntAreaService: No features found in GML response',
            name: 'EffisBurntAreaService',
          );
          return const Right([]);
        }
      }

      final burntAreas = <BurntArea>[];

      for (final featureMember in featureMembers) {
        try {
          final burntArea = _parseGmlFeature(featureMember);
          if (burntArea != null) {
            // Apply Douglas-Peucker simplification if needed
            if (PolygonSimplifier.wouldSimplify(burntArea.boundaryPoints)) {
              final simplified = PolygonSimplifier.simplify(
                burntArea.boundaryPoints,
              );
              final simplifiedArea = burntArea.copyWithSimplified(
                simplifiedPoints: simplified,
              );

              developer.log(
                'EffisBurntAreaService: Simplified polygon ${burntArea.id} from ${burntArea.originalPointCount} to ${simplified.length} points',
                name: 'EffisBurntAreaService',
              );

              burntAreas.add(simplifiedArea);
            } else {
              burntAreas.add(burntArea);
            }
          }
        } catch (e) {
          // Skip malformed features but continue parsing
          developer.log(
            'EffisBurntAreaService: Skipping malformed feature: $e',
            name: 'EffisBurntAreaService',
          );
        }
      }

      developer.log(
        'EffisBurntAreaService: Parsed ${burntAreas.length} burnt areas from GML',
        name: 'EffisBurntAreaService',
      );

      return Right(burntAreas);
    } on xml.XmlParserException catch (e) {
      return Left(ApiError(message: 'Invalid GML response: ${e.message}'));
    } catch (e) {
      return Left(ApiError(message: 'Failed to parse GML response: $e'));
    }
  }

  /// Parse a single GML feature member to BurntArea
  BurntArea? _parseGmlFeature(xml.XmlElement featureMember) {
    // Get the actual feature element (child of featureMember)
    final feature =
        featureMember.children.whereType<xml.XmlElement>().firstOrNull;

    if (feature == null) return null;

    // Extract properties
    String? id;
    DateTime? fireDate;
    double? areaHectares;
    List<LatLng>? boundaryPoints;

    for (final child in feature.children.whereType<xml.XmlElement>()) {
      // EFFIS uses uppercase element names with ms: namespace
      // child.name.local strips the namespace prefix
      final localName = child.name.local.toUpperCase();

      switch (localName) {
        case 'ID':
          id = child.innerText;
          break;
        case 'FIREDATE':
          final text = child.innerText;
          if (text.isNotEmpty) {
            // EFFIS date format: "2025-02-06 13:44:00"
            fireDate = DateTime.tryParse(text.replaceAll(' ', 'T'));
          }
          break;
        case 'AREA_HA':
          final text = child.innerText;
          if (text.isNotEmpty) {
            areaHectares = double.tryParse(text);
          }
          break;
        case 'COUNTRY':
          // Country field available but not stored in BurntArea model
          break;
        case 'THE_GEOM':
        case 'MSGEOMETRY':
          boundaryPoints = _parseGmlGeometry(child);
          break;
      }
    }

    // Validate required fields
    if (id == null || id.isEmpty) {
      developer.log(
        'EffisBurntAreaService: Feature missing id',
        name: 'EffisBurntAreaService',
      );
      return null;
    }

    if (boundaryPoints == null || boundaryPoints.length < 3) {
      developer.log(
        'EffisBurntAreaService: Feature $id has invalid geometry (${boundaryPoints?.length ?? 0} points)',
        name: 'EffisBurntAreaService',
      );
      return null;
    }

    // BurntArea.centroid is a computed getter, so we just pass boundary points
    return BurntArea(
      id: id,
      boundaryPoints: boundaryPoints,
      areaHectares: areaHectares ?? 0.0,
      fireDate: fireDate ?? DateTime.now(),
      seasonYear: fireDate?.year ?? DateTime.now().year,
      landCoverBreakdown: null,
      isSimplified: false,
    );
  }

  /// Parse GML geometry element to list of LatLng points
  List<LatLng>? _parseGmlGeometry(xml.XmlElement geomElement) {
    // Look for MultiPolygon or Polygon
    final multiPolygon =
        geomElement.findAllElements('gml:MultiPolygon').firstOrNull ??
            geomElement.findAllElements('MultiPolygon').firstOrNull;

    if (multiPolygon != null) {
      // Get first polygon from MultiPolygon
      final polygon = multiPolygon.findAllElements('gml:Polygon').firstOrNull ??
          multiPolygon.findAllElements('Polygon').firstOrNull;
      if (polygon != null) {
        return _parsePolygon(polygon);
      }
    }

    // Check for direct Polygon
    final polygon = geomElement.findAllElements('gml:Polygon').firstOrNull ??
        geomElement.findAllElements('Polygon').firstOrNull;
    if (polygon != null) {
      return _parsePolygon(polygon);
    }

    return null;
  }

  /// Parse GML Polygon element
  List<LatLng>? _parsePolygon(xml.XmlElement polygon) {
    // Get exterior ring
    final exterior = polygon.findAllElements('gml:exterior').firstOrNull ??
        polygon.findAllElements('exterior').firstOrNull;

    if (exterior == null) return null;

    // Get LinearRing
    final linearRing = exterior.findAllElements('gml:LinearRing').firstOrNull ??
        exterior.findAllElements('LinearRing').firstOrNull;

    if (linearRing == null) return null;

    // Get coordinates - could be posList or coordinates
    final posList = linearRing.findAllElements('gml:posList').firstOrNull ??
        linearRing.findAllElements('posList').firstOrNull;

    if (posList != null) {
      return _parsePosList(posList.innerText);
    }

    // Try coordinates element
    final coordinates =
        linearRing.findAllElements('gml:coordinates').firstOrNull ??
            linearRing.findAllElements('coordinates').firstOrNull;

    if (coordinates != null) {
      return _parseCoordinates(coordinates.innerText);
    }

    return null;
  }

  /// Parse GML posList format: "lat1 lon1 lat2 lon2 ..."
  List<LatLng> _parsePosList(String text) {
    final values = text.trim().split(RegExp(r'\s+'));
    final points = <LatLng>[];

    // Values are in pairs: lat lon lat lon ...
    for (int i = 0; i < values.length - 1; i += 2) {
      final lat = double.tryParse(values[i]);
      final lon = double.tryParse(values[i + 1]);
      if (lat != null && lon != null) {
        points.add(LatLng(lat, lon));
      }
    }

    return points;
  }

  /// Parse GML coordinates format: "lon1,lat1 lon2,lat2 ..."
  List<LatLng> _parseCoordinates(String text) {
    final pairs = text.trim().split(RegExp(r'\s+'));
    final points = <LatLng>[];

    for (final pair in pairs) {
      final parts = pair.split(',');
      if (parts.length >= 2) {
        final lon = double.tryParse(parts[0]);
        final lat = double.tryParse(parts[1]);
        if (lat != null && lon != null) {
          points.add(LatLng(lat, lon));
        }
      }
    }

    return points;
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
