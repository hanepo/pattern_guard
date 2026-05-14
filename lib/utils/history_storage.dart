import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pattern_model.dart';

class HistoryStorage {
  static const String historyKey = 'history';
  static const String autoSaveKey = 'auto_save_history';

  static Future<bool> getAutoSaveEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(autoSaveKey) ?? true;
  }

  static Future<void> setAutoSaveEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoSaveKey, value);
  }

  static Future<void> savePattern({
    required List<int> pattern,
    required double score,
    required StrengthCategory strength,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(historyKey) ?? [];

    final entry = HistoryEntry(
      pattern: List<int>.from(pattern),
      score: score,
      strength: strength,
      timestamp: DateTime.now(),
    );

    history.add(jsonEncode(entry.toJson()));

    await prefs.setStringList(historyKey, history);
  }
}