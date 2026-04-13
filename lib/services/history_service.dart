import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/history_entry.dart';
import '../core/utils/logger.dart';

/// Service for managing inspection history persistence.
class HistoryService {
  static const String _historyKey = 'inspection_history';
  static const int _maxHistoryEntries = 50;

  /// Get all history entries, sorted by timestamp (newest first)
  static Future<List<HistoryEntry>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      final entries = historyJson
          .map((json) => HistoryEntry.fromJson(jsonDecode(json)))
          .toList();

      // Sort by timestamp, newest first
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return entries;
    } catch (e) {
      AppLogger.e('Failed to load history', 'HistoryService', e);
      return [];
    }
  }

  /// Add a new entry to history
  static Future<void> addEntry(HistoryEntry entry) async {
    try {
      final history = await getHistory();
      history.add(entry);

      // Always enforce newest-first ordering before trim/persist.
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Trim to max entries
      if (history.length > _maxHistoryEntries) {
        history.removeRange(_maxHistoryEntries, history.length);
      }

      await _saveHistory(history);
      AppLogger.i('Added history entry: ${entry.issueType}', 'HistoryService');
    } catch (e) {
      AppLogger.e('Failed to add history entry', 'HistoryService', e);
    }
  }

  /// Update an existing entry (e.g., mark repair as completed)
  static Future<void> updateEntry(String id, HistoryEntry updatedEntry) async {
    try {
      final history = await getHistory();
      final index = history.indexWhere((e) => e.id == id);

      if (index != -1) {
        history[index] = updatedEntry;
        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        await _saveHistory(history);
        AppLogger.i('Updated history entry: $id', 'HistoryService');
      }
    } catch (e) {
      AppLogger.e('Failed to update history entry', 'HistoryService', e);
    }
  }

  /// Mark a repair as completed for a given entry
  static Future<void> markRepairCompleted(String id) async {
    try {
      final history = await getHistory();
      final index = history.indexWhere((e) => e.id == id);

      if (index != -1) {
        history[index] = history[index].copyWith(completedRepair: true);
        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        await _saveHistory(history);
      }
    } catch (e) {
      AppLogger.e('Failed to mark repair completed', 'HistoryService', e);
    }
  }

  /// Delete a specific entry
  static Future<void> deleteEntry(String id) async {
    try {
      final history = await getHistory();
      history.removeWhere((e) => e.id == id);
      await _saveHistory(history);
      AppLogger.i('Deleted history entry: $id', 'HistoryService');
    } catch (e) {
      AppLogger.e('Failed to delete history entry', 'HistoryService', e);
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      AppLogger.i('Cleared all history', 'HistoryService');
    } catch (e) {
      AppLogger.e('Failed to clear history', 'HistoryService', e);
    }
  }

  /// Get the most recent entry
  static Future<HistoryEntry?> getLastEntry() async {
    final history = await getHistory();
    return history.isNotEmpty ? history.first : null;
  }

  /// Save history to SharedPreferences
  static Future<void> _saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }
}
