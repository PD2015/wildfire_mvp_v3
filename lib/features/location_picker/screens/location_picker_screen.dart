import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';
import 'package:wildfire_mvp_v3/features/location_picker/controllers/location_picker_controller.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_state.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/picked_location.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/what3words_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/location_search_bar.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/place_suggestions_list.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/location_preview.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/confirmation_panel.dart';
import 'package:wildfire_mvp_v3/features/location_picker/widgets/static_map_preview.dart';

/// Full-screen location picker screen (T023)
///
/// Features:
/// - Search bar for place search and what3words input
/// - Autocomplete suggestions dropdown
/// - Location preview with what3words and coordinates
/// - Static map preview
/// - Confirmation panel with mode-specific buttons
///
/// Returns [PickedLocation] via Navigator.pop when confirmed.
class LocationPickerScreen extends StatefulWidget {
  final LocationPickerMode mode;
  final LatLng? initialLocation;
  final What3wordsAddress? initialWhat3words;
  final String? initialPlaceName;
  final What3wordsService what3wordsService;
  final GeocodingService geocodingService;

  const LocationPickerScreen({
    super.key,
    required this.mode,
    required this.what3wordsService,
    required this.geocodingService,
    this.initialLocation,
    this.initialWhat3words,
    this.initialPlaceName,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final LocationPickerController _controller;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

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
    _controller.addListener(_onStateChanged);

    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _onSearchChanged(String query) {
    _controller.onSearchTextChanged(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    _controller.onSearchTextChanged('');
    _searchFocusNode.requestFocus();
  }

  void _onConfirm() {
    final result = _controller.confirmSelection();
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  void _copyWhat3words(What3wordsAddress address) {
    Clipboard.setData(ClipboardData(text: address.copyFormat));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${address.displayFormat}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onCancel,
          tooltip: 'Cancel',
        ),
      ),
      body: Column(
        children: [
          // Search bar section
          Padding(
            padding: const EdgeInsets.all(16),
            child: LocationSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onClear: _onClearSearch,
              isLoading: state is LocationPickerSearching && state.isLoading,
            ),
          ),

          // Main content area
          Expanded(
            child: _buildContent(state, theme),
          ),

          // Confirmation panel (only when location selected)
          if (state is LocationPickerSelected)
            ConfirmationPanel(
              mode: widget.mode,
              onConfirm: state.isFullyResolved ? _onConfirm : null,
              onCancel: _onCancel,
              isConfirmEnabled: state.isFullyResolved,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(LocationPickerState state, ThemeData theme) {
    return switch (state) {
      LocationPickerInitial() => _buildInitialContent(state, theme),
      LocationPickerSearching() => _buildSearchingContent(state, theme),
      LocationPickerSelected() => _buildSelectedContent(state, theme),
      LocationPickerError() => _buildErrorContent(state, theme),
    };
  }

  Widget _buildInitialContent(LocationPickerInitial state, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for a location',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter an address, place name, or what3words',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Show initial location if available
          if (state.initialLocation != null) ...[
            Text(
              'Current location:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildMiniPreview(
              state.initialLocation!,
              state.initialWhat3words,
              state.initialPlaceName,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchingContent(
      LocationPickerSearching state, ThemeData theme) {
    return PlaceSuggestionsList(
      suggestions: state.suggestions,
      onSelected: _controller.onPlaceSelected,
      isLoading: state.isLoading,
    );
  }

  Widget _buildSelectedContent(LocationPickerSelected state, ThemeData theme) {
    final geocodingService = widget.geocodingService;
    final mapUrl = geocodingService.buildStaticMapUrl(
      lat: state.coordinates.latitude,
      lon: state.coordinates.longitude,
      zoom: 15,
      width: 400,
      height: 200,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Static map preview
          StaticMapPreview(
            mapUrl: mapUrl,
            height: 200,
          ),
          const SizedBox(height: 16),

          // Location preview with details
          GestureDetector(
            onTap: () {
              if (state.what3words != null) {
                _copyWhat3words(state.what3words!);
              }
            },
            child: LocationPreview(
              coordinates: state.coordinates,
              what3words: state.what3words,
              placeName: state.placeName,
              isResolvingWhat3words: state.isResolvingWhat3words,
              isResolvingPlaceName: state.isResolvingPlaceName,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(LocationPickerError state, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isWhat3wordsError
                  ? Icons.location_off
                  : Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _controller.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPreview(
    LatLng location,
    What3wordsAddress? what3words,
    String? placeName,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (placeName != null)
                  Text(
                    placeName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (what3words != null)
                  Text(
                    what3words.displayFormat,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                Text(
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
