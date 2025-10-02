# Phase 0: Research & Technical Decisions

## Flutter BLoC Pattern for Widget State Management

**Decision**: Use flutter_bloc package with Cubit for RiskBanner state management

**Rationale**: 
- Cubit provides simpler state management than full BLoC for single-widget use case
- Integrates well with existing A2 FireRiskService architecture
- Built-in testing support with bloc_test package
- Reactive state updates for loading/error/success states
- Follows Flutter recommended patterns for business logic separation

**Alternatives considered**:
- Provider: Less structured for complex state transitions
- StatefulWidget only: Harder to test business logic
- Riverpod: Adds new dependency, BLoC already established in project

## Widget Testing Strategy for Accessibility

**Decision**: Use flutter_test with semantics testing and golden tests

**Rationale**:
- flutter_test includes built-in semantic analysis for accessibility
- Golden tests ensure visual consistency across states
- Semantic finders validate screen reader compatibility
- Touch target verification through widget dimensions

**Alternatives considered**:
- Manual accessibility testing only: Not scalable or automated
- Third-party a11y tools: flutter_test sufficient for basic compliance

## Scottish Wildfire Risk Color Implementation

**Decision**: Create WildfireColors constants class with validation tests

**Rationale**:
- Single source of truth prevents color inconsistencies
- Const values enable compile-time optimization
- Test validation ensures official color compliance
- Easy to update if government standards change

**Alternatives considered**:
- Theme-based colors: Unnecessary complexity for static official colors
- Hardcoded colors in widget: Violates DRY principle
- JSON/asset-based colors: Runtime loading overhead

## Integration with A2 FireRiskService

**Decision**: Use dependency injection pattern with repository abstraction

**Rationale**:
- Maintains loose coupling with A2 service implementation
- Enables easy mocking for widget tests
- Repository pattern allows future service swapping
- Aligns with clean architecture principles

**Alternatives considered**:
- Direct service dependency: Tight coupling, harder to test
- Static service access: Prevents proper mocking
- Singleton pattern: Makes testing difficult

## Error and Loading State Management

**Decision**: Sealed class hierarchy for widget states with specific error types

**Rationale**:
- Type-safe state transitions prevent invalid UI states
- Specific error types enable targeted error messages
- Loading states provide user feedback during data fetching
- Cached state indication maintains transparency

**Alternatives considered**:
- Boolean flags: Prone to invalid combinations
- String-based states: Not type-safe
- Generic error handling: Less informative to users

## Widget Responsiveness and Layout

**Decision**: Use Flexible layout with minimum height constraints

**Rationale**:
- Adapts to different screen sizes and orientations
- Maintains minimum 44dp touch target requirement
- Preserves visual hierarchy in various contexts
- Supports tablet and phone form factors

**Alternatives considered**:
- Fixed dimensions: Poor responsive behavior
- Expanded widget: May consume too much space
- Intrinsic dimensions only: May violate accessibility requirements

## Testing Architecture

**Decision**: Three-tier testing approach: unit, widget, integration

**Rationale**:
- Unit tests: BLoC/Cubit logic and color constants
- Widget tests: UI rendering and accessibility compliance
- Integration tests: End-to-end widget behavior with real services

**Alternatives considered**:
- Unit tests only: Insufficient UI coverage
- Integration tests only: Slow feedback loop
- Manual testing only: Not scalable or repeatable