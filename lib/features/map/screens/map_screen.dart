import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/risk_check_button.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';

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
  late MapController _controller;

  @override
  void initState() {
    super.initState();
    // Controller must be provided
    if (widget.controller == null) {
      throw ArgumentError('MapController must be provided to MapScreen');
    }
    _controller = widget.controller!;
    _controller.addListener(_onControllerUpdate);
    // Initialize map data on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initialize();
    });
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMarkers(MapSuccess state) {
    _markers = state.incidents.map((incident) {
      debugPrint(
          '🎯 Creating marker: id=${incident.id}, intensity="${incident.intensity}", desc=${incident.description}');

      // Ensure title is never null
      final title = incident.description?.isNotEmpty == true
          ? incident.description!
          : 'Fire Incident #${incident.id}';

      return Marker(
        markerId: MarkerId(incident.id),
        position: LatLng(
          incident.location.latitude,
          incident.location.longitude,
        ),
        icon: _getMarkerIcon(incident.intensity),
        infoWindow: InfoWindow(
          title: title,
          snippet:
              '${incident.intensity.toUpperCase()} - ${incident.areaHectares?.toStringAsFixed(1) ?? "?"} ha',
          // Remove anchor to prevent screen shift - let Google Maps handle it
        ),
        onTap: () {
          debugPrint('🎯 Marker tapped: $title (${incident.intensity})');
        },
      );
    }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(String intensity) {
    // Use color-coded markers based on intensity
    // Hue values: 0=Red, 30=Orange, 45=Gold, 60=Yellow, 120=Green, 240=Blue, 300=Magenta
    debugPrint('🎨 Getting marker icon for intensity: "$intensity"');
    switch (intensity) {
      case 'high':
        debugPrint('🎨 Using RED marker (high) - hue 0');
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed); // 0.0 - bright red
      case 'moderate':
        debugPrint('🎨 Using ORANGE marker (moderate) - hue 30');
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange); // 30.0 - orange
      case 'low':
        debugPrint('🎨 Using CYAN marker (low) - hue 180');
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueCyan); // 180.0 - bright cyan/turquoise
      default:
        debugPrint('🎨 Using VIOLET marker (unknown intensity) - hue 270');
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet); // 270.0 - violet for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    // Platform detection: google_maps_flutter v2.5.0 doesn't support macOS
    final bool isMapSupported =
        kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

    if (!isMapSupported) {
      return _buildUnsupportedPlatformView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Map'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      body: switch (state) {
        MapLoading() => Center(
            child: Semantics(
              label: 'Loading map data',
              child: const CircularProgressIndicator(),
            ),
          ),
        MapSuccess() => _buildMapView(state),
        MapError() => _buildErrorView(state),
      },
      floatingActionButton: RiskCheckButton(controller: _controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildUnsupportedPlatformView() {
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Map'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 64.0,
                color: Colors.grey,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Map Not Available',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Google Maps is not supported on macOS.\nPlease use Android, iOS, or Web to view the fire map.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              // Still show fire data summary
              if (state is MapSuccess) ...[
                Card(
                  margin: const EdgeInsets.all(16),
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
                          ...state.incidents.take(5).map((incident) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: incident.intensity == 'high'
                                          ? Colors.red
                                          : incident.intensity == 'moderate'
                                              ? Colors.orange
                                              : Colors.cyan,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        incident.description ?? 'Fire Incident',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
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
                'Tip: Run on Android/iOS to see interactive map',
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
    // Update markers when data changes
    _updateMarkers(state);

    return Stack(
      children: [
        Semantics(
          label: 'Map showing ${state.incidents.length} fire incidents',
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                state.centerLocation.latitude,
                state.centerLocation.longitude,
              ),
              zoom: 8.0,
            ),
            markers: _markers,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true, // Enable pinch-to-zoom
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            mapToolbarEnabled: false,
            // Add padding to prevent FAB from overlapping GPS button
            padding: const EdgeInsets.only(
              bottom: 80.0, // Room for FAB
              right: 16.0,
            ),
          ),
        ),
        // Source chip positioned at top
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: MapSourceChip(
            source: state.freshness,
            lastUpdated: state.lastUpdated,
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
                      color: Colors.green[700],
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
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
            const Icon(
              Icons.error_outline,
              size: 64.0,
              color: Colors.red,
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
