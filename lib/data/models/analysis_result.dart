import 'detection.dart';
import 'repair_step.dart';

/// Structured result from image analysis.
/// This is the core output contract for the inference layer.
class AnalysisResult {
  final String machineType;
  final String issueType;
  final double confidence;
  final String summary;
  final List<Detection> detections;
  final List<RepairStep> repairSteps;
  final List<String> stopConditions;
  final DateTime timestamp;

  AnalysisResult({
    required this.machineType,
    required this.issueType,
    required this.confidence,
    required this.summary,
    required this.detections,
    required this.repairSteps,
    required this.stopConditions,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Check if confidence is too low to proceed
  bool get isLowConfidence => confidence < 0.5;

  /// Known issues can still include stop conditions without blocking repair.
  bool get requiresTechnician => issueType == 'unknown' || repairSteps.isEmpty;

  /// Get the primary detection (first or highest severity)
  Detection? get primaryDetection {
    if (detections.isEmpty) return null;

    // Prioritize by severity
    const severityOrder = {'high': 3, 'medium': 2, 'low': 1};
    return detections.reduce((a, b) {
      return (severityOrder[a.severity] ?? 0) >= (severityOrder[b.severity] ?? 0) ? a : b;
    });
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      machineType: json['machine_type'] as String? ?? 'unknown',
      issueType: json['issue_type'] as String? ?? 'unknown',
      confidence: _parseConfidence(json['confidence']),
      summary: json['summary'] as String? ?? 'Analysis complete',
      detections: (json['detections'] as List?)
          ?.map((d) => Detection.fromJson(d as Map<String, dynamic>))
          .toList() ?? [],
      repairSteps: (json['repair_steps'] as List?)
          ?.map((s) => RepairStep.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      stopConditions: List<String>.from(json['stop_conditions'] as List? ?? []),
    );
  }

  static double _parseConfidence(dynamic value) {
    if (value == null) return 0.5;
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is int) return (value / 100.0).clamp(0.0, 1.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.clamp(0.0, 1.0) ?? 0.5;
    }
    return 0.5;
  }

  Map<String, dynamic> toJson() {
    return {
      'machine_type': machineType,
      'issue_type': issueType,
      'confidence': confidence,
      'summary': summary,
      'detections': detections.map((d) => d.toJson()).toList(),
      'repair_steps': repairSteps.map((s) => s.toJson()).toList(),
      'stop_conditions': stopConditions,
    };
  }

  /// Create a low-confidence result for uncertainty flows
  factory AnalysisResult.lowConfidence(String reason) {
    return AnalysisResult(
      machineType: 'belt_driven_water_pump',
      issueType: 'unknown',
      confidence: 0.3,
      summary: 'Unable to confidently identify the issue. $reason',
      detections: [],
      repairSteps: [],
      stopConditions: ['Image quality insufficient for reliable analysis'],
    );
  }

  /// Create a result indicating technician is needed
  factory AnalysisResult.technicianRequired(String reason) {
    return AnalysisResult(
      machineType: 'belt_driven_water_pump',
      issueType: 'unknown',
      confidence: 0.4,
      summary: 'This issue requires a qualified technician. $reason',
      detections: [],
      repairSteps: [],
      stopConditions: [reason, 'Contact a qualified repair technician'],
    );
  }
}
