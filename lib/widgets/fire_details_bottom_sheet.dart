import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/utils/distance_calculator.dart';
import 'package:wildfire_mvp_v3/widgets/chips/data_source_chip.dart';
import 'package:wildfire_mvp_v3/widgets/chips/demo_data_chip.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';

/// Bottom sheet widget displaying comprehensive fire incident details
///
/// Shows detection time, source, confidence, FRP, distance, bearing,
/// and other metadata in a scrollable sheet. Supports loading states,
/// error handling, and retry functionality.
///
/// Example usage:
/// ```dart
/// // Simple usage with incident data
/// FireDetailsBottomSheet(
///   incident: fireIncident,
///   userLocation: currentLocation,
///   onClose: () {},
/// )
///
/// // With loading state
/// FireDetailsBottomSheet(
///   isLoading: true,
///   onClose: () {},
/// )
///
/// // With error state
/// FireDetailsBottomSheet(
///   errorMessage: 'Failed to load fire details',
///   onClose: () {},
///   onRetry: () {},
/// )
/// ```
///
/// Constitutional compliance:
/// - C3 (Accessibility): ≥44dp touch targets, semantic labels, high contrast
/// - C4 (Transparency): Shows data source, freshness, all detection metadata
class FireDetailsBottomSheet extends StatelessWidget {
  /// Fire incident to display (nullable for loading/error states)
  final FireIncident? incident;

  /// User's current location for distance/bearing calculation
  final LatLng? userLocation;

  /// Optional callback when close button is tapped
  final VoidCallback? onClose;

  /// Optional callback when retry button is tapped (error state only)
  final VoidCallback? onRetry;

  /// Whether to show loading state instead of incident data
  final bool isLoading;

  /// Error message to display (shows error state when non-null)
  final String? errorMessage;

  const FireDetailsBottomSheet({
    super.key,
    this.incident,
    this.userLocation,
    this.onClose,
    this.onRetry,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              _buildDragHandle(),

              // Header with title and close button
              _buildHeader(context),

              const Divider(height: 1),

              // Scrollable content based on state
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    // Loading state
    if (isLoading) {
      return _buildLoadingState(context);
    }

    // Error state
    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    // Incident must be provided for loaded state
    if (incident == null) {
      return const SizedBox.shrink();
    }

    // Loaded state with incident data
    return _buildLoadedState(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Semantics(
          label: 'Loading fire incident details',
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading fire details...',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to Load Fire Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage ?? 'An error occurred',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 48), // C3: ≥44dp touch targets
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadedState(BuildContext context) {
    final inc = incident!; // Safe to unwrap, checked in _buildContent

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data source and demo chips
        _buildChips(inc),

        const SizedBox(height: 20),

        // Distance and direction (if user location available)
        if (userLocation != null) ...[
          _buildDistanceCard(inc),
          const SizedBox(height: 16),
        ],

        // Detection details
        _buildSection(
          title: 'Detection Details',
          children: [
            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Detected',
              value: _formatDateTime(inc.detectedAt ?? inc.timestamp),
              semanticLabel:
                  'Detected at ${_formatDateTime(inc.detectedAt ?? inc.timestamp)}',
            ),
            _buildDetailRow(
              icon: Icons.satellite_alt,
              label: 'Sensor',
              value: inc.sensorSource ?? 'UNKNOWN',
              semanticLabel: 'Sensor source: ${inc.sensorSource ?? 'UNKNOWN'}',
            ),
            if (inc.lastUpdate != null)
              _buildDetailRow(
                icon: Icons.update,
                label: 'Last Update',
                value: _formatDateTime(inc.lastUpdate!),
                semanticLabel:
                    'Last updated at ${_formatDateTime(inc.lastUpdate!)}',
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Fire intensity metrics
        _buildSection(
          title: 'Fire Intensity',
          children: [
            if (inc.confidence != null)
              _buildDetailRow(
                icon: Icons.verified,
                label: 'Confidence',
                value: '${inc.confidence!.toStringAsFixed(1)}%',
                semanticLabel:
                    'Detection confidence: ${inc.confidence!.toStringAsFixed(1)} percent',
              ),
            if (inc.frp != null)
              _buildDetailRow(
                icon: Icons.local_fire_department,
                label: 'Fire Radiative Power',
                value: '${inc.frp!.toStringAsFixed(1)} MW',
                semanticLabel:
                    'Fire radiative power: ${inc.frp!.toStringAsFixed(1)} megawatts',
              ),
            _buildDetailRow(
              icon: Icons.trending_up,
              label: 'Intensity Level',
              value: _formatIntensity(inc.intensity),
              semanticLabel:
                  'Intensity level: ${_formatIntensity(inc.intensity)}',
            ),
            if (inc.areaHectares != null)
              _buildDetailRow(
                icon: Icons.map,
                label: 'Estimated Area',
                value: '${inc.areaHectares!.toStringAsFixed(1)} ha',
                semanticLabel:
                    'Estimated area: ${inc.areaHectares!.toStringAsFixed(1)} hectares',
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Location details
        _buildSection(
          title: 'Location',
          children: [
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Coordinates',
              value:
                  '${inc.location.latitude.toStringAsFixed(4)}, ${inc.location.longitude.toStringAsFixed(4)}',
              semanticLabel:
                  'Coordinates: ${inc.location.latitude.toStringAsFixed(4)} latitude, ${inc.location.longitude.toStringAsFixed(4)} longitude',
            ),
          ],
        ),

        if (inc.description != null) ...[
          const SizedBox(height: 16),
          _buildSection(
            title: 'Description',
            children: [
              Text(
                inc.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: RiskPalette.midGray,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: colorScheme.error,
            size: 24,
            semanticLabel: 'Fire incident',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fire Incident Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Close fire details',
            child: IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              onPressed: () {
                if (onClose != null) {
                  onClose!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Close',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(FireIncident inc) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        DataSourceChip(sourceType: _mapToDataSourceType(inc.source)),
        if (inc.source == DataSource.mock || inc.freshness == Freshness.mock)
          const DemoDataChip(),
      ],
    );
  }

  DataSourceType _mapToDataSourceType(DataSource source) {
    switch (source) {
      case DataSource.effis:
        return DataSourceType.live;
      case DataSource.sepa:
        return DataSourceType.live;
      case DataSource.cache:
        return DataSourceType.cached;
      case DataSource.mock:
        return DataSourceType.mock;
    }
  }

  Widget _buildDistanceCard(FireIncident inc) {
    if (userLocation == null) return const SizedBox.shrink();

    final distanceAndDirection = DistanceCalculator.formatDistanceAndDirection(
      userLocation!,
      inc.location,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A00B3FF), // RiskPalette.veryLow with 10% opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RiskPalette.veryLow, width: 2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.navigation,
            size: 32,
            color: RiskPalette.veryLow,
            semanticLabel: 'Distance and direction',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distance from your location',
                  style: TextStyle(
                    fontSize: 12,
                    color: RiskPalette.midGray,
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  label: 'Fire is $distanceAndDirection from your location',
                  child: Text(
                    distanceAndDirection,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: RiskPalette.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RiskPalette.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? semanticLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: RiskPalette.midGray,
            semanticLabel: '',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RiskPalette.midGray,
                  ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  label: semanticLabel,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RiskPalette.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final months = [
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
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month $day, $year • $hour:$minute UTC';
  }

  String _formatIntensity(String intensity) {
    return intensity.substring(0, 1).toUpperCase() + intensity.substring(1);
  }
}
