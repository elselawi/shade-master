import 'dart:async';
import 'package:hive_ce/hive.dart';

class PersistenceService {
  static PersistenceService? _instance;
  static const String _boxName = 'shade_master_persistence';

  static PersistenceService get instance {
    _instance ??= PersistenceService._();
    return _instance!;
  }

  PersistenceService._();

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<String>> getStringList(String key) async {
    final box = await _getBox();
    final List<dynamic>? list = box.get(key);
    return list?.cast<String>() ?? [];
  }

  Future<void> setStringList(String key, List<String> value) async {
    final box = await _getBox();
    await box.put(key, value);
  }
}
