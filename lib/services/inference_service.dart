import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../data/models/analysis_result.dart';
import '../data/models/detection.dart';
import '../data/models/repair_step.dart';
import '../data/mock/mock_knowledge_base.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/env_config.dart';

/// Inference mode for the analysis service.
enum InferenceMode {
  /// Uses mock/predefined results - reliable for demos
  mock,

  /// Uses local Gemma 4 model (on-device via LiteRT-LM) - offline capable
  /// Requires Gemma 4 model artifact in .task or .tflite format
  local,

  /// Uses Google AI API - requires network and API key
  remote,
}

/// Status of the local Gemma 4 model.
enum LocalModelStatus {
  /// Model not yet initialized
  notInitialized,

  /// Model is loading
  loading,

  /// Model loaded and ready for inference
  ready,

  /// Model artifact not found
  artifactMissing,

  /// Model artifact found but incompatible format
  artifactIncompatible,

  /// Model loaded but device lacks required resources (RAM/NPU)
  deviceInsufficient,

  /// Inference engine failed to initialize
  initFailed,
}

/// Service responsible for analyzing images and returning structured results.
/// Supports multiple interchangeable modes for flexibility.
class InferenceService {
  static const Duration _remoteTimeout = Duration(seconds: 20);
  static const int _maxRemoteRetries = 2;


  InferenceMode _mode;
  GenerativeModel? _model;
  dynamic _chatSession; // flutter_gemma Chat type
  bool _localModelInitialized = false;
  LocalModelStatus _localModelStatus = LocalModelStatus.notInitialized;
  Object? _localModelError;

  InferenceService({InferenceMode mode = InferenceMode.mock})
      : _mode = mode;

  /// Get current inference mode
  InferenceMode get mode => _mode;

  /// Get the local model status
  LocalModelStatus get localModelStatus => _localModelStatus;

  /// Get the local model error if any
  Object? get localModelError => _localModelError;

  /// Set the inference mode
  set mode(InferenceMode value) {
    _mode = value;
    if (value == InferenceMode.mock) {
      _model = null;
      _chatSession = null;
    }
  }

  /// Configure for remote API usage
  void configureRemote(String apiKey, {String modelName = 'gemma-2-2b'}) {
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );
    _mode = InferenceMode.remote;
  }

  /// Initialize flutter_gemma for on-device inference.
  /// Call this once at app startup.
  static Future<void> initializeGemma({String? huggingFaceToken}) async {
    try {
      await FlutterGemma.initialize(
        huggingFaceToken: huggingFaceToken,
        maxDownloadRetries: 10,
      );
      AppLogger.i('flutter_gemma initialized successfully', 'InferenceService');
    } catch (e) {
      AppLogger.w('flutter_gemma init failed: $e', 'InferenceService');
    }
  }

  /// Check if local Gemma 4 model is available and ready.
  /// Call this before switching to local mode.
  Future<LocalModelStatus> checkLocalModelAvailability() async {
    _localModelStatus = LocalModelStatus.loading;

    try {
      final modelPath = EnvConfig.localModelPath;

      if (!_isSupportedModelAsset(modelPath)) {
        _localModelStatus = LocalModelStatus.artifactIncompatible;
        _localModelError = 'Unsupported model format: $modelPath';
        return _localModelStatus;
      }

      // Check if model artifact exists in assets
      final modelExists = await _checkModelAssetExists();
      if (!modelExists) {
        _localModelStatus = LocalModelStatus.artifactMissing;
        _localModelError = 'Gemma 4 model artifact not found at ${EnvConfig.localModelPath}';
        return _localModelStatus;
      }

      // Model file exists - mark as ready (actual loading happens on first inference)
      _localModelStatus = LocalModelStatus.ready;
      _localModelError = null;
      return _localModelStatus;
    } on PlatformException catch (e) {
      // Platform-specific errors (e.g., GPU not available)
      _localModelStatus = LocalModelStatus.deviceInsufficient;
      _localModelError = 'Platform error: ${e.message}';
      AppLogger.e('Platform error checking model', 'InferenceService', e);
      return _localModelStatus;
    } catch (e) {
      _localModelStatus = LocalModelStatus.initFailed;
      _localModelError = e;
      AppLogger.e('Error checking model availability', 'InferenceService', e);
      return _localModelStatus;
    }
  }

  /// Check if model asset file exists.
  Future<bool> _checkModelAssetExists() async {
    final modelPath = EnvConfig.localModelPath;

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;
      if (manifest.containsKey(modelPath)) {
        return true;
      }

      AppLogger.w('Model asset not found at $modelPath', 'InferenceService');
      return false;
    } catch (e) {
      AppLogger.e('Error checking model asset', 'InferenceService', e);
      return false;
    }
  }

  bool _isSupportedModelAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.task') ||
        lower.endsWith('.litertlm') ||
        lower.endsWith('.tflite') ||
        lower.endsWith('.bin');
  }

  ModelFileType _modelFileTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.bin') || lower.endsWith('.tflite')) {
      return ModelFileType.binary;
    }
    return ModelFileType.task;
  }

  String _stripAssetPrefix(String path) {
    return path.startsWith('assets/') ? path.substring('assets/'.length) : path;
  }

  /// Initialize the local Gemma 4 model with flutter_gemma.
  /// Call after verifying availability.
  Future<bool> initializeLocalModel() async {
    if (_localModelStatus != LocalModelStatus.ready) {
      final status = await checkLocalModelAvailability();
      if (status != LocalModelStatus.ready) {
        return false;
      }
    }

    try {
      _localModelStatus = LocalModelStatus.loading;
      _localModelError = null;

      final modelPath = EnvConfig.localModelPath;
      final assetPath = _stripAssetPrefix(modelPath);

      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: _modelFileTypeForPath(modelPath),
      ).fromAsset(assetPath).install();

      // Get active model using flutter_gemma
      final inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        supportImage: true,
        maxNumImages: 1,
      );

      // Create chat session
      _chatSession = await inferenceModel.createChat();
      _localModelInitialized = true;

      _localModelStatus = LocalModelStatus.ready;
      AppLogger.i('Local Gemma model initialized', 'InferenceService');
      return true;
    } on PlatformException catch (e) {
      // Catch platform-specific crashes (GPU init failures, etc.)
      _localModelStatus = LocalModelStatus.initFailed;
      _localModelError = 'Platform error: ${e.message}';
      AppLogger.e('Platform error initializing model', 'InferenceService', e);
      return false;
    } on Exception catch (e) {
      _localModelStatus = LocalModelStatus.initFailed;
      _localModelError = e;
      AppLogger.e('Exception initializing model', 'InferenceService', e);
      return false;
    } catch (e) {
      _localModelStatus = LocalModelStatus.initFailed;
      _localModelError = e;
      AppLogger.e('Failed to initialize local model', 'InferenceService', e);
      return false;
    }
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

  /// Local inference using on-device Gemma 4 via flutter_gemma (LiteRT-LM backend).
  /// Requires model artifact to be placed in assets/models/
  Future<AnalysisResult> _analyzeLocal(Uint8List imageBytes) async {
    // Check model status before attempting inference
    if (_localModelStatus == LocalModelStatus.notInitialized) {
      await checkLocalModelAvailability();
    }

    // If model not ready, provide detailed diagnostic and fall back
    if (_localModelStatus != LocalModelStatus.ready) {
      return _analyzeLocalWithFallback(imageBytes);
    }

    // Initialize chat session if not already done
    if (!_localModelInitialized || _chatSession == null) {
      final initialized = await initializeLocalModel();
      if (!initialized) {
        return _analyzeLocalWithFallback(imageBytes);
      }
    }

    try {
      // Send image + prompt to local Gemma model
      final chat = _chatSession;

      // Add user message with image (multimodal input)
      await chat.addQueryChunk(
        Message.withImage(
          text: _buildLocalPrompt(),
          imageBytes: imageBytes,
          isUser: true,
        ),
      );

      // Generate response (synchronous)
      final response = await chat.generateChatResponse();
      final responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) {
        return AnalysisResult.lowConfidence('Local model returned empty response.');
      }

      // Parse JSON response
      final parsed = _parseJsonResponse(responseText);
      return _normalizeResult(parsed);
    } on PlatformException catch (e) {
      // Catch platform crashes (GPU failures, OOM, etc.)
      AppLogger.e('Local inference platform error', 'InferenceService', e);
      _localModelStatus = LocalModelStatus.initFailed;
      _localModelError = 'Platform error: ${e.message}';
      return _analyzeLocalWithFallback(imageBytes);
    } on Exception catch (e) {
      AppLogger.e('Local inference failed', 'InferenceService', e);
      return _analyzeLocalWithFallback(imageBytes);
    } catch (e) {
      AppLogger.e('Local inference failed', 'InferenceService', e);
      _localModelStatus = LocalModelStatus.initFailed;
      _localModelError = e;
      return _analyzeLocalWithFallback(imageBytes);
    }
  }

  /// Build prompt for local inference (optimized for on-device model).
  String _buildLocalPrompt() {
    return '''Analyze this image for belt-driven water pump faults.
Respond ONLY with valid JSON (no markdown, no explanation):
{"machine_type":"belt_driven_water_pump","issue_type":"loose_belt|worn_belt|misaligned_belt|unknown","confidence":0.XX,"summary":"...","detections":[...],"repair_steps":[...],"stop_conditions":[...]}
''';
  }

  /// Fall back to mock inference when local model unavailable.
  /// Adds diagnostic info about why local mode failed.
  Future<AnalysisResult> _analyzeLocalWithFallback(Uint8List imageBytes) async {
    String diagnosticNote;

    switch (_localModelStatus) {
      case LocalModelStatus.artifactMissing:
        diagnosticNote = 'Local Gemma 4 model not installed. See GEMMA4_MODEL_SETUP.md';
        break;
      case LocalModelStatus.artifactIncompatible:
        diagnosticNote = 'Model format incompatible. Expected .litertlm, .task, .tflite, or .bin';
        break;
      case LocalModelStatus.deviceInsufficient:
        diagnosticNote = 'Device lacks resources for local inference';
        break;
      case LocalModelStatus.initFailed:
        diagnosticNote = 'Local model init failed: $_localModelError';
        break;
      case LocalModelStatus.loading:
        diagnosticNote = 'Model still loading, using mock';
        break;
      default:
        diagnosticNote = 'Local inference unavailable';
    }

    final result = await _analyzeMock(imageBytes, null);
    return result.copyWith(
      summary: '${result.summary} ($diagnosticNote)',
    );
  }

  /// Remote inference using Google AI API.
  Future<AnalysisResult> _analyzeRemote(Uint8List imageBytes) async {
    if (_model == null) {
      throw StateError('Remote mode requires API key. Call configureRemote() first.');
    }

    final content = Content.multi([
      TextPart(_buildPrompt()),
      DataPart('image/jpeg', imageBytes),
    ]);

    for (int attempt = 0; attempt <= _maxRemoteRetries; attempt++) {
      try {
        final response = await _model!
            .generateContent([content])
            .timeout(_remoteTimeout);

        final modelText = response.text?.trim() ?? '';
        if (modelText.isEmpty) {
          throw const FormatException('Model returned empty response.');
        }

        final parsed = _parseJsonResponse(modelText);
        return _normalizeResult(parsed);
      } catch (error) {
        final shouldRetry = attempt < _maxRemoteRetries && _isRetryableRemoteError(error);
        if (shouldRetry) {
          await Future.delayed(_retryDelayForAttempt(attempt));
          continue;
        }

        return _remoteFailureResult(error);
      }
    }

    return AnalysisResult.lowConfidence('Remote analysis failed after retries.');
  }

  String _buildPrompt() {
    return '''
You are an expert agricultural equipment inspector. Analyze this image for belt-driven water pump faults.

IMPORTANT:
- Only analyze if this is clearly a belt-driven water pump or similar machinery
- If the image shows lamps, electronics, household items, or non-mechanical objects, return issue_type="unknown"
- Look specifically for: belt condition, belt alignment, and belt tension

Respond ONLY with valid JSON in this exact format:
{
  "machine_type": "belt_driven_water_pump" or "unknown",
  "issue_type": "loose_belt|worn_belt|misaligned_belt|unknown",
  "confidence": 0.0-1.0,
  "summary": "brief description of what you see and why you classified it this way",
  "detections": [
    {"label": "belt|pulley|worn_area|sag_zone|misalignment_zone", "x": 0.0-1.0, "y": 0.0-1.0, "width": 0.0-1.0, "height": 0.0-1.0, "severity": "low|medium|high"}
  ],
  "repair_steps": [
    {"step": 1, "title": "...", "instruction": "...", "warning": null}
  ],
  "stop_conditions": ["condition 1", "condition 2"]
}

Classification guide:
- loose_belt: Visible sag/droop in the belt between pulleys
- worn_belt: Cracks, fraying, glazing, or visible wear on belt surface
- misaligned_belt: Belt running off-center or not tracking straight on pulleys
- unknown: Not a belt-driven pump, image unclear, or no visible fault

If confidence is below 0.6, set issue_type to "unknown".
Output consistency examples:
Example A:
{"machine_type":"belt_driven_water_pump","issue_type":"loose_belt","confidence":0.86,"summary":"Belt sag is visible between pulleys.","detections":[{"label":"sag_zone","x":0.34,"y":0.46,"width":0.22,"height":0.12,"severity":"high"}],"repair_steps":[{"step":1,"title":"Turn off power","instruction":"Disconnect and verify motor cannot start.","warning":"Lock out if possible."}],"stop_conditions":["If belt is frayed, replace belt before restarting."]}

Example B:
{"machine_type":"unknown","issue_type":"unknown","confidence":0.42,"summary":"Image does not show a supported belt-driven water pump.","detections":[],"repair_steps":[],"stop_conditions":["Retake photo with full belt and pulley view.","If uncertain, contact a technician."]}
''';
  }

  Duration _retryDelayForAttempt(int attempt) {
    const backoff = [
      Duration(milliseconds: 600),
      Duration(milliseconds: 1500),
    ];
    return backoff[min(attempt, backoff.length - 1)];
  }

  bool _isRetryableRemoteError(Object error) {
    if (error is TimeoutException) return true;

    final text = error.toString().toLowerCase();
    return text.contains('429') ||
        text.contains('rate limit') ||
        text.contains('quota') ||
        text.contains('resource exhausted') ||
        text.contains('temporarily unavailable') ||
        text.contains('socket') ||
        text.contains('connection') ||
        text.contains('deadline');
  }

  AnalysisResult _remoteFailureResult(Object error) {
    final message = error.toString().toLowerCase();

    if (error is TimeoutException) {
      return AnalysisResult.lowConfidence('Remote analysis timed out. Please retry.');
    }

    if (message.contains('429') || message.contains('rate limit') || message.contains('quota')) {
      return AnalysisResult.lowConfidence('Remote service is rate-limited. Please retry shortly.');
    }

    if (message.contains('socket') || message.contains('connection') || message.contains('network')) {
      return AnalysisResult.lowConfidence('Network issue during remote analysis. Check connectivity and retry.');
    }

    return AnalysisResult.lowConfidence('Remote analysis failed. Please retry with a clearer image.');
  }

  AnalysisResult _normalizeResult(AnalysisResult result) {
    var normalized = result;

    final validMachineType = normalized.machineType == 'belt_driven_water_pump' ||
        normalized.machineType == 'unknown';
    if (!validMachineType) {
      normalized = normalized.copyWith(machineType: 'unknown', issueType: 'unknown');
    }

    if (normalized.confidence < 0.6 && normalized.issueType != 'unknown') {
      normalized = normalized.copyWith(issueType: 'unknown');
    }

    if (normalized.issueType == 'unknown') {
      return normalized.copyWith(
        repairSteps: [],
      );
    }

    // If remote missed steps for a known issue, fall back to local knowledge.
    if (normalized.repairSteps.isEmpty) {
      final fallback = MockKnowledgeBase.getMockResult(normalized.issueType);
      normalized = normalized.copyWith(
        repairSteps: fallback.repairSteps,
        stopConditions: normalized.stopConditions.isEmpty
            ? fallback.stopConditions
            : normalized.stopConditions,
      );
    }

    return normalized;
  }

  /// Parse JSON response from Gemma into AnalysisResult.
  AnalysisResult _parseJsonResponse(String jsonStr) {
    try {
      final json = _decodeBestEffortJsonObject(jsonStr);
      final machineType = _parseMachineType(json['machine_type']);
      final issueType = _parseIssueType(json['issue_type']);
      final confidence = _parseConfidence(json['confidence']);
      final summary = (json['summary'] as String?)?.trim().isNotEmpty == true
          ? (json['summary'] as String).trim()
          : 'Analysis complete';

      final detections = _parseDetections(json['detections']);
      final repairSteps = _parseRepairSteps(json['repair_steps']);
      final stopConditions = _parseStopConditions(json['stop_conditions']);

      return AnalysisResult(
        machineType: machineType,
        issueType: issueType,
        confidence: confidence,
        summary: summary,
        detections: detections,
        repairSteps: repairSteps,
        stopConditions: stopConditions,
      );
    } catch (e) {
      AppLogger.e('JSON parsing failed', 'InferenceService', e);
      return AnalysisResult.lowConfidence('Failed to parse model response: ${e.toString()}');
    }
  }

  Map<String, dynamic> _decodeBestEffortJsonObject(String rawText) {
    final candidates = _jsonCandidates(rawText);
    for (final candidate in candidates) {
      final sanitized = _sanitizeJson(candidate);
      try {
        final decoded = jsonDecode(sanitized);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Try next candidate.
      }
    }
    throw const FormatException('No valid JSON object found in model response.');
  }

  List<String> _jsonCandidates(String rawText) {
    final trimmed = rawText.trim();
    final strippedFences = trimmed
        .replaceAll(RegExp(r'^```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^```\s*'), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();

    final firstBrace = strippedFences.indexOf('{');
    final lastBrace = strippedFences.lastIndexOf('}');
    final extractedObject = (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace)
        ? strippedFences.substring(firstBrace, lastBrace + 1)
        : strippedFences;

    return [trimmed, strippedFences, extractedObject];
  }

  String _sanitizeJson(String jsonLike) {
    return jsonLike.replaceAll(RegExp(r',\s*([}\]])'), r'$1').trim();
  }

  String _parseMachineType(dynamic value) {
    final parsed = (value as String?)?.trim() ?? 'unknown';
    if (parsed == 'belt_driven_water_pump' || parsed == 'unknown') {
      return parsed;
    }
    return 'unknown';
  }

  String _parseIssueType(dynamic value) {
    const valid = {
      'loose_belt',
      'worn_belt',
      'misaligned_belt',
      'unknown',
    };
    final parsed = (value as String?)?.trim() ?? 'unknown';
    return valid.contains(parsed) ? parsed : 'unknown';
  }

  List<Detection> _parseDetections(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((entry) => Detection.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  List<RepairStep> _parseRepairSteps(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((entry) => RepairStep.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  List<String> _parseStopConditions(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).where((s) => s.trim().isNotEmpty).toList();
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
