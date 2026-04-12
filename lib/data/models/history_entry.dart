import 'analysis_result.dart';

/// Represents a single inspection history entry.
class HistoryEntry {
  final String id;
  final DateTime timestamp;
  final String issueType;
  final double confidence;
  final String summary;
  final String? imagePath; // Optional: path to captured image for thumbnail
  final bool completedRepair;

  HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.issueType,
    required this.confidence,
    required this.summary,
    this.imagePath,
    this.completedRepair = false,
  });

  /// Create a history entry from an AnalysisResult
  factory HistoryEntry.fromAnalysisResult(
    AnalysisResult result, {
    String? imagePath,
    bool completedRepair = false,
  }) {
    return HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: result.timestamp,
      issueType: result.issueType,
      confidence: result.confidence,
      summary: result.summary,
      imagePath: imagePath,
      completedRepair: completedRepair,
    );
  }

  /// Get a human-readable issue title
  String get issueTitle {
    return issueType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toInt()}%';

  /// Get a short relative time description
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'issue_type': issueType,
      'confidence': confidence,
      'summary': summary,
      'image_path': imagePath,
      'completed_repair': completedRepair,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      issueType: json['issue_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      summary: json['summary'] as String,
      imagePath: json['image_path'] as String?,
      completedRepair: json['completed_repair'] as bool? ?? false,
    );
  }

  HistoryEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? issueType,
    double? confidence,
    String? summary,
    String? imagePath,
    bool? completedRepair,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      issueType: issueType ?? this.issueType,
      confidence: confidence ?? this.confidence,
      summary: summary ?? this.summary,
      imagePath: imagePath ?? this.imagePath,
      completedRepair: completedRepair ?? this.completedRepair,
    );
  }
}
