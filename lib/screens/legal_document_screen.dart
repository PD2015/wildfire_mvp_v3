import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';

/// Screen for displaying a full legal document.
///
/// Shows a scrollable view of the document content with the title in the AppBar.
/// Used for Terms of Service, Privacy Policy, Disclaimer, and Data Sources.
class LegalDocumentScreen extends StatefulWidget {
  /// The legal document to display.
  final LegalDocument document;

  const LegalDocumentScreen({required this.document, super.key});

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  bool _isTocExpanded = false;
  late final List<_TocEntry> _tocEntries;
  late final List<_ContentSection> _contentSections;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tocEntries = _extractTocEntries(widget.document.content);
    _contentSections = _splitIntoSections(widget.document.content);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Extract table of contents entries from markdown content.
  List<_TocEntry> _extractTocEntries(String content) {
    final entries = <_TocEntry>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      // Match ## headers (level 2) - skip # main title
      if (trimmed.startsWith('## ')) {
        final title = trimmed.substring(3).replaceAll('**', '').trim();
        final id = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        entries.add(_TocEntry(title: title, id: id, level: 2));
      } else if (trimmed.startsWith('### ')) {
        final title = trimmed.substring(4).replaceAll('**', '').trim();
        final id = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        entries.add(_TocEntry(title: title, id: id, level: 3));
      }
    }

    return entries;
  }

  /// Split content into sections for individual rendering with keys.
  List<_ContentSection> _splitIntoSections(String content) {
    final sections = <_ContentSection>[];
    final lines = content.split('\n');
    final currentContent = StringBuffer();
    String? currentSectionId;
    var isFirstSection = true;

    for (final line in lines) {
      final trimmed = line.trim();

      // Check for section headers (## or ###)
      final isLevel2Header = trimmed.startsWith('## ');
      final isLevel3Header = trimmed.startsWith('### ');

      if (isLevel2Header || isLevel3Header) {
        // Save previous section
        if (currentContent.isNotEmpty || !isFirstSection) {
          sections.add(
            _ContentSection(
              id: currentSectionId,
              content: currentContent.toString(),
              key: GlobalKey(),
            ),
          );
          currentContent.clear();
        }
        isFirstSection = false;

        // Start new section
        final headerText = isLevel2Header
            ? trimmed.substring(3).replaceAll('**', '').trim()
            : trimmed.substring(4).replaceAll('**', '').trim();
        currentSectionId = headerText.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '-',
        );
      }

      currentContent.writeln(line);
    }

    // Add final section
    if (currentContent.isNotEmpty) {
      sections.add(
        _ContentSection(
          id: currentSectionId,
          content: currentContent.toString(),
          key: GlobalKey(),
        ),
      );
    }

    return sections;
  }

  /// Scroll to a section by its ID.
  void _scrollToSection(String sectionId) {
    final section = _contentSections.firstWhere(
      (s) => s.id == sectionId,
      orElse: () => _contentSections.first,
    );

    final keyContext = section.key.currentContext;
    if (keyContext != null) {
      // Use ensureVisible with explicit scroll controller context
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getDocumentIcon(widget.document.id), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.document.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              controller: _scrollController,
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
                          'Version ${widget.document.version} • '
                          'Effective ${_formatDate(widget.document.effectiveDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table of contents (collapsible)
                  if (_tocEntries.length >= 3) _buildTableOfContents(theme),

                  const SizedBox(height: 16),

                  // Document content - rendered as sections for scroll navigation
                  ..._contentSections.map(
                    (section) => KeyedSubtree(
                      key: section.key,
                      child: MarkdownBody(
                        data: _preprocessContent(section.content),
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                        styleSheet: _buildMarkdownStyleSheet(context),
                        builders: {'blockquote': _EmergencyCalloutBuilder()},
                      ),
                    ),
                  ),

                  // Footer with last updated
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Last updated: ${_formatDate(widget.document.effectiveDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build collapsible table of contents widget.
  Widget _buildTableOfContents(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible, tappable)
          InkWell(
            onTap: () => setState(() => _isTocExpanded = !_isTocExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.list_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Contents',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isTocExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._tocEntries.map((entry) => _buildTocItem(entry, theme)),
                ],
              ),
            ),
            crossFadeState: _isTocExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Build individual TOC item.
  Widget _buildTocItem(_TocEntry entry, ThemeData theme) {
    return InkWell(
      onTap: () {
        // Close TOC and scroll to section
        setState(() => _isTocExpanded = false);
        // Small delay to let TOC collapse animation start
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToSection(entry.id);
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.only(
          left: entry.level == 3 ? 16.0 : 0.0,
          top: 6,
          bottom: 6,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: entry.level == 3 ? 0.4 : 0.6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: entry.level == 2
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get icon for document type based on document ID.
  IconData _getDocumentIcon(String documentId) {
    return switch (documentId) {
      'terms' => Icons.description_outlined, // Terms of Service
      'privacy' => Icons.shield_outlined, // Privacy Policy
      'disclaimer' => Icons.warning_amber_outlined, // Emergency Disclaimer
      'data-sources' => Icons.storage_outlined, // Data Sources
      _ => Icons.article_outlined, // Default fallback
    };
  }

  /// Preprocess markdown content for display.
  ///
  /// - Removes main title (shown in AppBar)
  /// - Converts emergency content to blockquotes for callout styling
  /// - Wraps inline metadata (Version/Date) in italics for secondary styling
  String _preprocessContent(String content) {
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

    // Patterns for inline metadata (Version, Effective Date, Operator)
    final metadataPatterns = [
      RegExp(r'^\*\*Version:\*\*'),
      RegExp(r'^\*\*Effective Date:\*\*'),
      RegExp(r'^\*\*Operator:\*\*'),
      RegExp(r'^\*\*Last Updated:\*\*'),
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

      // Check if line is inline metadata
      final isMetadata = metadataPatterns.any(
        (pattern) => pattern.hasMatch(trimmedLine),
      );

      if (isEmergencyContent && trimmedLine.isNotEmpty) {
        processedLines.add('> $trimmedLine');
      } else if (isMetadata) {
        // Convert to italic for secondary styling
        // Remove existing bold markers and wrap in italics
        final cleanedLine = trimmedLine
            .replaceAll('**', '')
            .replaceFirst(': ', ': *');
        processedLines.add('_$cleanedLine*_');
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
      h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      h4: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      // Body text
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
      // Strong/bold
      strong: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.6,
      ),
      // Emphasis/italic - used for secondary metadata (Version, Date, etc.)
      em: theme.textTheme.bodySmall?.copyWith(
        fontStyle: FontStyle.normal, // Remove italic style
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        height: 1.6,
      ),
      // Lists
      listBullet: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
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
            Icon(Icons.warning_amber_rounded, color: iconColor, size: 20),
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

/// Entry in the table of contents.
class _TocEntry {
  final String title;
  final String id;
  final int level;

  const _TocEntry({required this.title, required this.id, required this.level});
}

/// A section of content with a global key for scroll navigation.
class _ContentSection {
  final String? id;
  final String content;
  final GlobalKey key;

  _ContentSection({required this.id, required this.content, required this.key});
}
