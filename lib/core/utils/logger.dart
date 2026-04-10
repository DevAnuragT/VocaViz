/// Simple logging utility for debugging and diagnostics.
class AppLogger {
  static bool _enabled = true;
  static String _tag = 'VocaViz';

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;
  static void setTag(String tag) => _tag = tag;

  static void d(String message, [String? tag]) {
    if (_enabled) {
      print('[${tag ?? _tag}/DEBUG] ${DateTime.now().toIso8601String().substring(11, 19)} $message');
    }
  }

  static void i(String message, [String? tag]) {
    if (_enabled) {
      print('[${tag ?? _tag}/INFO] ${DateTime.now().toIso8601String().substring(11, 19)} $message');
    }
  }

  static void w(String message, [String? tag]) {
    if (_enabled) {
      print('[${tag ?? _tag}/WARN] ${DateTime.now().toIso8601String().substring(11, 19)} $message');
    }
  }

  static void e(String message, [String? tag, dynamic error]) {
    if (_enabled) {
      print('[${tag ?? _tag}/ERROR] ${DateTime.now().toIso8601String().substring(11, 19)} $message');
      if (error != null) {
        print('  Error: $error');
      }
    }
  }
}
