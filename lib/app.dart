import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'controllers/home_controller.dart';
import 'screens/home_screen.dart';
import 'theme/wildfire_theme.dart';

/// WildFire application root widget
///
/// This widget configures the MaterialApp with proper theme settings and
/// routing. It receives the HomeController via dependency injection from
/// main.dart to maintain clean architecture and testability.
///
/// Constitutional compliance:
/// - C1: Clean architecture with dependency injection
/// - C4: Official Scottish wildfire theme colors
/// - C3: Accessibility support via theme configuration
class WildFireApp extends StatelessWidget {
  /// Home controller with injected services
  final HomeController homeController;

  const WildFireApp({
    super.key,
    required this.homeController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WildFire Risk Assessment',

      // Theme configuration with official Scottish colors
      theme: WildfireTheme.light,
      darkTheme: WildfireTheme.dark,
      themeMode: ThemeMode.system,

      // Accessibility and localization
      debugShowCheckedModeBanner: false,

      // Initial route configuration
      home: HomeScreen(controller: homeController),

      // Error handling for navigation
      builder: (context, child) {
        // Error boundary for unhandled exceptions
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return _buildErrorWidget(context, errorDetails);
        };

        return child ?? const SizedBox.shrink();
      },
    );
  }

  /// Builds error widget for unhandled exceptions
  Widget _buildErrorWidget(
      BuildContext context, FlutterErrorDetails errorDetails) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.0,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              'The app encountered an unexpected error. Please restart the app.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            if (kDebugMode) ...[
              Text(
                'Debug info:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  errorDetails.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
