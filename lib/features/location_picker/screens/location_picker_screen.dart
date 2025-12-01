import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart' as app;
import 'package:wildfire_mvp_v3/models/what3words_models.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/features/location_picker/controllers/location_picker_controller.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_state.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/picked_location.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/what3words_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/crosshair_overlay.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/location_info_panel.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/what3words_warning_dialog.dart';

/// Full-screen map-first location picker screen
///
/// **Design**: Map-centric interface where user pans to select location
/// with a fixed crosshair at center. what3words address resolves as user pans.
///
/// **Features**:
/// - Interactive GoogleMap with terrain/satellite/hybrid toggle
/// - Fixed crosshair overlay at map center
/// - Bottom panel showing coordinates and what3words
/// - Optional search (expandable via FAB or AppBar)
/// - Confirm button triggers warning if w3w not resolved
///
/// **Constitution Compliance**:
/// - C2: Coordinates logged with 2dp precision only
/// - C3: All buttons ≥48dp touch target
/// - C3: Semantic labels for accessibility
///
/// Returns [PickedLocation] via Navigator.pop when confirmed.
class LocationPickerScreen extends StatefulWidget {
  final LocationPickerMode mode;
  final app.LatLng? initialLocation;
  final What3wordsAddress? initialWhat3words;
  final String? initialPlaceName;
  final What3wordsService what3wordsService;
  final GeocodingService geocodingService;
  final LocationResolver locationResolver;

  const LocationPickerScreen({
    super.key,
    required this.mode,
    required this.what3wordsService,
    required this.geocodingService,
    required this.locationResolver,
    this.initialLocation,
    this.initialWhat3words,
    this.initialPlaceName,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final LocationPickerController _controller;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isGettingGps = false;

  /// Default camera position (Scotland centroid for wildfire app context)
  static const _scotlandCentroid = LatLng(57.2, -3.8);
  static const _defaultZoom = 10.0;

  @override
  void initState() {
    super.initState();
    _controller = LocationPickerController(
      what3wordsService: widget.what3wordsService,
      geocodingService: widget.geocodingService,
      mode: widget.mode,
      initialLocation: widget.initialLocation,
      initialWhat3words: widget.initialWhat3words,
      initialPlaceName: widget.initialPlaceName,
    );
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  /// Get initial camera position from initial location or default
  CameraPosition get _initialCameraPosition {
    final coords = widget.initialLocation;
    if (coords != null) {
      return CameraPosition(
        target: LatLng(coords.latitude, coords.longitude),
        zoom: 14.0, // Closer zoom for known location
      );
    }
    return const CameraPosition(
      target: _scotlandCentroid,
      zoom: _defaultZoom,
    );
  }

  /// Handle camera idle (user stopped panning)
  void _onCameraIdle() {
    _mapController?.getVisibleRegion().then((bounds) {
      // Calculate center from visible region
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      // Convert to app LatLng and update controller
      _controller.setLocationFromCamera(
        app.LatLng(center.latitude, center.longitude),
      );
    });
  }

  /// Handle confirm button tap
  Future<void> _onConfirm() async {
    final state = _controller.state;

    // Check if what3words is loading or unavailable
    if (state is LocationPickerSelected) {
      if (state.isResolvingWhat3words || state.what3words == null) {
        // Show warning dialog
        final confirm = await What3wordsWarningDialog.show(
          context,
          isLoading: state.isResolvingWhat3words,
        );
        if (!confirm) return;
      }
    }

    final result = _controller.confirmSelection();
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  void _onCopyWhat3words() {
    final state = _controller.state;
    if (state is LocationPickerSelected && state.what3words != null) {
      Clipboard.setData(ClipboardData(text: state.what3words!.copyFormat));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied ${state.what3words!.displayFormat}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onUseGps() async {
    if (_isGettingGps) return;

    setState(() {
      _isGettingGps = true;
    });

    try {
      // Use LocationResolver for GPS - single source of truth for location logic
      // allowDefault: false ensures we get actual GPS, not a fallback default
      final result =
          await widget.locationResolver.getLatLon(allowDefault: false);

      result.fold(
        (error) {
          // Convert LocationError to user-friendly SnackBar message
          if (mounted) {
            final message = switch (error) {
              app.LocationError.permissionDenied =>
                'Location permission denied. Enable in settings.',
              app.LocationError.gpsUnavailable =>
                'Location services unavailable. Please enable GPS.',
              app.LocationError.timeout => 'GPS timeout. Please try again.',
              app.LocationError.invalidInput =>
                'Invalid location data received.',
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        (latLng) async {
          // Animate map to GPS location
          final gpsLocation = LatLng(latLng.latitude, latLng.longitude);
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(gpsLocation, 14.0),
          );

          // Update controller with new location
          _controller.setLocationFromCamera(latLng);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not get GPS location: ${e.toString().split(':').last.trim()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingGps = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onCancel,
          tooltip: 'Cancel',
        ),
        actions: [
          // Confirm button - prominent filled button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: FilledButton.icon(
              key: const Key('confirm_button'),
              onPressed: _canConfirm(state) ? _onConfirm : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main map
          GoogleMap(
            key: const ValueKey('location_picker_map'),
            initialCameraPosition: _initialCameraPosition,
            mapType: _controller.mapType,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraIdle: _onCameraIdle,
            // Map UI settings
            myLocationEnabled: false, // We handle location via crosshair
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false, // We provide custom zoom controls
            mapToolbarEnabled: false,
            compassEnabled: true,
            // Enable all gesture controls for interactive panning/zooming
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),

          // Crosshair overlay (fixed at center)
          const CrosshairOverlay(),

          // Map controls column (top right corner)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Map type selector (Google-style popup menu)
                _buildMapTypeSelector(),
                const SizedBox(height: 16),
                // Zoom controls
                _buildZoomControls(),
                const SizedBox(height: 16),
                // GPS recenter button
                _buildGpsButton(),
              ],
            ),
          ),

          // Search bar at top
          Positioned(
            top: 8,
            left: 16,
            right: 80, // Leave space for map controls
            child: _buildSearchBar(),
          ),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInfoPanel(state),
          ),

          // Emergency banner for fireReport mode
          if (widget.mode == LocationPickerMode.fireReport)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildEmergencyBanner(),
            ),
        ],
      ),
    );
  }

  bool _canConfirm(LocationPickerState state) {
    // Can confirm if we have coordinates (even if w3w is loading)
    return state is LocationPickerSelected ||
        (state is LocationPickerInitial && state.initialLocation != null);
  }

  /// Zoom in on the map
  Future<void> _zoomIn() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  /// Zoom out on the map
  Future<void> _zoomOut() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  /// Build zoom control buttons (+ / -)
  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in button
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const Key('zoom_in_button'),
              icon: const Icon(Icons.add),
              onPressed: _zoomIn,
              tooltip: 'Zoom in',
              padding: EdgeInsets.zero,
            ),
          ),
          Container(
            height: 1,
            width: 32,
            color: Colors.grey.shade300,
          ),
          // Zoom out button
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const Key('zoom_out_button'),
              icon: const Icon(Icons.remove),
              onPressed: _zoomOut,
              tooltip: 'Zoom out',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// Build GPS recenter button
  Widget _buildGpsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: _isGettingGps
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                key: const Key('gps_center_button'),
                icon: const Icon(Icons.my_location),
                onPressed: _onUseGps,
                tooltip: 'Center on my location',
                padding: EdgeInsets.zero,
              ),
      ),
    );
  }

  /// Build Google-style map type selector popup
  Widget _buildMapTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<MapType>(
        key: const Key('map_type_selector'),
        icon: const Icon(Icons.layers),
        tooltip: 'Map type',
        onSelected: (MapType type) {
          _controller.setMapType(type);
        },
        itemBuilder: (context) => [
          _buildMapTypeMenuItem(
            MapType.terrain,
            'Terrain',
            Icons.terrain,
          ),
          _buildMapTypeMenuItem(
            MapType.satellite,
            'Satellite',
            Icons.satellite_alt,
          ),
          _buildMapTypeMenuItem(
            MapType.hybrid,
            'Hybrid',
            Icons.layers,
          ),
          _buildMapTypeMenuItem(
            MapType.normal,
            'Normal',
            Icons.map,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<MapType> _buildMapTypeMenuItem(
    MapType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _controller.mapType == type;
    return PopupMenuItem<MapType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  /// Build search bar for place/what3words lookup
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search places or ///what3words',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _controller.onSearchTextChanged('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (text) {
          _controller.onSearchTextChanged(text);
          setState(() {}); // Update suffix icon
        },
        onSubmitted: (text) {
          // Trigger search on submit
          _controller.onSearchTextChanged(text);
        },
      ),
    );
  }

  Widget _buildInfoPanel(LocationPickerState state) {
    // Get current coordinates
    app.LatLng? coords;
    What3wordsAddress? w3w;
    bool isLoading = false;
    String? error;

    switch (state) {
      case LocationPickerInitial(
          :final initialLocation,
          :final initialWhat3words
        ):
        coords = initialLocation;
        w3w = initialWhat3words;
      case LocationPickerSelected(
          :final coordinates,
          :final what3words,
          :final isResolvingWhat3words
        ):
        coords = coordinates;
        w3w = what3words;
        isLoading = isResolvingWhat3words;
      case LocationPickerError(:final message, :final isWhat3wordsError):
        if (isWhat3wordsError) {
          error = message;
        }
        coords = _controller.currentCoordinates;
      default:
        coords = _controller.currentCoordinates;
    }

    // Default to Scotland centroid if no coordinates
    coords ??= const app.LatLng(57.2, -3.8);

    return LocationInfoPanel(
      coordinates: coords,
      what3words: w3w,
      isLoadingWhat3words: isLoading,
      what3wordsError: error,
      showGpsButton: true,
      onCopyWhat3words: w3w != null ? _onCopyWhat3words : null,
      onUseGps: _onUseGps,
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade700,
      child: const SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'For emergencies, always call 999 first',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
