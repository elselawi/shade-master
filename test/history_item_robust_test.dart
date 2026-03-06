import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/models/history_item.dart';

void main() {
  group('HistoryItem.fromJson Robustness', () {
    test('should handle empty Map', () {
      final json = <String, dynamic>{};
      final item = HistoryItem.fromJson(json);

      expect(item.id, equals(''));
      expect(item.name, equals('Untitled Session'));
      expect(item.regions, isEmpty);
      expect(item.imageBytes, isEmpty);
    });

    test('should handle corrupted regions (not a list)', () {
      final json = {
        'id': '123',
        'name': 'Test',
        'regions': 'not a list',
      };
      final item = HistoryItem.fromJson(json);
      expect(item.regions, isEmpty);
    });

    test('should handle nested corrupted regions', () {
      final json = {
        'id': '123',
        'name': 'Test',
        'regions': [
          'not a list',
          [
            {'offsets': 'not a list'}
          ]
        ],
      };
      final item = HistoryItem.fromJson(json);
      expect(item.regions.length, equals(2));
      expect(item.regions[0], isEmpty);
      expect(item.regions[1], isEmpty);
    });

    test('should handle corrupted offsets', () {
      final json = {
        'id': '123',
        'name': 'Test',
        'regions': [
          [
            {
              'offsets': [
                {'nx': 0.5, 'ny': 0.5},
                'corrupted offset',
                {'nx': 0.6, 'ny': 0.6}
              ]
            }
          ]
        ],
      };
      final item = HistoryItem.fromJson(json);
      expect(item.regions.length, equals(1));
      expect(item.regions[0].length, equals(1));
      expect(item.regions[0][0].offsets.length, equals(2));
    });

    test('should handle missing fields with defaults', () {
      final json = {
        'id': '123',
        // 'name' missing
        // 'timestamp' missing
        // 'imageBytes' missing
      };
      final item = HistoryItem.fromJson(json);
      expect(item.id, equals('123'));
      expect(item.name, equals('Untitled Session'));
      expect(item.timestamp, isNotNull);
      expect(item.imageBytes, isEmpty);
    });
  });
}
