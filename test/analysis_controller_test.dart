import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/data/models/analysis_result.dart';
import 'package:vocaviz/data/models/repair_step.dart';
import 'package:vocaviz/features/inspection/providers/analysis_controller.dart';
import 'package:vocaviz/services/inference_service.dart';

class _FakeSuccessInferenceService extends InferenceService {
  final AnalysisResult _result;

  _FakeSuccessInferenceService(this._result) : super(mode: InferenceMode.mock);

  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    String? scenario,
  }) async {
    return _result;
  }
}

class _FakeFailureInferenceService extends InferenceService {
  _FakeFailureInferenceService() : super(mode: InferenceMode.mock);

  @override
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    String? scenario,
  }) async {
    throw StateError('fake inference failure');
  }
}

void main() {
  group('AnalysisController', () {
    test('emits analyzing then success state', () async {
      final expected = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'loose_belt',
        confidence: 0.91,
        summary: 'Detected loose belt',
        detections: const [],
        repairSteps: [
          RepairStep(stepNumber: 1, title: 'Step', instruction: 'Instruction'),
        ],
        stopConditions: const [],
      );

      final controller = AnalysisController(
        inferenceService: _FakeSuccessInferenceService(expected),
      );

      final container = ProviderContainer(
        overrides: [
          analysisControllerProvider.overrideWith((ref) => controller),
        ],
      );
      addTearDown(container.dispose);

      final states = <AnalysisState>[];
      container.listen<AnalysisState>(
        analysisControllerProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      await controller.analyze(
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        scenario: 'loose_belt',
      );

      final finalState = container.read(analysisControllerProvider);
      expect(states.any((s) => s.isAnalyzing), isTrue);
      expect(finalState.isAnalyzing, isFalse);
      expect(finalState.error, isNull);
      expect(finalState.result?.issueType, 'loose_belt');
    });

    test('sets error state when inference throws', () async {
      final controller = AnalysisController(
        inferenceService: _FakeFailureInferenceService(),
      );

      final container = ProviderContainer(
        overrides: [
          analysisControllerProvider.overrideWith((ref) => controller),
        ],
      );
      addTearDown(container.dispose);

      await controller.analyze(
        imageBytes: Uint8List.fromList([9, 9, 9]),
      );

      final finalState = container.read(analysisControllerProvider);
      expect(finalState.isAnalyzing, isFalse);
      expect(finalState.result, isNull);
      expect(finalState.error, isNotNull);
      expect(finalState.error, contains('Analysis failed'));
    });
  });
}
