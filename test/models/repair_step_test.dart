import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/data/models/repair_step.dart';

void main() {
  group('RepairStep', () {
    test('fromJson parses full payload', () {
      final step = RepairStep.fromJson({
        'step': 3,
        'title': 'Adjust tension',
        'instruction': 'Move motor away from pulley',
        'warning': 'Power must stay off',
      });

      expect(step.stepNumber, 3);
      expect(step.title, 'Adjust tension');
      expect(step.instruction, 'Move motor away from pulley');
      expect(step.warning, 'Power must stay off');
    });

    test('fromJson applies safe defaults for missing fields', () {
      final step = RepairStep.fromJson({});

      expect(step.stepNumber, 0);
      expect(step.title, 'Unknown Step');
      expect(step.instruction, '');
      expect(step.warning, isNull);
    });

    test('toJson serializes correctly', () {
      final step = RepairStep(
        stepNumber: 2,
        title: 'Loosen bolts',
        instruction: 'Use wrench to loosen motor mount bolts',
        warning: null,
      );

      final json = step.toJson();

      expect(json['step'], 2);
      expect(json['title'], 'Loosen bolts');
      expect(json['instruction'], 'Use wrench to loosen motor mount bolts');
      expect(json['warning'], isNull);
    });
  });
}
