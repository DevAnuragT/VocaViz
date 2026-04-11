import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../data/models/analysis_result.dart';
import '../data/models/detection.dart';
import '../data/models/repair_step.dart';
import '../data/mock/mock_knowledge_base.dart';
import '../../core/utils/logger.dart';

/// Inference mode for the analysis service.
enum InferenceMode {
  /// Uses mock/predefined results - reliable for demos
  mock,

  /// Uses local Gemma model (on-device) - offline capable
  local,

  /// Uses Google AI API - requires network and API key
  remote,
}

/// Service responsible for analyzing images and returning structured results.
/// Supports multiple interchangeable modes for flexibility.
class InferenceService {
  InferenceMode _mode;
  GenerativeModel? _model;

  InferenceService({InferenceMode mode = InferenceMode.mock})
      : _mode = mode;

  /// Get current inference mode
  InferenceMode get mode => _mode;

  /// Set the inference mode
  set mode(InferenceMode value) {
    _mode = value;
    if (value == InferenceMode.mock) {
      _model = null;
    }
  }

  /// Configure for remote API usage
  void configureRemote(String apiKey) {
    _model = GenerativeModel(
      model: 'gemma-2-2b',
      apiKey: apiKey,
    );
    _mode = InferenceMode.remote;
  }

  /// Analyze an image and return structured results.
  ///
  /// [imageBytes] - Raw image bytes from camera or file
  /// [scenario] - For mock mode, which fault type to simulate
  Future<AnalysisResult> analyze({
    required Uint8List imageBytes,
    String? scenario,
  }) async {
    switch (_mode) {
      case InferenceMode.mock:
        return _analyzeMock(imageBytes, scenario);
      case InferenceMode.local:
        return _analyzeLocal(imageBytes);
      case InferenceMode.remote:
        return _analyzeRemote(imageBytes);
    }
  }

  /// Mock analysis - returns predefined results for reliability.
  Future<AnalysisResult> _analyzeMock(Uint8List imageBytes, String? scenario) async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 800));

    // If scenario provided, use it directly
    if (scenario != null && MockKnowledgeBase.sampleImages.containsKey(scenario)) {
      return MockKnowledgeBase.getMockResult(scenario);
    }

    // Otherwise, deterministically pick based on image hash
    // This ensures the same image always returns the same result
    final hash = _hashBytes(imageBytes);
    final scenarios = ['loose_belt', 'worn_belt', 'misaligned_belt'];
    final selectedScenario = scenarios[hash % scenarios.length];

    return MockKnowledgeBase.getMockResult(selectedScenario);
  }

  /// Local inference using on-device Gemma.
  /// Currently falls back to mock - implement when on-device Gemma is available.
  Future<AnalysisResult> _analyzeLocal(Uint8List imageBytes) async {
    try {
      // TODO: Implement actual on-device Gemma inference
      // This would use Gemma 2B or 7B running locally via TFLite or similar

      // For now, fall back to mock with a note
      final result = await _analyzeMock(imageBytes, null);
      return result.copyWith(
        summary: '${result.summary} (Local inference - demo mode)',
      );
    } catch (e) {
      // On failure, return mock result
      return _analyzeMock(imageBytes, null);
    }
  }

  /// Remote inference using Google AI API.
  Future<AnalysisResult> _analyzeRemote(Uint8List imageBytes) async {
    if (_model == null) {
      throw StateError('Remote mode requires API key. Call configureRemote() first.');
    }

    try {
      // Construct the prompt for structured output
      final prompt = '''
Analyze this image of a belt-driven water pump. Identify if there is a visible fault.

Respond ONLY with valid JSON in this exact format:
{
  "machine_type": "belt_driven_water_pump",
  "issue_type": "loose_belt|worn_belt|misaligned_belt|unknown",
  "confidence": 0.0-1.0,
  "summary": "brief description",
  "detections": [
    {"label": "belt|worn_area|etc", "x": 0.0-1.0, "y": 0.0-1.0, "width": 0.0-1.0, "height": 0.0-1.0, "severity": "low|medium|high"}
  ],
  "repair_steps": [
    {"step": 1, "title": "...", "instruction": "...", "warning": null}
  ],
  "stop_conditions": ["condition 1", "condition 2"]
}

If no fault is visible or confidence is low, set issue_type to "unknown".
''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await _model!.generateContent([content]);

      // Parse the JSON response
      final jsonStr = response.text?.trim() ?? '';
      return _parseJsonResponse(jsonStr);
    } catch (e) {
      // On API failure, return low confidence result
      return AnalysisResult.lowConfidence('Remote analysis failed: ${e.toString()}');
    }
  }

  /// Parse JSON response from Gemma into AnalysisResult.
  AnalysisResult _parseJsonResponse(String jsonStr) {
    try {
      // Clean up markdown code blocks if present
      String cleanJson = jsonStr;
      if (jsonStr.startsWith('```json')) {
        cleanJson = jsonStr.substring(7);
        if (cleanJson.endsWith('```')) {
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        }
      } else if (jsonStr.startsWith('```')) {
        cleanJson = jsonStr.substring(3);
        if (cleanJson.endsWith('```')) {
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        }
      }
      cleanJson = cleanJson.trim();

      final json = jsonDecode(cleanJson) as Map<String, dynamic>;

      return AnalysisResult(
        machineType: json['machine_type'] as String? ?? 'belt_driven_water_pump',
        issueType: json['issue_type'] as String? ?? 'unknown',
        confidence: _parseConfidence(json['confidence']),
        summary: json['summary'] as String? ?? 'Analysis complete',
        detections: (json['detections'] as List?)
            ?.map((d) => Detection.fromJson(d as Map<String, dynamic>))
            .toList() ?? [],
        repairSteps: (json['repair_steps'] as List?)
            ?.map((s) => RepairStep.fromJson(s as Map<String, dynamic>))
            .toList() ?? [],
        stopConditions: List<String>.from(json['stop_conditions'] as List? ?? []),
      );
    } catch (e) {
      AppLogger.e('JSON parsing failed', 'InferenceService', e);
      return AnalysisResult.lowConfidence('Failed to parse model response: ${e.toString()}');
    }
  }

  double _parseConfidence(dynamic value) {
    if (value == null) return 0.5;
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is int) return (value / 100.0).clamp(0.0, 1.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.clamp(0.0, 1.0) ?? 0.5;
    }
    return 0.5;
  }

  /// Simple hash function for deterministic mock selection.
  int _hashBytes(Uint8List bytes) {
    int hash = 0;
    for (int i = 0; i < min(bytes.length, 1000); i++) {
      hash = ((hash * 31) + bytes[i]) % 0x7FFFFFFF;
    }
    return hash;
  }
}

/// Extension to add copyWith to AnalysisResult for modifications.
extension AnalysisResultCopy on AnalysisResult {
  AnalysisResult copyWith({
    String? machineType,
    String? issueType,
    double? confidence,
    String? summary,
    List<Detection>? detections,
    List<RepairStep>? repairSteps,
    List<String>? stopConditions,
  }) {
    return AnalysisResult(
      machineType: machineType ?? this.machineType,
      issueType: issueType ?? this.issueType,
      confidence: confidence ?? this.confidence,
      summary: summary ?? this.summary,
      detections: detections ?? this.detections,
      repairSteps: repairSteps ?? this.repairSteps,
      stopConditions: stopConditions ?? this.stopConditions,
    );
  }
}
