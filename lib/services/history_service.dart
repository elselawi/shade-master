import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:shadesmaster/services/persistence_service.dart';
import 'package:shadesmaster/models/history_item.dart';

class HistoryService {
  static const String _historyKey = 'shade_master_history';

  static Future<void> saveHistoryItem(HistoryItem item) async {
    final persistence = PersistenceService.instance;
    final List<String> historyStrings =
        await persistence.getStringList(_historyKey);

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

    await persistence.setStringList(_historyKey, historyStrings);
  }

  static Future<List<HistoryItem>> getHistoryItems() async {
    final persistence = PersistenceService.instance;
    final List<String> historyStrings =
        await persistence.getStringList(_historyKey);

    debugPrint("Loading ${historyStrings.length} history items...");

    final List<HistoryItem> items = [];
    for (int i = 0; i < historyStrings.length; i++) {
      final string = historyStrings[i];
      try {
        final map = jsonDecode(string);
        items.add(HistoryItem.fromJson(map));
      } catch (e) {
        debugPrint("Error decoding history item at index $i: $e");
        debugPrint(
            "Corrupted data snippet: ${string.length > 100 ? "${string.substring(0, 100)}..." : string}");
      }
    }
    debugPrint("Successfully loaded ${items.length} items.");
    return items;
  }

  static Future<void> deleteHistoryItem(String id) async {
    final persistence = PersistenceService.instance;
    final List<String> historyStrings =
        await persistence.getStringList(_historyKey);

    historyStrings.removeWhere((string) {
      try {
        final map = jsonDecode(string);
        return map['id'] == id;
      } catch (_) {
        return true; // remove corrupted items
      }
    });

    await persistence.setStringList(_historyKey, historyStrings);
  }
}
