import 'package:flutter/material.dart';

/// Search bar for location/what3words input (T017)
///
/// Features:
/// - what3words icon prefix when detecting /// pattern
/// - Clear button
/// - Loading indicator during search
class LocationSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool isLoading;
  final String hintText;
  final FocusNode? focusNode;

  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.isLoading = false,
    this.hintText = 'Search places or enter ///what3words',
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Detect what3words input pattern
    final isWhat3words = controller.text.startsWith('/') ||
        controller.text.contains('.') && controller.text.split('.').length >= 2;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        key: const Key('location_search_field'),
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: _buildPrefixIcon(isWhat3words, colorScheme),
          suffixIcon: _buildSuffixIcon(colorScheme),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: theme.textTheme.bodyLarge,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildPrefixIcon(bool isWhat3words, ColorScheme colorScheme) {
    if (isWhat3words) {
      // what3words triple-slash icon
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '///',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
    return Icon(Icons.search, color: colorScheme.onSurfaceVariant);
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (controller.text.isNotEmpty && onClear != null) {
      return IconButton(
        key: const Key('clear_search_button'),
        icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
        onPressed: onClear,
        tooltip: 'Clear search',
      );
    }

    return null;
  }
}
