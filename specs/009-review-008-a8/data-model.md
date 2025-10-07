# Data Model - A8 Debugging Tests

**Design Phase**: Phase 1  
**Date**: 2025-01-27  
**Prerequisites**: research.md complete

## Test Entity Models

### TestScenario
```dart
class TestScenario extends Equatable {
  final String scenarioId;
  final String description;
  final TestType type;
  final List<TestStep> steps;
  final ExpectedOutcome expectedOutcome;
  final TestPriority priority;
  
  const TestScenario({
    required this.scenarioId,
    required this.description,
    required this.type,
    required this.steps,
    required this.expectedOutcome,
    required this.priority,
  });
  
  @override
  List<Object?> get props => [scenarioId, description, type, steps, expectedOutcome, priority];
}

enum TestType {
  unit,
  integration,
  widget,
  restoration
}

enum TestPriority {
  critical,    // Must pass for production readiness
  high,        // Important for debugging validation
  medium,      // Good coverage but not blocking
  low          // Nice to have coverage
}
```

### TestStep
```dart
class TestStep extends Equatable {
  final String stepId;
  final String action;
  final Map<String, dynamic> parameters;
  final String expectedResult;
  final Duration? timeout;
  
  const TestStep({
    required this.stepId,
    required this.action,
    required this.parameters,
    required this.expectedResult,
    this.timeout,
  });
  
  @override
  List<Object?> get props => [stepId, action, parameters, expectedResult, timeout];
}
```

### CoverageTarget
```dart
class CoverageTarget extends Equatable {
  final String filePath;
  final String className;
  final String methodName;
  final double targetCoverage;
  final double currentCoverage;
  final CoverageStatus status;
  final List<String> uncoveredLines;
  
  const CoverageTarget({
    required this.filePath,
    required this.className,
    required this.methodName,
    required this.targetCoverage,
    required this.currentCoverage,
    required this.status,
    required this.uncoveredLines,
  });
  
  bool get isAchieved => currentCoverage >= targetCoverage;
  
  @override
  List<Object?> get props => [filePath, className, methodName, targetCoverage, currentCoverage, status, uncoveredLines];
}

enum CoverageStatus {
  notStarted,
  inProgress,
  achieved,
  failed
}
```

### DebuggingModification
```dart
class DebuggingModification extends Equatable {
  final String modificationId;
  final String filePath;
  final String description;
  final ModificationType type;
  final List<String> affectedMethods;
  final bool isProductionReady;
  final String? restorationNotes;
  
  const DebuggingModification({
    required this.modificationId,
    required this.filePath,
    required this.description,
    required this.type,
    required this.affectedMethods,
    required this.isProductionReady,
    this.restorationNotes,
  });
  
  @override
  List<Object?> get props => [modificationId, filePath, description, type, affectedMethods, isProductionReady, restorationNotes];
}

enum ModificationType {
  gpsBypass,
  cacheClearing,
  coordinateValidation,
  debugLogging
}
```

### TestConfiguration
```dart
class TestConfiguration extends Equatable {
  final String configId;
  final String environment;
  final Map<String, dynamic> settings;
  final List<String> requiredMocks;
  final Duration defaultTimeout;
  final bool enableLogging;
  
  const TestConfiguration({
    required this.configId,
    required this.environment,
    required this.settings,
    required this.requiredMocks,
    required this.defaultTimeout,
    required this.enableLogging,
  });
  
  @override
  List<Object?> get props => [configId, environment, settings, requiredMocks, defaultTimeout, enableLogging];
}
```

### ExpectedOutcome
```dart
class ExpectedOutcome extends Equatable {
  final String outcomeId;
  final String description;
  final OutcomeType type;
  final Map<String, dynamic> criteria;
  final String validationMethod;
  
  const ExpectedOutcome({
    required this.outcomeId,
    required this.description,
    required this.type,
    required this.criteria,
    required this.validationMethod,
  });
  
  @override
  List<Object?> get props => [outcomeId, description, type, criteria, validationMethod];
}

enum OutcomeType {
  coordinateValue,
  cacheState,
  coverageThreshold,
  errorHandling,
  performanceMetric
}
```

## State Transitions

### Test Execution States
```dart
enum TestExecutionState {
  pending,      // Test not yet started
  running,      // Test currently executing  
  passed,       // Test completed successfully
  failed,       // Test failed validation
  skipped,      // Test skipped due to conditions
  error         // Test encountered execution error
}
```

### Coverage Validation Flow
```
notStarted -> inProgress -> (achieved | failed)
    ^                           |
    |___________________________|
              (on retry)
```

### Test Scenario Flow
```
pending -> running -> (passed | failed | error)
    ^                      |
    |______________________|
         (on rerun)
```

## Validation Rules

### Test Scenario Validation
- `scenarioId` must be unique within test suite
- `steps` must not be empty
- `expectedOutcome` must have valid validation criteria
- `priority` determines execution order (critical first)

### Coverage Target Validation
- `targetCoverage` must be between 0.0 and 1.0
- `currentCoverage` must be between 0.0 and 1.0
- `filePath` must exist in project structure
- `uncoveredLines` must reference valid line numbers

### Debugging Modification Validation
- `filePath` must exist and contain the referenced methods
- `affectedMethods` must exist in the specified file
- `isProductionReady` determines if restoration tests are required
- `restorationNotes` required when `isProductionReady` is false

## Integration Points

### LocationResolver Integration
- TestScenarios validate GPS bypass behavior
- DebuggingModification tracks coordinate changes
- ExpectedOutcome validates Aviemore coordinates (57.2, -3.8)

### SharedPreferences Integration  
- TestScenarios validate cache clearing (5 keys)
- CoverageTarget tracks enhanced clearing method coverage
- ExpectedOutcome validates cache state before/after

### Coverage Analysis Integration
- CoverageTarget integrates with lcov.info data
- TestConfiguration specifies coverage reporting settings
- TestScenario validates coverage thresholds

---
*Data model complete - proceeding to contracts generation*