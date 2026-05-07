import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/services/inference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InferenceService', () {
    test('mock mode returns scenario-specific result', () async {
      final service = InferenceService(mode: InferenceMode.mock);

      final result = await service.analyze(
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        scenario: 'worn_belt',
      );

      expect(result.issueType, 'worn_belt');
      expect(result.machineType, 'belt_driven_water_pump');
      expect(result.detections, isNotEmpty);
      expect(result.repairSteps, isNotEmpty);
    });

    test('mock mode is deterministic for identical image bytes', () async {
      final service = InferenceService(mode: InferenceMode.mock);
      final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i % 256));

      final first = await service.analyze(imageBytes: bytes);
      final second = await service.analyze(imageBytes: bytes);

      expect(second.issueType, first.issueType);
      expect(second.summary, first.summary);
      expect(second.detections.length, first.detections.length);
    });

    test('local mode falls back to mock with diagnostic when local init fails', () async {
      final service = InferenceService(mode: InferenceMode.local);

      final result = await service.analyze(
        imageBytes: Uint8List.fromList([9, 8, 7, 6]),
      );

      expect(result.machineType, 'belt_driven_water_pump');
      // Should include a diagnostic note when local inference is unavailable
      expect(
        result.summary,
        anyOf(
          contains('Local Gemma 4 model not installed'),
          contains('Local model init failed'),
          contains('Local inference unavailable'),
          contains('Model still loading'),
        ),
      );
    });

    test('local mode status starts as notInitialized', () async {
      final service = InferenceService(mode: InferenceMode.local);
      expect(service.localModelStatus, LocalModelStatus.notInitialized);
    });

    test('checkLocalModelAvailability returns ready or artifactMissing', () async {
      final service = InferenceService(mode: InferenceMode.local);
      final status = await service.checkLocalModelAvailability();
      expect(
        [LocalModelStatus.ready, LocalModelStatus.artifactMissing],
        contains(status),
      );
      expect(
        [LocalModelStatus.ready, LocalModelStatus.artifactMissing],
        contains(service.localModelStatus),
      );
    });

    test('localModelError is set when model unavailable', () async {
      final service = InferenceService(mode: InferenceMode.local);
      final status = await service.checkLocalModelAvailability();
      if (status == LocalModelStatus.artifactMissing) {
        expect(service.localModelError, isNotNull);
        expect(service.localModelError.toString(), contains('not found'));
      }
    });
  });
}
