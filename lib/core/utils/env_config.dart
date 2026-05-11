import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logger.dart';

/// Environment configuration helper.
class EnvConfig {
  static String? _apiKey;
  static String _model = 'gemma-4-2b';  // Default to Gemma 4 for hackathon
  static String _mode = 'mock';
  static String? _overrideMode;
  static String _localModelPath =
      'assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm';

  /// Initialize environment variables.
  /// Must be called before using any env-dependent features.
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      _apiKey = dotenv.env['GEMMA_API_KEY'];
      _model = dotenv.env['GEMMA_MODEL'] ?? 'gemma-4-2b';
      _mode = dotenv.env['INFERENCE_MODE'] ?? 'mock';
        _localModelPath = dotenv.env['LOCAL_MODEL_PATH'] ??
          'assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm';

      AppLogger.i('Env loaded: mode=$_mode, model=$_model, apiKey=${_apiKey != null ? "set" : "missing"}, localModel=$_localModelPath');
    } catch (e) {
      AppLogger.w('Failed to load .env file - using defaults: $e', 'EnvConfig');
      _mode = 'mock';
    }
  }

  /// Get API key.
  static String? get apiKey => _apiKey;

  /// Get model name.
  static String get model => _model;

  /// Get inference mode.
  static String get mode => _overrideMode ?? _mode;

  /// Override inference mode at runtime.
  static void setOverrideMode(String? mode) {
    _overrideMode = mode;
  }

  /// Get local model path.
  static String get localModelPath => _localModelPath;

  /// Check if API key is configured.
  static bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Check if remote mode is enabled.
  static bool get isRemoteMode => mode == 'remote' && hasApiKey;

  /// Check if local mode is enabled.
  static bool get isLocalMode => mode == 'local';

  /// Check if offline mode is enabled.
  static bool get isOfflineMode => mode == 'offline';
}
