import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';

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

              // Document content
              SelectableText(
                _stripMarkdownHeaders(document.content),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        })
        .join('\n')
        .trim();
  }
}
