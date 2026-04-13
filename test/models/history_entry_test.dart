import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/data/models/history_entry.dart';
import 'package:vocaviz/data/models/analysis_result.dart';

void main() {
  group('HistoryEntry', () {
    test('creates valid instance', () {
      final entry = HistoryEntry(
        id: 'test-123',
        timestamp: DateTime(2024, 1, 1, 12, 0),
        issueType: 'loose_belt',
        confidence: 0.85,
        summary: 'Test summary',
        imagePath: '/path/to/image.jpg',
        completedRepair: false,
      );

      expect(entry.id, 'test-123');
      expect(entry.issueType, 'loose_belt');
      expect(entry.confidence, 0.85);
      expect(entry.completedRepair, false);
    });

    test('fromAnalysisResult creates entry with correct values', () {
      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'worn_belt',
        confidence: 0.92,
        summary: 'Belt wear detected',
        detections: [],
        repairSteps: [],
        stopConditions: [],
        timestamp: DateTime(2024, 1, 1, 10, 0),
      );

      final entry = HistoryEntry.fromAnalysisResult(
        result,
        imagePath: 'captured',
        completedRepair: true,
      );

      expect(entry.issueType, 'worn_belt');
      expect(entry.confidence, 0.92);
      expect(entry.summary, 'Belt wear detected');
      expect(entry.imagePath, 'captured');
      expect(entry.completedRepair, true);
    });

    test('issueTitle formats correctly', () {
      final entry = HistoryEntry(
        id: '1',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'test',
      );

      expect(entry.issueTitle, 'Loose Belt');
    });

    test('issueTitle handles multiple underscores', () {
      final entry = HistoryEntry(
        id: '1',
        timestamp: DateTime.now(),
        issueType: 'severe_belt_damage',
        confidence: 0.8,
        summary: 'test',
      );

      expect(entry.issueTitle, 'Severe Belt Damage');
    });

    test('confidencePercent returns formatted string', () {
      final entry = HistoryEntry(
        id: '1',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.87,
        summary: 'test',
      );

      expect(entry.confidencePercent, '87%');
    });

    test('relativeTime shows "Just now" for recent entries', () {
      final entry = HistoryEntry(
        id: '1',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'test',
      );

      expect(entry.relativeTime, 'Just now');
    });

    test('relativeTime shows minutes ago', () {
      final entry = HistoryEntry(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'test',
      );

      expect(entry.relativeTime, '15m ago');
    });

    test('relativeTime shows hours ago', () {
      final entry = HistoryEntry(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'test',
      );

      expect(entry.relativeTime, '5h ago');
    });

    test('relativeTime shows days ago', () {
      final entry = HistoryEntry(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'test',
      );

      expect(entry.relativeTime, '3d ago');
    });

    test('relativeTime shows date for old entries', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      final entry = HistoryEntry(
        id: '1',
        timestamp: oldDate,
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'test',
      );

      expect(entry.relativeTime, contains('/'));
    });

    test('toJson serializes correctly', () {
      final entry = HistoryEntry(
        id: 'test-456',
        timestamp: DateTime(2024, 1, 1, 12, 0),
        issueType: 'misaligned_belt',
        confidence: 0.78,
        summary: 'Alignment issue',
        imagePath: null,
        completedRepair: true,
      );

      final json = entry.toJson();

      expect(json['id'], 'test-456');
      expect(json['issue_type'], 'misaligned_belt');
      expect(json['confidence'], 0.78);
      expect(json['completed_repair'], true);
      expect(json['image_path'], isNull);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'test-789',
        'timestamp': '2024-01-15T10:30:00.000Z',
        'issue_type': 'worn_belt',
        'confidence': 0.91,
        'summary': 'Wear detected',
        'image_path': '/images/worn.jpg',
        'completed_repair': false,
      };

      final entry = HistoryEntry.fromJson(json);

      expect(entry.id, 'test-789');
      expect(entry.issueType, 'worn_belt');
      expect(entry.confidence, 0.91);
      expect(entry.summary, 'Wear detected');
      expect(entry.imagePath, '/images/worn.jpg');
      expect(entry.completedRepair, false);
    });

    test('fromJson handles missing completed_repair with default', () {
      final json = {
        'id': 'test-000',
        'timestamp': '2024-01-15T10:30:00.000Z',
        'issue_type': 'loose_belt',
        'confidence': 0.8,
        'summary': 'test',
      };

      final entry = HistoryEntry.fromJson(json);
      expect(entry.completedRepair, false);
    });

    test('copyWith creates modified copy', () {
      final original = HistoryEntry(
        id: 'original',
        timestamp: DateTime(2024, 1, 1),
        issueType: 'loose_belt',
        confidence: 0.8,
        summary: 'original',
        completedRepair: false,
      );

      final updated = original.copyWith(
        completedRepair: true,
        summary: 'updated summary',
      );

      expect(updated.id, 'original');
      expect(updated.completedRepair, true);
      expect(updated.summary, 'updated summary');
      expect(updated.issueType, 'loose_belt'); // unchanged
    });
  });
}
