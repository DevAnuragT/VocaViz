import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/data/models/detection.dart';

void main() {
  group('Detection', () {
    test('isValid returns true for normalized coordinates', () {
      final detection = Detection(
        label: 'belt',
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
        severity: 'medium',
      );

      expect(detection.isValid, isTrue);
    });

    test('isValid returns false for out-of-range coordinates', () {
      final detection = Detection(
        label: 'belt',
        x: -0.1,
        y: 1.2,
        width: 0.3,
        height: 0.4,
      );

      expect(detection.isValid, isFalse);
    });

    test('fromJson parses and clamps values defensively', () {
      final detection = Detection.fromJson({
        'label': 'worn_area',
        'x': -10,
        'y': '0.75',
        'width': 200,
        'height': 'bad',
        'severity': 'critical',
      });

      expect(detection.label, 'worn_area');
      expect(detection.x, 0.0);
      expect(detection.y, 0.75);
      expect(detection.width, 1.0);
      expect(detection.height, 0.3);
      expect(detection.severity, 'low');
    });

    test('toJson serializes fields correctly', () {
      final detection = Detection(
        label: 'misalignment_zone',
        x: 0.4,
        y: 0.5,
        width: 0.2,
        height: 0.1,
        severity: 'high',
      );

      final json = detection.toJson();

      expect(json['label'], 'misalignment_zone');
      expect(json['x'], 0.4);
      expect(json['y'], 0.5);
      expect(json['width'], 0.2);
      expect(json['height'], 0.1);
      expect(json['severity'], 'high');
    });
  });
}
