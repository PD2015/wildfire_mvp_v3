import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/features/map/utils/marker_icon_helper.dart';
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/incidents_timestamp_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/polygon_toggle_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_type_selector.dart';
// T-V2: RiskCheckButton temporarily disabled
// import 'package:wildfire_mvp_v3/features/map/widgets/risk_check_button.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/utils/debounced_viewport_loader.dart';
import 'package:wildfire_mvp_v3/widgets/fire_details_bottom_sheet.dart';

/// Map screen with Google Maps integration showing active fire incidents
///
/// Displays fire markers from EFFIS, SEPA, Cache, or Mock data sources.
/// Provides interactive map with zoom controls, fire markers, and risk checking.
///
/// Constitutional compliance:
/// - C3: Accessibility with semantic labels and ≥44dp touch targets
/// - C4: Uses Scottish color tokens for risk visualization
/// - C5: Mock-first approach (MAP_LIVE_DATA=false by default)
class MapScreen extends StatefulWidget {
  final MapController? controller;

  /// Creates a MapScreen widget
  const MapScreen({super.key, this.controller});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  late MapController _controller;
  FireIncident? _selectedIncident;
  bool _isBottomSheetVisible = false;
  bool _showPolygons = true; // Toggle for polygon visibility
  double _currentZoom = 8.0; // Track zoom for polygon visibility
  MapType _currentMapType = MapType.terrain; // Current map type
  late DebouncedViewportLoader _viewportLoader;

  @override
  void initState() {
    super.initState();
    // Controller must be provided
    if (widget.controller == null) {
      throw ArgumentError('MapController must be provided to MapScreen');
    }
    _controller = widget.controller!;
    _controller.addListener(_onControllerUpdate);

    // Initialize debounced viewport loader
    _viewportLoader = DebouncedViewportLoader(
      onViewportChanged: (bounds) async {
        await _controller.refreshMapData(bounds);
      },
    );

    // Initialize map data and marker icons on mount
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Pre-load flame marker icons
      await MarkerIconHelper.initialize();
      // Then load map data
      _controller.initialize();
    });
  }

  void _onControllerUpdate() {
    if (mounted) {
      final state = _controller.state;
      if (state is MapSuccess) {
        _updateMarkers(state);
        _updatePolygons(state);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _mapController?.dispose();
    _viewportLoader.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // CRITICAL: Set map controller for accurate viewport bounds
    _viewportLoader.setMapController(controller);

    debugPrint(
        '🗺️ MapScreen: GoogleMapController initialized, viewport loader configured');
  }

  void _updateMarkers(MapSuccess state) {
    _markers = state.incidents.map((incident) {
      debugPrint(
        '🎯 Creating marker: id=${incident.id}, intensity="${incident.intensity}", desc=${incident.description}',
      );

      final title = _buildInfoTitle(incident);
      final snippet = _buildInfoSnippet(incident);
      final isSelected = _selectedIncident?.id == incident.id;

      return Marker(
        markerId: MarkerId(incident.id),
        position: LatLng(
          incident.location.latitude,
          incident.location.longitude,
        ),
        icon: _getMarkerIcon(incident.intensity),
        // Anchor at bottom-center so the pin tip points to exact location
        anchor: const Offset(0.5, 1.0),
        alpha: isSelected ? 1.0 : 0.8, // Highlight selected marker
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
        onTap: () {
          debugPrint('🎯 Marker tapped: $title (${incident.intensity})');
          setState(() {
            _selectedIncident = incident;
            _isBottomSheetVisible = true;
          });
        },
      );
    }).toSet();
  }

  /// Build user-friendly title for info window
  /// Priority: description > shortened ID > full ID
  String _buildInfoTitle(FireIncident incident) {
    // Prefer descriptive location if available
    if (incident.description?.isNotEmpty == true) {
      return incident.description!;
    }

    // Fallback: Use shortened fire ID for readability
    // e.g., "mock_fire_001" → "Fire #ire_001" (last 7 chars)
    final shortId = incident.id.length > 7
        ? incident.id.substring(incident.id.length - 7)
        : incident.id;
    return 'Fire #$shortId';
  }

  /// Build user-friendly snippet with risk, area, source, and freshness
  /// Format: "Risk: Moderate • Burnt area: 12.5 ha\nSource: MOCK • 2h ago"
  String _buildInfoSnippet(FireIncident incident) {
    final intensityLabel = _formatIntensity(incident.intensity);
    final areaText = incident.areaHectares != null
        ? '${incident.areaHectares!.toStringAsFixed(1)} ha'
        : 'Unknown';

    final sourceLabel = _formatDataSource(incident.source);
    final freshnessText = _formatFreshness(incident.timestamp);

    // Line 1: Risk and burnt area
    // Line 2: Source and freshness
    return 'Risk: $intensityLabel • Burnt area: $areaText\n'
        'Source: $sourceLabel • $freshnessText';
  }

  /// Format intensity for user-friendly display
  String _formatIntensity(String raw) {
    switch (raw.toLowerCase()) {
      case 'high':
        return 'High';
      case 'moderate':
        return 'Moderate';
      case 'low':
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  /// Format data source for user-friendly display
  String _formatDataSource(DataSource source) {
    switch (source) {
      case DataSource.effis:
        return 'EFFIS';
      case DataSource.sepa:
        return 'SEPA';
      case DataSource.cache:
        return 'Cached';
      case DataSource.mock:
        return 'MOCK';
    }
  }

  /// Format timestamp as relative time (e.g., "2h ago", "3d ago")
  String _formatFreshness(DateTime timestamp) {
    final age = DateTime.now().difference(timestamp);

    if (age.inMinutes < 1) {
      return 'Just now';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes}m ago';
    } else if (age.inHours < 24) {
      return '${age.inHours}h ago';
    } else {
      return '${age.inDays}d ago';
    }
  }

  BitmapDescriptor _getMarkerIcon(String intensity) {
    // Use custom flame icons from MarkerIconHelper
    // Falls back to hue-based markers if icons not yet initialized
    return MarkerIconHelper.getIcon(intensity);
  }

  /// Update polygon overlays from fire incidents with valid boundary points
  void _updatePolygons(MapSuccess state) {
    if (!_shouldShowPolygons()) {
      _polygons = {};
      return;
    }

    _polygons = state.incidents
        .where((incident) => incident.hasValidPolygon)
        .map((incident) {
      final points = incident.boundaryPoints!
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      return Polygon(
        polygonId: PolygonId('polygon_${incident.id}'),
        points: points,
        fillColor: PolygonStyleHelper.getFillColor(incident.intensity),
        strokeColor: PolygonStyleHelper.getStrokeColor(incident.intensity),
        strokeWidth: PolygonStyleHelper.strokeWidth,
        consumeTapEvents: true,
        onTap: () {
          debugPrint(
              '🔶 Polygon tapped: ${incident.description ?? incident.id}');
          setState(() {
            _selectedIncident = incident;
            _isBottomSheetVisible = true;
          });
        },
      );
    }).toSet();

    debugPrint(
        '🔶 Updated ${_polygons.length} polygons from ${state.incidents.length} incidents');
  }

  /// Check if polygons should be visible based on zoom level and toggle
  bool _shouldShowPolygons() {
    return _showPolygons &&
        PolygonStyleHelper.shouldShowPolygonsAtZoom(_currentZoom);
  }

  /// Handle camera movement to track zoom level
  void _onCameraMove(CameraPosition position) {
    final newZoom = position.zoom;
    final wasShowingPolygons = _shouldShowPolygons();

    _currentZoom = newZoom;

    // Rebuild polygons if visibility threshold crossed
    final nowShowingPolygons = _shouldShowPolygons();
    if (wasShowingPolygons != nowShowingPolygons) {
      final state = _controller.state;
      if (state is MapSuccess) {
        _updatePolygons(state);
        setState(() {});
      }
    }

    // Also notify viewport loader
    _viewportLoader.onCameraMove(position);
  }

  /// Handle polygon visibility toggle
  void _onPolygonToggle() {
    setState(() {
      _showPolygons = !_showPolygons;
    });

    // Rebuild polygons with new visibility setting
    final state = _controller.state;
    if (state is MapSuccess) {
      _updatePolygons(state);
    }

    debugPrint('🔶 Polygon visibility toggled: $_showPolygons');
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    // Platform detection: google_maps_flutter supports:
    // - Web (kIsWeb=true): Uses google_maps_flutter_web with Maps JavaScript API
    // - Mobile (Android/iOS): Uses native Google Maps SDKs
    // - macOS desktop (kIsWeb=false && Platform.isMacOS): NOT SUPPORTED
    //
    // Note: "macOS" has two meanings:
    //   1. macOS Web (Flutter web in Safari/Chrome on Mac) → SUPPORTED ✅
    //   2. macOS Desktop (Flutter macOS native app) → NOT SUPPORTED ❌
    final bool isMapSupported =
        kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

    if (!isMapSupported) {
      return _buildUnsupportedPlatformView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Wildfire Fire Map'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main map content - simple switch on current state
          switch (state) {
            MapLoading() => Center(
                child: Semantics(
                  label: 'Loading map data',
                  child: const CircularProgressIndicator(),
                ),
              ),
            MapSuccess() => _buildMapView(state),
            MapError() => _buildErrorView(state),
          },
          // Fire details bottom sheet overlay
          if (_isBottomSheetVisible && _selectedIncident != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isBottomSheetVisible = false;
                    _selectedIncident = null;
                  });
                },
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .scrim
                      .withValues(alpha: 0.5),
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from closing when tapping sheet
                    child: FireDetailsBottomSheet(
                      incident: _selectedIncident!,
                      userLocation: _controller
                          .userGpsLocation, // Use actual GPS location, not viewport center
                      onClose: () {
                        setState(() {
                          _isBottomSheetVisible = false;
                          _selectedIncident = null;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // T-V2: FAB temporarily disabled - may be confusing/unnecessary feature
      // floatingActionButton: RiskCheckButton(controller: _controller),
      // floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildUnsupportedPlatformView() {
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Map'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined,
                  size: 64.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16.0),
              Text(
                'Map Not Available',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Google Maps is not supported on macOS Desktop.\nPlease use Android, iOS, or Web (Safari/Chrome) to view the fire map.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              // Still show fire data summary
              if (state is MapSuccess) ...[
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '${state.incidents.length} Active Fires',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data source: ${state.freshness.name.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (state.incidents.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          ...state.incidents.take(5).map(
                                (incident) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        color: incident.intensity == 'high'
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
                                            : incident.intensity == 'moderate'
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          incident.description ??
                                              'Fire Incident',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          if (state.incidents.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+ ${state.incidents.length - 5} more',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Tip: Run with "flutter run -d chrome" to see the web map',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(MapSuccess state) {
    return Stack(
      children: [
        Semantics(
          key: const ValueKey('map_semantics'),
          label: 'Map showing ${state.incidents.length} fire incidents',
          child: GoogleMap(
            key: const ValueKey('wildfire_map'),
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(57.2, -3.8), // Scotland centroid - constant
              zoom: 8.0,
            ),
            markers: _markers,
            polygons: _polygons, // Burnt area polygon overlays
            mapType: _currentMapType,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true, // Enable pinch-to-zoom
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            mapToolbarEnabled: false,
            // Add padding to prevent controls from overlapping chips
            padding: const EdgeInsets.only(
              bottom: 80.0, // Room for FAB
              left: 16.0, // Room for timestamp chip
              right: 16.0,
            ),
            // Track zoom level for polygon visibility + debounced viewport loading
            onCameraMove: _onCameraMove,
            onCameraIdle: _viewportLoader.onCameraIdle,
          ),
        ),
        // Source chip positioned at top-left
        Positioned(
          top: 16,
          left: 16,
          child: MapSourceChip(
            source: state.freshness,
            lastUpdated: state.lastUpdated,
          ),
        ),
        // Timestamp chip positioned at bottom-left
        Positioned(
          bottom: 16,
          left: 16,
          child: IncidentsTimestampChip(
            lastUpdated: state.lastUpdated,
          ),
        ),
        // Map controls positioned at top-right (burn areas toggle, then map type)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Burn areas visibility toggle (longer, so at top)
              PolygonToggleChip(
                showPolygons: _showPolygons,
                enabled:
                    PolygonStyleHelper.shouldShowPolygonsAtZoom(_currentZoom),
                onToggle: _onPolygonToggle,
              ),
              const SizedBox(height: 8),
              // Map type selector (dropdown menu)
              MapTypeSelector(
                currentMapType: _currentMapType,
                onMapTypeChanged: (mapType) {
                  setState(() {
                    _currentMapType = mapType;
                  });
                },
              ),
            ],
          ),
        ),
        // Empty state message if no fires
        if (state.incidents.isEmpty)
          Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Active Fires Detected',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are currently no wildfire incidents in this region',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Data source: ${state.freshness.name.toUpperCase()}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView(MapError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.0,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Failed to load map',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: () => _controller.initialize(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48), // C3: ≥44dp touch target
              ),
            ),
          ],
        ),
      ),
    );
  }
}
