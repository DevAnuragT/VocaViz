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
  final LocalModelStatus? localModelStatus;

  const AnalysisState({
    this.isAnalyzing = false,
    this.result,
    this.error,
    this.localModelStatus,
  });

  AnalysisState copyWith({
    bool? isAnalyzing,
    AnalysisResult? result,
    String? error,
    LocalModelStatus? localModelStatus,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return AnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      localModelStatus: localModelStatus ?? this.localModelStatus,
    );
  }
}

class AnalysisController extends StateNotifier<AnalysisState> {
  final InferenceService _inferenceService;

  AnalysisController({InferenceService? inferenceService})
      : _inferenceService = inferenceService ?? InferenceService(),
        super(const AnalysisState());

  /// Check local model availability and update state.
  Future<LocalModelStatus> checkLocalModel() async {
    final status = await _inferenceService.checkLocalModelAvailability();
    state = state.copyWith(localModelStatus: status);
    return status;
  }

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
      // Select inference mode based on config
      if (EnvConfig.isRemoteMode) {
        _inferenceService.mode = InferenceMode.remote;
        final apiKey = EnvConfig.apiKey!;
        _inferenceService.configureRemote(
          apiKey,
          modelName: EnvConfig.model,
        );
        AppLogger.i('Using remote Gemma inference (model: ${EnvConfig.model})', 'AnalysisController');
      } else if (EnvConfig.isLocalMode) {
        _inferenceService.mode = InferenceMode.local;
        // Check and initialize local model
        final status = await checkLocalModel();
        if (status == LocalModelStatus.ready) {
          await _inferenceService.initializeLocalModel();
          AppLogger.i('Using local Gemma 4 inference', 'AnalysisController');
        } else {
          AppLogger.w('Local mode requested but model not ready (status: $status). Falling back to mock.', 'AnalysisController');
        }
      } else {
        _inferenceService.mode = InferenceMode.mock;
        AppLogger.i('Using mock inference (mode=${EnvConfig.mode})', 'AnalysisController');
      }

      final result = await _inferenceService.analyze(
        imageBytes: imageBytes,
        scenario: scenario,
      );

      state = state.copyWith(
        isAnalyzing: false,
        result: result,
        clearError: true,
        localModelStatus: _inferenceService.localModelStatus,
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
