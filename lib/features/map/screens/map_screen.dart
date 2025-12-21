import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/features/map/utils/hotspot_clusterer.dart';
import 'package:wildfire_mvp_v3/features/map/utils/hotspot_style_helper.dart';
import 'package:wildfire_mvp_v3/features/map/utils/marker_icon_helper.dart';
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/hotspot_cluster_marker.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/hotspot_square_builder.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/incidents_timestamp_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/fire_data_mode_toggle.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/time_filter_chips.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_type_selector.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_zoom_controls.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
// T-V2: RiskCheckButton temporarily disabled
// import 'package:wildfire_mvp_v3/features/map/widgets/risk_check_button.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
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
  Hotspot? _selectedHotspot; // Track selected hotspot for native display
  BurntArea? _selectedBurntArea; // Track selected burnt area for native display
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
        // Uses controller's hotspots/burntAreas collections (live data flow)
        _updateMarkersForMode();
        _updatePolygonsForMode();

        // Center on user GPS location once when data first loads
        if (!_hasCenteredOnUser && _mapController != null) {
          _hasCenteredOnUser = true;
          _centerOnUserLocation();
        }
      }
      setState(() {});
    }
  }

  /// Toggle between live and demo data modes
  /// Called when user taps the MapSourceChip
  void _toggleDataMode() {
    final newMode = !_controller.useLiveData;
    _controller.setUseLiveData(newMode);

    // Show feedback snackbar
    final message =
        newMode ? 'Switched to Live Data mode' : 'Switched to Demo Data mode';
    final icon = newMode ? Icons.cloud_done : Icons.science_outlined;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
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
  /// In Hotspots mode: renders markers from controller.hotspots (List<Hotspot>)
  /// In Burnt Areas mode: renders centroid markers from controller.burntAreas (List<BurntArea>)
  void _updateMarkersForMode() {
    if (_controller.fireDataMode == FireDataMode.hotspots) {
      // Hotspots mode: use controller's hotspots list (live data flow)
      _updateHotspotMarkers(_controller.hotspots);
    } else {
      // Burnt Areas mode: use controller's burntAreas list (live data flow)
      _updateBurntAreaMarkersFromModel(_controller.burntAreas);
    }
  }

  /// Update markers for hotspots mode from Hotspot models
  ///
  /// Display rules based on zoom level:
  /// - Zoom < 8: Cluster badges only (grouped hotspots)
  /// - Zoom 8-12: Flame pin markers + 375m satellite footprint squares
  /// - Zoom >= 12: Satellite footprint squares only (pins hidden for clarity)
  void _updateHotspotMarkers(List<Hotspot> hotspots) {
    debugPrint(
      '🔥 Hotspots mode: ${hotspots.length} hotspots, zoom=$_currentZoom, '
      'shouldShowClusters=${_controller.shouldShowClusters}',
    );

    if (hotspots.isEmpty) {
      _markers = {};
      debugPrint('🔥 Hotspots mode: no hotspots, markers cleared');
      return;
    }

    // Check if we should show clusters (zoom < 10) or individual markers
    if (_controller.shouldShowClusters) {
      // Low zoom: show cluster markers instead of individual pins
      _updateClusterMarkers();
    } else {
      // High zoom: show individual flame pin markers
      _updateIndividualHotspotMarkers(hotspots);
    }
  }

  /// Update markers to show cluster badges (zoom < 10)
  ///
  /// Single-item clusters (count=1) are shown as flame pins instead of badges
  /// since a "cluster of 1" doesn't make visual sense.
  Future<void> _updateClusterMarkers() async {
    final clusters = _controller.clusters;

    if (clusters.isEmpty) {
      _markers = {};
      debugPrint('🔥 Cluster mode: no clusters, markers cleared');
      return;
    }

    // Separate multi-hotspot clusters from single hotspots
    final multiClusters = clusters.where((c) => c.count > 1).toList();
    final singleClusters = clusters.where((c) => c.count == 1).toList();

    debugPrint(
      '🔥 Cluster mode: ${multiClusters.length} multi-clusters, '
      '${singleClusters.length} single hotspots',
    );

    // Build cluster badges for multi-hotspot clusters
    final clusterMarkers = await HotspotClusterMarker.buildMarkers(
      clusters: multiClusters,
      onTap: (cluster) {
        debugPrint(
          '🔥 Cluster tapped: ${cluster.count} hotspots, '
          'zooming to fit bounds',
        );
        _zoomToClusterBounds(cluster);
      },
    );

    // Build flame pin markers for single hotspots
    final singleMarkers = singleClusters.map((cluster) {
      final hotspot = cluster.hotspots.first;
      return Marker(
        markerId: MarkerId('hotspot_${hotspot.id}'),
        position: LatLng(
          hotspot.location.latitude,
          hotspot.location.longitude,
        ),
        icon: MarkerIconHelper.getIcon(hotspot.intensity),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: 'Active Fire',
          snippet: _buildHotspotSnippetFromModel(hotspot),
        ),
        onTap: () {
          debugPrint('🔥 Hotspot tapped: ${hotspot.id} (${hotspot.intensity})');
          _showHotspotDetails(hotspot);
        },
      );
    }).toSet();

    // Combine both marker types
    _markers = {...clusterMarkers, ...singleMarkers};

    debugPrint(
      '🔥 Cluster mode: ${clusterMarkers.length} cluster badges + '
      '${singleMarkers.length} flame pins = ${_markers.length} total',
    );
    if (mounted) setState(() {});
  }

  /// Zoom map to fit all hotspots in a cluster
  void _zoomToClusterBounds(HotspotCluster cluster) {
    if (_mapController == null) return;

    // Get bounds from cluster and zoom to fit
    final bounds = cluster.bounds;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest:
              LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
          northeast:
              LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
        ),
        50.0, // padding
      ),
    );
  }

  /// Update markers to show individual flame pins (zoom 8-12)
  ///
  /// At zoom >= 12: satellite footprint squares are large enough to see clearly,
  /// so we hide pin markers to reduce visual clutter (squares only).
  void _updateIndividualHotspotMarkers(List<Hotspot> hotspots) {
    // At zoom >= 12, hide pins - only satellite squares are shown
    if (_currentZoom >= HotspotClusterer.maxClusterZoom) {
      _markers = {};
      debugPrint(
        '🔥 High zoom (${_currentZoom.toStringAsFixed(1)}): '
        'pins hidden, showing satellite squares only',
      );
      return;
    }

    _markers = hotspots.map((hotspot) {
      return Marker(
        markerId: MarkerId('hotspot_${hotspot.id}'),
        position: LatLng(
          hotspot.location.latitude,
          hotspot.location.longitude,
        ),
        icon: MarkerIconHelper.getIcon(hotspot.intensity),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: 'Active Fire',
          snippet: _buildHotspotSnippetFromModel(hotspot),
        ),
        onTap: () {
          debugPrint('🔥 Hotspot tapped: ${hotspot.id} (${hotspot.intensity})');
          _showHotspotDetails(hotspot);
        },
      );
    }).toSet();

    debugPrint('🔥 Individual mode: created ${_markers.length} pin markers');
  }

  /// Build info window snippet for hotspot marker from Hotspot model
  String _buildHotspotSnippetFromModel(Hotspot hotspot) {
    final parts = <String>[];
    parts.add('FRP: ${hotspot.frp.toStringAsFixed(1)} MW');
    parts.add(_formatIntensity(hotspot.intensity));
    parts.add('Detected: ${_formatFreshness(hotspot.detectedAt)}');
    return parts.join(' • ');
  }

  /// Update markers for burnt areas mode from BurntArea models
  /// Shows centroid pins when zoom is too low to see polygons
  void _updateBurntAreaMarkersFromModel(List<BurntArea> burntAreas) {
    final showPolygons = _shouldShowPolygons();

    debugPrint(
      '🔶 Burnt Areas mode: ${burntAreas.length} areas, '
      'zoom=$_currentZoom, showPolygons=$showPolygons',
    );

    // If polygons are visible, don't show markers (avoid duplicate displays)
    if (showPolygons) {
      _markers = {};
      debugPrint('🔶 Burnt Areas mode: polygons visible, markers cleared');
      return;
    }

    // Show centroid markers when polygons aren't visible
    _markers = burntAreas.map((area) {
      final centroid = area.centroid;
      return Marker(
        markerId: MarkerId('burnt_area_${area.id}'),
        position: LatLng(centroid.latitude, centroid.longitude),
        icon:
            MarkerIconHelper.getIcon('high'), // All burnt areas use red marker
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: 'Burnt Area',
          snippet: _buildBurntAreaSnippetFromModel(area),
        ),
        onTap: () {
          debugPrint('🔶 Burnt area marker tapped: ${area.id}');
          _showBurntAreaDetails(area);
        },
      );
    }).toSet();

    debugPrint(
        '🔶 Burnt Areas mode: created ${_markers.length} centroid markers');
  }

  /// Build info window snippet for burnt area marker from BurntArea model
  String _buildBurntAreaSnippetFromModel(BurntArea area) {
    final parts = <String>[];
    parts.add('${area.areaHectares.toStringAsFixed(1)} ha');
    parts.add('Fire date: ${_formatDate(area.fireDate)}');
    return parts.join(' • ');
  }

  /// Format date as short string (e.g., "15 Jul 2025")
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Show hotspot details in bottom sheet using native Hotspot data
  void _showHotspotDetails(Hotspot hotspot) {
    setState(() {
      _selectedHotspot = hotspot;
      _selectedBurntArea = null;
      _selectedIncident = null; // Clear legacy field
      _isBottomSheetVisible = true;
    });
  }

  /// Show burnt area details in bottom sheet using native BurntArea data
  void _showBurntAreaDetails(BurntArea area) {
    setState(() {
      _selectedBurntArea = area;
      _selectedHotspot = null;
      _selectedIncident = null; // Clear legacy field
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

  /// Build the appropriate bottom sheet based on selected data type
  Widget _buildBottomSheet() {
    final userLocation = _controller.userGpsLocation;

    void closeSheet() {
      setState(() {
        _isBottomSheetVisible = false;
        _selectedHotspot = null;
        _selectedBurntArea = null;
        _selectedIncident = null;
      });
    }

    // Hotspot selected - use native Hotspot display
    if (_selectedHotspot != null) {
      return FireDetailsBottomSheet.fromHotspot(
        hotspot: _selectedHotspot!,
        userLocation: userLocation,
        onClose: closeSheet,
        freshness: _controller.dataFreshness,
      );
    }

    // BurntArea selected - use native BurntArea display
    if (_selectedBurntArea != null) {
      return FireDetailsBottomSheet.fromBurntArea(
        burntArea: _selectedBurntArea!,
        userLocation: userLocation,
        onClose: closeSheet,
        freshness: _controller.dataFreshness,
      );
    }

    // Legacy FireIncident fallback
    if (_selectedIncident != null) {
      return FireDetailsBottomSheet(
        incident: _selectedIncident!,
        userLocation: userLocation,
        onClose: closeSheet,
      );
    }

    // Should never reach here due to condition in build()
    return const SizedBox.shrink();
  }

  /// Update polygon overlays based on current fire data mode
  ///
  /// In Burnt Areas mode: shows polygons from controller.burntAreas (List<BurntArea>)
  /// In Hotspots mode: shows 375m × 375m satellite footprint squares at high zoom
  void _updatePolygonsForMode() {
    // Hotspots mode: show 375m satellite footprint squares at high zoom
    if (_controller.fireDataMode == FireDataMode.hotspots) {
      _updateHotspotPolygons();
      return;
    }

    // Burnt Areas mode: check zoom threshold
    if (!_shouldShowPolygons()) {
      _polygons = {};
      debugPrint('🔶 Burnt Areas mode: zoom too low for polygons');
      return;
    }

    // Use controller's burntAreas list (live data flow)
    final burntAreas = _controller.burntAreas;

    _polygons = burntAreas.map((area) {
      final points = area.boundaryPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      return Polygon(
        polygonId: PolygonId('polygon_${area.id}'),
        points: points,
        fillColor: PolygonStyleHelper.burntAreaFillColor,
        strokeColor: PolygonStyleHelper.burntAreaStrokeColor,
        strokeWidth: PolygonStyleHelper.strokeWidth,
        consumeTapEvents: true,
        onTap: () {
          debugPrint('🔶 Polygon tapped: ${area.id}');
          _showBurntAreaDetails(area);
        },
      );
    }).toSet();

    debugPrint(
        '🔶 Updated ${_polygons.length} polygons from ${burntAreas.length} burnt areas');
  }

  /// Update polygon overlays for hotspots mode
  ///
  /// At zoom >= 8: Shows 375m × 375m satellite footprint squares
  /// At zoom < 8: No polygons (pin markers only for overview)
  void _updateHotspotPolygons() {
    // Check minimum zoom for squares (too small at low zoom)
    if (_currentZoom < HotspotStyleHelper.minZoomForSquares) {
      _polygons = {};
      debugPrint(
        '🔥 Hotspots mode: zoom $_currentZoom < ${HotspotStyleHelper.minZoomForSquares}, '
        'using markers only',
      );
      return;
    }

    // Build 375m satellite footprint squares
    final hotspots = _controller.hotspots;
    _polygons = HotspotSquareBuilder.buildPolygons(
      hotspots: hotspots,
      onTap: (hotspot) {
        debugPrint('🔥 Hotspot square tapped: ${hotspot.id}');
        _showHotspotDetails(hotspot);
      },
    );

    debugPrint(
      '🔥 Hotspots mode: created ${_polygons.length} satellite footprint squares '
      '(375m × 375m) at zoom $_currentZoom',
    );
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
    final wasShowingHotspotSquares =
        _currentZoom >= HotspotStyleHelper.minZoomForSquares;
    final wasShowingClusters = _controller.shouldShowClusters;

    _currentZoom = newZoom;

    // Update controller zoom for clustering decisions
    _controller.updateZoom(newZoom);

    final nowShowingClusters = _controller.shouldShowClusters;

    // Check if we crossed the cluster threshold (zoom 10)
    // This determines whether to show cluster badges vs individual pins
    if (wasShowingClusters != nowShowingClusters &&
        _controller.fireDataMode == FireDataMode.hotspots) {
      debugPrint(
        '🔥 Cluster threshold crossed: ${nowShowingClusters ? "showing clusters" : "showing individual pins"}',
      );
      _updateMarkersForMode();
      setState(() {});
    }

    // Check if we crossed the hotspot square threshold (zoom 8)
    final nowShowingHotspotSquares =
        newZoom >= HotspotStyleHelper.minZoomForSquares;
    if (wasShowingHotspotSquares != nowShowingHotspotSquares &&
        _controller.fireDataMode == FireDataMode.hotspots) {
      debugPrint(
        '🔥 Hotspot square threshold crossed: ${nowShowingHotspotSquares ? "showing 375m squares" : "hiding squares"}',
      );
      _updatePolygonsForMode();
      setState(() {});
    }

    // Rebuild polygons if visibility threshold crossed (Burnt Areas mode)
    final nowShowingPolygons = _shouldShowPolygons();
    if (wasShowingPolygons != nowShowingPolygons &&
        _controller.fireDataMode == FireDataMode.burntAreas) {
      _updatePolygonsForMode();
      setState(() {});
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

  /// Zoom in by 1 level
  Future<void> _zoomIn() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomIn());
  }

  /// Zoom out by 1 level
  Future<void> _zoomOut() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomOut());
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

    // Show loading indicator in AppBar when fetching data
    final isLoading = _controller.isFetchingBurntAreas &&
        _controller.fireDataMode == FireDataMode.burntAreas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Wildfire Fire Map'),
        centerTitle: true,
        // Material 3 pattern: LinearProgressIndicator in AppBar bottom for loading state
        bottom: isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : null,
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
          // Fire details bottom sheet overlay - supports Hotspot, BurntArea, or legacy FireIncident
          if (_isBottomSheetVisible &&
              (_selectedHotspot != null ||
                  _selectedBurntArea != null ||
                  _selectedIncident != null))
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isBottomSheetVisible = false;
                    _selectedHotspot = null;
                    _selectedBurntArea = null;
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
                    child: _buildBottomSheet(),
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
                          _controller.fireDataMode == FireDataMode.hotspots
                              ? '${_controller.fireDataCount} Active Hotspots'
                              : '${_controller.fireDataCount} Burnt Areas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data source: ${_controller.dataFreshness.name.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_controller.hasFireData) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Show fire data summary based on current mode
                          if (_controller.fireDataMode == FireDataMode.hotspots)
                            ..._controller.hotspots.take(5).map(
                                  (hotspot) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          color: hotspot.intensity == 'high'
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .error
                                              : hotspot.intensity == 'moderate'
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
                                            'Hotspot: FRP ${hotspot.frp.toStringAsFixed(1)} MW',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                          else
                            ..._controller.burntAreas.take(5).map(
                                  (area) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.terrain,
                                          color: area.intensity == 'high'
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .error
                                              : area.intensity == 'moderate'
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
                                            'Burnt Area: ${area.areaHectares.toStringAsFixed(1)} ha',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          if (_controller.fireDataCount > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+ ${_controller.fireDataCount - 5} more',
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
    final dataLabel = _controller.fireDataMode == FireDataMode.hotspots
        ? '${_controller.fireDataCount} hotspots'
        : '${_controller.fireDataCount} burnt areas';
    return Stack(
      children: [
        Semantics(
          key: const ValueKey('map_semantics'),
          label: 'Map showing $dataLabel',
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
            zoomControlsEnabled:
                false, // Disabled - using custom controls for theme consistency
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
        // Source chip positioned at top-left
        // Visibility logic (Option A from UX discussion):
        // 1. hasFireData: Show chip when there's fire data to display
        // 2. isOffline: Show chip to indicate offline/cached status
        // 3. useLiveData: ALWAYS show when live mode is enabled, even if no
        //    live data is available. This ensures users can toggle back to
        //    demo mode. Without this, users who switch to live mode in an
        //    area with no active fires would have no way to switch back.
        // When none of these are true, the empty state card shows the data source.
        // Tappable to toggle between live and demo data modes (disabled when offline)
        if (_controller.hasFireData ||
            _controller.isOffline ||
            _controller.useLiveData)
          Positioned(
            top: 16,
            left: 16,
            child: MapSourceChip(
              source: _controller.dataFreshness,
              lastUpdated: _controller.lastUpdated,
              isOffline: _controller.isOffline,
              onTap: _controller.isOffline ? null : _toggleDataMode,
            ),
          ),
        // Timestamp chip positioned at bottom-left - only show when there is fire data
        if (_controller.hasFireData)
          Positioned(
            bottom: 16,
            left: 16,
            child: IncidentsTimestampChip(
              lastUpdated: _controller.lastUpdated,
            ),
          ),
        // Loading status banner - positioned at bottom to avoid control overlap
        // Shows when fetching burnt area data (supplements AppBar progress indicator)
        if (_controller.isFetchingBurntAreas &&
            _controller.fireDataMode == FireDataMode.burntAreas)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: _buildLoadingBanner(context),
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
                  _updateMarkersForMode();
                  _updatePolygonsForMode();
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
              const SizedBox(height: 8),
              // Custom zoom controls - themed to match other map buttons
              MapZoomControls(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
              ),
            ],
          ),
        ),
        // Empty state message if no fire data - mode-specific messaging
        // Different UX for offline (API failure) vs normal empty state
        if (!_controller.hasFireData)
          Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _controller.isOffline
                    ? _buildOfflineEmptyState(context)
                    : _buildNormalEmptyState(context),
              ),
            ),
          ),
      ],
    );
  }

  /// Build loading banner - shows when fetching burnt area data
  ///
  /// Displays a subtle banner with progress indicator and text
  /// to inform users that data is being loaded.
  Widget _buildLoadingBanner(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading burnt areas...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build offline empty state - shown when API fails with MAP_LIVE_DATA=true
  ///
  /// Option C: Don't show mock data when live data was expected -
  /// that could be misleading for a safety-critical fire app.
  Widget _buildOfflineEmptyState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          'Unable to Load Fire Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Could not connect to fire monitoring services. '
          'Check your internet connection and try again.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Re-initialize to retry API calls
            _controller.initialize();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 48), // C3: ≥44dp touch target
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fire data will appear once connection is restored',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build normal empty state - shown when no fire data but API succeeded
  Widget _buildNormalEmptyState(BuildContext context) {
    return Column(
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
          'Data source: ${_controller.dataFreshness.name.toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Hint to try other mode
        TextButton(
          onPressed: () {
            final newMode = _controller.fireDataMode == FireDataMode.hotspots
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
