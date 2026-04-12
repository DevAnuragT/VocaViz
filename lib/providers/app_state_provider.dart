import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/analysis_result.dart';
import '../data/models/history_entry.dart';

/// App-level navigation and session state.
class AppState {
  final AppScreen currentScreen;
  final Uint8List? capturedImage;
  final String imageSource;
  final String? analysisScenario;
  final AnalysisResult? lastResult;
  final HistoryEntry? currentHistoryEntry;

  const AppState({
    this.currentScreen = AppScreen.home,
    this.capturedImage,
    this.imageSource = 'camera',
    this.analysisScenario,
    this.lastResult,
    this.currentHistoryEntry,
  });

  AppState copyWith({
    AppScreen? currentScreen,
    Uint8List? capturedImage,
    String? imageSource,
    String? analysisScenario,
    AnalysisResult? lastResult,
    HistoryEntry? currentHistoryEntry,
    bool clearImage = false,
    bool clearResult = false,
  }) {
    return AppState(
      currentScreen: currentScreen ?? this.currentScreen,
      capturedImage: clearImage ? null : (capturedImage ?? this.capturedImage),
      imageSource: imageSource ?? this.imageSource,
      analysisScenario: analysisScenario ?? this.analysisScenario,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      currentHistoryEntry: currentHistoryEntry ?? this.currentHistoryEntry,
    );
  }
}

class AppController extends StateNotifier<AppState> {
  AppController() : super(const AppState());

  void navigateTo(AppScreen screen) {
    state = state.copyWith(currentScreen: screen);
  }

  void setImage(Uint8List bytes, String source) {
    state = state.copyWith(
      capturedImage: bytes,
      imageSource: source,
      analysisScenario: null,
    );
  }

  void setAnalysisScenario(String scenario) {
    state = state.copyWith(analysisScenario: scenario);
  }

  void setResult(AnalysisResult result) {
    state = state.copyWith(lastResult: result);
  }

  void setHistoryEntry(HistoryEntry entry) {
    state = state.copyWith(currentHistoryEntry: entry);
  }

  void updateHistoryEntry(HistoryEntry entry) {
    state = state.copyWith(currentHistoryEntry: entry);
  }

  void clearSession() {
    state = const AppState().copyWith(currentScreen: state.currentScreen);
  }
}

final appStateProvider =
    StateNotifierProvider<AppController, AppState>((ref) => AppController());

enum AppScreen {
  home,
  camera,
  analysis,
  safety,
  repair,
  summary,
  samples,
  history,
}
