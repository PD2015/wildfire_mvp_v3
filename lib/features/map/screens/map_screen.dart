import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/features/map/utils/marker_icon_helper.dart';
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/incidents_timestamp_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/fire_data_mode_toggle.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/time_filter_chips.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_type_selector.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
// T-V2: RiskCheckButton temporarily disabled
// import 'package:wildfire_mvp_v3/features/map/widgets/risk_check_button.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
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
  bool _hasCenteredOnUser = false; // Track if we've centered on user location

  /// Default fallback location (Aviemore, Scotland - matches LocationResolver)
  static const _aviemoreLocation = LatLng(57.2, -3.8);
  static const _defaultZoom = 8.0;

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
        // Update markers and polygons based on current fire data mode
        _updateMarkersForMode(state);
        _updatePolygonsForMode(state);

        // Center on user GPS location once when data first loads
        if (!_hasCenteredOnUser && _mapController != null) {
          _hasCenteredOnUser = true;
          _centerOnUserLocation();
        }
      }
      setState(() {});
    }
  }

  /// Center map on user's GPS location, fallback to Aviemore
  Future<void> _centerOnUserLocation() async {
    // If manual location is set, center on that; otherwise use GPS or fallback
    final state = _controller.state;
    LatLng targetLocation;
    String locationSource;

    if (state is MapSuccess) {
      // Use centerLocation from state (which may be manual or GPS)
      targetLocation = LatLng(
        state.centerLocation.latitude,
        state.centerLocation.longitude,
      );
      locationSource = _controller.isManualLocation ? 'manual location' : 'GPS';
    } else {
      // Fallback to stored GPS or Aviemore
      final userLocation = _controller.userGpsLocation;
      if (userLocation != null) {
        targetLocation = LatLng(userLocation.latitude, userLocation.longitude);
        locationSource = 'GPS';
      } else {
        targetLocation = _aviemoreLocation;
        locationSource = 'Aviemore fallback';
      }
    }

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: targetLocation,
          zoom: _defaultZoom,
        ),
      ),
    );

    debugPrint(
      '📍 Map centered on: $locationSource '
      '(${targetLocation.latitude.toStringAsFixed(2)}, ${targetLocation.longitude.toStringAsFixed(2)})',
    );
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

  /// Update markers based on current fire data mode
  ///
  /// In Hotspots mode: shows fire markers as pins (no polygons displayed)
  /// In Burnt Areas mode: shows centroid pins until zoom is high enough for polygons
  void _updateMarkersForMode(MapSuccess state) {
    if (_controller.fireDataMode == FireDataMode.hotspots) {
      // Hotspots mode: filter to only hotspot incidents
      final hotspotIncidents =
          state.incidents.where((i) => i.fireType == FireType.hotspot).toList();
      _updateHotspotMarkers(hotspotIncidents);
    } else {
      // Burnt Areas mode: filter to only burnt area incidents, then by season
      final currentYear = _controller.burntAreaSeasonFilter.year;
      final burntAreaIncidents = state.incidents
          .where((i) =>
              i.fireType == FireType.burntArea &&
              (i.seasonYear == null || i.seasonYear == currentYear))
          .toList();
      _updateBurntAreaMarkers(burntAreaIncidents);
    }
  }

  /// Update markers for hotspots mode
  /// Shows all fire incidents as pin markers
  void _updateHotspotMarkers(List<FireIncident> incidents) {
    debugPrint(
      '🔥 Hotspots mode: ${incidents.length} incidents, zoom=$_currentZoom',
    );

    if (incidents.isEmpty) {
      _markers = {};
      debugPrint('🔥 Hotspots mode: no incidents, markers cleared');
      return;
    }

    _markers = incidents.map((incident) {
      return Marker(
        markerId: MarkerId('hotspot_${incident.id}'),
        position: LatLng(
          incident.location.latitude,
          incident.location.longitude,
        ),
        icon: _getMarkerIcon(incident.intensity),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: incident.description ?? 'Active Fire',
          snippet: _buildHotspotSnippet(incident),
        ),
        onTap: () {
          debugPrint(
              '🔥 Hotspot tapped: ${incident.id} (${incident.intensity})');
          _showFireDetails(incident);
        },
      );
    }).toSet();

    debugPrint('🔥 Hotspots mode: created ${_markers.length} markers');
  }

  /// Build info window snippet for hotspot marker
  String _buildHotspotSnippet(FireIncident incident) {
    final parts = <String>[];

    if (incident.frp != null) {
      parts.add('FRP: ${incident.frp!.toStringAsFixed(1)} MW');
    }

    parts.add(_formatIntensity(incident.intensity));

    if (incident.detectedAt != null) {
      parts.add('Detected: ${_formatFreshness(incident.detectedAt!)}');
    }

    return parts.join(' • ');
  }

  /// Update markers for burnt areas mode
  /// Shows centroid pins when zoom is too low to see polygons
  void _updateBurntAreaMarkers(List<FireIncident> incidents) {
    final showPolygons = _shouldShowPolygons();

    // Filter to only incidents that have polygon boundaries
    final incidentsWithBoundaries = incidents
        .where((i) => i.boundaryPoints != null && i.boundaryPoints!.length >= 3)
        .toList();

    debugPrint(
      '🔶 Burnt Areas mode: ${incidentsWithBoundaries.length}/${incidents.length} '
      'incidents with boundaries, zoom=$_currentZoom, showPolygons=$showPolygons',
    );

    // If polygons are visible, don't show markers (avoid duplicate displays)
    if (showPolygons) {
      _markers = {};
      debugPrint('🔶 Burnt Areas mode: polygons visible, markers cleared');
      return;
    }

    // Show centroid markers when polygons aren't visible
    _markers = incidentsWithBoundaries.map((incident) {
      return Marker(
        markerId: MarkerId('burnt_area_${incident.id}'),
        position: LatLng(
          incident.location.latitude,
          incident.location.longitude,
        ),
        icon: _getMarkerIcon(incident.intensity),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: incident.description ?? 'Burnt Area',
          snippet: _buildBurntAreaSnippet(incident),
        ),
        onTap: () {
          debugPrint('🔶 Burnt area marker tapped: ${incident.id}');
          _showFireDetails(incident);
        },
      );
    }).toSet();

    debugPrint(
        '🔶 Burnt Areas mode: created ${_markers.length} centroid markers');
  }

  /// Build info window snippet for burnt area marker
  String _buildBurntAreaSnippet(FireIncident incident) {
    final parts = <String>[];

    if (incident.areaHectares != null) {
      parts.add('${incident.areaHectares!.toStringAsFixed(1)} ha');
    }

    parts.add(_formatIntensity(incident.intensity));

    return parts.join(' • ');
  }

  /// Show fire details in bottom sheet
  void _showFireDetails(FireIncident incident) {
    setState(() {
      _selectedIncident = incident;
      _isBottomSheetVisible = true;
    });
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

  /// Update polygon overlays based on current fire data mode
  ///
  /// In Burnt Areas mode: shows polygons from incidents with boundary data
  /// In Hotspots mode: no polygons (markers shown instead)
  void _updatePolygonsForMode(MapSuccess state) {
    // In Hotspots mode, don't show polygons
    if (_controller.fireDataMode == FireDataMode.hotspots) {
      _polygons = {};
      debugPrint('🔶 Hotspots mode: polygons cleared');
      return;
    }

    // Burnt Areas mode: check zoom threshold
    if (!_shouldShowPolygons()) {
      _polygons = {};
      debugPrint('🔶 Burnt Areas mode: zoom too low for polygons');
      return;
    }

    // Filter by fire type and season
    final currentYear = _controller.burntAreaSeasonFilter.year;
    final incidentsWithBoundaries = state.incidents
        .where((i) =>
            i.fireType == FireType.burntArea &&
            (i.seasonYear == null || i.seasonYear == currentYear) &&
            i.boundaryPoints != null &&
            i.boundaryPoints!.length >= 3)
        .toList();

    _polygons = incidentsWithBoundaries.map((incident) {
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
          _showFireDetails(incident);
        },
      );
    }).toSet();

    debugPrint(
        '🔶 Updated ${_polygons.length} polygons from ${incidentsWithBoundaries.length} '
        'incidents with boundaries (year: $currentYear)');
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

    // Update controller zoom for clustering decisions
    _controller.updateZoom(newZoom);

    // Rebuild polygons if visibility threshold crossed (only in Burnt Areas mode)
    final nowShowingPolygons = _shouldShowPolygons();
    if (wasShowingPolygons != nowShowingPolygons) {
      final state = _controller.state;
      if (state is MapSuccess) {
        _updatePolygonsForMode(state);
        setState(() {});
      }
    }

    // Also notify viewport loader
    _viewportLoader.onCameraMove(position);
  }

  // T-V3: Polygon toggle replaced by FireDataModeToggle (021-live-fire-data)
  // void _onPolygonToggle() {
  //   setState(() {
  //     _showPolygons = !_showPolygons;
  //   });
  //
  //   // Rebuild polygons with new visibility setting
  //   final state = _controller.state;
  //   if (state is MapSuccess) {
  //     _updatePolygons(state);
  //   }
  //
  //   debugPrint('🔶 Polygon visibility toggled: $_showPolygons');
  // }

  /// Animate camera to user's GPS location (or fallback to Aviemore)
  /// Called when user taps the GPS button
  Future<void> _animateToUserLocation() async {
    if (_mapController == null) return;

    try {
      // Use stored GPS location from controller, fallback to Aviemore
      final userLocation = _controller.userGpsLocation;
      final targetLocation = userLocation != null
          ? LatLng(userLocation.latitude, userLocation.longitude)
          : _aviemoreLocation;

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetLocation,
            zoom: 10.0,
          ),
        ),
      );

      debugPrint(
        '📍 GPS button: Animated to ${userLocation != null ? "user GPS" : "Aviemore fallback"} '
        '(${targetLocation.latitude.toStringAsFixed(2)}, ${targetLocation.longitude.toStringAsFixed(2)})',
      );
    } catch (e) {
      debugPrint('❌ Error animating to user location: $e');
    }
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
            // Start at Aviemore - will animate to user GPS once resolved
            initialCameraPosition: const CameraPosition(
              target: _aviemoreLocation,
              zoom: _defaultZoom,
            ),
            markers: _markers,
            polygons: _polygons, // Burnt area polygon overlays
            mapType: _currentMapType,
            myLocationEnabled: true, // Show blue dot for user location
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true, // Enable pinch-to-zoom
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            mapToolbarEnabled: false,
            // Disable native GPS button - we add our own for better positioning
            myLocationButtonEnabled: false,
            // Padding for zoom controls and overlays
            padding: const EdgeInsets.only(
              top: 100.0, // Room for top-right chips
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
            ),
            // Track zoom level for polygon visibility + debounced viewport loading
            onCameraMove: _onCameraMove,
            onCameraIdle: _viewportLoader.onCameraIdle,
          ),
        ),
        // Source chip positioned at top-left - only show when there are fires
        // When no fires, the empty state card already shows the data source
        if (state.incidents.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            child: MapSourceChip(
              source: state.freshness,
              lastUpdated: state.lastUpdated,
            ),
          ),
        // Timestamp chip positioned at bottom-left - only show when there are fires
        if (state.incidents.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            child: IncidentsTimestampChip(
              lastUpdated: state.lastUpdated,
            ),
          ),
        // Map controls positioned at top-right (fire data mode, filters, map type, GPS)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Fire data mode toggle (Hotspots / Burnt Areas)
              FireDataModeToggle(
                mode: _controller.fireDataMode,
                onModeChanged: (mode) {
                  _controller.setFireDataMode(mode);
                  // Immediately update markers/polygons for new mode
                  final state = _controller.state;
                  if (state is MapSuccess) {
                    _updateMarkersForMode(state);
                    _updatePolygonsForMode(state);
                  }
                  setState(() {
                    // Sync local polygon visibility with mode
                    _showPolygons = mode == FireDataMode.burntAreas;
                  });
                },
                enabled: true,
              ),
              const SizedBox(height: 8),
              // Time filter chips (dynamic based on mode)
              TimeFilterChips(
                mode: _controller.fireDataMode,
                hotspotFilter: _controller.hotspotTimeFilter,
                burntAreaFilter: _controller.burntAreaSeasonFilter,
                onHotspotFilterChanged: (filter) {
                  _controller.setHotspotTimeFilter(filter);
                },
                onBurntAreaFilterChanged: (filter) {
                  _controller.setBurntAreaSeasonFilter(filter);
                },
                enabled: true,
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
              const SizedBox(height: 8),
              // GPS button - center on user location
              // Styled to match Google Maps native controls (white bg, grey icon)
              Semantics(
                key: const Key('gps_button'),
                label: 'Center map on your location',
                button: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _animateToUserLocation,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.my_location,
                          size: 24,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Empty state message if no fires - mode-specific messaging
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
                      _getEmptyStateTitle(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEmptyStateDescription(),
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
                    const SizedBox(height: 8),
                    // Hint to try other mode
                    TextButton(
                      onPressed: () {
                        final newMode =
                            _controller.fireDataMode == FireDataMode.hotspots
                                ? FireDataMode.burntAreas
                                : FireDataMode.hotspots;
                        _controller.setFireDataMode(newMode);
                        setState(() {
                          _showPolygons = newMode == FireDataMode.burntAreas;
                        });
                      },
                      child: Text(
                        _getEmptyStateHint(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Get mode-specific empty state title
  String _getEmptyStateTitle() {
    switch (_controller.fireDataMode) {
      case FireDataMode.hotspots:
        return 'No Active Fires Detected';
      case FireDataMode.burntAreas:
        return 'No Burnt Areas This Season';
    }
  }

  /// Get mode-specific empty state description
  String _getEmptyStateDescription() {
    switch (_controller.fireDataMode) {
      case FireDataMode.hotspots:
        return 'No satellite-detected hotspots in the last 24 hours within the current view. This is good news!';
      case FireDataMode.burntAreas:
        return 'No verified burnt areas have been recorded for the current fire season in this region.';
    }
  }

  /// Get hint text suggesting the user try the other mode
  String _getEmptyStateHint() {
    switch (_controller.fireDataMode) {
      case FireDataMode.hotspots:
        return 'Try viewing burnt areas instead →';
      case FireDataMode.burntAreas:
        return 'Try viewing active hotspots instead →';
    }
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
