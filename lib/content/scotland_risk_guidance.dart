import '../models/risk_level.dart';
import '../models/risk_guidance.dart';

/// Scotland-specific wildfire risk guidance content
///
/// Provides public safety advice based on guidance from:
/// - Scottish Fire and Rescue Service (SFRS)
/// - Ready.Scot (Scottish Government emergency preparedness)
/// - Cairngorms National Park Authority (CNPA)
/// - Forestry and Land Scotland
/// - Scottish Outdoor Access Code
///
/// Constitutional compliance:
/// - C4: Transparency through authoritative, actionable public safety information
class ScotlandRiskGuidance {
  /// Shared disclaimer for all risk levels
  static const String _sharedDisclaimer =
      'Risk levels describe conditions, not safety. Fires can still start at any level.';

  /// Shared help route for all risk levels
  static const String _helpRoute = '/help/doc/risk-levels';

  /// Shared help link label for accessibility
  static const String _helpLinkLabel = 'Learn more about risk levels';

  /// Guidance mapped to each risk level
  static const Map<RiskLevel, RiskGuidance> guidanceByLevel = {
    RiskLevel.veryLow: RiskGuidance(
      title: 'What this risk level means',
      summary:
          'VERY LOW risk – conditions are generally cool or damp. Wildfires are unlikely but still possible.',
      bulletPoints: [
        'Use stoves or BBQs only in provided areas or on hard surfaces.',
        'Keep any flame off peat, heather and dry grass.',
        'Fully extinguish cigarettes, stoves and BBQs and check the ground is cool.',
      ],
      helpRoute: _helpRoute,
      helpLinkLabel: _helpLinkLabel,
      disclaimer: _sharedDisclaimer,
    ),
    RiskLevel.low: RiskGuidance(
      title: 'What this risk level means',
      summary:
          'LOW risk – vegetation will burn if exposed to a flame, but large wildfires are unlikely.',
      bulletPoints: [
        'Prefer gas stoves or fixed BBQ points; avoid fire pits on open moorland.',
        'Keep vehicles and hot exhausts off dry grass and heather.',
        'Take all litter home, especially glass which can focus sunlight.',
      ],
      helpRoute: _helpRoute,
      helpLinkLabel: _helpLinkLabel,
      disclaimer: _sharedDisclaimer,
    ),
    RiskLevel.moderate: RiskGuidance(
      title: 'What this risk level means',
      summary: 'MODERATE risk – heather, grass and woodland edges are drying.',
      bulletPoints: [
        'Avoid campfires and disposable BBQs away from formal sites.',
        'Be extra careful with cigarettes, vapes and matches.',
        'Have water or an extinguisher available if using tools or machinery.',
      ],
      helpRoute: _helpRoute,
      helpLinkLabel: _helpLinkLabel,
      disclaimer: _sharedDisclaimer,
    ),
    RiskLevel.high: RiskGuidance(
      title: 'What this risk level means',
      summary:
          'HIGH risk – fires will start easily and spread quickly in dry vegetation, especially on moorland and forest edges.',
      bulletPoints: [
        'Do not light campfires or use disposable BBQs in the countryside.',
        'Follow local fire restrictions from land managers and National Parks.',
        'Avoid parking or idling vehicles on dry grassy verges.',
      ],
      helpRoute: _helpRoute,
      helpLinkLabel: _helpLinkLabel,
      disclaimer: _sharedDisclaimer,
    ),
    RiskLevel.veryHigh: RiskGuidance(
      title: 'What this risk level means',
      summary:
          'VERY HIGH risk – conditions are very dry. Any spark could start a fast-moving wildfire.',
      bulletPoints: [
        'Avoid lighting any fires or BBQs outdoors.',
        'Keep to paths and watch for smoke on hillsides and in woodland.',
        'Pack out all litter; even a bottle can start a fire in strong sun.',
      ],
      helpRoute: _helpRoute,
      helpLinkLabel: _helpLinkLabel,
      disclaimer: _sharedDisclaimer,
    ),
    RiskLevel.extreme: RiskGuidance(
      title: 'What this risk level means',
      summary:
          'EXTREME risk – wildfires can start very easily, spread rapidly and be very difficult to control.',
      bulletPoints: [
        'Do not use outdoor fires, BBQs or stoves in the countryside.',
        'Follow local closures and ranger advice – bans may be in force.',
        'If you see smoke or flames, move to safety and call 999 immediately.',
      ],
      helpRoute: _helpRoute,
      helpLinkLabel: _helpLinkLabel,
      disclaimer: _sharedDisclaimer,
    ),
  };

  /// Generic fallback guidance for when risk level is unavailable
  static const RiskGuidance genericGuidance = RiskGuidance(
    title: 'Unable to determine current risk level',
    summary:
        'We cannot determine the wildfire risk for your location right now, but you can still help prevent wildfires.',
    bulletPoints: [
      'Be cautious with any outdoor fires, BBQs or smoking materials.',
      'Follow local fire safety advice and restrictions.',
      'Keep vehicles off dry grass and vegetation.',
    ],
    helpRoute: _helpRoute,
    helpLinkLabel: _helpLinkLabel,
    disclaimer: _sharedDisclaimer,
  );

  /// Emergency response footer (same for all levels)
  static const String emergencyFooter =
      // 'If you see a wildfire, call 999 and ask for the Fire Service.';
      'If you see a wildfire, report it. Provide as much information as possible about the location and size of the fire.';

  /// Gets guidance for a specific risk level, or generic guidance if null
  static RiskGuidance getGuidance(RiskLevel? level) {
    if (level == null) {
      return genericGuidance;
    }
    return guidanceByLevel[level]!;
  }
}
