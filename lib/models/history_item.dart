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
    var regionsJson = json['regions'];
    List<List<Region>> loadedRegions = [];

    if (regionsJson is List) {
      for (int i = 0; i < regionsJson.length; i++) {
        var listJson = regionsJson[i];
        List<Region> currentRegionList = [];
        if (listJson is List) {
          for (var regionJson in listJson) {
            if (regionJson is Map) {
              var offsetsJson = regionJson['offsets'];
              if (offsetsJson is List) {
                List<NormalizedOffset> offsets = [];
                for (var o in offsetsJson) {
                  if (o is Map) {
                    if (o.containsKey('nx')) {
                      offsets.add(NormalizedOffset(Offset(
                          (o['nx'] as num).toDouble(),
                          (o['ny'] as num).toDouble())));
                    } else if (o.containsKey('dx')) {
                      // fallback for legacy data that might use 'dx'/'dy'
                      offsets.add(NormalizedOffset(Offset(
                          (o['dx'] as num).toDouble(),
                          (o['dy'] as num).toDouble())));
                    }
                  }
                }
                currentRegionList.add(Region(offsets));
              }
            }
          }
        }
        loadedRegions.add(currentRegionList);
      }
    }

    return HistoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled Session',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'])
          : Uint8List(0),
      regions: loadedRegions,
    );
  }
}
