import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/utils/distance_calculator.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';

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
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            //color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              _buildDragHandle(context),

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

        // Location section
        _InfoSection(
          title: 'Location',
          icon: Icons.place_outlined,
          children: [
            // User's GPS location status
            _buildDetailRow(
              context: context,
              icon: userLocation != null ? Icons.gps_fixed : Icons.gps_off,
              label: 'Your location',
              value: userLocation != null
                  ? '${userLocation!.latitude.toStringAsFixed(2)}, ${userLocation!.longitude.toStringAsFixed(2)} (GPS)'
                  : 'Unknown (GPS unavailable)',
              semanticLabel: userLocation != null
                  ? 'Your GPS location: ${userLocation!.latitude.toStringAsFixed(2)} latitude, ${userLocation!.longitude.toStringAsFixed(2)} longitude'
                  : 'Your GPS location is unavailable',
            ),
            // Distance and direction (only if GPS available)
            _buildDetailRow(
              context: context,
              icon: Icons.social_distance,
              label: 'Distance & direction',
              value: userLocation != null
                  ? '${DistanceCalculator.formatDistanceAndDirection(userLocation!, inc.location)} from your location'
                  : 'Unable to calculate (GPS required)',
              semanticLabel: userLocation != null
                  ? 'Fire is ${DistanceCalculator.formatDistanceAndDirection(userLocation!, inc.location)} from your GPS location'
                  : 'Distance unavailable because GPS location is unknown',
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.location_on,
              label: 'Fire coordinates',
              value:
                  '${inc.location.latitude.toStringAsFixed(4)}, ${inc.location.longitude.toStringAsFixed(4)}',
              semanticLabel:
                  'Fire coordinates: ${inc.location.latitude.toStringAsFixed(4)} latitude, ${inc.location.longitude.toStringAsFixed(4)} longitude',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Fire characteristics section
        _InfoSection(
          title: 'Fire characteristics',
          icon: Icons.local_fire_department_outlined,
          children: [
            // Fire ID first
            _buildDetailRow(
              context: context,
              icon: Icons.fingerprint,
              label: 'Fire ID',
              value: inc.id,
              semanticLabel: 'Fire ID: ${inc.id}',
            ),
            if (inc.areaHectares != null)
              _buildDetailRow(
                context: context,
                icon: Icons.square_foot,
                label: 'Estimated burned area',
                value: '${inc.areaHectares!.toStringAsFixed(1)} hectares (ha)',
                semanticLabel:
                    'Estimated area: ${inc.areaHectares!.toStringAsFixed(1)} hectares',
              ),
            if (inc.frp != null)
              _buildDetailRow(
                context: context,
                icon: Icons.power,
                label: 'Fire power (FRP)',
                value: '${inc.frp!.toStringAsFixed(0)} MW',
                semanticLabel:
                    'Fire radiative power: ${inc.frp!.toStringAsFixed(0)} megawatts',
              ),
            _buildDetailRow(
              context: context,
              icon: Icons.warning_amber,
              label: 'Risk level',
              value: _formatIntensity(inc.intensity),
              semanticLabel: 'Risk level: ${_formatIntensity(inc.intensity)}',
            ),
            if (inc.confidence != null)
              _buildDetailRow(
                context: context,
                icon: Icons.verified,
                label: 'Detection confidence',
                value: '${inc.confidence!.toStringAsFixed(0)}%',
                semanticLabel:
                    'Detection confidence: ${inc.confidence!.toStringAsFixed(0)} percent',
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Detection and Source section
        _InfoSection(
          title: 'Detection & source',
          icon: Icons.access_time,
          children: [
            _buildDetailRow(
              context: context,
              icon: Icons.access_time,
              label: 'Detected',
              value: _formatDateTime(inc.detectedAt ?? inc.timestamp),
              semanticLabel:
                  'Detected at ${_formatDateTime(inc.detectedAt ?? inc.timestamp)}',
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.source,
              label: 'Data source',
              value: _formatDataSource(inc.source),
              semanticLabel: 'Data source: ${_formatDataSource(inc.source)}',
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.satellite_alt,
              label: 'Sensor',
              value: inc.sensorSource ?? 'Unknown sensor',
              semanticLabel:
                  'Sensor source: ${inc.sensorSource ?? 'Unknown sensor'}',
            ),
            if (inc.lastUpdate != null)
              _buildDetailRow(
                context: context,
                icon: Icons.update,
                label: 'Last updated',
                value: _formatDateTime(inc.lastUpdate!),
                semanticLabel:
                    'Last updated at ${_formatDateTime(inc.lastUpdate!)}',
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Safety warning text
        Text(
          'These details come from satellite detections and may lag behind real-world conditions. '
          'If you are in immediate danger, call 999 without delay.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor =
        theme.textTheme.titleLarge?.color ?? colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 24,
                color: textColor,
                semanticLabel: '',
              ),
              const SizedBox(width: 12),
              Text(
                'Fire Incident Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(FireIncident inc) {
    return MapSourceChip(
      source: inc.freshness,
      lastUpdated: inc.timestamp,
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
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
            color: Theme.of(context).colorScheme.onSurface,
            semanticLabel: '',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  label: semanticLabel,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          //fontWeight: FontWeight.w500,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
    final utcTime = dateTime.toUtc();
    final now = DateTime.now().toUtc();

    // Format time as 12-hour with AM/PM
    final hour12 = utcTime.hour > 12
        ? utcTime.hour - 12
        : (utcTime.hour == 0 ? 12 : utcTime.hour);
    final amPm = utcTime.hour >= 12 ? 'PM' : 'AM';
    final timeString =
        '$hour12:${utcTime.minute.toString().padLeft(2, '0')} $amPm';

    // Check if today
    if (now.year == utcTime.year &&
        now.month == utcTime.month &&
        now.day == utcTime.day) {
      return 'Today at $timeString UTC';
    }

    // Check if yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == utcTime.year &&
        yesterday.month == utcTime.month &&
        yesterday.day == utcTime.day) {
      return 'Yesterday at $timeString UTC';
    }

    // Otherwise show date
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
    final monthName = months[utcTime.month - 1];
    return '${utcTime.day} $monthName at $timeString UTC';
  }

  String _formatIntensity(String intensity) {
    return intensity.substring(0, 1).toUpperCase() + intensity.substring(1);
  }

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
}

/// Section wrapper for clearer grouping of fire details
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
