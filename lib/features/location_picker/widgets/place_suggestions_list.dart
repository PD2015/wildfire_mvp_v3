import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/place_search_result.dart';

/// Dropdown list showing place search suggestions (T019)
///
/// Displays results from Geocoding API search with
/// name and formatted address.
class PlaceSuggestionsList extends StatelessWidget {
  final List<PlaceSearchResult> suggestions;
  final ValueChanged<PlaceSearchResult> onSelected;
  final bool isLoading;

  const PlaceSuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading && suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No results found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: colorScheme.outlineVariant,
        ),
        itemBuilder: (context, index) {
          final place = suggestions[index];
          return _PlaceSuggestionTile(
            place: place,
            onTap: () => onSelected(place),
          );
        },
      ),
    );
  }
}

class _PlaceSuggestionTile extends StatelessWidget {
  final PlaceSearchResult place;
  final VoidCallback onTap;

  const _PlaceSuggestionTile({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      key: Key('place_suggestion_${place.placeId}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.formattedAddress.isNotEmpty &&
                      place.formattedAddress != place.name)
                    Text(
                      place.formattedAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
