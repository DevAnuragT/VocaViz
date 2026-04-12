import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/env_config.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/analysis_result.dart';
import '../../../services/inference_service.dart';

class AnalysisState {
  final bool isAnalyzing;
  final AnalysisResult? result;
  final String? error;

  const AnalysisState({
    this.isAnalyzing = false,
    this.result,
    this.error,
  });

  AnalysisState copyWith({
    bool? isAnalyzing,
    AnalysisResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return AnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AnalysisController extends StateNotifier<AnalysisState> {
  final InferenceService _inferenceService;

  AnalysisController({InferenceService? inferenceService})
      : _inferenceService = inferenceService ?? InferenceService(),
        super(const AnalysisState());

  Future<void> analyze({
    required Uint8List imageBytes,
    String? scenario,
  }) async {
    state = state.copyWith(
      isAnalyzing: true,
      clearError: true,
      clearResult: true,
    );

    try {
      if (EnvConfig.isRemoteMode) {
        _inferenceService.mode = InferenceMode.remote;
        final apiKey = EnvConfig.apiKey!;
        _inferenceService.configureRemote(apiKey);
        AppLogger.i('Using remote Gemma inference', 'AnalysisController');
      } else {
        _inferenceService.mode = InferenceMode.mock;
        AppLogger.i('Using mock inference (no API key or mode=mock)', 'AnalysisController');
      }

      final result = await _inferenceService.analyze(
        imageBytes: imageBytes,
        scenario: scenario,
      );

      state = state.copyWith(
        isAnalyzing: false,
        result: result,
        clearError: true,
      );
    } catch (error) {
      AppLogger.e('Analysis failed', 'AnalysisController', error);
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Analysis failed: ${error.toString()}',
        clearResult: true,
      );
    }
  }
}

final analysisControllerProvider =
    StateNotifierProvider.autoDispose<AnalysisController, AnalysisState>(
  (ref) => AnalysisController(),
);
