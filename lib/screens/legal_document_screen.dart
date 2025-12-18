import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';

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

              // Document content using Markdown renderer
              MarkdownBody(
                data: _preprocessContent(document.content),
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href));
                  }
                },
                styleSheet: _buildMarkdownStyleSheet(context),
                builders: {
                  'blockquote': _EmergencyCalloutBuilder(),
                },
              ),

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

  /// Preprocess markdown content to convert emergency sections to blockquotes.
  ///
  /// This allows us to use a custom builder to render them as callouts.
  String _preprocessContent(String content) {
    // Remove the main title (# Header) as it's shown in AppBar
    final lines = content.split('\n');
    final processedLines = <String>[];
    var skipNextEmpty = false;

    // Patterns that indicate emergency/safety critical content
    final emergencyPatterns = [
      'not an emergency',
      'not rely on this app',
      'call 999',
      'life-safety system',
      'emergency-warning tool',
    ];

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Skip main title
      if (trimmedLine.startsWith('# ') && !trimmedLine.startsWith('## ')) {
        skipNextEmpty = true;
        continue;
      }

      // Skip empty line after title
      if (skipNextEmpty && trimmedLine.isEmpty) {
        skipNextEmpty = false;
        continue;
      }
      skipNextEmpty = false;

      // Convert emergency content to blockquote for custom rendering
      final isEmergencyContent = emergencyPatterns.any(
        (pattern) => trimmedLine.toLowerCase().contains(pattern),
      );

      if (isEmergencyContent && trimmedLine.isNotEmpty) {
        processedLines.add('> $trimmedLine');
      } else {
        processedLines.add(line);
      }
    }

    return processedLines.join('\n');
  }

  /// Build custom MarkdownStyleSheet matching app theme.
  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownStyleSheet(
      // Headers
      h1: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      h4: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      // Body text
      p: theme.textTheme.bodyMedium?.copyWith(
        height: 1.6,
      ),
      // Strong/bold
      strong: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.6,
      ),
      // Lists
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        height: 1.6,
      ),
      // Links
      a: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        height: 1.6,
      ),
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
      ),
      // Spacing
      h2Padding: const EdgeInsets.only(top: 24, bottom: 8),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 8),
      pPadding: const EdgeInsets.only(bottom: 12),
      listIndent: 24,
      listBulletPadding: const EdgeInsets.only(right: 8),
      // Blockquote (for emergency callouts - styled via builder)
      blockquoteDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF3D2E1F) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFFFFB74D).withValues(alpha: 0.3)
              : const Color(0xFFE65100).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      blockquotePadding: const EdgeInsets.all(12),
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
}

/// Custom builder for emergency callout blockquotes.
///
/// Adds warning icon to blockquotes that contain emergency content.
class _EmergencyCalloutBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(element, preferredStyle) {
    return null;
  }

  @override
  Widget visitText(text, preferredStyle) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final iconColor = isDark
            ? const Color(0xFFFFB74D) // Amber 300
            : const Color(0xFFE65100); // Deep orange 900

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
