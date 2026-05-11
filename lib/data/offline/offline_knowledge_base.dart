import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/analysis_result.dart';

/// Loads pre-generated Gemma knowledge for offline repair guidance.
class OfflineKnowledgeBase {
  static const String _assetPath = 'assets/knowledge/offline_knowledge_base.json';
  static Map<String, dynamic>? _cache;

  static Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    final content = await rootBundle.loadString(_assetPath);
    _cache = jsonDecode(content) as Map<String, dynamic>;
  }

  static Future<AnalysisResult?> getResult(String issueType) async {
    await _ensureLoaded();
    final entry = _cache?[issueType];
    if (entry is Map<String, dynamic>) {
      return AnalysisResult.fromJson(entry);
    }
    return null;
  }
}
