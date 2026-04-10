import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/models/analysis_result.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/inspection/camera_screen.dart';
import '../features/inspection/analysis_screen.dart';
import '../features/guidance/repair_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/sample/sample_images_screen.dart';

/// Main app widget with navigation state management.
class VocaVizApp extends StatefulWidget {
  const VocaVizApp({super.key});

  @override
  State<VocaVizApp> createState() => _VocaVizAppState();
}

class _VocaVizAppState extends State<VocaVizApp> {
  bool _hasCompletedOnboarding = false;

  // Navigation state
  AppScreen _currentScreen = AppScreen.home;

  // Image data passed between screens
  Uint8List? _capturedImage;
  String _imageSource = 'camera';
  String? _analysisScenario;
  AnalysisResult? _lastResult;

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
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(
        onComplete: () => setState(() => _hasCompletedOnboarding = true),
      );
    }

    switch (_currentScreen) {
      case AppScreen.home:
        return HomeScreen(
          onInspectPressed: _navigateToCamera,
          onSampleImagesPressed: _navigateToSamples,
          onHistoryPressed: () {
            AppLogger.i('History not yet implemented', 'App');
          },
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
        );

      case AppScreen.repair:
        if (_lastResult == null) {
          _navigateTo(AppScreen.home);
          return const SizedBox.shrink();
        }
        return RepairScreen(
          result: _lastResult!,
          onComplete: () => _navigateTo(AppScreen.summary),
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

      case AppScreen.samples:
        return SampleImagesScreen(
          onImageSelected: _handleSampleSelected,
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

  void _handleImageCaptured(Uint8List bytes, String source) {
    _capturedImage = bytes;
    _imageSource = source;
    _analysisScenario = null;
    _navigateTo(AppScreen.analysis);
  }

  void _handleSampleSelected(String scenario) {
    _navigateTo(AppScreen.samples);
    // For demo, we'll use mock data directly in analysis screen
    _analysisScenario = scenario;
    _imageSource = 'sample';

    // Create a placeholder image (in real app, would load from assets)
    // For now, analysis screen will use mock data based on scenario
    _capturedImage = Uint8List(100); // Dummy data - mock service ignores this
    _navigateTo(AppScreen.analysis);
  }

  void _handleAnalysisComplete(AnalysisResult result) {
    _lastResult = result;
    if (!result.isLowConfidence && !result.requiresTechnician) {
      _navigateTo(AppScreen.repair);
    }
  }
}

enum AppScreen {
  home,
  camera,
  analysis,
  repair,
  summary,
  samples,
}
