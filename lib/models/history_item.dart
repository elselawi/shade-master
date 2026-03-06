import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shadesmaster/drawings.dart';

class HistoryItem {
  final String id;
  final String name;
  final DateTime timestamp;
  final Uint8List imageBytes;
  final List<List<Region>> regions;

  HistoryItem({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.imageBytes,
    required this.regions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'imageBytes': base64Encode(imageBytes),
      'regions': regions.map((regionList) {
        return regionList.map((region) {
          return {
            'offsets': region.offsets
                .map((o) => {
                      'nx': o.normalized.dx,
                      'ny': o.normalized.dy,
                    })
                .toList(),
          };
        }).toList();
      }).toList(),
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    var regionsJson = json['regions'] as List;
    List<List<Region>> loadedRegions = [];

    for (int i = 0; i < regionsJson.length; i++) {
      var listJson = regionsJson[i] as List;
      List<Region> currentRegionList = [];
      for (var regionJson in listJson) {
        var offsetsJson = regionJson['offsets'] as List;
        List<NormalizedOffset> offsets = offsetsJson.map((o) {
          if (o is Map && o.containsKey('nx')) {
            return NormalizedOffset(Offset(
                (o['nx'] as num).toDouble(), (o['ny'] as num).toDouble()));
          }
          // fallback for legacy data that might use 'dx'/'dy'
          return NormalizedOffset(
              Offset((o['dx'] as num).toDouble(), (o['dy'] as num).toDouble()));
        }).toList();
        currentRegionList.add(Region(offsets));
      }
      loadedRegions.add(currentRegionList);
    }

    return HistoryItem(
      id: json['id'],
      name: json['name'],
      timestamp: DateTime.parse(json['timestamp']),
      imageBytes: base64Decode(json['imageBytes']),
      regions: loadedRegions,
    );
  }
}
