# Changelog

All notable changes to the WildFire MVP v3 project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Onboarding Flow**: 4-page wizard (Welcome, Safety Information, Privacy, Setup) with:
  - Dual consent checkboxes for disclaimer acknowledgment and terms acceptance
  - Notification radius selection (5km, 10km, 25km, 50km)
  - Back navigation on pages 2-4
  - PageIndicator with accessible step labels ("Step X of 4: Title")
  - Router redirect for first-time users
  - Consent persistence via SharedPreferences
- **Legal Document Screens**: Full markdown rendering with:
  - Collapsible table of contents with scroll-to-section navigation
  - Document-type iconography in AppBar (gavel, shield, warning, storage)
  - Emergency callout cards with 999/101 contact info
  - Max-width constraint for tablet/web readability
  - Terms of Service, Privacy Policy, Emergency Disclaimer, Data Sources
- **Settings Hub**: Organized settings interface with:
  - About section (app info, version, Reset Onboarding for dev)
  - Legal Documents section (links to all legal content)
  - Notifications section (placeholder for future settings)
- **Help Hub**: User support screens with:
  - FAQ with expandable questions
  - Contact Support information
  - Emergency Information with direct call links
- **Emergency Disclaimer Footer**: Persistent safety reminder on Fire Risk screen with About link
- Created `lib/config/ui_constants.dart` for centralized UI string and icon constants
- Added route name 'fire-risk' and '/fire-risk' alias for improved navigation clarity
- Added descriptive semantic labels to warning icons for improved accessibility

### Changed
- Renamed "Home" screen to "Fire Risk" screen throughout the application for improved clarity
- Updated bottom navigation label from "Home" to "Fire Risk" with warning icon (Icons.warning_amber)
- Enhanced semantic labels for screen readers with dynamic fire risk status announcements
- Updated documentation to reflect Fire Risk screen terminology
- Routes restructured under `/settings/*` and `/help/*` paths
- Legacy routes (`/about`, `/terms`, `/privacy`) redirect to new locations

