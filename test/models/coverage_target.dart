import 'package:equatable/equatable.dart';

/// Coverage target entity for debugging tests
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
  
  /// Check if coverage target is achieved
  bool get isAchieved => currentCoverage >= targetCoverage;

  /// Get coverage percentage as string
  String get coveragePercentage => '${(currentCoverage * 100).toStringAsFixed(1)}%';

  /// Get target percentage as string
  String get targetPercentage => '${(targetCoverage * 100).toStringAsFixed(1)}%';

  /// Get coverage gap
  double get coverageGap => targetCoverage - currentCoverage;

  /// Check if coverage is critically low (< 50% of target)
  bool get isCriticallyLow => currentCoverage < (targetCoverage * 0.5);
  
  @override
  List<Object?> get props => [filePath, className, methodName, targetCoverage, currentCoverage, status, uncoveredLines];

  /// Create a copy with modified properties
  CoverageTarget copyWith({
    String? filePath,
    String? className,
    String? methodName,
    double? targetCoverage,
    double? currentCoverage,
    CoverageStatus? status,
    List<String>? uncoveredLines,
  }) {
    return CoverageTarget(
      filePath: filePath ?? this.filePath,
      className: className ?? this.className,
      methodName: methodName ?? this.methodName,
      targetCoverage: targetCoverage ?? this.targetCoverage,
      currentCoverage: currentCoverage ?? this.currentCoverage,
      status: status ?? this.status,
      uncoveredLines: uncoveredLines ?? this.uncoveredLines,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'className': className,
      'methodName': methodName,
      'targetCoverage': targetCoverage,
      'currentCoverage': currentCoverage,
      'status': status.name,
      'uncoveredLines': uncoveredLines,
    };
  }

  /// Create from JSON
  factory CoverageTarget.fromJson(Map<String, dynamic> json) {
    return CoverageTarget(
      filePath: json['filePath'] as String,
      className: json['className'] as String,
      methodName: json['methodName'] as String,
      targetCoverage: (json['targetCoverage'] as num).toDouble(),
      currentCoverage: (json['currentCoverage'] as num).toDouble(),
      status: CoverageStatus.values.firstWhere((s) => s.name == json['status']),
      uncoveredLines: List<String>.from(json['uncoveredLines'] as List),
    );
  }

  /// Validate coverage target
  bool get isValid {
    return filePath.isNotEmpty &&
           className.isNotEmpty &&
           methodName.isNotEmpty &&
           targetCoverage >= 0.0 &&
           targetCoverage <= 1.0 &&
           currentCoverage >= 0.0 &&
           currentCoverage <= 1.0;
  }

  /// Get coverage report summary
  String get summaryReport {
    return '''
Coverage Target Report:
  File: $filePath
  Class: $className
  Method: $methodName
  Target: $targetPercentage
  Current: $coveragePercentage
  Status: ${status.name}
  Gap: ${(coverageGap * 100).toStringAsFixed(1)}%
  Uncovered Lines: ${uncoveredLines.length}
''';
  }

  /// Create coverage target for GPS bypass (100% requirement)
  factory CoverageTarget.gpsBypass({
    required double currentCoverage,
    required List<String> uncoveredLines,
  }) {
    return CoverageTarget(
      filePath: 'lib/services/location_resolver_impl.dart',
      className: 'LocationResolverImpl',
      methodName: 'getLatLon',
      targetCoverage: 1.0, // 100%
      currentCoverage: currentCoverage,
      status: currentCoverage >= 1.0 ? CoverageStatus.achieved : CoverageStatus.inProgress,
      uncoveredLines: uncoveredLines,
    );
  }

  /// Create coverage target for cache clearing (95% requirement)
  factory CoverageTarget.cacheClearing({
    required double currentCoverage,
    required List<String> uncoveredLines,
  }) {
    return CoverageTarget(
      filePath: 'lib/main.dart',
      className: 'MainApp',
      methodName: '_clearCachedLocation',
      targetCoverage: 0.95, // 95%
      currentCoverage: currentCoverage,
      status: currentCoverage >= 0.95 ? CoverageStatus.achieved : CoverageStatus.inProgress,
      uncoveredLines: uncoveredLines,
    );
  }

  /// Create coverage target for integration scenarios (90% requirement)
  factory CoverageTarget.integration({
    required String filePath,
    required String className,
    required double currentCoverage,
    required List<String> uncoveredLines,
  }) {
    return CoverageTarget(
      filePath: filePath,
      className: className,
      methodName: 'integrationScenario',
      targetCoverage: 0.90, // 90%
      currentCoverage: currentCoverage,
      status: currentCoverage >= 0.90 ? CoverageStatus.achieved : CoverageStatus.inProgress,
      uncoveredLines: uncoveredLines,
    );
  }
}

/// Coverage status enumeration
enum CoverageStatus {
  notStarted,
  inProgress,
  achieved,
  failed
}

/// Coverage analysis utilities
class CoverageAnalysis {
  /// Calculate overall coverage from multiple targets
  static double calculateOverallCoverage(List<CoverageTarget> targets) {
    if (targets.isEmpty) return 0.0;
    
    final totalCoverage = targets.fold<double>(
      0.0, 
      (sum, target) => sum + target.currentCoverage
    );
    
    return totalCoverage / targets.length;
  }

  /// Get coverage targets that are not achieved
  static List<CoverageTarget> getUnachievedTargets(List<CoverageTarget> targets) {
    return targets.where((target) => !target.isAchieved).toList();
  }

  /// Get critical coverage targets (< 50% of target)
  static List<CoverageTarget> getCriticalTargets(List<CoverageTarget> targets) {
    return targets.where((target) => target.isCriticallyLow).toList();
  }

  /// Generate coverage summary report
  static String generateSummaryReport(List<CoverageTarget> targets) {
    final overall = calculateOverallCoverage(targets);
    final unachieved = getUnachievedTargets(targets);
    final critical = getCriticalTargets(targets);

    return '''
Coverage Summary Report:
  Overall Coverage: ${(overall * 100).toStringAsFixed(1)}%
  Total Targets: ${targets.length}
  Achieved: ${targets.length - unachieved.length}
  Unachieved: ${unachieved.length}
  Critical: ${critical.length}

${unachieved.isNotEmpty ? 'Unachieved Targets:' : ''}
${unachieved.map((t) => '  - ${t.className}.${t.methodName}: ${t.coveragePercentage} (target: ${t.targetPercentage})').join('\n')}

${critical.isNotEmpty ? 'Critical Targets:' : ''}
${critical.map((t) => '  - ${t.className}.${t.methodName}: ${t.coveragePercentage} (target: ${t.targetPercentage})').join('\n')}
''';
  }
}