/// Represents a detected region in an image with normalized coordinates.
class Detection {
  final String label;
  final double x;      // Normalized 0.0 - 1.0
  final double y;      // Normalized 0.0 - 1.0
  final double width;  // Normalized 0.0 - 1.0
  final double height; // Normalized 0.0 - 1.0
  final String severity; // 'low', 'medium', 'high'

  Detection({
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.severity = 'low',
  });

  /// Validate that coordinates are within normalized range
  bool get isValid {
    return x >= 0 && x <= 1 &&
           y >= 0 && y <= 1 &&
           width >= 0 && width <= 1 &&
           height >= 0 && height <= 1;
  }

  /// Create from JSON with defensive parsing
  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'] as String? ?? 'unknown',
      x: _parseDouble(json['x'], 0.5),
      y: _parseDouble(json['y'], 0.5),
      width: _parseDouble(json['width'], 0.3),
      height: _parseDouble(json['height'], 0.3),
      severity: _parseSeverity(json['severity']),
    );
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is int) return (value / 100.0).clamp(0.0, 1.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.clamp(0.0, 1.0) ?? defaultValue;
    }
    return defaultValue;
  }

  static String _parseSeverity(dynamic value) {
    if (value is String && ['low', 'medium', 'high'].contains(value)) {
      return value;
    }
    return 'low';
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'severity': severity,
    };
  }
}
