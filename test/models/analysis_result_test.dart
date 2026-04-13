import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/data/models/analysis_result.dart';
import 'package:vocaviz/data/models/detection.dart';
import 'package:vocaviz/data/models/repair_step.dart';

void main() {
  group('AnalysisResult', () {
    test('creates valid instance', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'loose_belt',
        confidence: 0.85,
        summary: 'Test summary',
        detections: [],
        repairSteps: [
          RepairStep(stepNumber: 1, title: 'Test', instruction: 'Do test'),
        ],
        stopConditions: [],
      );

      expect(result.machineType, 'belt_driven_water_pump');
      expect(result.issueType, 'loose_belt');
      expect(result.confidence, 0.85);
      expect(result.summary, 'Test summary');
      expect(result.isLowConfidence, false);
      expect(result.requiresTechnician, false);
    });

    test('isLowConfidence returns true when confidence < 0.5', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'unknown',
        confidence: 0.3,
        summary: 'Low confidence',
        detections: [],
        repairSteps: [],
        stopConditions: [],
      );

      expect(result.isLowConfidence, true);
    });

    test('requiresTechnician returns true when issueType is unknown', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'unknown',
        confidence: 0.8,
        summary: 'Unknown issue',
        detections: [],
        repairSteps: [],
        stopConditions: [],
      );

      expect(result.requiresTechnician, true);
    });

    test('requiresTechnician returns true when repairSteps is empty', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'No steps',
        detections: [],
        repairSteps: [],
        stopConditions: [],
      );

      expect(result.requiresTechnician, true);
    });

    test('primaryDetection returns highest severity detection', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'Test',
        detections: [
          Detection(label: 'belt', x: 0.1, y: 0.1, width: 0.2, height: 0.2, severity: 'low'),
          Detection(label: 'sag', x: 0.2, y: 0.2, width: 0.2, height: 0.2, severity: 'high'),
          Detection(label: 'pulley', x: 0.3, y: 0.3, width: 0.2, height: 0.2, severity: 'medium'),
        ],
        repairSteps: [],
        stopConditions: [],
      );

      expect(result.primaryDetection?.label, 'sag');
      expect(result.primaryDetection?.severity, 'high');
    });

    test('primaryDetection returns null when no detections', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'Test',
        detections: [],
        repairSteps: [],
        stopConditions: [],
      );

      expect(result.primaryDetection, isNull);
    });

    test('toJson serializes correctly', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'loose_belt',
        confidence: 0.85,
        summary: 'Test summary',
        detections: [],
        repairSteps: [],
        stopConditions: ['condition1'],
      );

      final json = result.toJson();

      expect(json['machine_type'], 'belt_driven_water_pump');
      expect(json['issue_type'], 'loose_belt');
      expect(json['confidence'], 0.85);
      expect(json['summary'], 'Test summary');
      expect(json['stop_conditions'], ['condition1']);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'machine_type': 'belt_driven_water_pump',
        'issue_type': 'worn_belt',
        'confidence': 0.92,
        'summary': 'Parsed summary',
        'detections': [],
        'repair_steps': [],
        'stop_conditions': ['stop1'],
      };

      final result = AnalysisResult.fromJson(json);

      expect(result.machineType, 'belt_driven_water_pump');
      expect(result.issueType, 'worn_belt');
      expect(result.confidence, 0.92);
      expect(result.summary, 'Parsed summary');
      expect(result.stopConditions, ['stop1']);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final result = AnalysisResult.fromJson(json);

      expect(result.machineType, 'unknown');
      expect(result.issueType, 'unknown');
      expect(result.confidence, 0.5);
      expect(result.summary, 'Analysis complete');
    });

    test('fromJson parses confidence from string', () {
      final json = {
        'machine_type': 'belt_driven_water_pump',
        'issue_type': 'loose_belt',
        'confidence': '0.75',
        'summary': 'Test',
        'detections': [],
        'repair_steps': [],
        'stop_conditions': [],
      };

      final result = AnalysisResult.fromJson(json);
      expect(result.confidence, 0.75);
    });

    test('fromJson parses confidence from int', () {
      final json = {
        'machine_type': 'belt_driven_water_pump',
        'issue_type': 'loose_belt',
        'confidence': 85,
        'summary': 'Test',
        'detections': [],
        'repair_steps': [],
        'stop_conditions': [],
      };

      final result = AnalysisResult.fromJson(json);
      expect(result.confidence, 0.85);
    });

    test('lowConfidence factory creates correct result', () {
      final result = AnalysisResult.lowConfidence('Test reason');

      expect(result.issueType, 'unknown');
      expect(result.confidence, 0.3);
      expect(result.summary, contains('Test reason'));
      expect(result.detections, isEmpty);
      expect(result.repairSteps, isEmpty);
    });

    test('technicianRequired factory creates correct result', () {
      final result = AnalysisResult.technicianRequired('Needs expert');

      expect(result.issueType, 'unknown');
      expect(result.confidence, 0.4);
      expect(result.summary, contains('Needs expert'));
      expect(result.repairSteps, isEmpty);
      expect(result.stopConditions, contains('Needs expert'));
    });

    test('timestamp is set on creation', () {
      final before = DateTime.now();
      final result = AnalysisResult(
        machineType: 'pump',
        issueType: 'fault',
        confidence: 0.5,
        summary: 'test',
        detections: [],
        repairSteps: [],
        stopConditions: [],
      );
      final after = DateTime.now();

      expect(result.timestamp.isAfter(before), true);
      expect(result.timestamp.isBefore(after) || result.timestamp.isAtSameMomentAs(after), true);
    });

    test('custom timestamp is preserved', () {
      final customTime = DateTime(2024, 1, 1, 12, 0);
      final result = AnalysisResult(
        machineType: 'pump',
        issueType: 'fault',
        confidence: 0.5,
        summary: 'test',
        detections: [],
        repairSteps: [],
        stopConditions: [],
        timestamp: customTime,
      );

      expect(result.timestamp, equals(customTime));
    });
  });
}
