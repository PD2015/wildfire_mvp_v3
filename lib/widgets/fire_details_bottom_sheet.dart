import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/utils/distance_calculator.dart';

/// Display type for fire data in the bottom sheet
enum FireDataDisplayType {
  /// Standard fire incident (legacy)
  incident,

  /// Live hotspot (VIIRS satellite detection)
  hotspot,

  /// Verified burnt area (MODIS confirmed)
  burntArea,
}

/// V2 Bottom sheet for fire details with improved UX
///
/// Key improvements over V1:
/// - Dynamic header based on data type (not generic "Fire Incident Details")
/// - Summary card with key info at top
/// - Plain language descriptions (no jargon)
/// - Progressive disclosure (land cover hidden by default)
/// - "Learn More" link to help docs
/// - Improved time format: "X ago (HH:MM UK time)"
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => FireDetailsBottomSheet.fromHotspot(
///     hotspot: hotspot,
///     userLocation: userLocation,
///   ),
/// );
/// ```
class FireDetailsBottomSheet extends StatelessWidget {
  /// The fire incident being displayed
  final FireIncident? incident;

  /// User's current GPS location (for distance calculation)
  final LatLng? userLocation;

  /// Callback when close button is pressed
  final VoidCallback? onClose;

  /// Callback when retry button is pressed (error state only)
  final VoidCallback? onRetry;

  /// What type of fire data we're displaying
  final FireDataDisplayType displayType;

  /// Original Hotspot data (when created via fromHotspot factory)
  final Hotspot? hotspot;

  /// Original BurntArea data (when created via fromBurntArea factory)
  final BurntArea? burntArea;

  /// Whether the sheet is in loading state
  final bool isLoading;

  /// Error message to display (null if no error)
  final String? errorMessage;

  /// Optional callback for "Learn More" action
  /// If null, defaults to navigating to appropriate help doc
  final VoidCallback? onLearnMore;

  /// Whether the user's location was set manually (vs GPS)
  /// Used to display "Your Location (Manual)" vs "Your Location (GPS)"
  final bool isManualLocation;

  const FireDetailsBottomSheet({
    super.key,
    this.incident,
    this.userLocation,
    this.onClose,
    this.onRetry,
    this.displayType = FireDataDisplayType.incident,
    this.hotspot,
    this.burntArea,
    this.isLoading = false,
    this.errorMessage,
    this.onLearnMore,
    this.isManualLocation = false,
  });

  /// Factory constructor for displaying a Hotspot
  factory FireDetailsBottomSheet.fromHotspot({
    Key? key,
    required Hotspot hotspot,
    LatLng? userLocation,
    VoidCallback? onClose,
    VoidCallback? onRetry,
    Freshness freshness = Freshness.live,
    VoidCallback? onLearnMore,
    bool isManualLocation = false,
  }) {
    // Convert Hotspot to FireIncident for rendering
    final incident = FireIncident(
      id: hotspot.id,
      location: hotspot.location,
      source: DataSource.effis,
      freshness: freshness,
      timestamp: hotspot.detectedAt,
      intensity: hotspot.intensity,
      detectedAt: hotspot.detectedAt,
      sensorSource: 'VIIRS',
      confidence: hotspot.confidence,
      frp: hotspot.frp,
    );

    return FireDetailsBottomSheet(
      key: key,
      incident: incident,
      userLocation: userLocation,
      onClose: onClose,
      onRetry: onRetry,
      displayType: FireDataDisplayType.hotspot,
      hotspot: hotspot,
      onLearnMore: onLearnMore,
      isManualLocation: isManualLocation,
    );
  }

  /// Factory constructor for displaying a BurntArea
  factory FireDetailsBottomSheet.fromBurntArea({
    Key? key,
    required BurntArea burntArea,
    LatLng? userLocation,
    VoidCallback? onClose,
    VoidCallback? onRetry,
    Freshness freshness = Freshness.live,
    VoidCallback? onLearnMore,
    bool isManualLocation = false,
  }) {
    // Convert BurntArea to FireIncident for rendering
    final incident = FireIncident(
      id: burntArea.id,
      location: burntArea.centroid,
      source: DataSource.effis,
      freshness: freshness,
      timestamp: burntArea.fireDate,
      intensity: burntArea.intensity,
      detectedAt: burntArea.fireDate,
      sensorSource: 'MODIS',
      areaHectares: burntArea.areaHectares,
      boundaryPoints: burntArea.boundaryPoints,
    );

    return FireDetailsBottomSheet(
      key: key,
      incident: incident,
      userLocation: userLocation,
      onClose: onClose,
      onRetry: onRetry,
      displayType: FireDataDisplayType.burntArea,
      burntArea: burntArea,
      onLearnMore: onLearnMore,
      isManualLocation: isManualLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
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

              // Dynamic header based on type
              _buildHeader(context),

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
          label: 'Loading fire details',
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading details...',
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
          'Failed to Load Details',
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
    final inc = incident!;

    // Route to the appropriate layout based on display type
    return switch (displayType) {
      FireDataDisplayType.burntArea => _buildBurntAreaLayout(context, inc),
      FireDataDisplayType.hotspot => _buildHotspotLayout(context, inc),
      FireDataDisplayType.incident => _buildIncidentLayout(context, inc),
    };
  }

  /// Build layout for Burnt Area bottom sheet
  Widget _buildBurntAreaLayout(BuildContext context, FireIncident inc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Supporting text with inline learn more link
        _buildSupportingTextWithLearnMore(context),

        const SizedBox(height: 16),

        // Key Metrics section
        _buildKeyMetricsSection(
          context: context,
          rows: [
            if (inc.areaHectares != null)
              _KeyMetricRow(
                icon: Icons.square_foot,
                label: 'Est. burned area',
                value: '${inc.areaHectares!.toStringAsFixed(1)} ha',
              ),
            _KeyMetricRow(
              icon: Icons.access_time,
              label: 'When detected',
              value:
                  _formatRelativeTimeWithClock(inc.detectedAt ?? inc.timestamp),
            ),
            _KeyMetricRow(
              icon: Icons.location_on,
              label: 'Fire coordinates',
              value:
                  '${inc.location.latitude.toStringAsFixed(4)}, ${inc.location.longitude.toStringAsFixed(4)}',
            ),
            if (userLocation != null)
              _KeyMetricRow(
                icon: Icons.social_distance,
                label: 'Distance from your location',
                value:
                    _formatDistanceWithDirection(userLocation!, inc.location),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // More Details expandable section
        _ExpandableDetailsSection(
          title: 'More details',
          children: [
            if (userLocation != null)
              _buildDetailRow(
                context: context,
                icon: isManualLocation ? Icons.edit_location : Icons.gps_fixed,
                label: isManualLocation
                    ? 'Your Location (Manual)'
                    : 'Your Location (GPS)',
                value:
                    '${userLocation!.latitude.toStringAsFixed(2)}, ${userLocation!.longitude.toStringAsFixed(2)}',
              ),
            _buildDetailRow(
              context: context,
              icon: Icons.source,
              label: 'Data source',
              value: _formatDataSourceForType(inc.source, inc.freshness),
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.satellite_alt,
              label: 'Sensor',
              value: _formatSensorName(inc.sensorSource),
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.fingerprint,
              label: 'Fire ID',
              value: inc.id,
            ),
            // Land cover breakdown
            if (burntArea?.landCoverBreakdown != null &&
                burntArea!.landCoverBreakdown!.isNotEmpty)
              _buildLandCoverSection(context),
            // Polygon simplification notice
            if (burntArea != null && burntArea!.isSimplified)
              _buildSimplificationNotice(context),
          ],
        ),

        const SizedBox(height: 16),

        // Safety note at bottom
        _buildSafetyText(context),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Build layout for Hotspot bottom sheet
  Widget _buildHotspotLayout(BuildContext context, FireIncident inc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Supporting text with inline learn more link
        _buildSupportingTextWithLearnMore(context),

        const SizedBox(height: 16),

        // Key Metrics section
        _buildKeyMetricsSection(
          context: context,
          rows: [
            _KeyMetricRow(
              icon: Icons.location_on,
              label: 'Fire coordinates',
              value:
                  '${inc.location.latitude.toStringAsFixed(4)}, ${inc.location.longitude.toStringAsFixed(4)}',
            ),
            _KeyMetricRow(
              icon: Icons.access_time,
              label: 'When detected',
              value:
                  _formatRelativeTimeWithClock(inc.detectedAt ?? inc.timestamp),
            ),
            if (userLocation != null)
              _KeyMetricRow(
                icon: Icons.social_distance,
                label: 'Distance from your location',
                value:
                    _formatDistanceWithDirection(userLocation!, inc.location),
              ),
            if (inc.confidence != null)
              _KeyMetricRow(
                icon: Icons.verified_outlined,
                label: 'Satellite confidence',
                value: '${inc.confidence!.toStringAsFixed(0)}%',
              ),
            if (inc.intensity.isNotEmpty)
              _KeyMetricRow(
                icon: Icons.whatshot,
                label: 'Fire intensity',
                value: _formatIntensity(inc.intensity),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // More Details expandable section
        _ExpandableDetailsSection(
          title: 'More details',
          children: [
            if (userLocation != null)
              _buildDetailRow(
                context: context,
                icon: isManualLocation ? Icons.edit_location : Icons.gps_fixed,
                label: isManualLocation
                    ? 'Your Location (Manual)'
                    : 'Your Location (GPS)',
                value:
                    '${userLocation!.latitude.toStringAsFixed(2)}, ${userLocation!.longitude.toStringAsFixed(2)}',
              ),
            _buildDetailRow(
              context: context,
              icon: Icons.source,
              label: 'Data source',
              value: _formatDataSourceForType(inc.source, inc.freshness),
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.satellite_alt,
              label: 'Sensor',
              value: _formatSensorName(inc.sensorSource),
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.fingerprint,
              label: 'Ref ID',
              value: inc.id,
            ),
            if (inc.frp != null)
              _buildDetailRow(
                context: context,
                icon: Icons.bolt,
                label: 'Fire Radiative Power',
                value: '${inc.frp!.toStringAsFixed(1)} MW',
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Safety note at bottom
        _buildSafetyText(context),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Build layout for legacy Incident type (simplified, future use)
  Widget _buildIncidentLayout(BuildContext context, FireIncident inc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key Metrics section
        _buildKeyMetricsSection(
          context: context,
          rows: [
            _KeyMetricRow(
              icon: Icons.location_on,
              label: 'Fire coordinates',
              value:
                  '${inc.location.latitude.toStringAsFixed(4)}, ${inc.location.longitude.toStringAsFixed(4)}',
            ),
            _KeyMetricRow(
              icon: Icons.access_time,
              label: 'When detected',
              value:
                  _formatRelativeTimeWithClock(inc.detectedAt ?? inc.timestamp),
            ),
            if (userLocation != null)
              _KeyMetricRow(
                icon: Icons.social_distance,
                label: 'Distance from your location',
                value:
                    _formatDistanceWithDirection(userLocation!, inc.location),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // More Details expandable section
        _ExpandableDetailsSection(
          title: 'More details',
          children: [
            if (userLocation != null)
              _buildDetailRow(
                context: context,
                icon: isManualLocation ? Icons.edit_location : Icons.gps_fixed,
                label: isManualLocation
                    ? 'Your Location (Manual)'
                    : 'Your Location (GPS)',
                value:
                    '${userLocation!.latitude.toStringAsFixed(2)}, ${userLocation!.longitude.toStringAsFixed(2)}',
              ),
            _buildDetailRow(
              context: context,
              icon: Icons.source,
              label: 'Data source',
              value: _formatDataSourceForType(inc.source, inc.freshness),
            ),
            if (inc.id.isNotEmpty)
              _buildDetailRow(
                context: context,
                icon: Icons.fingerprint,
                label: 'Ref ID',
                value: inc.id,
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Safety note at bottom
        _buildSafetyText(context),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Build Key Metrics section with title and card
  Widget _buildKeyMetricsSection({
    required BuildContext context,
    required List<_KeyMetricRow> rows,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Filter out null rows
    final validRows = rows.where((r) => true).toList();
    if (validRows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.bar_chart,
                size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Key metrics',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Card container
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < validRows.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildDetailRow(
                  context: context,
                  icon: validRows[i].icon,
                  label: validRows[i].label,
                  value: validRows[i].value,
                  semanticLabel: '${validRows[i].label}: ${validRows[i].value}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build dynamic header based on display type
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor =
        theme.textTheme.titleLarge?.color ?? colorScheme.onSurface;

    // Dynamic title and icon based on type
    // C2: Use less assertive title for hotspots ("Satellite Hotspot" not "Active Hotspot")
    final (icon, title) = switch (displayType) {
      FireDataDisplayType.hotspot => (
          Icons.local_fire_department,
          'Satellite Hotspot',
        ),
      FireDataDisplayType.burntArea => (
          Icons.layers,
          'Burnt Area',
        ),
      FireDataDisplayType.incident => (
          Icons.local_fire_department,
          'Fire Details',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title section (left)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: textColor,
                semanticLabel: '',
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          // Demo chip centered in remaining space
          if (incident != null)
            Expanded(
              child: Center(
                child: _buildHeaderChip(context),
              ),
            )
          else
            const Spacer(),
          // Close button (right)
          Semantics(
            button: true,
            label: 'Close details',
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

  /// Build compact chip for header (just source label)
  Widget _buildHeaderChip(BuildContext context) {
    if (incident == null) return const SizedBox.shrink();
    return MapSourceChip(
      source: incident!.freshness,
      lastUpdated: incident!.timestamp,
    );
  }

  /// Build supporting text with inline "Learn more" link at the end
  Widget _buildSupportingTextWithLearnMore(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (description, helpDocId) = switch (displayType) {
      FireDataDisplayType.hotspot => (
          'A satellite detected unusual heat here. It could be a wildfire, controlled burning, or another heat source.',
          'hotspots',
        ),
      FireDataDisplayType.burntArea => (
          'This outline indicates land that appears to have burned earlier in the season.',
          'burnt-area',
        ),
      FireDataDisplayType.incident => (null, 'hotspots'),
    };

    if (description == null) return const SizedBox.shrink();

    return Semantics(
      label: '$description Learn more.',
      child: Text.rich(
        TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          children: [
            TextSpan(text: '$description '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () {
                  if (onLearnMore != null) {
                    onLearnMore!();
                  } else {
                    context.push('/help/doc/$helpDocId');
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Learn more',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  /// Build land cover breakdown section
  Widget _buildLandCoverSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final breakdown = burntArea!.landCoverBreakdown!;

    // Sort by percentage descending
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terrain,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Land types affected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in sortedEntries)
            _buildLandCoverBar(
              context: context,
              label: _formatLandCoverLabel(entry.key),
              percentage: entry.value,
              color: _getLandCoverColor(entry.key, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildLandCoverBar({
    required BuildContext context,
    required String label,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '$label: ${(percentage * 100).toStringAsFixed(0)} percent',
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplificationNotice(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final originalCount = burntArea?.originalPointCount ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: 'Boundary simplified from $originalCount points for display',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.compress,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Boundary simplified (from $originalCount points)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build safety warning text
  Widget _buildSafetyText(BuildContext context) {
    return Text(
      'Satellite data may lag behind real conditions. '
      'If you are in immediate danger, call 999.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Formatting helpers
  // ─────────────────────────────────────────────────────────────

  /// Format distance with direction for summary card (C1: direction is useful)
  String _formatDistanceWithDirection(LatLng from, LatLng to) {
    // Use the existing calculator which returns "X.X km E" format
    return DistanceCalculator.formatDistanceAndDirection(from, to);
  }

  /// Format time as "X ago (HH:MM UK time)"
  String _formatRelativeTimeWithClock(DateTime detectedAt) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(detectedAt.toUtc());

    // Format relative part
    String relativePart;
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      relativePart = '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      relativePart = '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      relativePart = '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      // For very old data, just show date
      return _formatDateOnly(detectedAt);
    }

    // Format UK time (local time for UK users)
    final ukTime = detectedAt.toLocal();
    final hour = ukTime.hour.toString().padLeft(2, '0');
    final minute = ukTime.minute.toString().padLeft(2, '0');
    final clockPart = '$hour:$minute UK time';

    return '$relativePart ($clockPart)';
  }

  String _formatDateOnly(DateTime dateTime) {
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
      'Dec',
    ];
    final d = dateTime.toLocal();
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatIntensity(String intensity) {
    return intensity.substring(0, 1).toUpperCase() + intensity.substring(1);
  }

  String _formatSensorName(String? sensor) {
    if (sensor == null) return 'Unknown';
    return switch (sensor.toUpperCase()) {
      'VIIRS' => 'VIIRS satellite',
      'MODIS' => 'MODIS satellite',
      _ => sensor,
    };
  }

  String _formatDataSourceForType(DataSource source, Freshness freshness) {
    if (displayType == FireDataDisplayType.hotspot) {
      if (source == DataSource.mock || freshness == Freshness.mock) {
        return 'Demo Data';
      }
      return 'GWIS (EC JRC)';
    }

    if (displayType == FireDataDisplayType.burntArea) {
      if (source == DataSource.mock || freshness == Freshness.mock) {
        return 'Demo Data';
      }
      return 'EFFIS (EC JRC)';
    }

    switch (source) {
      case DataSource.effis:
        return 'EFFIS';
      case DataSource.sepa:
        return 'SEPA';
      case DataSource.cache:
        return 'Cached';
      case DataSource.mock:
        return 'Demo Data';
    }
  }

  String _formatLandCoverLabel(String key) {
    return switch (key.toLowerCase()) {
      'forest' => 'Forest',
      'shrubland' => 'Shrubland',
      'grassland' => 'Grassland',
      'agriculture' => 'Farmland',
      'wetland' => 'Wetland',
      'urban' => 'Urban',
      'other' => 'Other',
      _ => key.substring(0, 1).toUpperCase() + key.substring(1),
    };
  }

  Color _getLandCoverColor(String key, ColorScheme colorScheme) {
    return switch (key.toLowerCase()) {
      'forest' => Colors.green.shade700,
      'shrubland' => Colors.orange.shade600,
      'grassland' => Colors.lightGreen.shade500,
      'agriculture' => Colors.amber.shade600,
      'wetland' => Colors.blue.shade400,
      'urban' => Colors.grey.shade600,
      _ => colorScheme.primary,
    };
  }
}

/// Key metric row data class for _buildKeyMetricsSection
class _KeyMetricRow {
  final IconData icon;
  final String label;
  final String value;

  const _KeyMetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Expandable "More details" section with smooth animation
///
/// Inspired by RiskBanner's ExpandableLocationPanel:
/// - Chevron icon that rotates on expand/collapse
/// - Subtle background on header row
/// - Smooth height animation using AnimatedSize
/// - Content not built when collapsed (performance)
class _ExpandableDetailsSection extends StatefulWidget {
  const _ExpandableDetailsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  State<_ExpandableDetailsSection> createState() =>
      _ExpandableDetailsSectionState();
}

class _ExpandableDetailsSectionState extends State<_ExpandableDetailsSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with tap target
        Semantics(
          button: true,
          expanded: _isExpanded,
          label:
              '${widget.title}. ${_isExpanded ? "Tap to collapse" : "Tap to expand"}',
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                // Subtle background color for header row
                color: isDark
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 12),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 12),
                ),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.expand_more,
                      size: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expandable content with smooth animation
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surfaceContainerLowest,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      left: BorderSide(color: colorScheme.outlineVariant),
                      right: BorderSide(color: colorScheme.outlineVariant),
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < widget.children.length; i++) ...[
                        if (i > 0) const SizedBox(height: 4),
                        widget.children[i],
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
