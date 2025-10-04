// This is a basic widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/app.dart';
import 'package:wildfire_mvp_v3/controllers/home_controller.dart';
import 'package:wildfire_mvp_v3/services/location_resolver_impl.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/widgets/risk_banner.dart';
import 'package:dartz/dartz.dart';

// Mock FireRiskService for testing
class _TestFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    return Right(FireRisk(
      level: RiskLevel.low,
      freshness: Freshness.live,
      source: DataSource.mock,
      observedAt: DateTime.now().toUtc(),
    ));
  }
}

void main() {
  testWidgets('WildFire app loads successfully', (WidgetTester tester) async {
    // Create test services
    final locationResolver = LocationResolverImpl();
    final fireRiskService = _TestFireRiskService();
    
    // Create controller with test services
    final homeController = HomeController(
      locationResolver: locationResolver,
      fireRiskService: fireRiskService,
    );
    
    // Build our app and trigger a frame
    await tester.pumpWidget(WildFireApp(homeController: homeController));

    // Verify that our app title appears in AppBar
    expect(find.text('Wildfire Risk'), findsOneWidget);
    
    // Verify the risk banner widget is present (check for loading state or content)
    expect(find.byType(RiskBanner), findsOneWidget);
    
    // Clean up any pending operations
    homeController.dispose();
  });
}
