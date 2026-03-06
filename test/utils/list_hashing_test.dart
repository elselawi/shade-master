import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/utils/list_hashing.dart';

void main() {
  group('listHash', () {
    test('same list content yields same hash', () {
      final list1 = [1, 2, 3];
      final list2 = [1, 2, 3];
      expect(listHash(list1), listHash(list2));
    });

    test('different list content yields different hash', () {
      final list1 = [1, 2, 3];
      final list2 = [1, 2, 4];
      expect(listHash(list1), isNot(listHash(list2)));
    });

    test('order matters for hashing', () {
      final list1 = [1, 2, 3];
      final list2 = [3, 2, 1];
      expect(listHash(list1), isNot(listHash(list2)));
    });

    test('handles nested lists', () {
      final list1 = [
        1,
        [2, 3],
        4
      ];
      final list2 = [
        1,
        [2, 3],
        4
      ];
      final list3 = [
        1,
        [3, 2],
        4
      ];

      expect(listHash(list1), listHash(list2));
      expect(listHash(list1), isNot(listHash(list3)));
    });

    test('handles empty lists', () {
      final list1 = [];
      final list2 = [];
      expect(listHash(list1), listHash(list2));
      expect(listHash(list1), 17); // Seed value
    });

    test('handles different types', () {
      final list1 = [1, 'a', true];
      final list2 = [1, 'a', true];
      expect(listHash(list1), listHash(list2));
    });
  });
}
