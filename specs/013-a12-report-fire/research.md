# Research: A12 – Report Fire Screen (MVP)

**Date**: 28 October 2025  
**Feature**: Report Fire Screen with emergency calling functionality

## Research Findings

### url_launcher Package Integration
**Decision**: Use url_launcher ^6.2.0 for native dialer integration  
**Rationale**: 
- Mature, stable package with cross-platform support for iOS, Android, and Web
- Built-in error handling for unsupported platforms/schemes  
- Zero additional dependencies beyond Flutter SDK
- Well-documented tel: scheme support with fallback capabilities
**Alternatives considered**:
- Native platform channels: Too complex for MVP scope
- Third-party calling packages: Unnecessary overhead for simple dialer launching

### Emergency Contact Button Styling
**Decision**: Use Material 3 ColorScheme with emergency-specific variants  
**Rationale**:
- Leverage existing theme infrastructure from WildFire app
- 999 Fire Service gets `colorScheme.error` for emergency prominence
- 101 Police and 0800 Crimestoppers use `colorScheme.primary` variants
- Maintains WCAG AA contrast compliance in both light/dark themes
**Alternatives considered**:
- Hard-coded emergency colors: Violates "single source of truth" principle
- Custom emergency theme: Over-engineered for three buttons

### Accessibility Testing Strategy
**Decision**: Combine flutter_test Semantics testing with manual verification  
**Rationale**:
- Semantics widget testing can verify semantic labels and touch target sizes programmatically
- Manual testing required for actual screen reader behavior verification
- Testable approach aligns with C1 (Code Quality & Tests) requirements
**Alternatives considered**:
- Automated accessibility testing tools: Limited Flutter ecosystem support
- Manual testing only: Doesn't satisfy CI/testing gate requirements

### Error Handling for Unsupported Devices
**Decision**: Try-catch url_launcher.launch() with SnackBar fallback  
**Rationale**:
- url_launcher throws PlatformException on unsupported schemes/devices
- SnackBar provides non-intrusive notification with manual dialing instructions
- Graceful degradation maintains functionality on emulators and web platforms
**Alternatives considered**:
- canLaunch() pre-check: Deprecated in url_launcher 6.0+
- Dialog fallback: Too intrusive for emergency use case

### Offline Capability Implementation
**Decision**: Static screen with no network dependencies  
**Rationale**:
- Emergency contact numbers are constants, no API calls required
- Screen loads instantly with zero latency, critical for emergency situations
- Satisfies FR-009 offline functionality requirement completely
**Alternatives considered**:
- Cached remote emergency contacts: Unnecessary complexity for static data
- Progressive web app approach: Doesn't align with native app architecture

### Testing Platform Coverage
**Decision**: Widget tests for all platforms, integration tests for device-specific behavior  
**Rationale**:
- Widget tests validate UI behavior and accessibility compliance across all platforms
- Integration tests on real devices verify tel: scheme handling and dialer integration
- Emulator testing specifically validates SnackBar fallback behavior
**Alternatives considered**:
- Platform-specific test suites: Over-engineered for simple UI screen
- Manual testing only: Doesn't meet C1 automated testing requirements

## Implementation Dependencies
- url_launcher: ^6.2.0 (add to pubspec.yaml)
- flutter_test: (already available in dev_dependencies)
- integration_test: (already configured in project)

## Risk Mitigations Validated
- **tel: scheme failures**: Confirmed url_launcher provides reliable exception handling
- **Theme token conflicts**: Material 3 ColorScheme approach ensures consistency with existing app theme
- **Cross-platform compatibility**: url_launcher supports all target platforms (iOS, Android, Web, macOS web mode)

## Next Phase Requirements
All technical unknowns resolved. Ready for Phase 1 design and contract generation.