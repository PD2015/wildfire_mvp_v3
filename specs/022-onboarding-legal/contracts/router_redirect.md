# Contract: Router Redirect Logic

**Version**: 1.0  
**Status**: Draft

---

## Overview

The router redirect logic gates access to the main app until onboarding is complete. This follows go_router's synchronous redirect pattern with pre-loaded preferences.

---

## Architecture

```
main.dart                    app.dart
┌─────────────────────┐     ┌─────────────────────────────┐
│ void main() async   │     │ WildFireApp                 │
│                     │     │                             │
│ 1. WidgetsBinding   │────▶│ SharedPreferences prefs     │
│ 2. await prefs      │     │ (from constructor)          │
│ 3. runApp(          │     │                             │
│   WildFireApp(prefs)│     │ GoRouter uses prefs in      │
│ )                   │     │ redirect: (context, state)  │
└─────────────────────┘     └─────────────────────────────┘
```

---

## Redirect Decision Tree

```dart
redirect: (BuildContext context, GoRouterState state) {
  final path = state.uri.path;
  
  // 1. Get onboarding version (pre-loaded, synchronous)
  final version = prefs.getInt('onboarding_version') ?? 0;
  final isOnboardingComplete = version >= OnboardingConfig.currentOnboardingVersion;
  
  // 2. Check if currently on onboarding route
  final isOnboardingRoute = path == '/onboarding';
  
  // 3. Allow legal routes even during onboarding
  final isLegalRoute = path.startsWith('/about');
  
  // 4. Redirect logic
  if (!isOnboardingComplete && !isOnboardingRoute && !isLegalRoute) {
    // Not done + not on onboarding + not viewing legal = go to onboarding
    return '/onboarding';
  }
  
  if (isOnboardingComplete && isOnboardingRoute) {
    // Done + on onboarding = go home
    return '/';
  }
  
  // No redirect needed
  return null;
}
```

---

## Route Definitions

```dart
final _router = GoRouter(
  initialLocation: '/',
  redirect: _redirect,
  routes: [
    // ─────────────────────────────────────────────────────────
    // Shell Route (with bottom navigation)
    // ─────────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    
    // ─────────────────────────────────────────────────────────
    // Standalone Routes (no bottom navigation)
    // ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // Legal/About routes (accessible during onboarding)
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutScreen(),
      routes: [
        GoRoute(
          path: 'terms',
          name: 'terms',
          builder: (context, state) => const LegalDocumentScreen(
            document: LegalContent.termsOfService,
          ),
        ),
        GoRoute(
          path: 'privacy',
          name: 'privacy',
          builder: (context, state) => const LegalDocumentScreen(
            document: LegalContent.privacyPolicy,
          ),
        ),
        GoRoute(
          path: 'data-sources',
          name: 'data-sources',
          builder: (context, state) => const LegalDocumentScreen(
            document: LegalContent.dataSources,
          ),
        ),
      ],
    ),
  ],
);
```

---

## Test Cases

### Redirect Tests

```dart
group('Router Redirect', () {
  late SharedPreferences prefs;
  late GoRouter router;
  
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    router = createRouter(prefs);
  });
  
  group('Onboarding not complete', () {
    setUp(() {
      // onboarding_version = 0 or missing
    });
    
    test('/ redirects to /onboarding', () async {
      router.go('/');
      await router.navigatorKey.currentState?.popUntil((r) => true);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
    });
    
    test('/map redirects to /onboarding', () async {
      router.go('/map');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
    });
    
    test('/onboarding stays on /onboarding', () async {
      router.go('/onboarding');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
    });
    
    test('/about allowed during onboarding', () async {
      router.go('/about');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/about');
    });
    
    test('/about/terms allowed during onboarding', () async {
      router.go('/about/terms');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/about/terms');
    });
    
    test('/about/privacy allowed during onboarding', () async {
      router.go('/about/privacy');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/about/privacy');
    });
  });
  
  group('Onboarding complete', () {
    setUp(() async {
      await prefs.setInt('onboarding_version', 1);
      router = createRouter(prefs); // Recreate with updated prefs
    });
    
    test('/ stays on /', () async {
      router.go('/');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });
    
    test('/map stays on /map', () async {
      router.go('/map');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/map');
    });
    
    test('/onboarding redirects to /', () async {
      router.go('/onboarding');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });
    
    test('/about stays on /about', () async {
      router.go('/about');
      expect(router.routerDelegate.currentConfiguration.uri.path, '/about');
    });
  });
});
```

### Navigation Tests

```dart
group('Onboarding Navigation', () {
  testWidgets('completing onboarding navigates to home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WildFireApp());
    await tester.pumpAndSettle();
    
    // Should start on onboarding
    expect(find.byType(OnboardingScreen), findsOneWidget);
    
    // Complete onboarding flow
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // ... navigate through pages ...
    
    // Check both boxes
    await tester.tap(find.byKey(const Key('disclaimer_checkbox')));
    await tester.tap(find.byKey(const Key('terms_checkbox')));
    await tester.pump();
    
    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    
    // Should be on home
    expect(find.byType(HomeScreen), findsOneWidget);
  });
  
  testWidgets('legal route navigable from onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WildFireApp());
    await tester.pumpAndSettle();
    
    // Navigate to page 2 (safety disclaimer)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    
    // Tap "View Terms"
    await tester.tap(find.text('View Terms'));
    await tester.pumpAndSettle();
    
    // Should be on terms screen
    expect(find.byType(LegalDocumentScreen), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    
    // Back should return to onboarding
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
});
```

---

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Deep link to `/map` on first launch | Redirect to `/onboarding` |
| Deep link to `/about/privacy` on first launch | Allow (legal routes accessible) |
| Complete onboarding, force close, relaunch | Go to `/` (persisted) |
| Clear app data after onboarding | Redirect to `/onboarding` |
| Version bump (1→2) | Show migration, then `/` |
| Back button on `/onboarding` page 1 | Exit app (no back navigation) |
| Back button on legal route from onboarding | Return to onboarding page |

---

## Implementation Notes

### Synchronous vs Async Redirect

**Problem**: `go_router`'s `redirect` callback is synchronous, but `SharedPreferences.getInstance()` is async.

**Solution**: Pre-load `SharedPreferences` in `main()` before `runApp()`:

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-load SharedPreferences (sync access after this)
  final prefs = await SharedPreferences.getInstance();
  
  runApp(WildFireApp(prefs: prefs));
}

// app.dart
class WildFireApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const WildFireApp({required this.prefs, super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _createRouter(prefs),
    );
  }
  
  GoRouter _createRouter(SharedPreferences prefs) {
    return GoRouter(
      redirect: (context, state) {
        // prefs.getInt() is synchronous
        final version = prefs.getInt('onboarding_version') ?? 0;
        // ... redirect logic
      },
      routes: [...],
    );
  }
}
```

### Router Refresh on Onboarding Complete

When onboarding completes, the router must know to allow navigation. Options:

1. **Direct navigation**: `context.go('/')` after saving prefs
2. **Recreate router**: Not recommended (loses state)
3. **RefreshListenable**: Use `ChangeNotifier` that router listens to

**Recommended**: Direct navigation after `completeOnboarding()`:

```dart
// In OnboardingController or OnboardingScreen
Future<void> _finishOnboarding() async {
  await _prefsService.completeOnboarding(radiusKm: _selectedRadius);
  
  if (mounted) {
    context.go('/'); // Direct navigation
  }
}
```
