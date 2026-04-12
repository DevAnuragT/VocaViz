import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Main app widget with navigation state management.
class VocaVizApp extends StatefulWidget {
  const VocaVizApp({super.key});

  @override
  State<VocaVizApp> createState() => _VocaVizAppState();
}

class _VocaVizAppState extends State<VocaVizApp> {
  bool _hasCompletedOnboarding = false;
  bool _isLoading = true;

  // Navigation state
  AppScreen _currentScreen = AppScreen.home;

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

  // Image data passed between screens
  Uint8List? _capturedImage;
  String _imageSource = 'camera';
  String? _analysisScenario;
  AnalysisResult? _lastResult;
  HistoryEntry? _currentHistoryEntry;

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

    switch (_currentScreen) {
      case AppScreen.home:
        return HomeScreen(
          onInspectPressed: _navigateToCamera,
          onSampleImagesPressed: _navigateToSamples,
          onHistoryPressed: _navigateToHistory,
        );

      case AppScreen.camera:
        return CameraScreen(
          onImageCaptured: _handleImageCaptured,
          onCancel: () => _navigateTo(AppScreen.home),
        );

      case AppScreen.analysis:
        if (_capturedImage == null) {
          _navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return AnalysisScreen(
          imageBytes: _capturedImage!,
          source: _imageSource,
          scenario: _analysisScenario,
          onBack: () => _navigateTo(AppScreen.home),
          onAnalysisComplete: _handleAnalysisComplete,
          onStartRepair: _navigateToRepair,
        );

      case AppScreen.repair:
        if (_lastResult == null) {
          _navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return RepairScreen(
          result: _lastResult!,
          onComplete: _handleRepairComplete,
        );

      case AppScreen.summary:
        if (_lastResult == null) {
          _navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return SummaryScreen(
          result: _lastResult!,
          onHome: () => _navigateTo(AppScreen.home),
          onNewInspection: _navigateToCamera,
        );

      case AppScreen.safety:
        if (_lastResult == null) {
          _navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return SafetyStopScreen(
          result: _lastResult!,
          onHome: () => _navigateTo(AppScreen.home),
          onRetry: _navigateToCamera,
        );

      case AppScreen.samples:
        return SampleImagesScreen(
          onImageSelected: _handleSampleSelected,
          onBack: () => _navigateTo(AppScreen.home),
        );

      case AppScreen.history:
        return HistoryScreen(
          onBack: () => _navigateTo(AppScreen.home),
          onNewInspection: _navigateToCamera,
        );
    }
  }

  void _navigateTo(AppScreen screen) {
    setState(() => _currentScreen = screen);
  }

  void _navigateToCamera() {
    _navigateTo(AppScreen.camera);
  }

  void _navigateToSamples() {
    _navigateTo(AppScreen.samples);
  }

  void _navigateToHistory() {
    _navigateTo(AppScreen.history);
  }

  void _handleImageCaptured(Uint8List bytes, String source) {
    _capturedImage = bytes;
    _imageSource = source;
    _analysisScenario = null;
    _navigateTo(AppScreen.analysis);
  }

  Future<void> _handleSampleSelected(String scenario) async {
    final assetPath = MockKnowledgeBase.sampleImages[scenario];
    if (assetPath == null) {
      AppLogger.w('Missing sample asset for scenario: $scenario', 'App');
      return;
    }

    try {
      _analysisScenario = scenario;
      _imageSource = 'sample';
      _capturedImage = (await rootBundle.load(assetPath)).buffer.asUint8List();
      _navigateTo(AppScreen.analysis);
    } catch (error) {
      AppLogger.e('Failed to load sample asset', 'App', error);
    }
  }

  void _handleAnalysisComplete(AnalysisResult result) {
    _lastResult = result;
    // Create history entry when analysis completes
    _currentHistoryEntry = HistoryEntry.fromAnalysisResult(
      result,
      imagePath: _imageSource == 'sample' ? null : 'captured',
      completedRepair: false,
    );
    if (result.isLowConfidence || result.requiresTechnician) {
      // Save immediately for safety-stop cases (no repair possible)
      HistoryService.addEntry(_currentHistoryEntry!);
      _navigateTo(AppScreen.safety);
    }
    // For normal analyses, history is saved when repair completes
    // or when user navigates away without repair
  }

  void _navigateToRepair() {
    if (_lastResult == null) return;
    _navigateTo(AppScreen.repair);
  }

  void _handleRepairComplete() {
    // Mark the current history entry as completed
    if (_currentHistoryEntry != null) {
      _currentHistoryEntry = _currentHistoryEntry!.copyWith(completedRepair: true);
      HistoryService.addEntry(_currentHistoryEntry!);
    }
    _navigateTo(AppScreen.summary);
  }
}

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
