import 'package:flutter/material.dart';

/// App-wide constants and configuration.
class AppConstants {
  // App Info
  static const String appName = 'VocaViz';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Camera-based repair guidance';

  // Supported machine types
  static const String supportedMachineType = 'belt_driven_water_pump';
  static const List<String> supportedIssues = [
    'loose_belt',
    'worn_belt',
    'misaligned_belt',
  ];

  // Confidence thresholds
  static const double lowConfidenceThreshold = 0.5;
  static const double mediumConfidenceThreshold = 0.7;
  static const double highConfidenceThreshold = 0.85;

  // UI Constants
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultIconSize = 24.0;

  // Camera constants
  static const double minCameraZoom = 1.0;
  static const double maxCameraZoom = 4.0;
  static const Duration cameraInitTimeout = Duration(seconds: 5);

  // Inference constants
  static const Duration inferenceTimeout = Duration(seconds: 30);
  static const int maxImageDimension = 1024; // Resize larger images for API

  // Demo mode
  static const bool demoModeDefault = true;
  static const String demoModeKey = 'demo_mode_enabled';

  // Storage keys
  static const String recentSessionsKey = 'recent_sessions';
  static const String settingsKey = 'app_settings';
}

/// Color scheme for the app.
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF2563EB); // Blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Semantic colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Severity colors
  static const Color severityLow = Color(0xFF10B981);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityHigh = Color(0xFFEF4444);

  // Background colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
}
