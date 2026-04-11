import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logger.dart';

/// Environment configuration helper.
class EnvConfig {
  static String? _apiKey;
  static String _model = 'gemma-2-2b';
  static String _mode = 'mock';

  /// Initialize environment variables.
  /// Must be called before using any env-dependent features.
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      _apiKey = dotenv.env['GEMMA_API_KEY'];
      _model = dotenv.env['GEMMA_MODEL'] ?? 'gemma-2-2b';
      _mode = dotenv.env['INFERENCE_MODE'] ?? 'mock';

      AppLogger.i('Env loaded: mode=$_mode, model=$_model, apiKey=${_apiKey != null ? "set" : "missing"}');
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
  static String get mode => _mode;

  /// Check if API key is configured.
  static bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Check if remote mode is enabled.
  static bool get isRemoteMode => _mode == 'remote' && hasApiKey;
}
