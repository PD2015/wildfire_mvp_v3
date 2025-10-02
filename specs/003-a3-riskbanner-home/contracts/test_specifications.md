# Contract Test Specifications

## Test Files to Create

### Widget Contract Tests
**File**: `test/features/risk_banner/presentation/widgets/risk_banner_widget_test.dart`

**Purpose**: Verify RiskBannerWidget adheres to interface contracts

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

import 'package:wildfire_mvp_v3/features/risk_banner/presentation/widgets/risk_banner_widget.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/presentation/bloc/risk_banner_cubit.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/domain/repositories/fire_risk_repository.dart';

class MockFireRiskRepository extends Mock implements FireRiskRepository {}

void main() {
  group('RiskBannerWidget Contract Tests', () {
    late MockFireRiskRepository mockRepository;
    
    setUp(() {
      mockRepository = MockFireRiskRepository();
    });

    testWidgets('constructor requires valid coordinates', (tester) async {
      // Test: Widget creation with invalid coordinates should fail gracefully
      // Expected: Widget handles validation appropriately
      expect(() => RiskBannerWidget(latitude: 100.0, longitude: 0.0), 
             throwsAssertionError);
    });

    testWidgets('displays loading state initially', (tester) async {
      // Test: Widget shows loading indicator on first render
      // Expected: Loading spinner visible with correct semantic label
      when(mockRepository.getRiskData(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => await Future.delayed(Duration(seconds: 1)));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => RiskBannerCubit(repository: mockRepository),
            child: RiskBannerWidget(latitude: 55.9533, longitude: -3.1883),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading wildfire risk data'), findsOneWidget);
    });

    testWidgets('meets minimum height requirement', (tester) async {
      // Test: Widget height is at least 44dp for accessibility
      // Expected: Height >= 44.0 logical pixels
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => RiskBannerCubit(repository: mockRepository),
            child: RiskBannerWidget(latitude: 55.9533, longitude: -3.1883),
          ),
        ),
      );

      final widget = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(widget.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('displays correct color for risk level', (tester) async {
      // Test: Background color matches risk level
      // Expected: High risk = red background
      final highRiskData = FireRisk(
        level: WildfireRiskLevel.high,
        fwiValue: 85.0,
        source: 'EFFIS',
        timestamp: DateTime.now(),
        latitude: 55.9533,
        longitude: -3.1883,
      );

      when(mockRepository.getRiskData(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => Right(highRiskData));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => RiskBannerCubit(repository: mockRepository)
              ..loadRiskData(55.9533, -3.1883),
            child: RiskBannerWidget(latitude: 55.9533, longitude: -3.1883),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(WildfireColors.high));
    });

    testWidgets('includes proper semantic labels', (tester) async {
      // Test: Screen reader can understand widget content
      // Expected: Descriptive semantic labels present
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => RiskBannerCubit(repository: mockRepository),
            child: RiskBannerWidget(latitude: 55.9533, longitude: -3.1883),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'wildfire risk')), findsOneWidget);
    });

    testWidgets('responds to tap when callback provided', (tester) async {
      // Test: Widget triggers onTap callback when tapped
      // Expected: Callback invoked exactly once
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => RiskBannerCubit(repository: mockRepository),
            child: RiskBannerWidget(
              latitude: 55.9533,
              longitude: -3.1883,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RiskBannerWidget));
      expect(tapped, isTrue);
    });
  });
}
```

### BLoC Contract Tests  
**File**: `test/features/risk_banner/presentation/bloc/risk_banner_cubit_test.dart`

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:wildfire_mvp_v3/features/risk_banner/presentation/bloc/risk_banner_cubit.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/domain/repositories/fire_risk_repository.dart';

class MockFireRiskRepository extends Mock implements FireRiskRepository {}

void main() {
  group('RiskBannerCubit Contract Tests', () {
    late MockFireRiskRepository mockRepository;
    late RiskBannerCubit cubit;

    setUp(() {
      mockRepository = MockFireRiskRepository();
      cubit = RiskBannerCubit(repository: mockRepository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is RiskBannerInitial', () {
      expect(cubit.state, equals(const RiskBannerInitial()));
    });

    blocTest<RiskBannerCubit, RiskBannerState>(
      'emits loading then loaded when getRiskData succeeds',
      build: () => cubit,
      setUp: () {
        when(mockRepository.getRiskData(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        )).thenAnswer((_) async => Right(
          FireRisk(
            level: WildfireRiskLevel.moderate,
            fwiValue: 45.0,
            source: 'EFFIS',
            timestamp: DateTime.now(),
            latitude: 55.9533,
            longitude: -3.1883,
          ),
        ));
      },
      act: (cubit) => cubit.loadRiskData(55.9533, -3.1883),
      expect: () => [
        isA<RiskBannerLoading>(),
        isA<RiskBannerLoaded>(),
      ],
    );

    blocTest<RiskBannerCubit, RiskBannerState>(
      'emits loading then error when getRiskData fails',
      build: () => cubit,
      setUp: () {
        when(mockRepository.getRiskData(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        )).thenAnswer((_) async => Left(
          NetworkFailure('Connection timeout'),
        ));
      },
      act: (cubit) => cubit.loadRiskData(55.9533, -3.1883),
      expect: () => [
        isA<RiskBannerLoading>(),
        isA<RiskBannerError>(),
      ],
    );

    blocTest<RiskBannerCubit, RiskBannerState>(
      'refresh only works from loaded state',
      build: () => cubit,
      act: (cubit) => cubit.refresh(),
      expect: () => [], // No state change from initial state
    );

    test('validates coordinate ranges', () {
      expect(() => cubit.loadRiskData(100.0, 0.0), throwsArgumentError);
      expect(() => cubit.loadRiskData(0.0, 200.0), throwsArgumentError);
    });
  });
}
```

### Repository Contract Tests
**File**: `test/features/risk_banner/domain/repositories/fire_risk_repository_test.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:wildfire_mvp_v3/features/risk_banner/domain/repositories/fire_risk_repository.dart';
import 'package:wildfire_mvp_v3/features/risk_banner/data/repositories/fire_risk_repository_impl.dart';

class MockFireRiskService extends Mock implements FireRiskService {}

void main() {
  group('FireRiskRepository Contract Tests', () {
    late MockFireRiskService mockService;
    late FireRiskRepository repository;

    setUp(() {
      mockService = MockFireRiskService();
      repository = FireRiskRepositoryImpl(service: mockService);
    });

    test('getRiskData returns Right when service succeeds', () async {
      // Test: Repository properly wraps successful service calls
      // Expected: Returns Right<FireRisk>
      final expectedRisk = FireRisk(
        level: WildfireRiskLevel.low,
        fwiValue: 25.0,
        source: 'EFFIS',
        timestamp: DateTime.now(),
        latitude: 55.9533,
        longitude: -3.1883,
      );

      when(mockService.getCurrent(
        lat: anyNamed('lat'),
        lon: anyNamed('lon'),
      )).thenAnswer((_) async => Right(expectedRisk));

      final result = await repository.getRiskData(
        latitude: 55.9533,
        longitude: -3.1883,
      );

      expect(result, isA<Right<FireRiskFailure, FireRisk>>());
      expect(result.fold((l) => null, (r) => r), equals(expectedRisk));
    });

    test('getRiskData returns Left when service fails', () async {
      // Test: Repository properly handles service failures  
      // Expected: Returns Left<FireRiskFailure>
      when(mockService.getCurrent(
        lat: anyNamed('lat'),
        lon: anyNamed('lon'),
      )).thenAnswer((_) async => Left(
        ApiError(message: 'Service unavailable'),
      ));

      final result = await repository.getRiskData(
        latitude: 55.9533,
        longitude: -3.1883,
      );

      expect(result, isA<Left<FireRiskFailure, FireRisk>>());
    });

    test('validates coordinate ranges', () async {
      // Test: Repository validates input parameters
      // Expected: Returns validation failure for invalid coordinates
      final result = await repository.getRiskData(
        latitude: 100.0, // Invalid latitude
        longitude: -3.1883,
      );

      expect(result, isA<Left<ValidationFailure, FireRisk>>());
    });

    test('forceRefresh parameter passed to service', () async {
      // Test: Repository passes refresh flag to underlying service
      // Expected: Service called with appropriate cache bypass
      when(mockService.getCurrent(
        lat: anyNamed('lat'),
        lon: anyNamed('lon'),
        forceRefresh: anyNamed('forceRefresh'),
      )).thenAnswer((_) async => Right(FireRisk(
        level: WildfireRiskLevel.veryLow,
        fwiValue: 5.0,
        source: 'EFFIS',
        timestamp: DateTime.now(),
        latitude: 55.9533,
        longitude: -3.1883,
      )));

      await repository.getRiskData(
        latitude: 55.9533,
        longitude: -3.1883,
        forceRefresh: true,
      );

      verify(mockService.getCurrent(
        lat: 55.9533,
        lon: -3.1883,
        forceRefresh: true,
      )).called(1);
    });
  });
}
```

### Constants Contract Tests
**File**: `test/shared/constants/wildfire_colors_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/shared/constants/wildfire_colors.dart';

void main() {
  group('WildfireColors Contract Tests', () {
    test('all risk levels have corresponding colors', () {
      // Test: Every enum value has a color mapping
      // Expected: No exceptions thrown, all colors defined
      for (final level in WildfireRiskLevel.values) {
        expect(() => WildfireColors.getColorForLevel(level), returnsNormally);
        expect(WildfireColors.getColorForLevel(level), isA<Color>());
      }
    });

    test('colors match Scottish Government standards', () {
      // Test: Color values match official specification
      // Expected: Exact RGB values as per government standards
      expect(WildfireColors.veryLow, equals(const Color(0xFF00FF00))); // Green
      expect(WildfireColors.low, equals(const Color(0xFFFFFF00)));     // Yellow
      expect(WildfireColors.moderate, equals(const Color(0xFFFFA500))); // Orange
      expect(WildfireColors.high, equals(const Color(0xFFFF0000)));    // Red
      expect(WildfireColors.veryHigh, equals(const Color(0xFF800080))); // Purple
    });

    test('colors provide sufficient contrast', () {
      // Test: Colors meet accessibility contrast requirements
      // Expected: All colors contrast well with white text
      final colors = [
        WildfireColors.veryLow,
        WildfireColors.low,
        WildfireColors.moderate,
        WildfireColors.high,
        WildfireColors.veryHigh,
      ];

      for (final color in colors) {
        final luminance = color.computeLuminance();
        final contrastRatio = (Colors.white.computeLuminance() + 0.05) / 
                             (luminance + 0.05);
        expect(contrastRatio, greaterThan(4.5)); // WCAG AA standard
      }
    });

    test('getColorForLevel handles all enum cases', () {
      // Test: Switch statement is exhaustive
      // Expected: No exceptions for any enum value
      expect(WildfireColors.getColorForLevel(WildfireRiskLevel.veryLow), 
             equals(WildfireColors.veryLow));
      expect(WildfireColors.getColorForLevel(WildfireRiskLevel.low), 
             equals(WildfireColors.low));
      expect(WildfireColors.getColorForLevel(WildfireRiskLevel.moderate), 
             equals(WildfireColors.moderate));
      expect(WildfireColors.getColorForLevel(WildfireRiskLevel.high), 
             equals(WildfireColors.high));
      expect(WildfireColors.getColorForLevel(WildfireRiskLevel.veryHigh), 
             equals(WildfireColors.veryHigh));
    });
  });
}
```

## Expected Test Results

**All tests should FAIL initially** since no implementation exists yet. This is the expected TDD workflow:

1. **Widget tests** - `RiskBannerWidget` class not found
2. **BLoC tests** - `RiskBannerCubit` class not found  
3. **Repository tests** - `FireRiskRepository` interface not found
4. **Constants tests** - `WildfireColors` class not found

**Success criteria**: Tests compile but fail with "class not found" or similar errors, confirming contracts are well-defined and implementation can be guided by these failing tests.

## Integration Test Specifications

**File**: `integration_test/risk_banner_integration_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wildfire_mvp_v3/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('RiskBanner Integration Tests', () {
    testWidgets('end-to-end risk display with real service', (tester) async {
      // Test: Full widget lifecycle with real FireRiskService
      // Expected: Widget loads, displays correct risk level, handles user interaction
      app.main();
      await tester.pumpAndSettle();

      // Find RiskBanner widget on home screen
      expect(find.byType(RiskBannerWidget), findsOneWidget); 

      // Wait for data to load
      await tester.pump(Duration(seconds: 5));

      // Verify risk level is displayed
      expect(find.textContaining('wildfire risk'), findsOneWidget);
      
      // Verify timestamp is shown
      expect(find.textContaining('Last updated'), findsOneWidget);
      
      // Verify source is labeled
      expect(find.textContaining(RegExp(r'EFFIS|SEPA|Cache|Mock')), findsOneWidget);

      // Test tap interaction
      await tester.tap(find.byType(RiskBannerWidget));
      await tester.pumpAndSettle();
      
      // Verify tap response (navigation or action)
      // This depends on implementation details
    });

    testWidgets('accessibility compliance in real environment', (tester) async {
      // Test: Widget meets accessibility requirements with real data
      // Expected: Semantic labels, touch targets, contrast all correct
      app.main();
      await tester.pumpAndSettle();

      final widget = find.byType(RiskBannerWidget);
      expect(widget, findsOneWidget);

      // Verify semantic label exists
      expect(find.bySemanticsLabel(RegExp(r'wildfire risk')), findsOneWidget);

      // Verify minimum touch target size
      final renderBox = tester.renderObject(widget) as RenderBox;
      expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
    });
  });
}
```