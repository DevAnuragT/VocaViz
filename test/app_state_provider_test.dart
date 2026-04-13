import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocaviz/data/models/analysis_result.dart';
import 'package:vocaviz/data/models/history_entry.dart';
import 'package:vocaviz/data/models/repair_step.dart';
import 'package:vocaviz/providers/app_state_provider.dart';

void main() {
  group('AppController', () {
    test('initial state is home with empty session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appStateProvider);

      expect(state.currentScreen, AppScreen.home);
      expect(state.capturedImage, isNull);
      expect(state.lastResult, isNull);
      expect(state.analysisScenario, isNull);
    });

    test('navigation updates current screen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appStateProvider.notifier).navigateTo(AppScreen.analysis);

      expect(container.read(appStateProvider).currentScreen, AppScreen.analysis);
    });

    test('setImage updates bytes/source and clears scenario by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appStateProvider.notifier).setAnalysisScenario('worn_belt');
      container.read(appStateProvider.notifier).setImage(
            Uint8List.fromList([1, 2, 3]),
            'camera',
          );

      final state = container.read(appStateProvider);
      expect(state.capturedImage, isNotNull);
      expect(state.imageSource, 'camera');
      expect(state.analysisScenario, isNull);
    });

    test('setImage can preserve scenario for sample flow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appStateProvider.notifier).setAnalysisScenario('misaligned_belt');
      container.read(appStateProvider.notifier).setImage(
            Uint8List.fromList([4, 5, 6]),
            'sample',
            clearScenario: false,
          );

      expect(container.read(appStateProvider).analysisScenario, 'misaligned_belt');
    });

    test('setResult and history entry are stored', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = AnalysisResult(
        machineType: 'belt_driven_water_pump',
        issueType: 'loose_belt',
        confidence: 0.9,
        summary: 'Loose belt detected',
        detections: const [],
        repairSteps: [
          RepairStep(stepNumber: 1, title: 'Step', instruction: 'Instruction'),
        ],
        stopConditions: const [],
      );

      final entry = HistoryEntry(
        id: 'entry-1',
        timestamp: DateTime.now(),
        issueType: 'loose_belt',
        confidence: 0.9,
        summary: 'Loose belt detected',
      );

      final notifier = container.read(appStateProvider.notifier);
      notifier.setResult(result);
      notifier.setHistoryEntry(entry);

      final state = container.read(appStateProvider);
      expect(state.lastResult?.issueType, 'loose_belt');
      expect(state.currentHistoryEntry?.id, 'entry-1');
    });

    test('clearSession keeps current screen but clears session payload', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appStateProvider.notifier);

      notifier.navigateTo(AppScreen.repair);
      notifier.setImage(Uint8List.fromList([1, 2]), 'camera');
      notifier.setResult(
        AnalysisResult(
          machineType: 'belt_driven_water_pump',
          issueType: 'worn_belt',
          confidence: 0.8,
          summary: 'Test',
          detections: const [],
          repairSteps: [
            RepairStep(stepNumber: 1, title: 'Step', instruction: 'Instruction'),
          ],
          stopConditions: const [],
        ),
      );

      notifier.clearSession();
      final state = container.read(appStateProvider);

      expect(state.currentScreen, AppScreen.repair);
      expect(state.capturedImage, isNull);
      expect(state.lastResult, isNull);
    });
  });
}
