import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:wildfire_mvp_v3/features/help/content/help_content.dart';

/// Screen for displaying a full help document.
///
/// Shows a scrollable view of the document content with the title in the AppBar.
/// Uses markdown rendering for formatted content.
class HelpDocumentScreen extends StatelessWidget {
  /// The help document to display.
  final HelpDocument document;

  const HelpDocumentScreen({
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
        child: Markdown(
          data: document.content,
          selectable: true,
          padding: const EdgeInsets.all(16),
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            h1: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            h2: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            h3: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            p: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
            listBullet: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
            blockquote: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            blockquotePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 4,
                ),
              ),
            ),
          ),
          onTapLink: (text, href, title) {
            if (href != null) {
              _launchUrl(href);
            }
          },
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
