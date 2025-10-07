import 'package:equatable/equatable.dart';

/// Test scenario entity for debugging tests
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

  /// Create a copy with modified properties
  TestScenario copyWith({
    String? scenarioId,
    String? description,
    TestType? type,
    List<TestStep>? steps,
    ExpectedOutcome? expectedOutcome,
    TestPriority? priority,
  }) {
    return TestScenario(
      scenarioId: scenarioId ?? this.scenarioId,
      description: description ?? this.description,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      expectedOutcome: expectedOutcome ?? this.expectedOutcome,
      priority: priority ?? this.priority,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'scenarioId': scenarioId,
      'description': description,
      'type': type.name,
      'steps': steps.map((step) => step.toJson()).toList(),
      'expectedOutcome': expectedOutcome.toJson(),
      'priority': priority.name,
    };
  }

  /// Create from JSON
  factory TestScenario.fromJson(Map<String, dynamic> json) {
    return TestScenario(
      scenarioId: json['scenarioId'] as String,
      description: json['description'] as String,
      type: TestType.values.firstWhere((t) => t.name == json['type']),
      steps: (json['steps'] as List)
          .map((step) => TestStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      expectedOutcome: ExpectedOutcome.fromJson(json['expectedOutcome'] as Map<String, dynamic>),
      priority: TestPriority.values.firstWhere((p) => p.name == json['priority']),
    );
  }

  /// Validate scenario completeness
  bool get isValid {
    return scenarioId.isNotEmpty &&
           description.isNotEmpty &&
           steps.isNotEmpty &&
           steps.every((step) => step.isValid);
  }

  /// Get estimated execution time in seconds
  int get estimatedExecutionTimeSeconds {
    return steps.fold(0, (total, step) => 
        total + (step.timeout?.inSeconds ?? 5));
  }

  /// Check if scenario is critical for production readiness
  bool get isCritical => priority == TestPriority.critical;
}

/// Test type enumeration
enum TestType {
  unit,
  integration,
  widget,
  restoration
}

/// Test priority enumeration  
enum TestPriority {
  critical,    // Must pass for production readiness
  high,        // Important for debugging validation
  medium,      // Good coverage but not blocking
  low          // Nice to have coverage
}

/// Test step entity
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

  /// Create a copy with modified properties
  TestStep copyWith({
    String? stepId,
    String? action,
    Map<String, dynamic>? parameters,
    String? expectedResult,
    Duration? timeout,
  }) {
    return TestStep(
      stepId: stepId ?? this.stepId,
      action: action ?? this.action,
      parameters: parameters ?? this.parameters,
      expectedResult: expectedResult ?? this.expectedResult,
      timeout: timeout ?? this.timeout,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'action': action,
      'parameters': parameters,
      'expectedResult': expectedResult,
      'timeoutSeconds': timeout?.inSeconds,
    };
  }

  /// Create from JSON
  factory TestStep.fromJson(Map<String, dynamic> json) {
    return TestStep(
      stepId: json['stepId'] as String,
      action: json['action'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      expectedResult: json['expectedResult'] as String,
      timeout: json['timeoutSeconds'] != null 
          ? Duration(seconds: json['timeoutSeconds'] as int)
          : null,
    );
  }

  /// Validate step completeness
  bool get isValid {
    return stepId.isNotEmpty &&
           action.isNotEmpty &&
           expectedResult.isNotEmpty;
  }
}

/// Expected outcome entity
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

  /// Create a copy with modified properties
  ExpectedOutcome copyWith({
    String? outcomeId,
    String? description,
    OutcomeType? type,
    Map<String, dynamic>? criteria,
    String? validationMethod,
  }) {
    return ExpectedOutcome(
      outcomeId: outcomeId ?? this.outcomeId,
      description: description ?? this.description,
      type: type ?? this.type,
      criteria: criteria ?? this.criteria,
      validationMethod: validationMethod ?? this.validationMethod,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'outcomeId': outcomeId,
      'description': description,
      'type': type.name,
      'criteria': criteria,
      'validationMethod': validationMethod,
    };
  }

  /// Create from JSON
  factory ExpectedOutcome.fromJson(Map<String, dynamic> json) {
    return ExpectedOutcome(
      outcomeId: json['outcomeId'] as String,
      description: json['description'] as String,
      type: OutcomeType.values.firstWhere((t) => t.name == json['type']),
      criteria: Map<String, dynamic>.from(json['criteria'] as Map),
      validationMethod: json['validationMethod'] as String,
    );
  }

  /// Validate outcome completeness
  bool get isValid {
    return outcomeId.isNotEmpty &&
           description.isNotEmpty &&
           criteria.isNotEmpty &&
           validationMethod.isNotEmpty;
  }
}

/// Outcome type enumeration
enum OutcomeType {
  coordinateValue,
  cacheState,
  coverageThreshold,
  errorHandling,
  performanceMetric
}