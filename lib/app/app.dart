import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../core/utils/preferences.dart';
import '../data/models/analysis_result.dart';
import '../data/models/history_entry.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/inspection/camera_screen.dart';
import '../features/inspection/analysis_screen.dart';
import '../features/guidance/repair_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/sample/sample_images_screen.dart';
import '../features/analysis/safety_stop_screen.dart';
import '../features/history/history_screen.dart';
import '../data/mock/mock_knowledge_base.dart';
import '../services/history_service.dart';
import '../providers/app_state_provider.dart';

/// Main app widget with navigation state management.
class VocaVizApp extends ConsumerStatefulWidget {
  const VocaVizApp({super.key});

  @override
  ConsumerState<VocaVizApp> createState() => _VocaVizAppState();
}

class _VocaVizAppState extends ConsumerState<VocaVizApp> {
  bool _hasCompletedOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final completed = await AppPreferences.hasCompletedOnboarding();
    if (mounted) {
      setState(() {
        _hasCompletedOnboarding = completed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
          ),
        ),
      ),
      home: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(
        onComplete: () async {
          await AppPreferences.setOnboardingCompleted();
          setState(() => _hasCompletedOnboarding = true);
        },
      );
    }

    final appState = ref.watch(appStateProvider);
    final appController = ref.read(appStateProvider.notifier);

    switch (appState.currentScreen) {
      case AppScreen.home:
        return HomeScreen(
          onInspectPressed: () => appController.navigateTo(AppScreen.camera),
          onSampleImagesPressed: () => appController.navigateTo(AppScreen.samples),
          onHistoryPressed: () => appController.navigateTo(AppScreen.history),
        );

      case AppScreen.camera:
        return CameraScreen(
          onImageCaptured: (bytes, source) {
            appController.setImage(bytes, source);
            appController.navigateTo(AppScreen.analysis);
          },
          onCancel: () => appController.navigateTo(AppScreen.home),
        );

      case AppScreen.analysis:
        if (appState.capturedImage == null) {
          appController.navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return AnalysisScreen(
          imageBytes: appState.capturedImage!,
          source: appState.imageSource,
          scenario: appState.analysisScenario,
          onBack: () => appController.navigateTo(AppScreen.home),
          onAnalysisComplete: (result) => _handleAnalysisComplete(appController, appState.imageSource, result),
          onStartRepair: () => appController.navigateTo(AppScreen.repair),
        );

      case AppScreen.repair:
        if (appState.lastResult == null) {
          appController.navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return RepairScreen(
          result: appState.lastResult!,
          onComplete: () => _handleRepairComplete(appController, appState.currentHistoryEntry),
        );

      case AppScreen.summary:
        if (appState.lastResult == null) {
          appController.navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return SummaryScreen(
          result: appState.lastResult!,
          onHome: () => appController.navigateTo(AppScreen.home),
          onNewInspection: () => appController.navigateTo(AppScreen.camera),
        );

      case AppScreen.safety:
        if (appState.lastResult == null) {
          appController.navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return SafetyStopScreen(
          result: appState.lastResult!,
          onHome: () => appController.navigateTo(AppScreen.home),
          onRetry: () => appController.navigateTo(AppScreen.camera),
        );

      case AppScreen.samples:
        return SampleImagesScreen(
          onImageSelected: _handleSampleSelected,
          onBack: () => appController.navigateTo(AppScreen.home),
        );

      case AppScreen.history:
        return HistoryScreen(
          onBack: () => appController.navigateTo(AppScreen.home),
          onNewInspection: () => appController.navigateTo(AppScreen.camera),
        );
    }
  }

  Future<void> _handleSampleSelected(String scenario) async {
    final assetPath = MockKnowledgeBase.sampleImages[scenario];
    if (assetPath == null) {
      AppLogger.w('Missing sample asset for scenario: $scenario', 'App');
      return;
    }

    try {
      final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
      ref.read(appStateProvider.notifier).setAnalysisScenario(scenario);
      ref.read(appStateProvider.notifier).setImage(
        bytes,
        'sample',
        clearScenario: false,
      );
      ref.read(appStateProvider.notifier).navigateTo(AppScreen.analysis);
    } catch (error) {
      AppLogger.e('Failed to load sample asset', 'App', error);
    }
  }

  void _handleAnalysisComplete(AppController controller, String imageSource, AnalysisResult result) {
    controller.setResult(result);
    // Create history entry when analysis completes
    final entry = HistoryEntry.fromAnalysisResult(
      result,
      imagePath: imageSource == 'sample' ? null : 'captured',
      completedRepair: false,
    );
    controller.setHistoryEntry(entry);
    if (result.isLowConfidence || result.requiresTechnician) {
      // Save immediately for safety-stop cases (no repair possible)
      HistoryService.addEntry(entry);
      controller.navigateTo(AppScreen.safety);
    }
    // For normal analyses, history is saved when repair completes
  }

  void _handleRepairComplete(AppController controller, HistoryEntry? currentEntry) {
    // Mark the current history entry as completed
    if (currentEntry != null) {
      final updated = currentEntry.copyWith(completedRepair: true);
      controller.updateHistoryEntry(updated);
      HistoryService.addEntry(updated);
    }
    controller.navigateTo(AppScreen.summary);
  }
}
