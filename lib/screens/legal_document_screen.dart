import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';

// TODO: Add flutter_markdown dependency for proper markdown rendering
// TODO: Parse markdown headers into styled titleMedium widgets with dividers
// TODO: Add max width constraint (~700px) for tablets/web
// TODO: Style inline version/date as secondary text to reduce visual repetition
// TODO: Add consistent doc-type iconography to AppBar per document type
// TODO: Add collapsible table of contents for longer documents

/// Screen for displaying a full legal document.
///
/// Shows a scrollable view of the document content with the title in the AppBar.
/// Used for Terms of Service, Privacy Policy, Disclaimer, and Data Sources.
class LegalDocumentScreen extends StatelessWidget {
  /// The legal document to display.
  final LegalDocument document;

  const LegalDocumentScreen({
    required this.document,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version and date info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Version ${document.version} • '
                      'Effective ${_formatDate(document.effectiveDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Document content with emergency callouts
              ..._buildContentWithCallouts(context, document.content),

              // Footer with last updated
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Last updated: ${_formatDate(document.effectiveDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Build content widgets, highlighting emergency disclaimers with callout boxes.
  List<Widget> _buildContentWithCallouts(BuildContext context, String content) {
    final theme = Theme.of(context);
    final strippedContent = _stripMarkdownHeaders(content);

    // Patterns that indicate emergency/safety critical content
    final emergencyPatterns = [
      'not an emergency',
      'not rely on this App',
      'Call 999',
      'life-safety system',
      'emergency-warning tool',
    ];

    final lines = strippedContent.split('\n');
    final widgets = <Widget>[];
    final currentParagraph = StringBuffer();

    void flushParagraph() {
      if (currentParagraph.isNotEmpty) {
        final text = currentParagraph.toString().trim();
        if (text.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
          );
        }
        currentParagraph.clear();
      }
    }

    for (final line in lines) {
      // Check if this line contains emergency content
      final isEmergencyContent = emergencyPatterns.any(
        (pattern) => line.toLowerCase().contains(pattern.toLowerCase()),
      );

      if (isEmergencyContent && line.trim().isNotEmpty) {
        // Flush any pending paragraph
        flushParagraph();

        // Add emergency callout
        widgets.add(
          _EmergencyCallout(text: line.trim()),
        );
      } else if (line.trim().isEmpty) {
        // Empty line = paragraph break
        flushParagraph();
      } else {
        // Accumulate paragraph content
        if (currentParagraph.isNotEmpty) {
          currentParagraph.write(' ');
        }
        currentParagraph.write(line.trim());
      }
    }

    // Flush any remaining content
    flushParagraph();

    return widgets;
  }

  /// Format date for display (e.g., "10 December 2025").
  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Strip markdown headers (# symbols) for plain text display.
  /// A more sophisticated implementation could use a Markdown widget.
  String _stripMarkdownHeaders(String content) {
    return content
        .split('\n')
        .map((line) {
          // Remove leading # characters from headers
          if (line.startsWith('#')) {
            return line.replaceFirst(RegExp(r'^#+\s*'), '');
          }
          // Remove ** for bold (keep text)
          return line.replaceAll('**', '');
          // Remove --- horizontal rules
        })
        .where((line) => line.trim() != '---')
        .join('\n')
        .trim();
  }
}

/// Callout box for emergency/safety-critical content.
///
/// Displays text in an amber-toned container with warning icon
/// to make critical safety information impossible to miss.
class _EmergencyCallout extends StatelessWidget {
  final String text;

  const _EmergencyCallout({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Amber/warning tone that's softer than error red
    final backgroundColor = isDark
        ? const Color(0xFF3D2E1F) // Dark amber
        : const Color(0xFFFFF3E0); // Light amber (orange.shade50 equivalent)
    final iconColor = isDark
        ? const Color(0xFFFFB74D) // Amber 300
        : const Color(0xFFE65100); // Deep orange 900

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
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
