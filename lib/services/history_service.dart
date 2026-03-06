import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadesmaster/models/history_item.dart';

class HistoryService {
  static const String _historyKey = 'shade_master_history';

  static Future<void> saveHistoryItem(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> historyStrings = prefs.getStringList(_historyKey) ?? [];

    // Check if we are updating an existing item (by id)
    final existingIndex = historyStrings.indexWhere((string) {
      try {
        final map = jsonDecode(string);
        return map['id'] == item.id;
      } catch (_) {
        return false;
      }
    });

    final itemJson = jsonEncode(item.toJson());

    if (existingIndex >= 0) {
      // Update existing
      historyStrings[existingIndex] = itemJson;
    } else {
      // Add new
      historyStrings.insert(0, itemJson); // add to top
    }

    await prefs.setStringList(_historyKey, historyStrings);
  }

  static Future<List<HistoryItem>> getHistoryItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings = prefs.getStringList(_historyKey) ?? [];

    final List<HistoryItem> items = [];
    for (String string in historyStrings) {
      try {
        final map = jsonDecode(string);
        items.add(HistoryItem.fromJson(map));
      } catch (e) {
        debugPrint("Error decoding history item: $e");
      }
    }
    return items;
  }

  static Future<void> deleteHistoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings = prefs.getStringList(_historyKey) ?? [];

    historyStrings.removeWhere((string) {
      try {
        final map = jsonDecode(string);
        return map['id'] == id;
      } catch (_) {
        return true; // remove corrupted items
      }
    });

    await prefs.setStringList(_historyKey, historyStrings);
  }
}
