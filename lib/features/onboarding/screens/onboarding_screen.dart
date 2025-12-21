import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/features/onboarding/pages/disclaimer_page.dart';
import 'package:wildfire_mvp_v3/features/onboarding/pages/privacy_page.dart';
import 'package:wildfire_mvp_v3/features/onboarding/pages/setup_page.dart';
import 'package:wildfire_mvp_v3/features/onboarding/pages/welcome_page.dart';
import 'package:wildfire_mvp_v3/features/onboarding/widgets/hero_background.dart';
import 'package:wildfire_mvp_v3/features/onboarding/widgets/page_indicator.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs.dart';

/// Main onboarding screen with 4-page flow.
///
/// Pages:
/// 1. Welcome - App introduction
/// 2. Disclaimer - Safety information
/// 3. Privacy - Data usage transparency
/// 4. Setup - Preferences and consent
class OnboardingScreen extends StatefulWidget {
  /// Service for persisting onboarding state.
  final OnboardingPrefsService prefsService;

  /// Callback when onboarding is complete.
  final VoidCallback? onComplete;

  const OnboardingScreen({
    required this.prefsService,
    this.onComplete,
    super.key,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Setup page state
  int _selectedRadius = OnboardingConfig.defaultRadiusKm;
  bool _disclaimerAcknowledged = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _navigateToTerms() {
    context.push('/settings/about/terms');
  }

  void _navigateToPrivacy() {
    context.push('/settings/about/privacy');
  }

  Future<void> _completeOnboarding() async {
    // Complete onboarding with selected radius
    await widget.prefsService.completeOnboarding(radiusKm: _selectedRadius);

    // Notify completion
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeroBackground(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  // Page 1: Welcome
                  WelcomePage(
                    onContinue: _nextPage,
                  ),

                  // Page 2: Disclaimer
                  DisclaimerPage(
                    onContinue: _nextPage,
                    onBack: _previousPage,
                    onViewTerms: _navigateToTerms,
                  ),

                  // Page 3: Privacy
                  PrivacyPage(
                    onContinue: _nextPage,
                    onBack: _previousPage,
                    onViewPrivacy: _navigateToPrivacy,
                  ),

                  // Page 4: Setup
                  SetupPage(
                    initialRadius: _selectedRadius,
                    disclaimerAcknowledged: _disclaimerAcknowledged,
                    termsAccepted: _termsAccepted,
                    onRadiusChanged: (radius) {
                      setState(() => _selectedRadius = radius);
                    },
                    onDisclaimerChanged: (acknowledged) {
                      setState(() => _disclaimerAcknowledged = acknowledged);
                    },
                    onTermsChanged: (accepted) {
                      setState(() => _termsAccepted = accepted);
                    },
                    onComplete: _completeOnboarding,
                    onBack: _previousPage,
                    onViewTerms: _navigateToTerms,
                    onViewPrivacy: _navigateToPrivacy,
                  ),
                ],
              ),
            ),

            // Page indicator
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PageIndicator(
                  totalPages: 4,
                  currentPage: _currentPage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
