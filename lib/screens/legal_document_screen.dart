import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';

// TODO: Add flutter_markdown dependency for proper markdown rendering
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

  /// Build content widgets with section headers, emergency callouts, and body text.
  List<Widget> _buildContentWithCallouts(BuildContext context, String content) {
    final theme = Theme.of(context);

    // Patterns that indicate emergency/safety critical content
    final emergencyPatterns = [
      'not an emergency',
      'not rely on this App',
      'Call 999',
      'life-safety system',
      'emergency-warning tool',
    ];

    final lines = content.split('\n');
    final widgets = <Widget>[];
    final currentParagraph = StringBuffer();

    void flushParagraph() {
      if (currentParagraph.isNotEmpty) {
        final text = currentParagraph.toString().trim();
        if (text.isNotEmpty) {
          // Remove markdown bold markers
          final cleanText = text.replaceAll('**', '');
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText(
                cleanText,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
          );
        }
        currentParagraph.clear();
      }
    }

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Skip horizontal rules
      if (trimmedLine == '---') {
        flushParagraph();
        continue;
      }

      // Check for markdown headers (## or #)
      if (trimmedLine.startsWith('#')) {
        flushParagraph();

        // Extract header text and level
        final headerMatch = RegExp(r'^(#+)\s*(.+)$').firstMatch(trimmedLine);
        if (headerMatch != null) {
          final level = headerMatch.group(1)!.length;
          final headerText = headerMatch.group(2)!.replaceAll('**', '').trim();

          // Skip the main title (# Header) as it's in the AppBar
          if (level == 1) continue;

          widgets.add(
            _SectionHeader(
              text: headerText,
              isSubsection: level > 2,
            ),
          );
        }
        continue;
      }

      // Check if this line contains emergency content
      final isEmergencyContent = emergencyPatterns.any(
        (pattern) => trimmedLine.toLowerCase().contains(pattern.toLowerCase()),
      );

      if (isEmergencyContent && trimmedLine.isNotEmpty) {
        flushParagraph();
        // Remove markdown bold markers from emergency text
        final cleanText = trimmedLine.replaceAll('**', '');
        widgets.add(_EmergencyCallout(text: cleanText));
      } else if (trimmedLine.isEmpty) {
        // Empty line = paragraph break
        flushParagraph();
      } else {
        // Accumulate paragraph content
        if (currentParagraph.isNotEmpty) {
          currentParagraph.write(' ');
        }
        currentParagraph.write(trimmedLine);
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
}

/// Section header with visual hierarchy for legal documents.
///
/// Displays section titles with proper typography and a subtle divider
/// to create clear document structure.
class _SectionHeader extends StatelessWidget {
  final String text;
  final bool isSubsection;

  const _SectionHeader({
    required this.text,
    this.isSubsection = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: isSubsection ? 16 : 24,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: isSubsection
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )
                : theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
          const SizedBox(height: 8),
          Divider(
            thickness: isSubsection ? 0.5 : 0.8,
            color: theme.colorScheme.onSurface.withValues(
              alpha: isSubsection ? 0.06 : 0.1,
            ),
          ),
        ],
      ),
    );
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
